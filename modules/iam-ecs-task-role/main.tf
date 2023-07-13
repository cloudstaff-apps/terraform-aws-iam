resource "aws_iam_role" "this" {
  count = var.create_role ? 1 : 0

  name                 = var.role_name
  name_prefix          = var.role_name_prefix
  tags                 = var.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "ecs_s3_policy_doc" {
  count = var.create_role && length(var.s3_access) > 0 ? 0 : 1

  dynamic "statement" {
    for_each = length(var.s3_access) > 0 ? [1] : []

    content {
      actions = ["s3:PutObject", "s3:PutObjectAcl", "s3:GetObject", "s3:DeleteObject"]
      resources = var.s3_access
    }
  }
}

resource "aws_iam_role_policy" "ecs_s3_policy" {
  count  = var.create_role && length(var.s3_access) > 0 ? 0 : 1
  name   = "${var.role_name}-s3-policy"
  role   = aws_iam_role.this[0].name

  policy = data.aws_iam_policy_document.ecs_s3_policy_doc.this[0].json
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "custom" {
  count = var.create_role ? coalesce(var.number_of_custom_role_policy_arns, length(var.custom_role_policy_arns)) : 0

  role       = aws_iam_role.this[0].name
  policy_arn = element(var.custom_role_policy_arns, count.index)
}

resource "aws_iam_role_policy_attachment" "readonly" {
  count = var.create_role && var.attach_readonly_policy ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = var.readonly_role_policy_arn
}