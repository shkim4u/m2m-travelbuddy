## CodeCommit repository.
resource "aws_codecommit_repository" "application_source" {
  repository_name = "${var.name}-application"
  description = "Application source code repository for ${var.name}"
}

###
### Begin of CodeBuild project, role and related permissions.
###

## 1. S3 bucket.
resource "aws_s3_bucket" "build" {
  bucket = "${var.name}-${local.phase}-build-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true
}

## 2. IAM role and policies.
data "aws_iam_policy_document" "build_role_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "build_role_policy" {
  statement {
    effect = "Allow"
    actions = ["cloudformation:*", "iam:*", "ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
#      "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"
      "s3:Abort*",
      "s3:DeleteObject*",
      "s3:GetBucket*",
      "s3:GetObject*",
      "s3:List*",
      "s3:PutObject*",
#      "s3:PutObjectLegalHold",
#      "s3:PutObjectRetention",
#      "s3:PutObjectTagging",
#      "s3:PutObjectVersionTagging"
    ]
    resources = [
      aws_s3_bucket.build.arn,
      "${aws_s3_bucket.build.arn}/*",
      aws_s3_bucket.pipeline_artifact.arn,
      "${aws_s3_bucket.pipeline_artifact.arn}/*"
    ]
  }

#  statement {
#    effect = "Allow"
#    actions = [
#      "ecr:*"
#    ]
#    resources = [
#      "*"
#    ]
#  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability", "ecr:PutImage",
      "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "airflow:CreateCliToken"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "acm:ListCertificates"
    ]
    resources = ["*"]
  }
}

# Role and permission for build.
resource "aws_iam_role" "build" {
  name = "${var.name}-${local.phase}-build-role"
  assume_role_policy = data.aws_iam_policy_document.build_role_trust.json
}

resource "aws_iam_role_policy" "build" {
  name = "${var.name}-${local.phase}-build-policy"
  role = aws_iam_role.build.id
  policy = data.aws_iam_policy_document.build_role_policy.json
}

resource "aws_iam_role_policy_attachment" "build" {
  for_each = {
    for k, v in {
      AWSLambda_FullAccess = "${local.iam_role_policy_prefix}/AWSLambda_FullAccess",
      AmazonAPIGatewayAdministrator = "${local.iam_role_policy_prefix}/AmazonAPIGatewayAdministrator",
      AmazonSSMFullAccess = "${local.iam_role_policy_prefix}/AmazonSSMFullAccess",
      AWSCodeCommitPowerUser = "${local.iam_role_policy_prefix}/AWSCodeCommitPowerUser",
    }: k => v if true
  }

  policy_arn = each.value
  role = aws_iam_role.build.name
}

#---

# For post process.
resource "aws_s3_bucket" "post_process" {
  bucket = "${var.name}-${local.phase}-post-process-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true
}

## 2. IAM role and policies.
data "aws_iam_policy_document" "post_process_role_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "post_process_role_policy" {
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:Abort*",
      "s3:DeleteObject*",
      "s3:GetBucket*",
      "s3:GetObject*",
      "s3:List*",
      "s3:PutObject*",
    ]
    resources = [
      aws_s3_bucket.build.arn,
      "${aws_s3_bucket.build.arn}/*",
      aws_s3_bucket.post_process.arn,
      "${aws_s3_bucket.post_process.arn}/*",
      aws_s3_bucket.pipeline_artifact.arn,
      "${aws_s3_bucket.pipeline_artifact.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
  }
}

# Role and permission policy for post-process.
resource "aws_iam_role" "post_process" {
  name = "${var.name}-${local.phase}-post-process-role"
  assume_role_policy = data.aws_iam_policy_document.post_process_role_trust.json
}

resource "aws_iam_role_policy" "post_process" {
  name = "${var.name}-${local.phase}-post-process-policy"
  role = aws_iam_role.post_process.id
  policy = data.aws_iam_policy_document.post_process_role_policy.json
}

resource "aws_iam_role_policy_attachment" "post_process" {
  for_each = {
    for k, v in {
      AWSCodeCommitPowerUser = "${local.iam_role_policy_prefix}/AmazonBedrockFullAccess"
    }: k => v if true
  }

  policy_arn = each.value
  role = aws_iam_role.post_process.name
}

## 3. CodeBuild.
resource "aws_codebuild_project" "build" {
  name = "${var.name}-${local.phase}-build"
  service_role = aws_iam_role.build.arn

  artifacts {
    # 만약 Build Spec에서 정의되는 Artifact 이름을 유효하게 하고, S3 Prefix 및 객체 이름을 지정할 수 잏게 하려면 "S3" 타입으로 지정하고,
    # Artifact Namespace Type을 "BUILD_ID"로 지정한다.
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-codebuild-project-artifacts.html
    type = "CODEPIPELINE"
  }

  cache {
    type = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type = "BUILD_GENERAL1_LARGE"
    image = "aws/codebuild/standard:5.0"
    type = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name = "ECR_REPO_URI"
      value = var.ecr_repository_url
    }
    environment_variable {
      name  = "WEIGHTED_ERRORS"
      value = "10"
    }
    environment_variable {
      name  = "WEIGHTED_WARNINGS"
      value = "3"
    }
    environment_variable {
      name  = "WEIGHTED_NOTES"
      value = "1"
    }
    environment_variable {
      name  = "LOC_SCALER"
      value = "1000"
    }
    environment_variable {
      name  = "NVS_THRESHOLD"
      value = "10"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec.yaml"  # CDK: buildspec.yml, Terraform: buildspec.yaml
  }

  description = "Build project for ${var.name}-${local.phase}"
}

resource "aws_codebuild_project" "post_process" {
  name = "${var.name}-${local.phase}-post-process"
  service_role = aws_iam_role.post_process.arn

  artifacts {
    # 만약 Build Spec에서 정의되는 Artifact 이름을 유효하게 하고, S3 Prefix 및 객체 이름을 지정할 수 잏게 하려면 "S3" 타입으로 지정하고,
    # Artifact Namespace Type을 "BUILD_ID"로 지정한다.
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-codebuild-project-artifacts.html
    type = "CODEPIPELINE"
  }

  cache {
    type = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type = "BUILD_GENERAL1_LARGE"
    image = "aws/codebuild/standard:5.0"
    type = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "postprocess.yaml"
  }

  description = "Post process project for ${var.name}-${local.phase}"
}

###
### End of of CodeBuild project, role and related permissions.
###

## S3 bucket for CodePipeline artifact.
resource "aws_s3_bucket" "pipeline_artifact" {
  bucket = "pipeline-artifact-${var.name}-${local.phase}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

###
### Begin of CodePipeline role and related permission.
###
data "aws_iam_policy_document" "pipeline_role_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

#resource "aws_s3_bucket_acl" "build_delivery_pipeline_artifact_acl" {
#  bucket = aws_s3_bucket.build_delivery_pipeline_artifact.id
#  acl    = "private"
#}

# References
# - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline
data "aws_iam_policy_document" "pipeline_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:Abort*",
      "s3:DeleteObject*",
      "s3:GetBucket*",
      "s3:GetObject*",
      "s3:List*",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectLegalHold",
      "s3:PutObjectRetention",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]
    resources = [
      aws_s3_bucket.pipeline_artifact.arn,
      "${aws_s3_bucket.pipeline_artifact.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:UploadArchive",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:CancelUploadArchive"
    ]

    resources = [
      aws_codecommit_repository.application_source.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "pipeline" {
  name               = "${var.name}-${local.phase}-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.pipeline_role_trust.json
}

resource "aws_iam_role_policy" "pipeline" {
  name   = "${var.name}-${local.phase}-pipeline-policy"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.pipeline_role_policy.json
}
###
### End of CodePipeline role and related permission.
###

resource "aws_codepipeline" "pipeline" {
  name = "${var.name}-${local.phase}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifact.bucket
    type     = "S3"

#    encryption_key {
#      id   = data.aws_kms_alias.build_delivery_pipeline_artifact.arn
#      type = "KMS"
#    }
  }

  # CodeCommit action: https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodeCommit.html
  stage {
    name = "Source_Stage"
    action {
      name = "Pull_Source_Code_Action"
      category = "Source"
      owner = "AWS"
      provider = "CodeCommit"
      version = "1"
      output_artifacts = ["SourceOutput"]
      configuration = {
        RepositoryName = aws_codecommit_repository.application_source.repository_name
        BranchName = "main"
      }
    }
  }

  stage {
    name = "Build_And_Delivery_Stage"
    action {
      name             = "Build_And_Delivery_Action"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"

      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      run_order = 1

      configuration = {
        ProjectName = aws_codebuild_project.build.id
      }
    }
  }

  # [2023-12-10] Post processing, for example, analyze vulnerability report, acquire remediation actions from GenAI (eg. by calling Bedrock),
  # and send them to communicaton channels (eg. Slack, Teams, etc.)
  # 우리는 이러한 후처리를 Lambda에서 수행할 수도 있지만, 15분이라는 시간 제한을 염두에 두어야 하고, 또 현재로서는 복잡한
  # 구조를 가져갈 필요가 없으므로 일단 단순한 형태인 Pipeline 내의 추가 Stage로서 구현해 본다. (YAGNI)
  stage {
    name = "Post_Process_Stage"
    action {
      name = "Post_Process_Action"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"

      input_artifacts = ["BuildOutput"]
      output_artifacts = ["PostProcessOutput"]
      run_order = 1

      configuration = {
        ProjectName = aws_codebuild_project.post_process.id
      }
    }
  }
}

###
### EventBridge trigger role.
###
resource "aws_iam_role" "pipeline_trigger" {
  name = "${var.name}-${local.phase}-pipeline-trigger-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "pipeline_trigger" {
  description = "${var.name} - CodePipeline (CI) Trigger Execution Policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codepipeline:StartPipelineExecution"
      ],
      "Effect": "Allow",
      "Resource": "${aws_codepipeline.pipeline.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "pipeline_trigger_attach" {
  role       = aws_iam_role.pipeline_trigger.name
  policy_arn = aws_iam_policy.pipeline_trigger.arn
}
