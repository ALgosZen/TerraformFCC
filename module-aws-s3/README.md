# module-aws-s3
## Overview
Creates an AWS S3 bucket with lifecycle rules

Precedence of KMS Keys

kms_key_arn if passed in
kms_key_alias if passed in (and kms_key_arn = "")
kms_key_alias = accountLevelKey (and kms_key_arn = "")
No encryption of kms_key_alias = "" (and kms_key_arn = "")


To add Custom Bucket policy please follow these steps:

(Note: There is a sample code in example section under heading "Create a new S3 bucket with addition of custom bucket policy")
step 1 Run your solution to create S3 bucket, with commented variable "bucket_policy" and commented custom bucket policy
step 2 Once your bucket is created successfully, now un-comment the variable  "bucket_policy" and un-comment the custom bucket policy
Step 3 Run your solution again and this will merge your custom policy with default kabali s3policy    

---
## Examples
### Create a new S3 bucket with a new KMS key created for this applicaiton
```terraform
module "kms" {
  source = "git::codecommit://module-aws-kms?ref=v1"
  kms_key_alias = null
  payer = var.payer
  ou_security_type = var.ou_security_type
  application = var.application
  environment = var.environment
  tags = var.tags
}

module "s3" {
  source = "git::codecommit://module-aws-s3?ref=v2"
  application = var.application
  service = var.service
  environment = var.environment
  is_production = var.is_production
  tags = var.tags
  kms_key_alias = module.kms.kms_key_alias
  
  # We need to add depends to the KMS module when creating a new KMS key in this same terraform solution.
  depends_on = [
    module.kms
  ]
}
```
### Create a new S3 bucket with default Account Level CMK KMS key
```terraform
module "s3" {
  source = "git::codecommit://module-aws-s3?ref=v2"
  application = var.application
  service = var.service
  environment = var.environment
  is_production = var.is_production
  tags = var.tags  
}
```
### Create a new S3 bucket with addition of custom bucket policy
```terraform
module "s3" {
  source = "git::codecommit://module-aws-s3?ref=v2"
  application = var.application
  service = var.service
  environment = var.environment
  is_production = var.is_production
  # We need to add the data source name for the IAM Policy document  
  bucket_policy = [data.aws_iam_policy_document.example.json]
  tags = var.tags  
}

data "aws_iam_policy_document" "example" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      join("/", [module.s3.bucket_arn, "*"])
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

```

### Adding single retention rule to S3 Bucket:
```
s3_retention_rules = [
  {
    id:"rule_one",
    prefix: "rule_one",
    days: 10
  }
]
```
### Adding multiple retention rules to S3 Bucket:
```
s3_retention_rules = [
  {
    id:"rule_one",
    prefix: "rule_one",
    days: 10
  },
  {
    id:"rule_two",
    prefix: "rule_two",
    days: 18
  }
]
```

### Bucket Naming
The following rules are used to create the bucket name, which follows the format app-service-environment-region.
- If the size of the name is greater than 63 - truncate to 63
- If the size of the name is 60 to 62 - leave as is NO random number attached
- If the size of the name is 59 then add 3 digit random number
- If the size of the name is 58 then add 4 digit random number
- If the size of the name is 57 then add 5 digit random number
- If the size of the name is 56 then add 6 digit random number
- If the size of the name is 55 or less then add 7 digit random number

---
## Dependencies (Modules)
**Note: May have other dependencies not listed below**

No dependencies

---
## Inputs
### Required
- tags
	- Description: "Application tags"
	- Type: map(string)
- application
	- Description: "Project name, all lowercase with no spaces (ie. idb, eloise, ect.)"
	- Type: string
- environment
	- Description: "Environment name, all lowercase with no spaces (ie. lb, dv, qa, ect.)"
	- Type: string
- service
	- Description: "Bucket name, all lowercase with no spaces"
	- Type: string
- is_production
	- Description: "Does the currently environment have confidential data?"
	- Type: bool
### Optional Inputs
- enable_kms_encryption
	- Description: "Should the objects in this bucket be encrypted using a KMS key? The value should always be true unless used for CodePipeline"
	- Type: bool
	- Default Value: true
- enable_access_logging
	- Description: "If this value is try then configure the AWS logging bucket to the account specific S3 access log bucket"
	- Type: bool
	- Default Value: true
- enable_long_term_storage
	- Description: "After time, should the data be saved into long term storage or simply deleted? If production and long term storage - resources are moved to STANDARD_IA in 30 days, GLACIER in 90 days and deleted after 365 days. In development, if not long term storage - resources are deleted in 7 days"
	- Type: bool
	- Default Value: true
- prod_custom_lifecycle_rule
	- Description: "Custom prod lifecycle rule to choose days until transition to Standard-IA, days until transition to Glacier, and days until objects expire."
	- Type: map(string)
	- Default Value: {
- dev_custom_lifecycle_rule
	- Description: "Custom dev lifecycle rule to choose days until transition to Standard-IA, days until transition to Glacier, and days until objects expire."
	- Type: map(string)
	- Default Value: {
- noncurrent_version_lifecycle_rule
	- Description: "Noncurrent versionlifecycle rule to choose days until transition to Standard-IA, days until transition to Glacier, and days until objects delete."
	- Type: map(string)
	- Default Value: {
- enable_versioning
	- Description: "Should the bucket have versioning turned on. Required for CodePipeline"
	- Type: bool
	- Default Value: false
- suspend_versioning
	- Description: "Should the bucket have suspend versioning turned on. AWS status for bucket versioning are Disabled, Enabled, Suspended"
	- Type: bool
	- Default Value: false
	
- backup_plan
	- Description: "Backup plan schedule to be used in DataSync task. Valid Values are 's3-datasync-1-hour-rpo', 's3-datasync-4-hour-rpo', 's3-datasync-24-hour-rpo', 's3-datasync-local-1-hour-rpo', 's3-datasync-local-4-hour-rpo', and 's3-datasync-local-24-hour-rpo'."
	- Type: string
	- Default Value: ""
- backup_name
	- Description: "Backup name will be used to name the DataSync task. Required if backup_plan is passed in."
	- Type: string
	- Default Value: ""
- kms_key_alias
	- Description: "KMS alias to encrypt bucket"
	- Type: string
	- Default Value: "alias/accountLevelKMSKey"
- kms_key_arn
	- Description: "KMS Key ARN if not using the AccountLevelKey"
	- Type: string
	- Default Value: ""
- bucket_policy
	- Description: "For the addition of  bucket policy pass the data source for your custom ploicy"
	- Type: List
	- Default Value: []
- eventbridge
	- Description: "To Enable eventbridge functionality set it as true"
	- Type: bool
	- Default Value: false
- s3_retention_rules
	- Description: "Input variable to allow for adding lifecycle policy retention rules. Multiple rules can be added at once to allow for different objects to have different retention periods. If multiple rules are added the 'id' field must be unique for each rule. Prefix is used to filter out the objects the rule should apply to"
	- NOTE - Generally, S3 Lifecycle optimizes for cost. For example, if two expiration policies overlap, the shorter expiration policy is honored so that data is not stored for longer than expected. Likewise, if two transition policies overlap, S3 Lifecycle transitions your objects to the lower-cost storage class.
	- Type: list(object({
               id = string, 
               prefix = string, 
               days = number
            }))   
	- Default Value: []


---
## Output
- bucket_arn
	- Description: ARN: Bucket arn
- bucket_name
	- Description: String: Bucket name
- bucket_policy_arn
	- Description: ARN: Bucket policy arn
- bucket
	- Description: S3_Bucket: Bucket object
---
## Potential Resources Created
- s3_name_uuid
	- Type: resource
	- Source: random_string
- bucket
	- Type: resource
	- Source: aws_s3_bucket
- s3_policy
	- Type: resource
	- Source: aws_iam_policy
- kms_bucket_policy
	- Type: resource
	- Source: aws_s3_bucket_policy
