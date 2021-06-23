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
cp -r /database/postgres /database/backup/$(date +"%Y-%m-%d")-postgres

ln -s /database/postgres/conf /opt/bitnami/postgresql/conf
ln -s /database/postgres/data /opt/bitnami/postgresql/data

systemctl start bitnami
