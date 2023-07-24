module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "M2M-VPC"

  cidr = "10.220.0.0/19"
  azs = var.azs
}
