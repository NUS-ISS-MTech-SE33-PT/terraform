output "domain_name" {
  description = "The CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "arn" {
  description = "The CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_id" {
  description = "The CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}
