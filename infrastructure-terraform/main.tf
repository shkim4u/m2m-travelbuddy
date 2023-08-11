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
}
