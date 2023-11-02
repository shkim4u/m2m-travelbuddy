# Region 조회
export AWS_REGION=`aws ec2 describe-availability-zones --output text --query "AvailabilityZones[0].[RegionName]"` && echo $AWS_REGION

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output=text) && echo $AWS_ACCOUNT_ID
docker tag riches:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/riches:latest
