resource "aws_apigatewayv2_api" "makan_go_http_api" {
  name          = "makan-go-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = [
      "authorization",
      "content-type"
    ]
    allow_methods = [
      "OPTIONS",
      "GET",
      "POST",
      "PUT",
      "DELETE"
    ]
    allow_origins = [
      "http://localhost:5173",
      "http://127.0.0.1:5173",
      "https://${aws_cloudfront_distribution.web_static.domain_name}",
      "https://${aws_cloudfront_distribution.admin_web.domain_name}"
    ]
    expose_headers = ["www-authenticate"]
    max_age        = 3600
  }
}

resource "aws_apigatewayv2_stage" "prod_stage" {
  api_id      = aws_apigatewayv2_api.makan_go_http_api.id
  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_log.arn
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

resource "aws_apigatewayv2_authorizer" "cognito_authorizer" {
  name            = "CognitoAuthorizer"
  api_id          = aws_apigatewayv2_api.makan_go_http_api.id
  authorizer_type = "JWT"

  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = "https://cognito-idp.ap-southeast-1.amazonaws.com/${module.cognito.user_pool_id}"
    audience = [module.cognito.android_client_id, module.cognito.admin_web_client_id]
  }
}

resource "aws_apigatewayv2_vpc_link" "ecs_vpc_link" {
  name               = "ecs-vpc-link"
  subnet_ids         = aws_subnet.ecs_subnet[*].id
  security_group_ids = [aws_security_group.ecs_sg.id]
}

resource "aws_apigatewayv2_integration" "review_service_integration" {
  api_id             = aws_apigatewayv2_api.makan_go_http_api.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.review_service_network_load_balancer_listener.arn
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.ecs_vpc_link.id
  integration_method = "ANY"

  request_parameters = {
    "overwrite:path"           = "$request.path",
    "append:header.x-user-sub" = "$context.authorizer.claims.sub"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_route" "auth_route" {
  for_each = toset([
    "POST /spots/{id}/reviews",
    "GET /users/me/reviews",
    "GET /users/me/favorites",
    "GET /spots/{id}/favorite",
    "PUT /spots/{id}/favorite",
    "DELETE /spots/{id}/favorite"
  ])

  api_id             = aws_apigatewayv2_api.makan_go_http_api.id
  route_key          = each.value
  target             = "integrations/${aws_apigatewayv2_integration.review_service_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_authorizer.id

  lifecycle {
    create_before_destroy = true
  }
}
