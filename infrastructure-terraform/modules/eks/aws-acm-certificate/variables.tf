variable "domain_name" {
  default = "www.mydemo.co.kr"
}

variable "subject_alternative_names" {
  default = ["cool.mydemo.co.kr", "test.mydemo.co.kr"]
}

variable "certificate_authority_arn" {}
