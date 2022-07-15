SHELL := /bin/bash
include ./config.mk
include ./config_secrets.mk

MONTY_FRONTEND_URL = $(shell aws cloudformation describe-stacks --stack-name $(AWS_STACK_NAME_BASE) | jq '.Stacks[0].Outputs[1].OutputValue')
MONTY_BACKEND_URL = $(shell aws cloudformation describe-stacks --stack-name $(AWS_STACK_NAME_BACKEND) | jq '.Stacks[0].Outputs[1].OutputValue')
MONTY_BACKEND_URL_BASE = $(shell echo $(MONTY_BACKEND_URL) | sed -r 's/https:\/\/(.+)\/.+/\1/g')
BACKEND_CLOUDFLARE_ID = $(shell make cloudflare-dns-list-api-data)

CLOUDFLARE_TOKEN = $(shell source "./aws_utils.sh" && get_ssm_param "/monty/CLOUDFLARE_TOKEN")
CLOUDFLARE_ZONE_ID = $(shell source "./aws_utils.sh" && get_ssm_param "/monty/CLOUDFLARE_ZONE_ID")



build-frontend:
	MONTY_BACKEND_URL=$(MONTY_BACKEND_URL) yarn build:frontend

build-backend:
	# yarn build:backend
	# make package-sam
	# @echo "^Do not use that last suggested command!^ Execute the following command instead:"
	# make deploy-backend

# deploy-frontend:
# 	aws s3 cp ./dist/frontend/ s3://$(AWS_WEBSITE_BUCKET)/ --recursive --include "*" --acl public-read

deploy-backend:
	make package-sam
	aws cloudformation deploy --stack-name $(AWS_STACK_NAME_BACKEND) \
		--template-file ./dist/backend/template-sam.yaml \
		--parameter-overrides ChumBucketName=$(AWS_CHUM_BUCKET) \
		--capabilities CAPABILITY_IAM
	aws cloudformation wait stack-update-complete --stack-name $(AWS_STACK_NAME_BACKEND)

package-sam:
	mkdir -p ./dist/backend
	mkdir -p ./build
	rm -rf ./build/*
	rm -rf ./dist/backend/*
	cp -r ./src/backend/flask_api/* ./dist/backend/
	python3.9 -m venv ./build/venv
	source ./build/venv/bin/activate
	./build/venv/bin/pip install -r ./dist/backend/requirements.txt -t ./dist/backend/
	# deactivate
	aws cloudformation package \
		--template-file ./aws/cloud-formation/template-sam.yml \
		--s3-bucket $(AWS_STAGING_BUCKET) \
		--output-template-file ./dist/backend/template-sam.yaml

deprovision-base:
	aws cloudformation delete-stack --stack-name $(AWS_STACK_NAME_BASE)
	aws cloudformation wait stack-delete-complete --stack-name $(AWS_STACK_NAME_BASE)

deprovision-backend:
	aws cloudformation delete-stack --stack-name $(AWS_STACK_NAME_BACKEND)

dev-frontend:
	# MONTY_BACKEND_URL=$(MONTY_BACKEND_URL) yarn dev
	 npm run start --prefix src/frontend

.ONESHELL:
dev-backend:
	# source /home/tom/git/home/monty_aws_fullstack/config.mk
	FLASK_APP=./src/backend/flask_api/app.py BUCKET_NAME=$(AWS_CHUM_BUCKET) FLASK_ENV=development python -m flask run

# put-types:
# 	mkdir -p ./temp
# 	npx babel ./src/backend/* --out-dir ./temp/src/backend
# 	XilutionClientId=$(XILUTION_CLIENT_ID) node ./utils/types/put-types.js

provision-base:
	aws cloudformation create-stack --stack-name $(AWS_STACK_NAME_BASE) \
		--template-body file://./aws/cloud-formation/template-base.yml \
		--parameters ParameterKey=StagingBucketName,ParameterValue=$(AWS_STAGING_BUCKET) \
					 ParameterKey=WebsiteBucketName,ParameterValue=$(AWS_WEBSITE_BUCKET) \
					 ParameterKey=ChumBucketName,ParameterValue=$(AWS_CHUM_BUCKET) \
		--capabilities CAPABILITY_NAMED_IAM
	aws cloudformation wait stack-create-complete --stack-name $(AWS_STACK_NAME_BASE)

reprovision-base:
	makefile_scripts/reprovision-base.sh
	# aws cloudformation update-stack --stack-name $(AWS_STACK_NAME_BASE) \
	# 	--template-body file://./aws/cloud-formation/template-base.yml \
	# 	--parameters ParameterKey=StagingBucketName,ParameterValue=$(AWS_STAGING_BUCKET) \
	# 				 ParameterKey=WebsiteBucketName,ParameterValue=$(AWS_WEBSITE_BUCKET) \
	# 				 ParameterKey=ChumBucketName,ParameterValue=$(AWS_CHUM_BUCKET) \
    #     --capabilities CAPABILITY_NAMED_IAM
	# aws cloudformation wait stack-update-complete --stack-name $(AWS_STACK_NAME_BASE)

describe-events-base:
	aws cloudformation describe-stack-events --stack-name $(AWS_STACK_NAME_BASE) \
        | date="$date" jq -ce '.StackEvents[] | select(.Timestamp>env.date)' | grep -i FAILED \
        | jq -re '[.Timestamp,.LogicalResourceId,.ResourceStatusReason] | @tsv' | sort >&2

show-frontend-url:
	@echo $(MONTY_FRONTEND_URL)

show-backend-url:
	@echo $(MONTY_BACKEND_URL)

show-backend-base-url:
	@echo $(MONTY_BACKEND_URL_BASE)
	
show-frontend-ssl-url:
	@echo https://s3.$(AWS_REGION).amazonaws.com/$(AWS_WEBSITE_BUCKET)/index.html

cloudflare-dns-verify-token:
	curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
		-H "Authorization: Bearer $(CLOUDFLARE_TOKEN)" \
		-H "Content-Type:application/json"; echo 
	
cloudflare-dns-list-zones:
	curl -X GET "https://api.cloudflare.com/client/v4/zones/$(CLOUDFLARE_ZONE_ID)/dns_records" \
		-H "Authorization: Bearer $(CLOUDFLARE_TOKEN)" \
		-H "Content-Type: application/json"; echo

cloudflare-dns-list-api-data:
	curl -X GET "https://api.cloudflare.com/client/v4/zones/$(CLOUDFLARE_ZONE_ID)/dns_records?name=api.howmanydayssincemontaguestreetbridgehasbeenhit.com" \
		-H "Authorization: Bearer $(CLOUDFLARE_TOKEN)" \
		-H "Content-Type: application/json" ; echo
	# | jq '.result[0].id'

cloudflare-dns-update-backend:
	@echo $(shell makefile_scripts/update_backend_dns.sh)
	
