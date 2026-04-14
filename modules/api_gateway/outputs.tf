output "api_endpoint" {
  description = "The HTTP API invoke URL (includes stage name)."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "api_id" {
  description = "The HTTP API ID."
  value       = aws_apigatewayv2_api.this.id
}
