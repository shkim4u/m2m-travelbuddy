module "network" {
  source = "./modules/network"
}

module "iam" {
  source = "./modules/iam"
}

module "ec2" {
  source = "./modules/ec2"
  subnet_id = module.network.public_subnets[0]
  role_name = module.iam.m2m_admin_role_name
  vpc_id = module.network.vpc_id
  instance_profile_name = module.iam.m2m_admin_ec2_instance_profile_name
}

module "eks" {
  source = "./modules/eks"
  region = var.region
  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnets
  certificate_authority_arn = var.ca_arn
  grafana_admin_password = var.grafana_admin_password
}

module "cicd" {
  source = "./modules/cicd"

  for_each = {
    "cicd-travelbuddy" = "travelbuddy"
    "cicd-flightspecials" = "flightspecials"
  }

  name = each.value
  eks_cluster_admin_role_arn = module.eks.cluster_admin_role_arn
  eks_cluster_deploy_role_arn = module.eks.cluster_deploy_role_arn
  eks_cluster_name = module.eks.cluster_name
}

###
### SSM Parameter Store for TravelBuddy container image tag or others.
###
module "ssm" {
  source = "./modules/ssm"
}

###
### M2M-RdsLegacyStack은 <Project Root>/prepare/rds-fixed-sg-cidr.template 파일을 사용하여 CloudFormation으로 생성.
###


###
### RDS database for microservices (incl. FlightSpecials)
###
module "rds" {
  source = "./modules/rds"
  vpc_id = module.network.vpc_id
  vpc_cidr_block = module.network.vpc_cidr_block
  subnet_ids = module.network.private_subnets
}

###
### MSK cluster.
###
module "msk" {
  count = var.exclude_msk ? 0 : 1

  source = "./modules/msk"
  vpc_id = module.network.vpc_id
  vpc_cidr_block = module.network.vpc_cidr_block
  subnet_ids = module.network.private_subnets
}

###
### [2023-09-20] Frontend resources - S3 bucket, bucket policy, CloudFront distribution, etc.
###
module "frontend" {
  source = "./modules/frontend"
}
