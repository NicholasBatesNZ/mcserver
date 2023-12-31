resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

data "aws_iam_policy_document" "github-trust-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github-role" {
  name               = "GitHubOIDC"
  assume_role_policy = data.aws_iam_policy_document.github-trust-policy.json
}

data "aws_iam_policy_document" "github-permissions-policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${var.s3_manager_bucket}",
      "arn:aws:s3:::${var.s3_manager_bucket}/*"
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.management-distribution.arn]
  }
}

resource "aws_iam_role_policy" "github-role-policy" {
  name   = "GitHubActionsRolePolicy"
  role   = aws_iam_role.github-role.name
  policy = data.aws_iam_policy_document.github-permissions-policy.json
}

resource "aws_iam_role_policy_attachment" "github_oidc_admin" {
  role       = aws_iam_role.github-role.name
  policy_arn = data.aws_iam_policy.admin_access.arn
}
