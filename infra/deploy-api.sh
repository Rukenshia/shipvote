#!/bin/bash
set -x

set -e -o pipefail

LAUNCH_TEMPLATE_NAME="${LAUNCH_TEMPLATE_NAME:-shipvote-api}"
SCALING_GROUP_NAME="${SCALING_GROUP_NAME:-shipvote-api}"

if [ -z "${NEW_AMI}" ]; then
	echo "[!] NEW_AMI is not set."
	exit
fi
if [ -z "${NEW_SNAPSHOT_ID}" ]; then
	echo "[!] NEW_SNAPSHOT_ID is not set."
	exit
fi

# create new version
aws ec2 create-launch-template-version --launch-template-name "${LAUNCH_TEMPLATE_NAME}" --source-version '$Latest' --launch-template-data '{"ImageId":"'"${NEW_AMI}"'", "BlockDeviceMappings": [{"DeviceName": "/dev/xvda", "Ebs": {"SnapshotId": "'"${NEW_SNAPSHOT_ID}"'", "Encrypted": false, "DeleteOnTermination": true, "VolumeSize": 8, "VolumeType": "gp2"}}]}' > /dev/null

# change default version to the new one
aws ec2 modify-launch-template --launch-template-name "${LAUNCH_TEMPLATE_NAME}" --default-version '$Latest' > /dev/null

# destroy current instance
instances="$(aws ec2 describe-instances --filters Name=tag:app,Values=shipvote Name=tag:tier,Values=api | jq -r '.Reservations[].Instances[] | select(.State.Name == "running") | .InstanceId')" 


for instance in $instances; do
	echo "Terminating instance ${instance}"

	aws ec2 terminate-instances --instance-ids "${instance}"
done
