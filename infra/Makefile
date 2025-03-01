REGION ?= eu-central-1
DB_INSTANCE_ID := $(shell aws --region ${REGION} ec2 describe-instances --filters 'Name=tag:Name,Values=shipvote-db' 'Name=instance-state-name,Values=running' --output text --query 'Reservations[*].Instances[*].InstanceId')
DB_AZ := $(shell aws --region ${REGION} ec2 describe-instances --filters 'Name=tag:Name,Values=shipvote-db' 'Name=instance-state-name,Values=running' --output text --query 'Reservations[*].Instances[*].Placement.AvailabilityZone')
DB_IP := $(shell aws --region ${REGION} ec2 describe-instances --filters 'Name=tag:Name,Values=shipvote-db' 'Name=instance-state-name,Values=running' --output text --query 'Reservations[*].Instances[*].NetworkInterfaces[*].Association.PublicDnsName')
SSH_USER ?= ec2-user
INSTANCE_ID := $(shell aws --region ${REGION} ec2 describe-instances --filters 'Name=tag:Name,Values=shipvote' 'Name=instance-state-name,Values=running' --output text --query 'Reservations[*].Instances[*].InstanceId')

export AWS_DEFAULT_REGION=${REGION}

.PHONY: cert
cert:
	poetry run certbot certonly --config-dir ~/.certbot --logs-dir ~/.certbot --work-dir ~/.certbot \
		--dns-route53 \
		--email svc-shipvote@ruken.pw \
		--agree-tos -d shipvote.in.fkn.space

.PHONY: upload
upload:
	aws ssm put-parameter --overwrite --type String --name /shipvote/ssl/cert.pem --value file://$$HOME/.certbot/live/shipvote.in.fkn.space/cert.pem
	aws ssm put-parameter --overwrite --type String --name /shipvote/ssl/privkey.pem --value file://$$HOME/.certbot/live/shipvote.in.fkn.space/privkey.pem
	aws ssm put-parameter --overwrite --type String --name /shipvote/ssl/chain.pem --value file://$$HOME/.certbot/live/shipvote.in.fkn.space/chain.pem

.PHONY: terminate-instance
terminate-instance:
	aws ec2 terminate-instances --instance-ids ${INSTANCE_ID}


.PHONY: upload-key
upload-key:
	aws ec2-instance-connect send-ssh-public-key \
		--region ${REGION} \
		--instance-id ${INSTANCE_ID} \
		--availability-zone ${AVAILABILITY_ZONE} \
		--instance-os-user ${SSH_USER} \
		--ssh-public-key file://${HOME}/.ssh/chrstphrsn_aws_rsa.pub

.PHONY: connect-db
connect-db:
	$(MAKE) REGION=${REGION} INSTANCE_ID=${DB_INSTANCE_ID} AVAILABILITY_ZONE=${DB_AZ} SSH_USER=bitnami upload-key
	ssh -i ${HOME}/.ssh/chrstphrsn_aws_rsa bitnami@${DB_IP}
