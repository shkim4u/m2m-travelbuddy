variable "cluster_name" {}
variable "cluster_endpoint" {}
variable "cluster_version" {}
variable "oidc_provider_arn" {}

variable "depends_upon" {
  default = []
}
