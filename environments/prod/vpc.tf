data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "ecs_subnet" {
  count             = 2
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ecs_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_route_table" "ecs_rt" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_route" "ecs_route" {
  route_table_id         = aws_route_table.ecs_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ecs_igw.id
}

resource "aws_route_table_association" "ecs_rta" {
  count          = 2
  subnet_id      = aws_subnet.ecs_subnet[count.index].id
  route_table_id = aws_route_table.ecs_rt.id
}

# Dedicated security group for the API Gateway VPC Link.
# VPC Link only needs outbound connectivity to reach the internal NLBs.
# No ingress rules — the VPC Link originates connections, it does not receive them.
resource "aws_security_group" "ecs_sg" {
  name        = "api-gw-vpc-link-sg"
  description = "API Gateway VPC Link — outbound to internal NLBs only"
  vpc_id      = aws_vpc.ecs_vpc.id

  egress {
    description = "Allow all outbound to reach internal NLBs in the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Per-service ECS security groups.
#
# Ingress is restricted to:
#   1. Port 8080 from the VPC Link SG — NLB (target_type=ip) preserves the client
#      source IP, so the ECS task sees the VPC Link's ENI IP, which is associated
#      with ecs_sg. SG-to-SG referencing therefore works through the NLB.
#   2. Port 8080 from the VPC CIDR — required for internal NLB health checks,
#      which originate from the NLB's own private IPs in the subnet range.
#      Known limitation: ECS task IPs are in the same CIDR, so cross-service
#      calls within the VPC are technically still possible via this rule.
#      Eliminating this gap would require per-service subnets + NACLs.
#
# Egress is restricted to HTTPS (443) only. All AWS SDK calls (DynamoDB, S3,
# CloudWatch Logs, ECR) use HTTPS. This also blocks any unexpected outbound
# connections on non-standard ports.
locals {
  ecs_services_sg = {
    review_service          = "review-service-ecs-sg"
    spot_service            = "spot-service-ecs-sg"
    spot_submission_service = "spot-submission-service-ecs-sg"
  }
}

resource "aws_security_group" "ecs_service_sg" {
  for_each = local.ecs_services_sg

  name        = each.value
  description = "ECS Fargate task SG for ${each.value}"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description     = "Allow from API Gateway VPC Link (source IP preserved through NLB)"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  ingress {
    description = "Allow from VPC CIDR for internal NLB health checks"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.ecs_vpc.cidr_block]
  }

  egress {
    description = "HTTPS only - covers ECR, CloudWatch Logs, DynamoDB, S3"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
