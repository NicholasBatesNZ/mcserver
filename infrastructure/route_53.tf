resource "aws_route53_zone" "mcserver-zone" {
  name = var.domain
}

data "archive_file" "route53_lambda_source_zip" {
  type        = "zip"
  source_file = "lambda_sources/manage_route53_record.py"
  output_path = "lambda_sources/manage_route53_record.zip"
}

resource "aws_lambda_function" "manage_route53_record" {
  function_name    = "CreateRoute53Record"
  runtime          = "python3.11"
  handler          = "manage_route53_record.lambda_handler"
  role             = aws_iam_role.lambda_execution_role_route53.arn
  filename         = data.archive_file.route53_lambda_source_zip.output_path
  source_code_hash = data.archive_file.route53_lambda_source_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      HOSTED_ZONE_ID = aws_route53_zone.mcserver-zone.id
      RECORD_NAME    = var.domain
    }
  }
}

resource "aws_iam_role" "lambda_execution_role_route53" {
  name               = "LambdaExecutionRoleRoute53Record"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role_trust_policy.json
}

data "aws_iam_policy_document" "lambda_execution_policy_doc_route53" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
      "route53:ListResourceRecordSets"
    ]
    resources = [aws_route53_zone.mcserver-zone.arn]
  }
}

resource "aws_iam_role_policy" "lambda_execution_policy_route53" {
  name   = "Route53Record"
  role   = aws_iam_role.lambda_execution_role_route53.name
  policy = data.aws_iam_policy_document.lambda_execution_policy_doc_route53.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_basic_policy-route53" {
  role       = aws_iam_role.lambda_execution_role_route53.name
  policy_arn = data.aws_iam_policy.lambda-basic-execution.arn
}
