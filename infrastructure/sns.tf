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

resource "aws_sns_topic_subscription" "events_subscription_route53" {
  endpoint  = aws_lambda_function.manage_route53_record.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.scaling_events_topic.arn
}
