#!/bin/bash
#
#
usage() {
    echo "$0 <role-name> <policy-file-1> <policy-file-2> ..."
}

fatal() {
   echo "ERROR: $1"
   exit 1
}

DIR=$(dirname $0)

export ROLE_NAME=${1:-${ROLE_NAME}}
[[ -z "${ROLE_NAME}" ]] && usage && fatal "ROLE_NAME is missing"

shift
[[ -z "${1}" ]] && usage && fatal "need to specify at list one policy file"


AWS_ACCOUNT_ID=$(aws iam get-user | sed -nE '/Arn/{s/.*arn:aws:iam::([0-9]{1,}):.*$/\1/p}')
AWS_ARN_PREFIX="arn:aws:iam::${AWS_ACCOUNT_ID}"
ASSUME_ROLE_POLICY_DOCUMENT='{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
'

echo -e "\nCreating role ${ROLE_NAME}"
aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document "$ASSUME_ROLE_POLICY_DOCUMENT" --description "role $ROLE_NAME created by create-iam-role.sh"
# if [[ $? != 0 ]]; then
#     echo "Failed to create role $ROLE_NAME"
#     exit 1
# fi

for ii in "$@"
do
    if [[ ! -f "${ii}" ]]; then
        echo "Policy File $ii does not exists"
        continue
    fi
    POLICY_NAME=$(basename -s .json $ii)
    POLICY_DOCUMENT=file://$(realpath ${ii})
    echo "Creating Policy $POLICY_NAME for file $POLICY_DOCUMENT ..."
    aws iam create-policy --policy-name ${POLICY_NAME} --policy-document ${POLICY_DOCUMENT}
    echo -e "\nattach-role-policy ${ROLE_NAME}"
    aws iam attach-role-policy --role-name ${ROLE_NAME} --policy-arn ${AWS_ARN_PREFIX}:policy/${POLICY_NAME}
done
echo "aws iam create-instance-profile --instance-profile-name ${ROLE_NAME}"
aws iam create-instance-profile --instance-profile-name ${ROLE_NAME}
echo "aws iam add-role-to-instance-profile --instance-profile-name ${ROLE_NAME} --role-name ${ROLE_NAME}"
aws iam add-role-to-instance-profile --instance-profile-name ${ROLE_NAME} --role-name ${ROLE_NAME}

