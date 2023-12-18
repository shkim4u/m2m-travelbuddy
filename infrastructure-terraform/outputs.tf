/*
 * Outputs from network resources.
 */
output "network_vpc_id" {
  description = "(Network) VPC ID"
  value = module.network.vpc_id
}

output "network_vpc_cidr_block" {
  description = "(Network) VPC CIDR block"
  value = module.network.vpc_cidr_block
}

output "network_private_subnets_cidr_blocks" {
  description = "(Network) Private subnets CIDR block"
  value = module.network.private_subnets_cidr_blocks
}

output "network_public_subnets_cidr_blocks" {
  description = "(Network) Public subnets CIDR block"
  value = module.network.public_subnets_cidr_blocks
}

/*
 * Outputs from IAM resources.
 */
output "iam_m2m_admin_role_arn" {
  description = "(IAM) M2M admin role ARN"
  value = module.iam.m2m_admin_role_arn
}

output "iam_m2m_admin_ec2_instance_profile" {
  description = "(IAM) M2M admin EC2 instance profile"
  value = module.iam.m2m_admin_ec2_instance_profile_name
}

/*
 * Outputs from EKS resources.
 */
output "eks_cluster_name" {
  description = "(EKS) EKS cluster name"
  value = module.eks.cluster_name
}

#output "eks_cluster_arn" {
#  description = "(EKS) EKS cluster ARN"
#  value = module.eks.eks_cluster_arn
#}

output "eks_update_kubeconfig_command" {
  description = "(EKS) Command for aws eks update-kubeconfig"
  value = module.eks.update_kubeconfig_command
}

#output "eks_cluster_endpoint" {
#  description = "(EKS) EKS cluster endpoint"
#  value = module.eks.eks_cluster_endpoint
#}
#
#output "eks_cluster_certificate_authority_data" {
#  description = "(EKS) EKS cluster certificate authority data"
#  value = module.eks.eks_cluster_certificate_authority_data
#}
#
#output "eks_cluster_admin_role_arn" {
#  description = "(EKS) EKS admin role ARN"
#  value = module.eks.eks_cluster_admin_role_arn
#}

output "eks_ca_arn" {
  description = "(EKS) Private CA ARN"
  value = module.eks.ca_arn
}

###
### Frontend.
###
output "frontend_cloudfront_domain_name" {
  description = "(Frontend) CloudFront Domain Name"
  value = module.frontend.frontend_cloudfront_domain_name
}


###
### CI/CI
###
output "cicd_appsec_slack_webhook_url" {
  description = "(CICD) Slack webhook URL to notify application vulnerabilities and recommended mitigations (AppSec)"
  value = var.cicd_appsec_slack_webhook_url
}

output "cicd_appsec_slack_channel" {
  description = "(CICD) Slack channel to notify application vulnerabilities and recommended mitigations (AppSec)"
  value = var.cicd_appsec_slack_channel
}
