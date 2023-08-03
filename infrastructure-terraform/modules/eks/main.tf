/**
 * References
 * - https://antonputra.com/amazon/create-eks-cluster-using-terraform-modules/#add-iam-user-role-to-eks
 */

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_caller_identity" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

#data "aws_eks_cluster" "default" {
#  name = module.eks.cluster_id
#}
#
#data "aws_eks_cluster_auth" "default" {
#  name = module.eks.cluster_id
#}

locals {
  cluster_name = "M2M-EksCluster"
  cluster_version = "1.27"
}

# 필요하면 모듈 사용
resource "aws_iam_role" "m2m_eks_cluster_admin" {
  name = "${local.cluster_name}-AdminRole"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })

  # This is IAM Policy with Full Access to EKS Configuration
  inline_policy {
    name = "eks-full-access-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "eks:*"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  tags = {
    description = "${local.cluster_name}-AdminRole"
  }
}

/**
 * Kubernetes-related sources.
 * References:
 * - https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/karpenter/main.tf
 */

provider "kubernetes" {
  host = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache = "${path.module}/.helm"
  kubernetes {
    host = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count = 5
  host = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

resource "null_resource" "kubectl" {
#  triggers = {
#    always = timestamp()
#  }

  depends_on = [module.eks]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      set -e
      echo 'Applying "aws eks update-kubeconfig" for kubectl...'
      aws eks wait cluster-active --name '${local.cluster_name}'
      aws eks update-kubeconfig --name ${local.cluster_name} --alias ${local.cluster_name} --region=${var.region} --role-arn ${aws_iam_role.m2m_eks_cluster_admin.arn}
    EOT
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  cluster_name = local.cluster_name
  cluster_version = local.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true

  vpc_id = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_irsa = true

  # Create master role for the EKS cluster.
  create_iam_role = true
  iam_role_name = "${local.cluster_name}-ClusterRole"

  # TODO: Externalize.
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.m2m_eks_cluster_admin.arn
      username = aws_iam_role.m2m_eks_cluster_admin.name
      groups   = ["system:masters"]
    },
  ]

  # Managed node group.
  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
    disk_size = 100
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  eks_managed_node_groups = {
    "OnDemand" = {
      capacity_type = "ON_DEMAND"
      instance_types = ["m5.4xlarge"]
      min_size = 2
      max_size = 4
      desired_size = 2
      # 생성된 node에 labels 추가 (kubectl get nodes --show-labels로 확인 가능)
      labels = {
        ondemand = "true"
      }
    }
  }

  # Reserved
#  node_security_group_name = "${local.cluster_name}-node"
  node_security_group_tags = {

  }
}

################################################################################
# Karpenter
################################################################################

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  // TODO: Add additionally necessary permission below.
#  iam_role_additional_policies = {
#    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#  }

#  tags = local.tags
}

resource "helm_release" "karpenter" {
  namespace = "karpenter"
  create_namespace = true

  name = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart = "karpenter"
  version = "v0.21.1"

  set {
    name = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
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

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      labels:
        cluster-name: ${module.eks.cluster_name}
        billing: "aws-proserve"
      requirements:
        - key: "karpenter.k8s.aws/instance-category"
          operator: In
          values: ["c", "m", "r"]
        - key: "karpenter.k8s.aws/instance-cpu"
          operator: In
          values: ["4", "8", "16", "32"]
        - key: "karpenter.k8s.aws/instance-hypervisor"
          operator: In
          values: ["nitro"]
        - key: "karpenter.k8s.aws/instance-generation"
          operator: Gt
          values: ["4"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "karpenter.sh/capacity-type" # If not included, the webhook for the AWS cloud provider will default to on-demand
          operator: In
          values: ["on-demand"]

        # A provisioner can be set up to only provision nodes on particular processor types.
        # The following example sets a taint that only allows pods with tolerations for Nvidia GPUs to be scheduled:
        # In order for a pod to run on a node defined in this provisioner, it must tolerate nvidia.com/gpu in its pod spec.
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["p3.8xlarge", "p3.16xlarge"]
      taints:
        - key: nvidia.com/gpu
          value: "true"
          effect: NoSchedule
      limits:
        resources:
          cpu: "250"
          mem: "1000Gi"
      consolidation:
        enabled: true
      providerRef:
        name: default
      # expected exactly one, got both: spec.consolidation.enabled, spec.ttlSecondsAfterEmpty
      #ttlSecondsAfterEmpty: 30
      ttlSecondsUntilExpired: 7200
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

# Refer to: https://karpenter.sh/docs/concepts/node-templates/
resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      amiFamily: AL2
      subnetSelector:
        karpenter.sh/discovery/${module.eks.cluster_name}: "*"
      securityGroupSelector:
        karpenter.sh/discovery/${module.eks.cluster_name}: "owned"
        Name: ${module.eks.cluster_name}-node
      tags:
        karpenter.sh/discovery: "${module.eks.cluster_name}"
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

# Example deployment using the [pause image](https://www.ianlewis.org/en/almighty-pause-container)
# and starts with zero replicas
resource "kubectl_manifest" "karpenter_example_deployment" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: inflate
    spec:
      replicas: 0
      selector:
        matchLabels:
          app: inflate
      template:
        metadata:
          labels:
            app: inflate
        spec:
          terminationGracePeriodSeconds: 0
          containers:
            - name: inflate
              image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
              resources:
                requests:
                  cpu: 1
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
