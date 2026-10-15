resource "aws_security_group" "authentik_sg" {
  name        = "authentik-lab-sg"
  description = "Security group for Authentik lab"
  vpc_id      = "vpc-002abe383118ef415"

  tags = {
    Name = "authentik-lab-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "authentik_outbound" {
  security_group_id = aws_security_group.authentik_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "authentik_server" {
  ami                         = "ami-004d1eaf8eaa0107d"
  instance_type               = "t3.medium"
  subnet_id                   = "subnet-0ff4945196ee40560"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.authentik_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data                   = file("${path.module}/install-docker.sh")
  user_data_replace_on_change = false

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "authentik-lab-server"
    Environment = "Learning"
    ManagedBy   = "Terraform"
  }
}