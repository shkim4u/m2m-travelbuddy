#terraform {
#  required_version = ">= 1.0"
#
#  required_providers {
#    aws = {
#      source  = "hashicorp/aws"
#      version = ">= 4.47"
#    }
#    helm = {
#      source  = "hashicorp/helm"
#      version = ">= 2.9"
#    }
#    kubernetes = {
#      source  = "hashicorp/kubernetes"
#      version = ">= 2.20"
#    }
#    // https://github.com/gavinbunney/terraform-provider-kubectl
#    kubectl = {
##      source  = "gavinbunney/kubectl"
##      version = ">= 1.14"
#      source  = "alekc/kubectl"
#      version = ">= 2.0.2"
#    }
#  }
#}
