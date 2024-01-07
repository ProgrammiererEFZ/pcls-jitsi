data "aws_iam_policy_document" "jitsi-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:*",
      "ec0:*"
    ]
    resources = ["*"]
  }
}