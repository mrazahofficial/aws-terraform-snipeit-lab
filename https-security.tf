locals {
  https_security_groups = {
    snipeit   = aws_security_group.snipeit_sg.id
    authentik = aws_security_group.authentik_sg.id
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = local.https_security_groups

  security_group_id = each.value
  description       = "HTTP for HTTPS certificate validation"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = local.https_security_groups

  security_group_id = each.value
  description       = "HTTPS access"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
