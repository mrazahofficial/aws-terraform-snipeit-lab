terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "snipeit_server" {
  ami                         = "ami-004d1eaf8eaa0107d"
  instance_type               = "t3.small"
  subnet_id                   = "subnet-0ff4945196ee40560"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.snipeit_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = file("${path.module}/install-docker.sh")
  user_data_replace_on_change = false

  tags = {
    Name        = "snipeit-lab-server"
    Environment = "Learning"
    ManagedBy   = "Terraform"
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}
resource "aws_security_group" "snipeit_sg" {
  name        = "snipeit-lab-sg"
  description = "Security group for Snipe-IT lab"
  vpc_id      = "vpc-002abe383118ef415"

  tags = {
    Name = "snipeit-lab-sg"
  }
}
resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.snipeit_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
resource "aws_iam_role" "ec2_ssm_role" {
  name = "snipeit-lab-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "snipeit-lab-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}
resource "aws_iam_role_policy" "snipeit_parameters" {
  name = "snipeit-lab-parameter-access"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:us-east-1:*:parameter/snipeit/lab/app-key",
          "arn:aws:ssm:us-east-1:*:parameter/snipeit/lab/db-password",
          "arn:aws:ssm:us-east-1:*:parameter/snipeit/lab/db-root-password"
        ]
      }
    ]
  })
}