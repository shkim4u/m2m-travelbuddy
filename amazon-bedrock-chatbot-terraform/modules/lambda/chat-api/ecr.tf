# Create a AWS ECR repository with Terraform HCL.
resource "aws_ecr_repository" "this" {
  name = local.ecr_repo
  image_tag_mutability = "MUTABLE"
  force_delete = true
  image_scanning_configuration {
      scan_on_push = true
  }
}
