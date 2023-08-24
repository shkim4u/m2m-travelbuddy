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

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
}
