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
      routes       = []
      jwt_routes = [
        "POST /spots/{id}/reviews",
        "GET /users/me/reviews",
        "GET /users/me/favorites",
        "GET /spots/{id}/favorite",
        "PUT /spots/{id}/favorite",
        "DELETE /spots/{id}/favorite",
      ]
    }
    spot_service = {
      listener_arn = aws_lb_listener.service["spot_service"].arn
      routes = [
        "GET /spots/health",
        "GET /spots",
        "GET /spots/{id}",
      ]
    }
    spot_submission_service = {
      listener_arn = aws_lb_listener.service["spot_submission_service"].arn
      routes = [
        "GET /spots/submissions/health",
        # TODO: add JWT authorization to moderation routes once roles are defined.
        "GET /moderation/submissions",
        "POST /moderation/submissions/{id}/approve",
        "POST /moderation/submissions/{id}/reject",
      ]
      jwt_routes = [
        "POST /spots/submissions/photos/presign",
        "POST /spots/submissions",
      ]
    }
  }
}

# --- Moved blocks (safe to remove after one successful apply) ---

# JWT routes split from the unified route resource
moved {
  from = module.api_gateway.aws_apigatewayv2_route.route["review_service:POST /spots/{id}/reviews"]
  to   = module.api_gateway.aws_apigatewayv2_route.jwt_route["review_service:POST /spots/{id}/reviews"]
}

moved {
  from = module.api_gateway.aws_apigatewayv2_route.route["review_service:GET /users/me/reviews"]
  to   = module.api_gateway.aws_apigatewayv2_route.jwt_route["review_service:GET /users/me/reviews"]
}

moved {
  from = module.api_gateway.aws_apigatewayv2_route.route["review_service:GET /users/me/favorites"]
  to   = module.api_gateway.aws_apigatewayv2_route.jwt_route["review_service:GET /users/me/favorites"]
}

moved {
  from = module.api_gateway.aws_apigatewayv2_route.route["review_service:GET /spots/{id}/favorite"]
  to   = module.api_gateway.aws_apigatewayv2_route.jwt_route["review_service:GET /spots/{id}/favorite"]
}

moved {
  from = module.api_gateway.aws_apigatewayv2_route.route["review_service:PUT /spots/{id}/favorite"]
  to   = module.api_gateway.aws_apigatewayv2_route.jwt_route["review_service:PUT /spots/{id}/favorite"]
}

moved {
  from = module.api_gateway.aws_apigatewayv2_route.route["review_service:DELETE /spots/{id}/favorite"]
  to   = module.api_gateway.aws_apigatewayv2_route.jwt_route["review_service:DELETE /spots/{id}/favorite"]
}

moved {
  from = module.api_gateway.aws_apigatewayv2_route.route["spot_submission_service:POST /spots/submissions/photos/presign"]
  to   = module.api_gateway.aws_apigatewayv2_route.jwt_route["spot_submission_service:POST /spots/submissions/photos/presign"]
}

moved {
  from = module.api_gateway.aws_apigatewayv2_route.route["spot_submission_service:POST /spots/submissions"]
  to   = module.api_gateway.aws_apigatewayv2_route.jwt_route["spot_submission_service:POST /spots/submissions"]
}
