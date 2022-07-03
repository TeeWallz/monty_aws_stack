#!/bin/bash
source ./config.mk

date="$(aws cloudformation describe-stack-events --stack-name "$AWS_STACK_NAME_BASE" 2>/dev/null | jq -re '[.StackEvents[].Timestamp]|max')" || true

# set -x
set -e

aws cloudformation update-stack --stack-name $AWS_STACK_NAME_BASE \
    --template-body file://./aws/cloud-formation/template-base.yml \
    --parameters ParameterKey=StagingBucketName,ParameterValue=$AWS_STAGING_BUCKET \
                    ParameterKey=WebsiteBucketName,ParameterValue=$AWS_WEBSITE_BUCKET \
                    ParameterKey=ChumBucketName,ParameterValue=$AWS_CHUM_BUCKET \
    --capabilities CAPABILITY_NAMED_IAM


if ! aws cloudformation wait stack-update-complete --stack-name $AWS_STACK_NAME_BASE; then
    echo dump the failure events
    aws cloudformation describe-stack-events --stack-name "$AWS_STACK_NAME_BASE" \
    | date="$date" jq -ce '.StackEvents[] | select(.Timestamp>env.date)' | grep -i fail \
    | jq -re '[.Timestamp,.LogicalResourceId,.ResourceStatusReason] | @tsv' | sort >&2
    echo "Failed to deploy $AWS_STACK_NAME_BASE" >&2
    exit 1
fi

aws cloudformation describe-stacks --stack-name "$AWS_STACK_NAME_BASE" --query 'Stacks[].Outputs' --output table
echo "Finished redeploying $AWS_STACK_NAME_BASE" >&2