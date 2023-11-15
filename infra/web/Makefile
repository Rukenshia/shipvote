all: ami deploy

.PHONY: ami
ami:
	packer build -force ami.pkr.hcl

.PHONY: deploy
deploy:
	@TFCLOUD_API_KEY=$(TFCLOUD_API_KEY) \
	WORKSPACE_ID=$(WORKSPACE_ID) \
	bash -c "script -q /dev/null ./deploy.sh"
