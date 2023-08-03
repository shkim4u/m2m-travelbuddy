provider "aws" {
  region = var.region
}

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
}

module "eks_addon" {
  source = "./modules/eks-addon"

#  depends_on = [module.eks]

  eks_cluster_name = module.eks.eks_cluster_name
  eks_cluster_endpoint = module.eks.eks_cluster_endpoint
  eks_cluster_certificate_authority_data = module.eks.eks_cluster_certificate_authority_data
}
