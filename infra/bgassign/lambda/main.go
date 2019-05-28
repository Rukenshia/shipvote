package main

import (
	"context"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/ssm"
)

// Handler is the main entry point of the lambda
func Handler(ctx context.Context) (string, error) {
	s := session.New()
	ec2svc := ec2.New(s)
	ssmsvc := ssm.New(s)

	// check if there is an existing instance with the "background features" tag
	params := &ec2.DescribeInstancesInput{
		Filters: []*ec2.Filter{
			{
				Name:   aws.String("tag:background-features"),
				Values: []*string{aws.String("enabled")},
			},
		},
	}

	resp, err := ec2svc.DescribeInstances(params)
	if err != nil {
		log.Fatal("Could not describe instances:", err)
	}

	if len(resp.Reservations) > 0 {
		log.Printf("Found instance %s with background-features enabled. No action required.\n", *resp.Reservations[0].Instances[0].InstanceId)
		return "noop", nil
	}

	webInstances, err := getWebInstances(ec2svc)
	if err != nil {
		log.Fatal("Could not describe web instances:", err)
	}

	log.Printf("Found %d web instances. Using instance %s for background features\n", len(webInstances), *webInstances[0].InstanceId)

	if err := enableBackgroundFeatures(ec2svc, *webInstances[0].InstanceId, ssmsvc); err != nil {
		log.Fatal("Could not enable background features:", err)
	}

	log.Printf("Successfully set instance %s to use background features\n", *webInstances[0].InstanceId)

	return "", nil
}

func getWebInstances(ec2svc *ec2.EC2) ([]*ec2.Instance, error) {
	params := &ec2.DescribeInstancesInput{
		Filters: []*ec2.Filter{
			{
				Name:   aws.String("tag:app"),
				Values: []*string{aws.String("shipvote")},
			},
			{
				Name:   aws.String("tag:tier"),
				Values: []*string{aws.String("web")},
			},
		},
	}

	resp, err := ec2svc.DescribeInstances(params)
	if err != nil {
		return nil, err
	}

	var instances []*ec2.Instance

	for _, r := range resp.Reservations {
		instances = append(instances, r.Instances...)
	}
	return instances, nil
}

func enableBackgroundFeatures(ec2svc *ec2.EC2, instanceID string, ssmsvc *ssm.SSM) error {
	command := &ssm.SendCommandInput{
		Comment:      aws.String("run by bgassign"),
		DocumentName: aws.String("AWS-RunShellScript"),
		InstanceIds:  []*string{aws.String(instanceID)},
		Parameters: map[string][]*string{
			"commands": []*string{
				aws.String("sed -i'' 's/REFRESH=0/REFRESH=1/g' /opt/shipvote/shipvote.env"),
				aws.String("sudo systemctl restart shipvote"),
			},
		},
	}

	log.Println("Sending SSM command")

	if _, err := ssmsvc.SendCommand(command); err != nil {
		return err
	}

	log.Println("Tagging instance with background-features enabled")

	// tag instance
	_, err := ec2svc.CreateTags(&ec2.CreateTagsInput{
		Resources: []*string{aws.String(instanceID)},
		Tags: []*ec2.Tag{
			{Key: aws.String("background-features"), Value: aws.String("enabled")},
		},
	})
	return err
}

func main() {
	lambda.Start(Handler)
}
