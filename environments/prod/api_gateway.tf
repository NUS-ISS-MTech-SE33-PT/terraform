module "api_gateway" {
  source = "../../modules/api_gateway"

  name       = "makan-go-http-api"
  stage_name = local.common_tags.environment
  tags       = local.common_tags

  cors_allow_origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "https://${aws_cloudfront_distribution.web_static.domain_name}",
    "https://${aws_cloudfront_distribution.admin_web.domain_name}",
  ]

  access_log_destination_arn = module.cloudwatch.log_groups["${local.common_tags.project}/${local.common_tags.environment}/api-gateway-access"].arn

  cognito_issuer   = "https://cognito-idp.${local.aws_region}.amazonaws.com/${module.cognito.user_pool_id}"
  cognito_audience = [module.cognito.android_client_id, module.cognito.admin_web_client_id]

  vpc_link_subnet_ids         = aws_subnet.ecs_subnet[*].id
  vpc_link_security_group_ids = [aws_security_group.ecs_sg.id]

  services = {
    review_service = {
      listener_arn = aws_lb_listener.service["review_service"].arn
      routes = [
        { route_key = "POST /spots/{id}/reviews", authorization_type = "JWT" },
        { route_key = "GET /users/me/reviews", authorization_type = "JWT" },
        { route_key = "GET /users/me/favorites", authorization_type = "JWT" },
        { route_key = "GET /spots/{id}/favorite", authorization_type = "JWT" },
        { route_key = "PUT /spots/{id}/favorite", authorization_type = "JWT" },
        { route_key = "DELETE /spots/{id}/favorite", authorization_type = "JWT" },
      ]
    }
    spot_service = {
      listener_arn = aws_lb_listener.service["spot_service"].arn
      routes = [
        { route_key = "GET /spots/health" },
        { route_key = "GET /spots" },
        { route_key = "GET /spots/{id}" },
      ]
    }
    spot_submission_service = {
      listener_arn = aws_lb_listener.service["spot_submission_service"].arn
      routes = [
        { route_key = "GET /spots/submissions/health" },
        # TODO: add JWT authorization to moderation routes once roles are defined.
        { route_key = "GET /moderation/submissions" },
        { route_key = "POST /moderation/submissions/{id}/approve" },
        { route_key = "POST /moderation/submissions/{id}/reject" },
        { route_key = "POST /spots/submissions/photos/presign", authorization_type = "JWT" },
        { route_key = "POST /spots/submissions", authorization_type = "JWT" },
      ]
    }
  }
}

# --- Moved blocks (safe to remove after one successful apply) ---

moved {
  from = aws_apigatewayv2_api.makan_go_http_api
  to   = module.api_gateway.aws_apigatewayv2_api.this
}

moved {
  from = aws_apigatewayv2_stage.prod_stage
  to   = module.api_gateway.aws_apigatewayv2_stage.this
}

moved {
  from = aws_apigatewayv2_authorizer.cognito_authorizer
  to   = module.api_gateway.aws_apigatewayv2_authorizer.cognito
}

moved {
  from = aws_apigatewayv2_vpc_link.ecs_vpc_link
  to   = module.api_gateway.aws_apigatewayv2_vpc_link.this
}

moved {
  from = aws_apigatewayv2_integration.review_service_integration
  to   = module.api_gateway.aws_apigatewayv2_integration.service["review_service"]
}

moved {
  from = aws_apigatewayv2_integration.spot_service_integration
  to   = module.api_gateway.aws_apigatewayv2_integration.service["spot_service"]
}

moved {
  from = aws_apigatewayv2_integration.spot_submission_service_integration
  to   = module.api_gateway.aws_apigatewayv2_integration.service["spot_submission_service"]
}

moved {
  from = aws_apigatewayv2_route.auth_route["POST /spots/{id}/reviews"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["review_service:POST /spots/{id}/reviews"]
}

moved {
  from = aws_apigatewayv2_route.auth_route["GET /users/me/reviews"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["review_service:GET /users/me/reviews"]
}

moved {
  from = aws_apigatewayv2_route.auth_route["GET /users/me/favorites"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["review_service:GET /users/me/favorites"]
}

moved {
  from = aws_apigatewayv2_route.auth_route["GET /spots/{id}/favorite"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["review_service:GET /spots/{id}/favorite"]
}

moved {
  from = aws_apigatewayv2_route.auth_route["PUT /spots/{id}/favorite"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["review_service:PUT /spots/{id}/favorite"]
}

moved {
  from = aws_apigatewayv2_route.auth_route["DELETE /spots/{id}/favorite"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["review_service:DELETE /spots/{id}/favorite"]
}

moved {
  from = aws_apigatewayv2_route.route["GET /spots/health"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["spot_service:GET /spots/health"]
}

moved {
  from = aws_apigatewayv2_route.route["GET /spots"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["spot_service:GET /spots"]
}

moved {
  from = aws_apigatewayv2_route.route["GET /spots/{id}"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["spot_service:GET /spots/{id}"]
}

moved {
  from = aws_apigatewayv2_route.public_route["GET /spots/submissions/health"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["spot_submission_service:GET /spots/submissions/health"]
}

moved {
  from = aws_apigatewayv2_route.public_route["GET /moderation/submissions"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["spot_submission_service:GET /moderation/submissions"]
}

moved {
  from = aws_apigatewayv2_route.public_route["POST /moderation/submissions/{id}/approve"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["spot_submission_service:POST /moderation/submissions/{id}/approve"]
}

moved {
  from = aws_apigatewayv2_route.public_route["POST /moderation/submissions/{id}/reject"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["spot_submission_service:POST /moderation/submissions/{id}/reject"]
}

moved {
  from = aws_apigatewayv2_route.user_auth_route["POST /spots/submissions/photos/presign"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["spot_submission_service:POST /spots/submissions/photos/presign"]
}

moved {
  from = aws_apigatewayv2_route.user_auth_route["POST /spots/submissions"]
  to   = module.api_gateway.aws_apigatewayv2_route.route["spot_submission_service:POST /spots/submissions"]
}
