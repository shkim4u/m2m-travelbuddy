#!/bin/bash

# AdministratorAccess 권한이 부여된 Trust Relationship Policy (from GitHub).
export ASSUME_ROLE_POLICY_DOCUMENT=`curl -fsSL https://raw.githubusercontent.com/shkim4u/m2m-travelbuddy/main/resources/cloud9/cloud9-admin-role-trust-polocy.json`
echo $ASSUME_ROLE_POLICY_DOCUMENT

# "cloud9-admin" Role 생성 및 권한 부여
aws iam create-role --role-name cloud9-admin --assume-role-policy-document "${ASSUME_ROLE_POLICY_DOCUMENT}"
aws iam attach-role-policy --role-name cloud9-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# 인스턴스 프로파일 생성
aws iam create-instance-profile --instance-profile-name cloud9-admin-instance-profile
aws iam add-role-to-instance-profile --role-name cloud9-admin --instance-profile-name cloud9-admin-instance-profile

# Cloud9 EC2 인스턴스에 인스턴스 프로파일 부착 (Attach)
export EC2_INSTANCE_ID=$(aws ec2 describe-instances --filters Name=tag:Name,Values="*cloud9-workspace*" Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].InstanceId" --output text)
echo $EC2_INSTANCE_ID
aws ec2 associate-iam-instance-profile --iam-instance-profile Name=cloud9-admin-instance-profile --instance-id $EC2_INSTANCE_ID

# 마지막으로 Cloud9 Managed Credentials 비활성화 -> 위에서 생성한 Instance Profile 사용
#aws cloud9 update-environment --environment-id ${C9_PID} --managed-credentials-action DISABLE
