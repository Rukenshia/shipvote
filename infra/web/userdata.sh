#!/bin/bash

# get cert
echo -e "$(aws ssm get-parameter --region eu-central-1 --name /shipvote/ssl/cert.pem --query Parameter.Value | sed 's/"//g')" > /opt/shipvote_cert.pem
echo -e "$(aws ssm get-parameter --region eu-central-1  --name /shipvote/ssl/privkey.pem --query Parameter.Value | sed 's/"//g')" > /opt/shipvote_privkey.pem
echo -e "$(aws ssm get-parameter --region eu-central-1 --name /shipvote/ssl/fullchain.pem --query Parameter.Value | sed 's/"//g')" > /opt/shipvote_fullchain.pem
echo -e "$(aws ssm get-parameter --region eu-central-1 --name /shipvote/ssl/chain.pem --query Parameter.Value | sed 's/"//g')" > /opt/shipvote_chain.pem

# make instance available
aws route53 change-resource-record-sets --hosted-zone-id ZWS4BIQ7CAA38 --change-batch '{"Changes": [{"Action": "UPSERT", "ResourceRecordSet": { "Name": "shipvote.in.fkn.space", "Type": "A", "TTL": 1, "ResourceRecords": [{"Value": "'$(curl http://169.254.169.254/latest/meta-data/public-ipv4)'"}]}}]}'
