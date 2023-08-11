data "aws_caller_identity" "current" {}

/**
 * https://github.com/cloudposse/terraform-aws-elasticsearch/issues/5
There is NO way to determine in Terraform if the Service Linked Role is already created on AWS in the account.
So yes, you have to check it manually, and if it does exist, set create_iam_service_linked_role to false.
Otherwise, set it to true.
We have not found a better way of doing this.

Also, one a ES cluster is created in the account manually from the AWS console, the role will be created automatically.
This complicates the matter even more.

If somebody has a better option please chime in.
*/
#data "aws_iam_role" "service_linked_role" {
#  name = "AWSServiceRoleForAmazonEKSNodegroup"
#}

# Error handling with "The configmap "aws-auth" does not exist"
# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009
#data "aws_eks_cluster" "this" {
#  name = module.eks.cluster_name
#  depends_on = [module.eks]
#}
#
#data "aws_eks_cluster_auth" "this" {
#  name = module.eks.cluster_name
#  depends_on = [module.eks]
#}
