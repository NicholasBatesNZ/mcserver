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