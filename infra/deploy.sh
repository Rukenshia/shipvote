#!/bin/bash
set -x

set -e -o pipefail

NEW_AMI="${NEW_AMI:-ami-0b49e2c4b652f31ae}"
LAUNCH_TEMPLATE_NAME="${LAUNCH_TEMPLATE_NAME:-shipvote-web}"
SCALING_GROUP_NAME="${SCALING_GROUP_NAME:-shipvote-web}"

# get current version
current_lc_version="$(aws ec2 describe-launch-template-versions --launch-template-name "${LAUNCH_TEMPLATE_NAME}" | jq '.LaunchTemplateVersions[] | select(.DefaultVersion == true)') | .VersionNumber)"

# create new version
aws ec2 create-launch-template-version --launch-template-name "${LAUNCH_TEMPLATE_NAME}" --source-version '$Latest' --launch-template-data '{"ImageId":"'"${NEW_AMI}"'"}' > /dev/null

# get ASG current desired scale
desired_instances="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "${SCALING_GROUP_NAME}" --query 'AutoScalingGroups[0].DesiredCapacity' --output text)"

# get ASG current instances
current_instances="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "${SCALING_GROUP_NAME}" --query 'AutoScalingGroups[0].Instances' | jq '. | length')"

# get target group arn
target_group_arn="$(aws elbv2 describe-target-groups --names web --query 'TargetGroups[0].TargetGroupArn' --output text)"

# check that current instances are healthy, otherwise abort
healthy_instances="$(aws elbv2 describe-target-health --target-group-arn "${target_group_arn}" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy")] | length')"

if [ "$current_instances" -ne "$desired_instances" ] || [ "$desired_instances" -ne "$healthy_instances" ]; then
    echo "[!] Cannot proceed, instance health precheck failed. current: $current_instances, desired: $desired_instances, healthy: $healthy_instances"
    exit 1
fi

# scale up
desired_instances_transition_phase="$(expr "$desired_instances" '*' 2)"
aws autoscaling update-auto-scaling-group --auto-scaling-group-name shipvote-web --default-cooldown 20 > /dev/null
aws autoscaling set-desired-capacity --auto-scaling-group-name "${SCALING_GROUP_NAME}" --desired-capacity "$desired_instances_transition_phase" > /dev/null

# get amount of healthy instances
healthy_instances="$(aws elbv2 describe-target-health --target-group-arn "${target_group_arn}" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy")] | length')"

tries=0
while true; do
    if [ "$tries" -gt "10" ]; then
        echo "[!] timed out while waiting for instances to become healthy"
        echo "deleting new instances and scaling back down"

        # delete new EC2s by changing the ASG to terminate newest instances
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name shipvote-web --termination-policies "NewestInstance" > /dev/null

        # scale back to normal
        aws autoscaling set-desired-capacity --auto-scaling-group-name shipvote-web --desired-capacity "$desired_instances" > /dev/null

        sleep 60

        # set ASG to default termination policy again
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name shipvote-web --termination-policies "OldestLaunchTemplate" "Default" --default-cooldown 300 > /dev/null
        exit 1
    fi
    let tries=tries+1

    healthy_instances="$(aws elbv2 describe-target-health --target-group-arn "${target_group_arn}" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy")] | length')"

    # check if we are there
    if [ "$healthy_instances" -ge "$desired_instances_transition_phase" ]; then
        echo "all instances healthy"

        # change default version to the new one
        aws ec2 modify-launch-template --launch-template-name shipvote-web --default-version '$Latest' > /dev/null

        # use OldestLaunchTemplate to delete old instances
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name shipvote-web --termination-policies "OldestLaunchTemplate" > /dev/null

        # scale ASG back to normal
        aws autoscaling set-desired-capacity --auto-scaling-group-name shipvote-web --desired-capacity "$desired_instances" > /dev/null

        sleep 60

        # return ASG termination policy back to normal
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name shipvote-web --termination-policies "OldestLaunchTemplate" "Default" --default-cooldown 300 > /dev/null
        break
    else
        sleep 20
    fi
done