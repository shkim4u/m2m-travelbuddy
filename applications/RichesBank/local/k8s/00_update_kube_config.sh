#!/bin/bash

# Region 조회
export AWS_REGION=`aws ec2 describe-availability-zones --output text --query "AvailabilityZones[0].[RegionName]"` && echo $AWS_REGION

aws eks update-kubeconfig --region ${AWS_REGION} --name dynatrace-workshop
