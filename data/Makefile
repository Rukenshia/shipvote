# get cloudfront distribution id for data.shipvote.in.fkn.space
DISTRIBUTION_ID=$(shell aws cloudfront list-distributions | jq -r '.DistributionList.Items[] | select(.Origins.Items[].DomainName == "data.shipvote.in.fkn.space.s3.amazonaws.com") | .Id')


.PHONY: all
all:
	./get_warships.sh

	aws s3 cp ./warships.json s3://data.shipvote.in.fkn.space/shipvote/warships.json
	
	# create invalidation for cloudfront
	aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths /shipvote/*
