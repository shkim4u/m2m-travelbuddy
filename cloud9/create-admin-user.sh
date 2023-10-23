#!/bin/bash

# IAM User 생성.
aws iam create-user --user-name admin

# Permission Policy 설정.
aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Verify.
aws iam get-user --user-name admin
aws iam list-attached-user-policies --user-name admin

# Create access key.
aws iam create-access-key --user-name admin
