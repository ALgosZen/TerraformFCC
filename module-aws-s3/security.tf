resource "aws_iam_policy" "s3_policy" {
  name        = join("-", [var.application, var.service, var.environment, "s3", data.aws_region.current.name])
  path        = "/"
  description = "Access to S3 bucket."
  policy      = data.aws_iam_policy_document.s3_policy.json
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    effect = "Allow"

    resources = [
      join("/", [aws_s3_bucket.bucket.arn, "*"])
    ]
  }
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid     = "DenySSE-S3"
    actions = ["s3:PutObject"]
    effect  = "Deny"
    resources = [
      join("/", [aws_s3_bucket.bucket.arn, "*"]),

    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "AES256",
      ]
    }
  }
  statement {
    sid     = "RequireKMSEncryption"
    actions = ["s3:PutObject"]
    effect  = "Deny"
    resources = [
      join("/", [aws_s3_bucket.bucket.arn, "*"]),
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotLikeIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"

      values = [
        local.custom_key,
      ]
    }
  }
  statement {
    sid     = "ssl-requests-only"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      join("/", [aws_s3_bucket.bucket.arn, "*"]),
      aws_s3_bucket.bucket.arn
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = [false, ]
    }
  }
}

data "aws_iam_policy_document" "merged_s3_bucket_policy" {
  source_policy_documents = [data.aws_iam_policy_document.kms_policy.json]
  # override_policy_documents  = [local.replace_input_policy]
  override_policy_documents = var.bucket_policy != [] ? var.bucket_policy : []
}
resource "aws_s3_bucket_policy" "kms_bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.merged_s3_bucket_policy.json
}
