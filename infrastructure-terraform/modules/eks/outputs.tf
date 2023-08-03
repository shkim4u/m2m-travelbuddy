output "eks_cluster_name" {
  description = "EKS cluster name"
  value = module.eks.cluster_name
}

output "eks_update_kubeconfig_command" {
  description = "Command for: aws eks update-kubeconfig"
  value = "aws eks update-kubeconfig --name ${local.cluster_name} --alias ${local.cluster_name} --region=${var.region} --role-arn ${aws_iam_role.m2m_eks_cluster_admin.arn}"
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value = module.eks.cluster_certificate_authority_data
}
