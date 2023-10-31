#!/bin/bash

# 기본 VPC 조회
export VPC_ID=`aws ec2 describe-vpcs --filter "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text`
echo $VPC_ID

# 서브넷 조회
export QUOTED_VPC_ID=\'${VPC_ID}\'
export SUBNET_ID=`aws ec2 describe-subnets --query "Subnets[?(VpcId==${QUOTED_VPC_ID} && AvailabilityZone=='ap-northeast-2a')].SubnetId" --output text`
echo $SUBNET_ID

aws ec2 run-instances \
    --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
    --count 1 \
    --instance-type m5.xlarge \
    --subnet-id ${SUBNET_ID} \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":30,\"DeleteOnTermination\":false}}]" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=appsec-demo-server}]' 'ResourceType=volume,Tags=[{Key=Name,Value=appsec-demo-server-disk}]' \
    --no-cli-pager

# AdministratorAccess 권한이 부여된 Trust Relationship Policy (from GitHub, shared with Cloud9).
export EC2_INSTANCE_ROLE_POLICY_DOCUMENT=`curl -fsSL https://raw.githubusercontent.com/shkim4u/m2m-travelbuddy/main/cloud9/cloud9-admin-role-trust-policy.json`
echo $EC2_INSTANCE_ROLE_POLICY_DOCUMENT

# "ec2-admin" Role 생성 및 권한 부여
aws iam create-role --role-name ec2-admin --assume-role-policy-document "${EC2_INSTANCE_ROLE_POLICY_DOCUMENT}"
aws iam attach-role-policy --role-name ec2-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# EC2 인스턴스 프로파일 생성
aws iam create-instance-profile --instance-profile-name ec2-admin-instance-profile
aws iam add-role-to-instance-profile --role-name ec2-admin --instance-profile-name ec2-admin-instance-profile

# EC2 인스턴스가 셩성되는 것을 확인.
EC2_INSTANCE_ID=$(aws ec2 describe-instances --filters Name=tag:Name,Values="*appsec-demo-server*" Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].InstanceId" --output text)
while [[ -z "${EC2_INSTANCE_ID}" ]]; do
  EC2_INSTANCE_ID=$(aws ec2 describe-instances --filters Name=tag:Name,Values="*appsec-demo-server*" Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].InstanceId" --output text)
  echo "EC2 instance is not yet created. Waiting for 5 seconds..."
  sleep 5
done
echo $EC2_INSTANCE_ID

# EC2 인스턴스가 실행되기까지 기다림.
STATUS=""
while [ "$STATUS" != "running" ]; do
  # Get the current status of the instance
  STATUS=$(aws ec2 describe-instances --instance-ids ${EC2_INSTANCE_ID} --query 'Reservations[].Instances[].State.Name' --output text)

  if [ "$STATUS" != "running" ]; then
    echo "Instance is not yet running. Waiting for 5 seconds..."
    sleep 5
  fi
done
echo "EC2 instance is now running."

# EC2의 기본 인스턴스 프로파일 Detach.
# 참고: https://repost.aws/knowledge-center/attach-replace-ec2-instance-profile
export EC2_INSTANCE_PROFILE_ASSOCIATION_ID=`aws ec2 describe-iam-instance-profile-associations --filters Name=instance-id,Values=${EC2_INSTANCE_ID} --query "IamInstanceProfileAssociations[0].AssociationId" --output text`
echo $EC2_INSTANCE_PROFILE_ASSOCIATION_ID
if [ "$EC2_INSTANCE_PROFILE_ASSOCIATION_ID" != "" ]; then
  aws ec2 disassociate-iam-instance-profile --association-id ${EC2_INSTANCE_PROFILE_ASSOCIATION_ID}
fi

# EC2 인스턴스에 인스턴스 프로파일 부착 (Attach)
aws ec2 associate-iam-instance-profile --iam-instance-profile Name=ec2-admin-instance-profile --instance-id $EC2_INSTANCE_ID
