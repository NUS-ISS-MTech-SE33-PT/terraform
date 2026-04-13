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

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
