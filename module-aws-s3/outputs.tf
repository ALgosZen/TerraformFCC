output "bucket_arn" {
  value       = aws_s3_bucket.bucket.arn
  description = "ARN: Bucket arn"
}

output "bucket_name" {
  value       = aws_s3_bucket.bucket.id
  description = "String: Bucket name"
}

output "bucket_policy_arn" {
  value       = aws_iam_policy.s3_policy.arn
  description = "ARN: Bucket policy arn"

}

output "bucket" {
  value       = aws_s3_bucket.bucket
  description = "S3_Bucket: Bucket object"
}
