# Get the policy by name
data "aws_iam_policy" "eks-cluster" {
  name = "AmazonEKSClusterPolicy"
}
