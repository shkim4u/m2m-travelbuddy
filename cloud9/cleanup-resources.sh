#!/bin/bash

## EKS admin role.
aws iam list-role-policies --role-name M2M-EksCluster-AdminRole
aws iam delete-role-policy --policy-name eks-full-access-policy --role-name M2M-EksCluster-AdminRole
aws iam list-attached-role-policies --role-name M2M-EksCluster-AdminRole
aws iam delete-role --role-name M2M-EksCluster-AdminRole

## EKs deploy role.
aws iam list-role-policies --role-name M2M-EksCluster-DeployRole
aws iam delete-role-policy --policy-name AdministratorAccess --role-name M2M-EksCluster-DeployRole
aws iam list-attached-role-policies --role-name M2M-EksCluster-DeployRole
aws iam delete-role --role-name M2M-EksCluster-DeployRole

## EC2 instance profile role.

# Remove role from the instance profile.
aws iam remove-role-from-instance-profile --instance-profile-name m2m-admin-instance-profile --role-name m2m-admin

# Delete instance profile.
aws iam delete-instance-profile --instance-profile-name m2m-admin-instance-profile

# List the attached policies.
aws iam list-attached-role-policies --role-name m2m-admin

# Detach the all attached policies from the role.
aws iam detach-role-policy --role-name m2m-admin --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam detach-role-policy --role-name m2m-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Finally, delete the role.
aws iam delete-role --role-name m2m-admin


## TODO:
# - RDS subnet group, parameter group, secrets manager, WAF Web ACL, CloudWatch log group, KMS
# - travelbuddy-cd-deploy-role, riches-cd-deploy-role, flightspecials-cd-deploy-role, flightspecials-cd-pipeline-role, travelbuddy-cd-pipeline-role, riches-cd-pipeline-role, riches-cd-pipeline-trigger-role,
# - flightspecials-cd-pipeline-trigger-role, travelbuddy-cd-pipeline-trigger-role, flightspecials-cd-cwe-role, and so on.
