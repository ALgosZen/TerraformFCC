data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  random_string_needed = length(format("%s-%s-%s-%s", var.application, var.service, var.environment, data.aws_region.current.name)) >= 60 ? false : true
  random_string_length = 7
  bucket_name_step1    = local.random_string_needed ? lower(format("%s-%s-%s-%s-%s", var.application, var.service, var.environment, data.aws_region.current.name, random_string.s3_name_uuid[0].result)) : lower(format("%s-%s-%s-%s", var.application, var.service, var.environment, data.aws_region.current.name))
  bucket_name_final    = substr(local.bucket_name_step1, 0, 63)
  custom_key           = var.kms_key_arn == "" ? data.aws_kms_key.kms_key.arn : var.kms_key_arn
 
}

data "aws_kms_key" "kms_key" {
  key_id = var.kms_key_alias
}

resource "random_string" "s3_name_uuid" {
  count   = local.random_string_needed ? 1 : 0
  length  = local.random_string_length
  special = false
}

resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket_name_final
  tags   = var.backup_plan != "" ? merge(var.tags, { BackupPlan = var.backup_plan, BackupName = var.backup_name }) : var.tags
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count       = var.eventbridge == true ? 1 : 0
  bucket      = aws_s3_bucket.bucket.id
  eventbridge = var.eventbridge
}


resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

# prod rule
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_config" {
  bucket = aws_s3_bucket.bucket.bucket
  rule {
    id     = "prod_rule"
    status = var.is_production && var.enable_long_term_storage ? "Enabled" : "Disabled"

    dynamic "transition" {
      for_each = var.prod_custom_lifecycle_rule.transition_to_standard_ia_day != null ? [1] : []
      content {
        days          = var.prod_custom_lifecycle_rule.transition_to_standard_ia_day
        storage_class = "STANDARD_IA"
      }
    }
    dynamic "transition" {
      for_each = var.prod_custom_lifecycle_rule.transition_to_glacier_day != null ? [1] : []
      content {
        days          = var.prod_custom_lifecycle_rule.transition_to_glacier_day
        storage_class = "GLACIER"
      }
    }

    dynamic "expiration" {
      for_each = var.prod_custom_lifecycle_rule.objects_expire_day != null ? [1] : []
      content {
        days = var.prod_custom_lifecycle_rule.objects_expire_day
      }
    }
  }
  rule {
    id     = "dev_rule"
    status = !var.is_production || !var.enable_long_term_storage ? "Enabled" : "Disabled"

    dynamic "transition" {
      for_each = var.dev_custom_lifecycle_rule.transition_to_standard_ia_day != null ? [1] : []
      content {
        days          = var.dev_custom_lifecycle_rule.transition_to_standard_ia_day
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "transition" {
      for_each = var.dev_custom_lifecycle_rule.transition_to_glacier_day != null ? [1] : []
      content {
        days          = var.dev_custom_lifecycle_rule.transition_to_glacier_day
        storage_class = "GLACIER"
      }
    }

    dynamic "expiration" {
      for_each = var.dev_custom_lifecycle_rule.objects_expire_day != null ? [1] : []
      content {
        days = var.dev_custom_lifecycle_rule.objects_expire_day
      }
    }
  }
  rule {
    id     = "version_rule"
    status = var.enable_versioning && !var.suspend_versioning ? "Enabled" : (!var.enable_versioning && var.suspend_versioning) ? "Suspended" : "Disabled"

    dynamic "noncurrent_version_transition" {
      for_each = var.noncurrent_version_lifecycle_rule.transition_to_standard_ia_day != null ? [1] : []
      content {
        noncurrent_days = var.noncurrent_version_lifecycle_rule.transition_to_standard_ia_day
        storage_class   = "STANDARD_IA"
      }
    }

    dynamic "noncurrent_version_transition" {
      for_each = var.noncurrent_version_lifecycle_rule.transition_to_glacier_day != null ? [1] : []
      content {
        noncurrent_days = var.noncurrent_version_lifecycle_rule.transition_to_glacier_day
        storage_class   = "GLACIER"
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.noncurrent_version_lifecycle_rule.objects_expire_day != null ? [1] : []
      content {
        noncurrent_days = var.noncurrent_version_lifecycle_rule.objects_expire_day
      }
    }
  }

  dynamic "rule" {
    for_each = var.s3_retention_rules
    content {
      id     = rule.value.id
      status = "Enabled"
      filter {
        prefix = rule.value.prefix
      }
      expiration {
        days = rule.value.days
      }
    }
  }
}

# Server side encryption

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_configuration" {
  bucket = aws_s3_bucket.bucket.bucket
  dynamic "rule" {
    for_each = var.enable_kms_encryption ? [1] : []
    content {
      apply_server_side_encryption_by_default {
        kms_master_key_id = local.custom_key
        sse_algorithm     = "aws:kms"
      }
    }
  }
  dynamic "rule" {
    for_each = !var.enable_kms_encryption ? [1] : []
    content {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

#   versioning recourse
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.bucket.bucket
  versioning_configuration {
    status = var.enable_versioning && !var.suspend_versioning ? "Enabled" : (!var.enable_versioning && var.suspend_versioning) ? "Suspended" : "Disabled" 

  }
} 

