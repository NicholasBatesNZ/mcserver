resource "aws_codebuild_project" "mcserver-codebuild" {
  name = "mcserver-build"
  service_role = "arn:aws:iam::251780365797:role/service-role/codebuild-mcserver-service-role"

  environment {
    type = "LINUX_CONTAINER"
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:7.0"
    privileged_mode = true

    environment_variable {
      name = "AWS_DEFAULT_REGION"
      type = "PLAINTEXT"
      value = "us-east-1"
    }
    environment_variable {
      name = "IMAGE_REPO_URI"
      type = "PLAINTEXT"
      value = "public.ecr.aws/l3c0s8n4"
    }
    environment_variable {
      name = "IMAGE_REPO_NAME"
      type = "PLAINTEXT"
      value = "mcserver"
    }
    environment_variable {
      name = "IMAGE_TAG"
      type = "PLAINTEXT"
      value = "latest"
    }
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
    s3_logs {
      location = "${var.s3_bucket_name}/logs"
      status = "ENABLED"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type = "S3"
    location = "${var.s3_bucket_name}/"
  }
}

data "archive_file" "codebuild_lambda_source_zip" {
  type = "zip"
  source_file = "lambda_sources/run_codebuild.py"
  output_path = "lambda_sources/run_codebuild.zip"
}

resource "aws_s3_object" "codebuild_lambda_source_object" {
  bucket = var.s3_bucket_name
  key = "lambda_sources/run_codebuild.zip"
  source = data.archive_file.codebuild_lambda_source_zip.output_path
  source_hash = data.archive_file.codebuild_lambda_source_zip.output_base64sha256
}

resource "aws_lambda_function" "run_codebuild" {
  function_name = "RunCodeBuild"
  runtime = "python3.11"
  handler = "run_codebuild.lambda_handler"
  s3_bucket = var.s3_bucket_name
  s3_key = aws_s3_object.codebuild_lambda_source_object.key
  role = aws_iam_role.lambda_execution_role_codebuild.arn
  source_code_hash = aws_s3_object.codebuild_lambda_source_object.source_hash
}

resource "aws_iam_role" "lambda_execution_role_codebuild" {
  name = "LambdaExecutionRoleCodeBuild"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role_trust_policy.json
}

data "aws_iam_policy_document" "lambda_execution_policy_doc_codebuild" {
  statement {
    effect = "Allow"
    actions = [ "codebuild:StartBuild" ]
    resources = [ "arn:aws:codebuild:ap-southeast-2:251780365797:project/mcserver-build" ]
  }
}

resource "aws_iam_role_policy" "lambda_execution_policy_codebuild" {
  name = "CodeBuild"
  role = aws_iam_role.lambda_execution_role_codebuild.name
  policy = data.aws_iam_policy_document.lambda_execution_policy_doc_codebuild.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_basic_policy-codebuild" {
  role = aws_iam_role.lambda_execution_role_codebuild.name
  policy_arn = data.aws_iam_policy.lambda-basic-execution.arn
}

resource "aws_lambda_permission" "codebuild_lambda_allow_bucket" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.run_codebuild.arn
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.mcserver-bucket.arn
}
