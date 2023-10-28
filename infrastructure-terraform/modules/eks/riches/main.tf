resource "kubernetes_namespace" "riches" {
  metadata {
    name = local.namespace
    labels = {
      name = local.name
      app = local.app
      purpose = "RichesBank"
    }
  }
}

resource "aws_iam_policy" "riches_irsa" {
  name = "Riches-IRSA-Policy"
  path = "/"
  policy = file("${path.module}/riches-irsa-policy.json")
  description = "IAM policy for Riches IRSA"
}

module "riches_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "Riches-IRSA-Role"

  role_policy_arns = {
    policy = aws_iam_policy.riches_irsa.arn
  }

  oidc_providers = {
    main = {
      provider_arn = var.irsa_oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.riches.metadata[0].name}:${var.service_account_name}"]
    }
  }

  tags = {
    Description = "IAM role for Riches"
  }
}

/**
 * [2023-10-08] Service Account
 */
resource "kubernetes_service_account" "riches_irsa" {
  metadata {
    name = var.service_account_name
    namespace = kubernetes_namespace.riches.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.riches_irsa.iam_role_arn
    }
  }

  timeouts {
    create = "30m"
  }
}
