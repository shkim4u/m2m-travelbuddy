# Create a AWS ECR repository with Terraform HCL.
resource "aws_ecr_repository" "this" {
  name                 = local.ecr_repo
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  # Lifecycle policy to retain only 1 image.
  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Retain only the latest image",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["latest"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
