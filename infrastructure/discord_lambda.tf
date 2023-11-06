data "archive_file" "discord_lambda_source_zip" {
  type = "zip"
  source_file = "lambda_sources/discordWebhook.mjs"
  output_path = "lambda_sources/discordWebhook.zip"
}

resource "aws_lambda_function" "send_discord_webhook" {
  function_name = "SNSDiscordWebhook"
  runtime = "nodejs18.x"
  handler = "discordWebhook.handler"
  role = aws_iam_role.lambda_execution_role_discord.arn
  filename = data.archive_file.discord_lambda_source_zip.output_path
  source_code_hash = data.archive_file.discord_lambda_source_zip.output_base64sha256

  environment {
    variables = {
        WEBHOOK_DISCORD = var.discord_webhook
    }
  }
}

resource "aws_iam_role" "lambda_execution_role_discord" {
  name = "LambdaExecutionRoleDiscordWebhook"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_basic_policy-discord" {
  role = aws_iam_role.lambda_execution_role_discord.name
  policy_arn = data.aws_iam_policy.lambda-basic-execution.arn
}
