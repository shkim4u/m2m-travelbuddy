module "ecr" {
  source = "./ecr"
  name = var.name
}

module "ci_pipeline" {
  source = "./ci-pipeline"
  name = var.name
  ecr_repository_arn = module.ecr.repository_arn
  ecr_repository_url = module.ecr.repository_url
  dev_slack_webhook_url = var.cicd_appsec_dev_slack_webhook_url
  dev_slack_channel = var.cicd_appsec_dev_slack_channel
  sec_slack_webhook_url = var.cicd_appsec_sec_slack_webhook_url
  sec_slack_channel = var.cicd_appsec_sec_slack_channel
  eks_cluster_deploy_role_arn = var.eks_cluster_deploy_role_arn
  eks_cluster_name = var.eks_cluster_name
  application_configuration_repo_url = module.cd_pipeline.application_configuration_repo_url
}

module "cd_pipeline" {
  source = "./cd-pipeline"
  name = var.name
  ecr_repository_arn = module.ecr.repository_arn
  ecr_repository_url = module.ecr.repository_url
  ecr_repository_name = module.ecr.repository_name
  eks_cluster_name = var.eks_cluster_name
  eks_cluster_admin_role_arn = var.eks_cluster_admin_role_arn
  eks_cluster_deploy_role_arn = var.eks_cluster_deploy_role_arn
}
