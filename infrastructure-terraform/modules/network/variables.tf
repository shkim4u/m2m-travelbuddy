variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnets" {
  description = "Public subnets of VPC"
  type = list(string)
  default = ["10.220.0.0/22", "10.220.12.0/22"]
}

variable "private_subnets" {
  description = "Private subnets of VPC"
  type = list(string)
  default = ["10.220.4.0/22", "10.220.8.0/22"]
}
