locals {
  public_routes = merge([
    for svc_key, svc in var.services : {
      for route_key in svc.routes : "${svc_key}:${route_key}" => {
        service_key = svc_key
        route_key   = route_key
      }
    }
  ]...)

  jwt_routes = merge([
    for svc_key, svc in var.services : {
      for route_key in svc.jwt_routes : "${svc_key}:${route_key}" => {
        service_key = svc_key
        route_key   = route_key
      }
    }
  ]...)
}

resource "aws_apigatewayv2_integration" "service" {
  for_each = var.services

  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = each.value.listener_arn
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.this.id
  integration_method = "ANY"

  request_parameters = {
    "overwrite:path"           = "$request.path"
    "append:header.x-user-sub" = "$context.authorizer.claims.sub"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_route" "route" {
  for_each = local.public_routes

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.service[each.value.service_key].id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_route" "jwt_route" {
  for_each = local.jwt_routes

  api_id             = aws_apigatewayv2_api.this.id
  route_key          = each.value.route_key
  target             = "integrations/${aws_apigatewayv2_integration.service[each.value.service_key].id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id

  lifecycle {
    create_before_destroy = true
  }
}
