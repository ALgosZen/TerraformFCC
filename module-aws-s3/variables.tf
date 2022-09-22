variable "tags" {
  type        = map(string)
  description = "Application tags"
}

variable "application" {
  type        = string
  description = "Project name, all lowercase with no spaces (ie. idb, eloise, ect.)"
}

variable "environment" {
  type        = string
  description = "Environment name, all lowercase with no spaces (ie. lb, dv, qa, ect.)"
}

variable "service" {
  type        = string
  description = "Bucket name, all lowercase with no spaces"
}

variable "is_production" {
  type        = bool
  description = "Does the currently environment have confidential data?"
}

variable "enable_kms_encryption" {
  type        = bool
  default     = true
  description = "Should the objects in this bucket be encrypted using a KMS key? The value should always be true unless used for CodePipeline"
}

variable "enable_access_logging" {
  type        = bool
  default     = true
  description = "If this value is try then configure the AWS logging bucket to the account specific S3 access log bucket"
}

variable "enable_long_term_storage" {
  type        = bool
  description = "After time, should the data be saved into long term storage or simply deleted? If production and long term storage - resources are moved to STANDARD_IA in 30 days, GLACIER in 90 days and deleted after 365 days. In development, if not long term storage - resources are deleted in 7 days"
  default     = true
}

variable "prod_custom_lifecycle_rule" {
  type        = map(string)
  description = "Custom prod lifecycle rule to choose days until transition to Standard-IA, days until transition to Glacier, and days until objects expire."
  default = {
    "transition_to_standard_ia_day" = "30",
    "transition_to_glacier_day"     = "90",
    "objects_expire_day"            = "365"
  }
}

variable "dev_custom_lifecycle_rule" {
  type        = map(string)
  description = "Custom dev lifecycle rule to choose days until transition to Standard-IA, days until transition to Glacier, and days until objects expire."
  default = {
    "transition_to_standard_ia_day" = null,
    "transition_to_glacier_day"     = null,
    "objects_expire_day"            = 0
  }
}

variable "noncurrent_version_lifecycle_rule" {
  type        = map(string)
  description = "Noncurrent versionlifecycle rule to choose days until transition to Standard-IA, days until transition to Glacier, and days until objects delete."
  default = {
    "transition_to_standard_ia_day" = 30,
    "transition_to_glacier_day"     = 90,
    "objects_expire_day"            = 365
  }
}

variable "enable_versioning" {
  default     = false
  description = "Should the bucket have versioning turned on. Required for CodePipeline"
  type        = bool
}

variable "suspend_versioning" {
  default     = false
  description = "Should the bucket have suspend versioning turned on. AWS status for bucket versioning are Disabled, Enabled, Suspended"
  type        = bool
}

variable "backup_plan" {
  type        = string
  description = "Backup plan schedule to be used in DataSync task. Valid Values are 's3-datasync-1-hour-rpo', 's3-datasync-4-hour-rpo', 's3-datasync-24-hour-rpo', 's3-datasync-local-1-hour-rpo', 's3-datasync-local-4-hour-rpo', and 's3-datasync-local-24-hour-rpo'."
  default     = ""

  validation {
    condition     = can(regex("^$|^s3-datasync-(1|4|24)-hour-rpo$|^s3-datasync-local-(1|4|24)-hour-rpo$", var.backup_plan))
    error_message = "The valid values for backup_plan are 's3-datasync-1-hour-rpo', 's3-datasync-4-hour-rpo', 's3-datasync-24-hour-rpo', 's3-datasync-local-1-hour-rpo', 's3-datasync-local-4-hour-rpo', and 's3-datasync-local-24-hour-rpo'."
  }
}

variable "backup_name" {
  type        = string
  description = "Backup name will be used to name the DataSync task. Required if backup_plan is passed in."
  default     = ""
}

variable "kms_key_alias" {
  type        = string
  description = "KMS alias to encrypt bucket"
  default     = "alias/accountLevelKMSKey"
}

variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "KMS Key ARN if not using the AccountLevelKey"
}

variable "bucket_policy" {
  type        = list(any)
  default     = []
  description = "For the addition of  bucket policy pass the data source for your custom ploicy"
}

variable "eventbridge" {
  default     = false
  description = "To Enable eventbridge functionality set it as true"
  type        = bool
}

variable "s3_retention_rules" {
  description = "S3 object expiration rules"
  type = list(object({
               id = string, 
               prefix = string, 
               days = number
            }))         
  default = []
}