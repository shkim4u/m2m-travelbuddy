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
 * Outputs from EC2 resources.
 */
output "ec2_rds_bastion_public_ip" {
  description = "(EC2) Public IP of RDS bastion"
  value = module.ec2.rds_bastion_public_ip
}

output "ec2_rds_bastion_private_ip" {
  description = "(EC2) Private IP of RDS bastion"
  value = module.ec2.rds_bastion_private_ip
}

/*
 * Outputs from EKS resources.
 */
output "eks_cluster_name" {
  description = "(EKS) EKS cluster name"
  value = module.eks.eks_cluster_name
}

output "eks_update_kubeconfig_command" {
  description = "(EKS) Command for aws eks update-kubeconfig"
  value = module.eks.eks_update_kubeconfig_command
}

output "eks_cluster_endpoint" {
  description = "(EKS) EKS cluster endpoint"
  value = module.eks.eks_cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "(EKS) EKS cluster certificate authority data"
  value = module.eks.eks_cluster_certificate_authority_data
}

