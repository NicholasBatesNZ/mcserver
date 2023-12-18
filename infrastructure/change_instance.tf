data "archive_file" "change_instance_source_zip" {
  type        = "zip"
  source_file = "lambda_sources/change_instance.py"
  output_path = "lambda_sources/change_instance.zip"
}

data "aws_ssm_parameter" "github_pat" {
  name = "github-token"
}

resource "aws_lambda_function" "change_instance" {
  function_name    = "ChangeInstance"
  runtime          = "python3.11"
  handler          = "change_instance.lambda_handler"
  role             = aws_iam_role.lambda_execution_role_change_instance.arn
  filename         = data.archive_file.change_instance_source_zip.output_path
  source_code_hash = data.archive_file.change_instance_source_zip.output_base64sha256

  environment {
    variables = {
      GITHUB_PAT = data.aws_ssm_parameter.github_pat.value
      repo       = var.github_repo
    }
  }
}

resource "aws_cloudwatch_event_rule" "param_change" {
  name = "SSMParameterChange"
  event_pattern = jsonencode({
    source      = ["aws.ssm"]
    detail-type = ["Parameter Store Change"]
  })
}

resource "aws_cloudwatch_event_target" "param_change_target" {
  rule = aws_cloudwatch_event_rule.param_change.name
  arn  = aws_lambda_function.change_instance.arn
}

resource "aws_lambda_permission" "change_instance_lambda_allow_eventbridge" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.change_instance.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.param_change.arn
}

resource "aws_iam_role" "lambda_execution_role_change_instance" {
  name               = "LambdaExecutionRoleChangeInstance"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_basic_policy_change_instance" {
  role       = aws_iam_role.lambda_execution_role_change_instance.name
  policy_arn = data.aws_iam_policy.lambda-basic-execution.arn
}
