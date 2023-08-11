// For public container image access.
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
  depends_on = [null_resource.depends_upon]
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
  depends_on = [null_resource.depends_upon]
}

# Refer: https://registry.terraform.io/providers/alon-dotan-starkware/kubectl/latest/docs/data-sources/kubectl_path_documents
data "kubectl_path_documents" "provisioner_manifests" {
  pattern = "${path.module}/karpenter-provisioner-manifests/*.yaml"
  vars = {
    cluster_name = var.cluster_name
  }
}

data "kubectl_path_documents" "provider_manifests" {
  pattern = "${path.module}/karpenter-provider-manifests/*.yaml"
  vars = {
    cluster_name = var.cluster_name
  }
}
