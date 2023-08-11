resource "null_resource" "depends_upon" {
  triggers = {
    depends_on = join("", var.depends_upon)
  }
}

module "aws_load_balancer_controller" {
  source = "aws-ia/eks-blueprints-addons/aws"
  # Ensure to update this to the lasted/desired version.
  version = "~> 1.0"

  cluster_name = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  cluster_version = var.cluster_version
  oidc_provider_arn = var.oidc_provider_arn

  enable_aws_load_balancer_controller = true
}
