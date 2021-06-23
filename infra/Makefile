REGION ?= eu-central-1
DB_INSTANCE_ID := $(shell aws --region ${REGION} ec2 describe-instances --filters 'Name=tag:Name,Values=shipvote-db' 'Name=instance-state-name,Values=running' --output text --query 'Reservations[*].Instances[*].InstanceId')
DB_AZ := $(shell aws --region ${REGION} ec2 describe-instances --filters 'Name=tag:Name,Values=shipvote-db' 'Name=instance-state-name,Values=running' --output text --query 'Reservations[*].Instances[*].Placement.AvailabilityZone')
DB_IP := $(shell aws --region ${REGION} ec2 describe-instances --filters 'Name=tag:Name,Values=shipvote-db' 'Name=instance-state-name,Values=running' --output text --query 'Reservations[*].Instances[*].NetworkInterfaces[*].Association.PublicDnsName')
SSH_USER ?= ec2-user

.PHONY: cert
cert:
	certbot certonly --config-dir ~/.certbot --logs-dir ~/.certbot --work-dir ~/.certbot \
		--text --email svc-shipvote@ruken.pw \
		--agree-tos --manual -d shipvote.in.fkn.space \
		--preferred-challenges dns

.PHONY: upload
upload:
	aws ssm put-parameter --overwrite --type String --name /shipvote/ssl/cert.pem --value file://$$HOME/.certbot/live/shipvote.in.fkn.space/cert.pem
	aws ssm put-parameter --overwrite --type String --name /shipvote/ssl/privkey.pem --value file://$$HOME/.certbot/live/shipvote.in.fkn.space/privkey.pem
	aws ssm put-parameter --overwrite --type String --name /shipvote/ssl/fullchain.pem --value file://$$HOME/.certbot/live/shipvote.in.fkn.space/fullchain.pem
	aws ssm put-parameter --overwrite --type String --name /shipvote/ssl/chain.pem --value file://$$HOME/.certbot/live/shipvote.in.fkn.space/chain.pem

.PHONY: use-cert
use-cert:
	echo -e "$$(aws ssm get-parameter --name /shipvote/ssl/cert.pem --query Parameter.Value | sed 's/"//g')" > /opt/shipvote_cert.pem
	echo -e "$$(aws ssm get-parameter --name /shipvote/ssl/privkey.pem --query Parameter.Value | sed 's/"//g')" > /opt/shipvote_privkey.pem
	echo -e "$$(aws ssm get-parameter --name /shipvote/ssl/fullchain.pem --query Parameter.Value | sed 's/"//g')" > /opt/shipvote_fullchain.pem
	echo -e "$$(aws ssm get-parameter --name /shipvote/ssl/chain.pem --query Parameter.Value | sed 's/"//g')" > /opt/shipvote_chain.pem

.PHONY: upload-key
upload-key:
	aws ec2-instance-connect send-ssh-public-key \
		--region ${REGION} \
		--instance-id ${INSTANCE_ID} \
		--availability-zone ${AVAILABILITY_ZONE} \
		--instance-os-user ${SSH_USER} \
		--ssh-public-key file://${HOME}/.ssh/aws_instance_connect.pub

.PHONY: connect-db
connect-db:
	$(MAKE) REGION=${REGION} INSTANCE_ID=${DB_INSTANCE_ID} AVAILABILITY_ZONE=${DB_AZ} SSH_USER=bitnami upload-key
	ssh -i ${HOME}/.ssh/aws_instance_connect bitnami@${DB_IP}


.PHONY: base-images
base-images:
	packer build ./ami.backend.base.json
