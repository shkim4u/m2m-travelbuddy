module "ecr" {
  source = "./ecr"
  name = var.name
}

module "ci_pipeline" {
  source = "./ci-pipeline"
  name = var.name
  ecr_repository_arn = module.ecr.repository_arn
  ecr_repository_url = module.ecr.repository_url
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
