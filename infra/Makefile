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
