.PHONY: cert
cert:
	certbot certonly --config-dir ~/.certbot --logs-dir ~/.certbot --work-dir ~/.certbot \
		--text --email svc-shipvote@ruken.pw \
		--agree-tos --manual -d shipvote.in.fkn.space \
		--preferred-challenges dns
