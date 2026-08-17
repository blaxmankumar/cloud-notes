resource "aws_security_group" "verified_access" {
  name        = "${var.name_prefix}-verified-access-endpoint"
  description = "Egress from Verified Access endpoint to internal ALB only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-verified-access-endpoint-sg" })
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb"
  description = "Internal ALB reachable only from Verified Access"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app"
  description = "Private application instance reachable only from ALB"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-ec2-app-sg" })
}

resource "aws_vpc_security_group_egress_rule" "verified_access_to_alb" {
  security_group_id            = aws_security_group.verified_access.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "Verified Access to ALB"
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_verified_access" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.verified_access.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "HTTP from Verified Access endpoint only"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.application_port
  to_port                      = var.application_port
  description                  = "ALB to application"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.application_port
  to_port                      = var.application_port
  description                  = "Application traffic from ALB only"
}

resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS for SSM, package repositories, and container registries"
}

resource "aws_vpc_security_group_egress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "HTTP package repository redirects during bootstrap"
}

resource "aws_vpc_security_group_egress_rule" "app_dns_udp" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  description       = "VPC DNS resolver"
}

resource "aws_vpc_security_group_egress_rule" "app_dns_tcp" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  description       = "VPC DNS resolver TCP fallback"
}
