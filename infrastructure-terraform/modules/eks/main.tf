/**
 * EKS admin role.
 */
resource "aws_iam_role" "cluster_admin" {
  name = "${var.cluster_name}-AdminRole"
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
    description = "Administrator role for EKS cluster"
  }
}

/**
 * Service-linked role (SLR) for EKS node group and Karpenter.
 * This is to remediate possible error like below that happens from time to time.
 * - AccessDenied: Amazon EKS Nodegroups was unable to assume the service-linked role in your account
 */
#resource "aws_iam_service_linked_role" "eks_nodegroup" {
#  aws_service_name = "eks-nodegroup.amazonaws.com"
#  count = if data.aws_iam_role.service_linked_role.id != "" ? 0 : 1
#}

#resource "aws_iam_service_linked_role" "karpenter" {
#  aws_service_name = "spot.amazonaws.com"
#  custom_suffix = "SLR"
#}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true

  vpc_id = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_irsa = true

  // Create master role for the EKS cluster.
  create_iam_role = true
  iam_role_name = "${var.cluster_name}-ClusterRole"

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.cluster_admin.arn
      username = aws_iam_role.cluster_admin.name
      groups   = ["system:masters"]
    }
  ]

  // Managed node group.
  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
    disk_size = 100
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
  eks_managed_node_groups = {
    "OnDemand" = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["m5.4xlarge"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      # 생성된 node에 labels 추가 (kubectl get nodes --show-labels로 확인 가능)
      labels         = {
        ondemand = "true"
      }
    }
  }

  node_security_group_additional_rules = {
    # Refer: https://github.com/aws-ia/terraform-aws-eks-blueprints/issues/619
    # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to simplify the example and further avoid issues with Add-ons communication with Control plane.
    # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
    # Change this according to your security requirements if needed
#    ingress_cluster_primary_to_node_all_traffic = {
#      description              = "Cluster API (Primary) to Nodegroup all traffic"
#      protocol                 = "-1"
#      from_port                = 0
#      to_port                  = 0
#      type                     = "ingress"
#      source_security_group_id = module.eks.cluster_primary_security_group_id
#    }
    ingress_cluster_to_node_all_traffic = {
      description              = "Cluster API to Nodegroup all traffic"
      protocol                 = "-1"
      from_port                = 0
      to_port                  = 0
      type                     = "ingress"
      source_security_group_id = module.eks.cluster_security_group_id
    }

    // Istio Ingress Gateway 80, 443에 대한 허용
    ingress_node_to_node_http_traffic = {
      description              = "Node-to-Node traffic for HTTP"
      protocol                 = "tcp"
      from_port                = 80
      to_port                  = 80
      type                     = "ingress"
      source_security_group_id = module.eks.node_security_group_id
    }
    ingress_node_to_node_htts_traffic = {
      description              = "Node-to-Node traffic for HTTPS"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = module.eks.node_security_group_id
    }
  }

  # Configure node security group tags for Karpenter later.
  node_security_group_tags = {}
}

resource "null_resource" "kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      set -e
      echo 'Adding ./kube/config context for the Amazon EKS cluster...'
      aws eks wait cluster-active --name '${var.cluster_name}'
      aws eks update-kubeconfig --name ${var.cluster_name} --alias ${var.cluster_name} --region=${var.region} --role-arn ${aws_iam_role.cluster_admin.arn}
    EOT
  }
}

/**
 * AWS load balancer controller.
 * Alt 1: Set up AWS load balancer controller from EKS blueprints add-on.
 * Commented out for now.
 */
#module "aws_load_balancer_controller" {
#  source = "./aws-load-balancer-controller"
#  cluster_name = var.cluster_name
#  cluster_endpoint = module.eks.cluster_endpoint
#  cluster_version = var.cluster_version
#  oidc_provider_arn = module.eks.oidc_provider_arn
#
#  # For safe data retrieval for EKS cluster.
#  depends_upon = [module.eks.cluster_arn]
#}

#/**
# * AWS load balancer controller.
# * Alt 2: Set up AWS load balancer controller from scratch.
# */
#module "aws_load_balancer_controller" {
#  source = "./aws-load-balancer-controller-greenfield"
#
#  cluster_name = var.cluster_name
#  cluster_identity_oidc_issuer = module.eks.oidc_provider
#  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
#  aws_region = var.region
#
#  # Safe data retrieval for EKS cluster.
#  depends_upon = [module.eks.cluster_arn]
#}

module "karpenter" {
  source = "./karpenter"
  cluster_name           = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  # For safe data retrieval for EKS cluster.
#  depends_upon = [module.eks.cluster_arn, module.aws_load_balancer_controller.name]
  depends_upon = [module.eks.cluster_arn]
}

/**
 * Certificate issued by private CA for various ALBs.
 */
module "aws_acm_certificate" {
  source = "./aws-acm-certificate"
  certificate_authority_arn = var.certificate_authority_arn
}

/**
 * Certificate manager.
 * (Not)
 * A resource created by terraform after its creation comsumes CPU/RAM on cluster where it is created,
 * so some kind of delay is needed before the next resource on the same cluster is created.
 * As an option to achieve this it was decided to use time_sleep terraform resource to implement some delay
 * before resources creation.
 * Refer: https://discuss.hashicorp.com/t/terraform-how-to-properly-implement-delay-with-for-each-and-time-sleep-resource/32514
 */
module "cert_manager" {
  source = "./cert-manager"
#  depends_on = [module.aws_load_balancer_controller]
#  depends_upon = [module.aws_load_balancer_controller.name]
}

/**
 * AWS load balancer controller.
 * Alt 2: Set up AWS load balancer controller from scratch.
 */
module "aws_load_balancer_controller" {
  source = "./aws-load-balancer-controller-greenfield"

  cluster_name = var.cluster_name
  cluster_identity_oidc_issuer = module.eks.oidc_provider
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  aws_region = var.region

  # Safe data retrieval for EKS cluster.
  depends_upon = [module.eks.cluster_arn, module.cert_manager.id, module.karpenter.id]
}

/**
 * ArgoCD.
 */
module "argocd" {
  source = "./argocd"
  certificate_arn = module.aws_acm_certificate.certificate_arn
  depends_on = [module.aws_load_balancer_controller, module.aws_acm_certificate]
}

/**
 * Argo Rollouts.
 */
module "argo_rollouts" {
  source = "./argo-rollouts"
  depends_on = [module.aws_load_balancer_controller, module.aws_acm_certificate]
}

/**
 * Metrics server
 */
module "metrics_server" {
  source = "./metrics-server"
  depends_on = [module.eks]
}

/**
 * Install Kubernetes Dashboard with Helm.
 * - https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard
 *
 * How to connect
 * - https://archive.eksworkshop.com/beginner/040_dashboard/
 * - https://github.com/kubernetes/dashboard/blob/master/charts/helm-chart/kubernetes-dashboard/templates/networking/ingress.yaml
 *
 * (참고)
 * 위의 Ingress Yaml 파일을 보면 Nginx만 Ingress 자원으로 정의하고 있음 -> AWS ALB 미지원!
 * (필독) https://github.com/kubernetes/dashboard/blob/master/docs/common/arguments.md
 *
 * (참고) Kubernetes Dashboard는 다음 경우에만 원격 로그인을 허용 (https://github.com/kubernetes/dashboard/blob/master/docs/user/accessing-dashboard/README.md#login-not-available)
 * - http://localhost/...
 * - http://127.0.0.1/...
 * - https://<domain_name>/...
 *
 * * 설정 후 로그인 방법: https://archive.eksworkshop.com/beginner/040_dashboard/connect/
 * 1. Kubeconfig가 설정된, 혹은 EKS에 접속 가능한 AWS Principal이 설정된 환경에서
 * 2. aws eks get-token --cluster-name M2M-EksCluster --role arn:aws:iam::805178225346:role/M2M-EksCluster-ap-northeast-2-MasterRole | jq -r '.status.token'
 * 3. 위 2의 결과를 로그인 창에 복사 후 로그인
 *
 */
module "kubernetes_dashboard" {
  source = "./kubernetes-dashboard"
  certificate_arn = module.aws_acm_certificate.certificate_arn
  depends_on = [module.aws_load_balancer_controller, module.aws_acm_certificate]
}

/**
 * Istio.
 */
module "istio" {
  source = "./istio"
  depends_on = [module.eks]
}

/**
 * AWS EBS CSI Driver for Prometheus.
 */
module "aws_ebs_csi_driver" {
  source = "./aws-ebs-csi-driver"
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
}

/**
 * Prometheus.
 */
module "prometheus" {
  source = "./prometheus"
  depends_on = [module.metrics_server, module.aws_ebs_csi_driver]
}

/**
 * Kiali.
 */
module "kiali" {
  source = "./kiali"
  depends_on = [module.istio, module.prometheus]
#  cluster_name = var.cluster_name
  # For safe data retrieval for EKS cluster.
#  depends_upon = [module.eks.cluster_arn, module.istio.istio_base_id, module.prometheus.id]
}

/**
 * Geme2048 for fun using Istio.
 */
module "game2048" {
  source = "./game2048"
  certificate_arn = module.aws_acm_certificate.certificate_arn
  depends_on = [module.istio, module.aws_acm_certificate, module.aws_load_balancer_controller]
#  cluster_name = var.cluster_name
#  depends_upon = [module.istio.istio_gateway_name, module.aws_acm_certificate.certificate_arn]
}

/**
 * AWSCLI pod for fun.
 */
module "awscli" {
  source = "./awscli"
  depends_on = [module.eks]
}

/**
 * [2023-08-11]
 * More to come
 */
#1. ADOT
#2. GuardDuty Agent
#3. Kubecost: 비용 통제
  #$ helm repo add kubecost https://kubecost.github.io/cost-analyzer/
  #$ helm upgrade --install kubecost kubecost/cost-analyzer --namespace kubecost --create-namespace
#4. Kpow: 카프카 관리 (MSK)
#5. Teleport: 접근 제어
#6. Tetrate: Application-aware networking
#1. https://academy.tetrate.io/
#7. Datree: Manifest 검증
#8. Kasten: 백업 및 복구 (cf. Velero)
