#!/bin/bash

# snippets

# purple
log() { ( set +x; printf '\e[1;35m%s\e[m\n' "$*" ) >&2; }

# yellow
warn() { ( set +x; printf '\e[1;33m%s\e[m\n' "$*" ) >&2; }

# red
error() { ( set +x; printf '\e[1;31m%s\e[m\n' "$*" ) >&2; }

urlencode () {
    echo -n "${@-"$(cat)"}" | jq -Rsr @uri | sed 's/%20/+/g'
}

xmlencode() {
    echo -n "${@-"$(cat)"}" | jq -Rsr @html
}

join_by() ( sep="$1" && shift && jq -rn '$ARGS.positional | join(",")' --args "$@"; )

# credstash/unicreds fallback
if ! command -v credstash &>/dev/null; then
    credstash() { unicreds "$@"; }
fi

get_stack_output() {
    aws cloudformation describe-stacks --stack-name "$1" \
    | key="$2" jq -re '.Stacks[0].Outputs[] | select(.OutputKey==env.key).OutputValue' \
    || { echo Could not find stack output "$1" "$2" >&2; return 1; }
}

get_stack_export() {
    aws cloudformation list-exports \
    | key="$1" jq -re '.Exports[] | select(.Name==env.key).Value' \
    || { echo Could not find stack export "$1" >&2; return 1; }
}

get_stack_parameter() {
    aws cloudformation describe-stacks --stack-name "$1" \
    | key="$2" jq -re '.Stacks[0].Parameters[] | select(.ParameterKey==env.key).ParameterValue' \
    || { echo Could not find stack parameter "$1" "$2" >&2; return 1; }
}

get_stack_resource() {
    aws cloudformation describe-stack-resources --stack-name "$1" --logical-resource-id "$2" \
    | jq -re '.StackResources[].PhysicalResourceId' \
    || { echo Could not find stack resource "$1" "$2" >&2; return 1; }
}

get_account_id() {
    aws sts get-caller-identity --query Account --output text
}

get_org_id() {
    aws organizations describe-organization | jq -re .Organization.Id
}

get_aws_region() {
    python3 -c 'import botocore.session; print(botocore.session.Session().get_config_variable("region"))'
}

get_ssm_param() {
    aws ssm get-parameter --name "$1" --query Parameter.Value --with-decryption --output text \
    || { echo Could not find ssm parameter "$1" >&2; return 1; }
}

put_ssm_param() {
    aws ssm put-parameter --name "$1" --value "$2" --type "${3:-String}" --overwrite >/dev/null
}

get_secret() {
    aws secretsmanager get-secret-value --secret-id "$1" --query SecretString --output text \
    || { echo Could not find in secrets manager "$1" >&2; return 1; }
}

get_secret_arn() {
    aws secretsmanager get-secret-value --secret-id "$1" --query ARN --output text \
    || { echo Could not find in secrets manager "$1" >&2; return 1; }
}

assume_role() (
    # usage: eval $(assume_role role_arn [role_session_name])
    role_arn="$1"
    role_session_name="${2:-$(uuidgen)}"

    creds="$(
        set -o pipefail
        aws sts assume-role --role-arn "$role_arn" --role-session-name "$role_session_name" --query Credentials \
        | jq -re '["AWS_ACCESS_KEY_ID="+.AccessKeyId, "AWS_SECRET_ACCESS_KEY="+.SecretAccessKey, "AWS_SESSION_TOKEN="+.SessionToken] | @sh'
    )" || {
        echo "Failed to assume role: $role_arn" >&2
        echo false
        return 1
    }
    echo "export $creds"
)

get_route53_alias_target() (
    record="${1%%.}."
    hosted_zone="$2"
    aws route53 list-resource-record-sets --hosted-zone-id "$hosted_zone" \
    | record="$record" jq -re '.ResourceRecordSets[] | select(.Name==env.record).AliasTarget.DNSName | rtrimstr(".")' \
    || { echo Could not find route53 alias "$hosted_zone" "$record" >&2; return 1; }
)

get_hosted_zone_id() (
    case "${2:-}" in
        private) filter='and (.Config.PrivateZone)' ;;
        public)  filter='and (.Config.PrivateZone|not)' ;;
    esac
    aws route53 list-hosted-zones-by-name \
    | name="${1%%.}." jq -re '.HostedZones[] | select(.Name==env.name '"${filter:-}"').Id | split("/")[2]' \
    || { echo Could not find "$2" route53 hosted zone "$1" >&2; return 1; }
)

list_existing_stacks() {
    aws cloudformation list-stacks | jq -re '.StackSummaries[] | select(.StackStatus!="DELETE_COMPLETE").StackName'
}

get_stack_events() {
    aws cloudformation describe-stack-events --stack-name "$@" \
    | jq -r '.StackEvents | sort_by(.Timestamp)[] | [.Timestamp, .ResourceStatus, .LogicalResourceId, .ResourceStatusReason] | @tsv'
}

# light weight deploy_stack()
deploy_stack() (
    stack_name="$1"
    shift
    
    date="$(aws cloudformation describe-stack-events --stack-name "$stack_name" 2>/dev/null | jq -re '[.StackEvents[].Timestamp]|max')" || true
    
    set -x
    aws cloudformation deploy --stack-name "$stack_name" --no-fail-on-empty-changeset "$@"
    exit 1
    
    if ! aws cloudformation deploy --stack-name "$stack_name" --no-fail-on-empty-changeset "$@"; then
        dump the failure events
        aws cloudformation describe-stack-events --stack-name "$stack_name" \
        | date="$date" jq -ce '.StackEvents[] | select(.Timestamp>env.date)' | grep -i fail \
        | jq -re '[.Timestamp,.LogicalResourceId,.ResourceStatusReason] | @tsv' | sort >&2
        echo "Failed to deploy $stack_name" >&2
        return 1
    fi

    aws cloudformation describe-stacks --stack-name "$stack_name" --query 'Stacks[].Outputs' --output table
    echo "Finished deploying $stack_name" >&2
)





delete_stack() (
    aws cloudformation delete-stack --stack-name "$1" && \
    aws cloudformation wait stack-delete-complete --stack-name "$1"
)

get_stack_status() {
    aws cloudformation describe-stacks --stack-name "$1" --query 'Stacks[0].StackStatus' --output text
}

set_stack_policy() {
    # usage: set_stack_policy stack_name < policy.json
    aws cloudformation set-stack-policy --stack-name "$1" --stack-policy-body "file:///dev/stdin"
}

change_route53_record() (
    change_id="$(aws route53 change-resource-record-sets "$@" --query 'ChangeInfo.Id' --output text)" && \
    aws route53 wait resource-record-sets-changed --id "$change_id"
)

share_ami() (
    # usage: share_ami ami_id account_id_1 account_id_2 ...
    ami="$1"
    shift
    aws ec2 modify-image-attribute --image-id "$ami" --attribute launchPermission --operation-type add --user-ids "$@"
)

# add to your packer file:
#       "post-processors": [{ "type": "manifest", "output": "manifest.json", "strip_path": true }]
ami_from_packer_manifest() {
    # usage: ami_from_packer_manifest < manifest.json
    jq -re '.builds[-1].artifact_id | split(":")[1]'
}

get_acm_cert() (
    name="$1"
    shift
    aws acm list-certificates --certificate-statuses ISSUED --includes keyTypes=RSA_2048,RSA_1024,RSA_4096,EC_prime256v1,EC_secp384r1,EC_secp521r1 "$@" \
    | name="${name%.}" jq -re '[.CertificateSummaryList[] | select(.DomainName==env.name).CertificateArn][0]' \
    || { echo Could not find issued ACM cert "$name" >&2; return 1; }
)

make_s3_bucket() {
    aws s3api head-bucket --bucket "$1" >/dev/null || aws s3 mb "s3://$1"
}

# this is crap, don't use it
package_sam_lambda() (
    template="$1"
    s3path="$2"
    s3path="$(<<<"$s3path" sed 's,^s3://,,')"
    bucket="$(<<<"$s3path" cut -d/ -f1)"
    s3prefix="$(<<<"$s3path" cut -d/ -f2- -s)"

    aws s3api head-bucket --bucket "$bucket" >/dev/null || aws s3 mb "s3://$bucket"
    output="$(mktemp)"
    trap 'rm -f "$output"' EXIT
    aws cloudformation package \
        --template-file "$template" \
        --s3-bucket "$bucket" \
        --s3-prefix "$s3prefix" \
        --output-template-file "$output" >&2
    cat "$output"
)

ansible_eval() (
    var="$1"
    shift
    ANSIBLE_LOAD_CALLBACK_PLUGINS=1 ANSIBLE_STDOUT_CALLBACK=json \
        ansible localhost -c local -m debug -a 'msg={{ _variable }}' -e _variable="{{ $var }}" "$@" \
        | jq -er '.plays[0].tasks[0].hosts.localhost | select(.failed|not).msg'
)

get_kms_key_arn() {
    aws kms describe-key --key-id "$1" --query 'KeyMetadata.Arn' --output text
}

get_cognito_user_pool_client_id() {
    aws cognito-idp list-user-pool-clients --user-pool-id "$1" | name="$2" jq -re '.UserPoolClients[] | select(.ClientName==env.name).ClientId'
}

get_amazon_linux2_ami() {
    aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query Parameter.Value --output text
}

change_security_group_rule() (
    # usage: change_security_group_rule authorize|revoke ingress|egress from=sg-abcdef|ip.address to=sg-abcdef port=1234 [descr=...] [proto=tcp|udp|icmp|all]
    action="$1"
    direction="$2"
    shift 2
    unset proto port from descr
    export "$@"
    perms="$(jq -nce '[{IpProtocol: (env.proto//"tcp"), FromPort: env.port|tonumber, ToPort: env.port|tonumber}]')"
    if [[ "$from" == sg-* ]]; then
        perms="$(<<<"$perms" jq -ce '.[0].UserIdGroupPairs |= [{GroupId: env.from, Description: (env.descr//"")}]')"
    else
        perms="$(<<<"$perms" jq -ce '.[0].IpRanges |= [{CidrIp: env.from, Description: (env.descr//"")}]')"
    fi
    if ! error="$(aws ec2 "$action-security-group-$direction" --group-id "$to" --ip-permissions "$perms" 2>&1 1>/dev/null)" &&
        [[ "$error" != *'An error occurred (InvalidPermission.Duplicate) when calling the AuthorizeSecurityGroupIngress'* ]] &&
        [[ "$error" != *'An error occurred (InvalidPermission.NotFound) when calling the RevokeSecurityGroupIngress'* ]]; then
        echo "$error" >&2
        exit 1
    fi
)

guess_hosted_zone() (
    case "${2:-}" in
        private) filter='and (.Config.PrivateZone)' ;;
        public)  filter='and (.Config.PrivateZone|not)' ;;
    esac
    aws route53 list-hosted-zones-by-name \
    | record="${1%%.}." jq -re "[.HostedZones[] | .Name as \$name | select((env.record|endswith(\$name)) ${filter:-})] | max_by(.Name|length).Id" \
    || { echo "Unable to determine hosted zone for $1" >&2; return 1; }
)

upsert_route53_record() (
    export record="${1%%.}." type="$2" target="$3" record_hosted_zone_id="$4" ttl="$5"

    change="$(jq -nc ' {
        Changes: [{
            Action: "UPSERT",
            ResourceRecordSet: {
                Name: env.record,
                Type: env.type,
                TTL: (env.ttl | tonumber),
                ResourceRecords: [{Value: env.target}]
            }
        }]
    }')"
    change_id="$(aws route53 change-resource-record-sets --hosted-zone-id "$hosted_zone" --change-batch "$change" --query 'ChangeInfo.Id' --output text)" && \
    aws route53 wait resource-record-sets-changed --id "$change_id"
)

upsert_route53_alias() (
    export record="${1%%.}." target="$2" record_hosted_zone_id="$3"
    export target_hosted_zone_id="${4-"$record_hosted_zone_id"}"

    change="$(jq -nc '{
        Changes: [{
            Action: "UPSERT",
            ResourceRecordSet: {
              Name: env.record,
              Type: "A",
              AliasTarget: {HostedZoneId: env.target_hosted_zone_id, DNSName: env.target, EvaluateTargetHealth: false}
            }
        }]
    }')"
    change_id="$(aws route53 change-resource-record-sets --hosted-zone-id "$record_hosted_zone_id" --change-batch "$change" --query 'ChangeInfo.Id' --output text)" && \
    aws route53 wait resource-record-sets-changed --id "$change_id"
)

delete_route53_records() (
    export record="${1%%.}." hosted_zone="$2" type="${3:-}"
    change="$(
        aws route53 list-resource-record-sets --hosted-zone-id="$hosted_zone" --start-record-name="$record" \
        | jq -c "{Changes: [
            .ResourceRecordSets[]
            | select(.Name==env.record ${type:+'and .Type==env.type'})
            | {Action: \"DELETE\", ResourceRecordSet: .}
        ]}"
    )" && \
    if <<<"$change" jq -e '.Changes | length != 0' >/dev/null; then
        change_id="$(aws route53 change-resource-record-sets --hosted-zone-id "$hosted_zone" --change-batch "$change" --query 'ChangeInfo.Id' --output text)" && \
        aws route53 wait resource-record-sets-changed --id "$change_id"
    fi
)

get_console_output() {
    aws ec2 get-console-output --query Output --output text --instance-id "$@"
}

get_ec2_in_stack() {
    aws ec2 describe-instances --filters Name=instance-state-name,Values=running,pending Name=tag:aws:cloudformation:stack-name,Values="$1" | jq -re '.Reservations[].Instances[].InstanceId'
}

get_ec2_tag() {
    aws ec2 describe-tags --filters "Name=resource-id,Values=$1" "Name=key,Values=$2" | jq -re '.Tags[0].Value' \
    || { echo "Unable to get tag $2 for $1" >&2; return 1; }
}

get_ami_by_name() {
    aws ec2 describe-images --owners self --filters "Name=name,Values=$@" \
    | jq -re '.Images | sort_by(.CreationDate)[].ImageId'
}

change_stack_termination_protection() {
    # usage: change_stack_termination_protection STACK enable|no-enable
    aws cloudformation update-termination-protection --"$2"-termination-protection --stack-name "$1"
}

changeset_will_replace() (
    changeset="$1"
    export resource="$2"
    aws cloudformation describe-change-set --change-set-name "$changeset" \
    | jq -re  '
    .Changes | map(.ResourceChange
        | select(
                .LogicalResourceId==env.resource
            and .Action=="Modify"
            and .Replacement!="False"
            and (.Details | any(.Target.RequiresRecreation=="Always"))
    ) )[0] and "1" // ""'
)

cleanup_failed_stack() {
    if (aws cloudformation describe-stacks --stack-name "$1" | jq -e '.Stacks[0].StackStatus=="ROLLBACK_COMPLETE"') &>/dev/null; then
        # rollback complete stacks can never be updated
        echo Existing stack found in ROLLBACK_COMPLETE state >&2
        echo Deleting existing stack >&2
        aws cloudformation delete-stack --stack-name "$1" && \
        aws cloudformation wait stack-delete-complete --stack-name "$1"
    fi
}

stop_ec2() {
    aws ec2 stop-instances --instance-ids "$1" && \
    aws ec2 wait instance-stopped --instance-ids "$1"
}

start_ec2() {
    aws ec2 start-instances --instance-ids "$1" && \
    aws ec2 wait instance-running --instance-ids "$1"
}

terminate_ec2() {
    aws ec2 terminate-instances --instance-ids "$1" && \
    aws ec2 wait instance-terminated --instance-ids "$1"
}

create_snapshot() (
    snapshot="$(aws ec2 create-snapshot --volume-id "$1")" && \
    aws ec2 wait snapshot-completed --snapshot-ids "$(<<<"$snapshot" jq .re .SnapshotId)" >/dev/null && \
    echo "$snapshot"
)

modify_volume() (
    aws ec2 modify-volume --volume-id "$@"
    while true; do
        state="$(aws ec2 describe-volumes-modifications --volume-ids "$1" | jq -re '.VolumesModifications[].ModificationState')" || return 1
        [ "$state" != failed ] || return 1
        [ "$state" = modifying ] || break
        sleep 10
    done
)

force_delete_lambda_eni() (
    # use this before deleting stack with vpc lambda, but only if safe, lambda should not be in use
    security_groups="$(aws lambda get-function --function-name "$1" | jq -re '.Configuration.VpcConfig.SecurityGroupIds | join(",")')"
    aws ec2 describe-network-interfaces --filters Name=group-id,Values="$security_groups" \
    | jq -re '.NetworkInterfaces[] | [.NetworkInterfaceId, .Attachment.AttachmentId] | @tsv' \
    | while IFS= read -r eni attachment; do
        aws ec2 detach-network-interface --attachment-id "$attachment" --force && \
        aws ec2 wait network-interface-available "$eni" && \
        aws ec2 delete-network-interface --network-interface-id "$eni"
    done
)

update_lambda_code() (
    lambda="$1"; shift
    python -m zipfile -c /dev/stdout "$@" \
    | aws lambda update-function-code --function-name "$lambda" --zip-file fileb:///dev/stdin && \
    aws lambda wait function-updated --function-name "$lambda"
)

yaml2json() {
    python3 -c 'import sys, yaml, json; [json.dump(doc, sys.stdout) for doc in yaml.safe_load_all(sys.stdin)]'
}

call_lambda() (
    payload="$(jq -nc "${2:-null}")" && \
    result="$(aws lambda invoke --function-name "$1" --log-type Tail --payload "$payload" /dev/stdout)" && \
    <<<"$result" jq -rse '.[1].LogResult | @base64d' >&2 && \
    <<<"$result" jq -rse '.[0].stackTrace//[] | join("")' >&2 && \
    <<<"$result" jq -rse '.[0]==null' >/dev/null
)

generate_password() {
    (cat /dev/urandom | tr -dc "[:${2:-graph}:]" || true) | head -c"${1:-32}"
}

git_ref() { git rev-parse HEAD; }
git_branch() { git branch -a --contains "$(git rev-parse HEAD)" | head -n1 | cut -d/ -f2-; }
git_branch() { git symbolic-ref --short HEAD; }

find_elb_by_url() {
    aws elb describe-load-balancers \
    | url="$1" jq -re '.LoadBalancerDescriptions[] | select(.DNSName==env.url).LoadBalancerName' \
    || { echo "Unable to find elb matching: $1" >&2; return 1; }
}

find_elbv2_by_url() {
    aws elbv2 describe-load-balancers \
    | url="$1" jq -re '.LoadBalancers[] | select(.DNSName==env.url).LoadBalancerArn' \
    || { echo "Unable to find elbv2 matching: $1" >&2; return 1; }
}

# you should usually use something like xargs, but this works on functions
in_parallel() (
    local children=() failed=0
    trap 'kill "${children[@]}" || true' EXIT
    while IFS= read -r arg; do
        ( "$@" "$arg" ) &
        children+=( "$!" )
    done
    for pid in "${children[@]}"; do
        if ! wait "$pid"; then
            failed=1
        fi
    done
    (( failed ))
)

add_trap() { eval 'set -- "$1" "$2" '"$(trap -p "$2")"; trap "${5:-:}; $1" "$2"; }

ssm_run() (
    # usage: echo COMMAND | ssm_run INSTANCE_ID
    command="$(jq -Rsc '{commands: [.]}')" && \
    command_id="$(
        aws ssm send-command \
            --instance-ids="$@" \
            --document-name='AWS-RunShellScript' \
            --parameters="$command" \
        | jq -re '.Command.CommandId'
    )" && \
    { aws ssm wait command-executed --command-id "$command_id" --instance-id "$1" || true; } && \
    result="$(aws ssm get-command-invocation --command-id "$command_id" --instance-id "$1")" && \
    <<<"$result" jq -je '.StandardOutputContent' && \
    <<<"$result" jq -je '.StandardErrorContent' >&2 && \
    return "$(<<<"$result" jq -re '.ResponseCode')"
)

# find "public" subnets ie ones with an igw and therefore direct internet access
guess_public_subnets() {
    aws ec2 describe-route-tables --filters Name=vpc-id,Values="$1" \
    | jq -re '.RouteTables[] | select(.Routes[] | select(.GatewayId//"" | startswith("igw-"))).Associations[].SubnetId' \
    || { echo Could not find any public subnets in "$1" >&2; return 1; }
}

# find "private" subnets ie ones with a 0.0.0.0/0 route that is not a gateway (should be a nat)
guess_private_subnets() {
    aws ec2 describe-route-tables --filters Name=vpc-id,Values="$1" \
    | jq -r '.RouteTables[] | select(.Routes[] | (.GatewayId|not) and .DestinationCidrBlock == "0.0.0.0/0").Associations[].SubnetId' \
    || { echo Could not find any private subnets in "$1" >&2; return 1; }
}

# set_difference SUPERSET SUBSET
# arguments must be strings of lines
set_difference() {
    fgrep -vx "$2" <<<"$1"
}

set_intersection() {
    fgrep -x "$2" <<<"$1"
}

lookup_arn() {
    aws resourcegroupstaggingapi get-resources \
    | jq -re --arg name "$1" '.ResourceTagMappingList[] | select(.ResourceARN | endswith("/"+$name) or endswith(":"+$name)).ResourceARN' \
    || { echo Could not find "$1" >&2; return 1; }
}

get_resource_creation_date() {
    aws configservice select-resource-config --expression "select resourceCreationTime where arn='$1';" \
    | jq -re '.Results[] | fromjson.resourceCreationTime' \
    || { echo Could not find "$1"; return 1; }
}

get_tag() {
    aws resourcegroupstaggingapi get-resources \
    | jq -r --arg name "$1" --arg key "$2" '.ResourceTagMappingList[] | select(.ResourceARN | endswith("/"+$name) or endswith(":"+$name)).Tags[] | select(.Key==$key).Value'
}

set_tag() {
    aws resourcegroupstaggingapi tag-resources --resource-arn-list "$1" --tags "$2=$3" \
    | jq -re '.FailedResourcesMap | to_entries | map(.value.ErrorMessage) | join("\n") | if .!="" then halt_error else . end'
}


create_log_group() {
    aws logs describe-log-groups --log-group-name-prefix "$1" \
    | jq --arg name "$1" -re '.logGroups[] | select(.logGroupName==$name)' >/dev/null \
    || aws logs create-log-group --log-group-name "$1"
}

wait_until_ssm_available() {
    until aws ssm get-connection-status --target "$1" | jq -e '.Status=="connected"' >/dev/null; do sleep 10; done
}

retry() {
    local tries_left="$1" delay="$2" code=0
    shift 2
    while (( tries_left > 0 )); do
        if "$@"; then
            return 0
        else
            code="$?"
        fi
        (( tries_left -- ))
        sleep "$delay"
    done
    return "$code"
}
