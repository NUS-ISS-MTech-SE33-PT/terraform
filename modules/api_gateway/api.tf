resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
  tags          = var.tags

  cors_configuration {
    allow_headers  = ["authorization", "content-type"]
    allow_methods  = ["OPTIONS", "GET", "POST", "PUT", "DELETE"]
    allow_origins  = var.cors_allow_origins
    expose_headers = ["www-authenticate"]
    max_age        = 3600
  }
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
  tags        = var.tags

  access_log_settings {
    destination_arn = var.access_log_destination_arn
    format = jsonencode({
      requestId               = "$context.requestId"
      ip                      = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      protocol                = "$context.protocol"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  name            = "CognitoAuthorizer"
  api_id          = aws_apigatewayv2_api.this.id
  authorizer_type = "JWT"

  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = var.cognito_issuer
    audience = var.cognito_audience
  }
}

resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "ecs-vpc-link"
  subnet_ids         = var.vpc_link_subnet_ids
  security_group_ids = var.vpc_link_security_group_ids
  tags               = var.tags
}
