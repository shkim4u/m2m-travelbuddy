variable "cluster_name" {
  description = "The name of EKS cluster"
  default = "M2M-EksCluster"
}

variable "cluster_version" {
  description = "The version of EKS cluster"
  default = "1.26"
}

variable "region" {}
variable "vpc_id" {}
variable "private_subnet_ids" {}

variable "certificate_authority_arn" {}

variable "grafana_admin_password" {}
