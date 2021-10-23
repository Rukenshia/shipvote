#!/bin/bash -xe
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -o pipefail

volume_id="$(aws ec2 --region eu-central-1 describe-volumes --filter 'Name=tag:Name,Values=shipvote-db-persistent' --output text --query 'Volumes[*].VolumeId')"
instance_id="$(curl 'http://169.254.169.254/latest/meta-data/instance-id')"

aws --region eu-central-1 ec2 attach-volume --volume-id "${volume_id}" --instance-id "${instance_id}" --device '/dev/xvdd'
sleep 10
mkdir /database

# aws remaps it to a nvme device name, the root disk is nvme0n1, so next one is nvme1n1
mount /dev/nvme1n1 /database
chown -R postgres:postgres /database

systemctl stop bitnami

rm -rf /opt/bitnami/postgresql/conf
unlink /opt/bitnami/postgresql/data

# create backup
cp -r /database/postgres "/database/backup/$(date +"%Y-%m-%d")-postgres"

ln -s /database/postgres/conf /opt/bitnami/postgresql/conf
ln -s /database/postgres/data /opt/bitnami/postgresql/data

systemctl start bitnami

aws route53 change-resource-record-sets --hosted-zone-id ZWS4BIQ7CAA38 \
    --change-batch '{"Changes": [{"Action": "UPSERT", "ResourceRecordSet": { "Name": "db.shipvote.in.fkn.space", "Type": "A", "TTL": 1, "ResourceRecords": [{"Value": "'"$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"'"}]}}]}'

# install appsignal agent
curl -L https://packagecloud.io/appsignal/agent/gpgkey | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/appsignal_agent.list
deb https://packagecloud.io/appsignal/agent/ubuntu/ focal main
deb-src https://packagecloud.io/appsignal/agent/ubuntu/ focal main
EOF

apt-get update && apt-get install --yes appsignal-agent

aws --region eu-central-1 s3 cp s3://shipvote.artifacts/appsignal-agent.conf /etc/appsignal-agent.conf
systemctl restart appsignal-agent
