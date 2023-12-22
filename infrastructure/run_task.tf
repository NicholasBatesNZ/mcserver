data "archive_file" "run_task_source_zip" {
  type        = "zip"
  source_file = "lambda_sources/run_task.py"
  output_path = "lambda_sources/run_task.zip"
}

resource "aws_lambda_function" "run_task" {
  function_name    = "RunTask"
  runtime          = "python3.11"
  handler          = "run_task.lambda_handler"
  role             = aws_iam_role.lambda_execution_role_run_task.arn
  filename         = data.archive_file.run_task_source_zip.output_path
  source_code_hash = data.archive_file.run_task_source_zip.output_base64sha256

  environment {
    variables = {
      TASK_ROLE_ARN = aws_iam_role.task_execution_role.arn
    }
  }
}

resource "aws_iam_role" "lambda_execution_role_run_task" {
  name               = "LambdaExecutionRoleRunTask"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_basic_policy_run_task" {
  role       = aws_iam_role.lambda_execution_role_run_task.name
  policy_arn = data.aws_iam_policy.lambda-basic-execution.arn
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_basic_policy_run_task_admin" {
  role       = aws_iam_role.lambda_execution_role_run_task.name
  policy_arn = data.aws_iam_policy.admin_access.arn
}
