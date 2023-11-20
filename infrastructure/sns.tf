resource "aws_sns_topic" "server_events_topic" {
  name         = "ServerEvents"
  display_name = "Generic Events"
}

resource "aws_sns_topic" "scaling_events_topic" {
  name         = "ScalingEvents"
  display_name = "ECS Autoscaling Events"
}

resource "aws_sns_topic_subscription" "events_subscription_discord" {
  endpoint  = aws_lambda_function.send_discord_webhook.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.server_events_topic.arn
}

resource "aws_sns_topic_subscription" "scaling_subscription_route53" {
  endpoint  = aws_lambda_function.manage_route53_record.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.scaling_events_topic.arn
}

data "aws_iam_policy_document" "codebuild_policy" {
  policy_id = "__default_policy_ID"

  statement {
    sid = "__default_statement_ID"

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        var.aws_account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.server_events_topic.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]
    resources = [aws_sns_topic.server_events_topic.arn]
    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "codebuild_policy" {
  arn    = aws_sns_topic.server_events_topic.arn
  policy = data.aws_iam_policy_document.codebuild_policy.json
}
