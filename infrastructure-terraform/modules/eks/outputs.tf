output "cluster_name" {
  description = "EKS cluster name"
  value = module.eks.cluster_name
}

output "cluster_admin_role_arn" {
  description = "EKS cluster admin role ARN"
  value = aws_iam_role.cluster_admin.arn
}

output "cluster_deploy_role_arn" {
  description = "EKS cluster deploy role ARN"
  value = aws_iam_role.cluster_deploy.arn
}


output "update_kubeconfig_command" {
  description = "Command to update ~/.kube/config file"
  value = "aws eks update-kubeconfig --name ${var.cluster_name} --alias ${var.cluster_name} --region ${var.region} --role-arn ${aws_iam_role.cluster_admin.arn}"
}

output "ca_arn" {
  description = "Private CA ARN"
  value = module.aws_acm_certificate.ca_arn
}
