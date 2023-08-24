output "update_kubeconfig_command" {
  description = "Command to update ~/.kube/config file"
  value = "aws eks update-kubeconfig --name ${var.cluster_name} --alias ${var.cluster_name} --region ${var.region} --role-arn ${aws_iam_role.cluster_admin.arn}"
}

output "ca_arn" {
  description = "Private CA ARN"
  value = module.aws_acm_certificate.ca_arn
}
