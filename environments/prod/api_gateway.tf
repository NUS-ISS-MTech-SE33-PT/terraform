module "api_gateway" {
  source = "../../modules/api_gateway"

  name       = "makan-go-http-api"
  stage_name = local.common_tags.environment
  tags       = local.common_tags

  cors_allow_origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "https://${module.cloudfront_web_static.domain_name}",
    "https://${module.cloudfront_admin_web.domain_name}",
  ]

  access_log_destination_arn = module.cloudwatch.log_groups["${local.common_tags.project}/${local.common_tags.environment}/api-gateway-access"].arn

  cognito_issuer = "https://cognito-idp.${local.aws_region}.amazonaws.com/${module.cognito.user_pool_id}"

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
      ]
      jwt_routes = [
        "POST /spots/submissions/photos/presign",
        "POST /spots/submissions",
        "GET /moderation/submissions",
        "POST /moderation/submissions/{id}/approve",
        "POST /moderation/submissions/{id}/reject",
      ]
    }
  }
}
