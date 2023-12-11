variable "region" {
  description = "AWS Region"
  type = string
  default = "ap-northeast-2"
}

// Private CA ARN to be passed to EKS module, which will be used ALB HTTTPS support.
/**
 * CA ARN은 입력하기 위해서는 먼서 Private Certificate Authority를 설정하여야 한다.
 * 참조: eks-cluster-cdk.md
 * CA ARN 변수 설정 방법
 * 1. export TF_VAR_ca_arn=arn:aws:
 * 2. terraform apply -var "ca_arn=arn:aws:"
 * 3. 그냥 실행하면 Terraform이 변수 입력 프롬프트 표시하며 이 때 입력
 */
variable "ca_arn" {
  description = "ARN of private certificate authority to create server certificate with"
}

#variable "eks_kms_key_alias" {
#  description = "The KMS key alias to avoid duplicate KMS key when repeating resource creation"
#}

variable "eks_cluster_name" {
  description = "The name of EKS cluster to be created"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  default = "P@$$w0rd00#1"
}

variable "exclude_msk" {
  description = "True or False to exclude Amazon MSK cluster for its longer time to create"
  default = false
}
