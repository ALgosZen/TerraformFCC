module "s3" {
  source        = "../module-aws-s3"
  application   = "damnIT"
  service       = "sb-bucket"
  environment   = "dev"
  is_production = true
  # Set the objects to never expire and never transition
  enable_versioning = true

  tags = {
    "backup_plan" = "s3-datasync-local-24-hour-rpo"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_block_public_access" {
  bucket = module.s3.bucket_name

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_config" {
  bucket = module.s3.bucket_name
  rule {
    id     = "prod_rule"
    status = "Enabled"

    transition {
      days          = var.custom_lc_rule.trans_standard_ia_day
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.custom_lc_rule.trans_glacier_day
      storage_class = "GLACIER"
    }

    expiration {
      days = var.custom_lc_rule.expiration_day

    }
  }
}
