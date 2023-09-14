resource "aws_lambda_function" "run_codebuild" {
  function_name = "RunCodeBuild"
  runtime = "python3.11"
  filename = "${var.lambda_source_location}/run_codebuild.py"
}