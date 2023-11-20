resource "aws_iam_role" "codebuild_service_role" {
  name               = "CodeBuildServiceRole"
  assume_role_policy = data.aws_iam_policy_document.codebuild_service_role_trust_policy.json
}

data "aws_iam_policy_document" "codebuild_service_role_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:GetAuthorizationToken",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:PutImage",
      "ecr-public:UploadLayerPart",
      "sts:GetServiceBearerToken"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*",
      "arn:aws:s3:::codepipeline-${var.aws_region}-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_service_role_policy" {
  name   = "CodeBuild"
  role   = aws_iam_role.codebuild_service_role.name
  policy = data.aws_iam_policy_document.codebuild_service_role_policy_doc.json
}

resource "aws_codebuild_project" "mcserver-codebuild" {
  name         = "mcserver-build"
  service_role = aws_iam_role.codebuild_service_role.arn

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      type  = "PLAINTEXT"
      value = "us-east-1"
    }
    environment_variable {
      name  = "IMAGE_REPO_URI"
      type  = "PLAINTEXT"
      value = "public.ecr.aws/l3c0s8n4"
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      type  = "PLAINTEXT"
      value = "mcserver"
    }
    environment_variable {
      name  = "IMAGE_TAG"
      type  = "PLAINTEXT"
      value = "latest"
    }
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
    s3_logs {
      location = "${var.s3_bucket_name}/logs"
      status   = "ENABLED"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type     = "S3"
    location = "${var.s3_bucket_name}/"
  }
}

resource "aws_codestarnotifications_notification_rule" "build_notifications" {
  detail_type = "FULL"
  event_type_ids = [
    "codebuild-project-build-state-failed",
    "codebuild-project-build-state-succeeded",
    "codebuild-project-build-state-in-progress",
    "codebuild-project-build-state-stopped",
  ]

  name     = "codebuild-events"
  resource = aws_codebuild_project.mcserver-codebuild.arn

  target {
    address = aws_sns_topic.server_events_topic.arn
  }
}

data "archive_file" "codebuild_lambda_source_zip" {
  type        = "zip"
  source_file = "lambda_sources/run_codebuild.py"
  output_path = "lambda_sources/run_codebuild.zip"
}

resource "aws_lambda_function" "run_codebuild" {
  function_name    = "RunCodeBuild"
  runtime          = "python3.11"
  handler          = "run_codebuild.lambda_handler"
  role             = aws_iam_role.lambda_execution_role_codebuild.arn
  filename         = data.archive_file.codebuild_lambda_source_zip.output_path
  source_code_hash = data.archive_file.codebuild_lambda_source_zip.output_base64sha256
}

resource "aws_iam_role" "lambda_execution_role_codebuild" {
  name               = "LambdaExecutionRoleCodeBuild"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role_trust_policy.json
}

data "aws_iam_policy_document" "lambda_execution_policy_doc_codebuild" {
  statement {
    effect    = "Allow"
    actions   = ["codebuild:StartBuild"]
    resources = [aws_codebuild_project.mcserver-codebuild.arn]
  }
}

resource "aws_iam_role_policy" "lambda_execution_policy_codebuild" {
  name   = "CodeBuild"
  role   = aws_iam_role.lambda_execution_role_codebuild.name
  policy = data.aws_iam_policy_document.lambda_execution_policy_doc_codebuild.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_basic_policy-codebuild" {
  role       = aws_iam_role.lambda_execution_role_codebuild.name
  policy_arn = data.aws_iam_policy.lambda-basic-execution.arn
}

resource "aws_lambda_permission" "codebuild_lambda_allow_bucket" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.run_codebuild.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.mcserver-bucket.arn
}
