#!/bin/bash

# Import the existing KMS key to the Terraform state.
# https://stackoverflow.com/questions/62654684/terraform-alreadyexistsexception-an-alias-with-the-name-arnawskmsxxxxxxxxxx
#╷
#│ Error: creating KMS Alias (alias/eks/M2M-EksCluster): AlreadyExistsException: An alias with the name arn:aws:kms:ap-northeast-2:xxxxxxxxxxx:alias/eks/M2M-EksCluster already exists
#│
#│   with module.eks.module.eks.module.kms.aws_kms_alias.this["cluster"],
#│   on .terraform/modules/eks.eks.kms/main.tf line 255, in resource "aws_kms_alias" "this":
#│  255: resource "aws_kms_alias" "this" {
#│

terraform import module.eks.module.eks.module.kms.aws_kms_alias.this["cluster"] arn:aws:kms:ap-northeast-2:xxxxxxxxxxx:alias/eks/M2M-EksCluster

