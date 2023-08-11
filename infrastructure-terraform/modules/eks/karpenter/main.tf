resource "null_resource" "depends_upon" {
  triggers = {
    depends_on = join("", var.depends_upon)
  }
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = var.cluster_name
  irsa_oidc_provider_arn = var.oidc_provider_arn

  # The SSMManagedInstanceCore permission is used by Karpenter to fetch the latest EKS optimised AMI
  # from the public SSM parameter store.
  # Hmm~, not for Karpenter IRSA.
#  policies = {
#    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#  }

  # Instead, use this.
  iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

# Additional reference
# - https://medium.com/@ahil.matheww/provisioning-aws-karpenter-provisioners-with-terraform-1cade400c104
resource "helm_release" "karpenter" {
  repository = "oci://public.ecr.aws/karpenter"
  chart = "karpenter"
  version = "v0.21.1"
  name  = "karpenter"
  namespace = "karpenter"
  create_namespace = true

  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password

  set {
    name = "settings.aws.clusterName"
    value = var.cluster_name
  }

  set {
    name = "settings.aws.clusterEndpoint"
    value = data.aws_eks_cluster.this.endpoint
  }

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }

  set {
    name = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }
}

resource "kubectl_manifest" "providers" {
  for_each  = data.kubectl_path_documents.provider_manifests.manifests
  yaml_body = each.value
  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "provisioners" {
  for_each  = data.kubectl_path_documents.provisioner_manifests.manifests
  yaml_body = each.value
  depends_on = [helm_release.karpenter]
}
