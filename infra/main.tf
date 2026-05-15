terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_iam_role" "database_role" {
  name = "${var.project_name}-database-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "database_ssm" {
  role       = aws_iam_role.database_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "database_s3_deploy" {
  name = "${var.project_name}-database-s3-deploy"
  role = aws_iam_role.database_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject"
      ]
      Resource = "arn:aws:s3:::${var.tf_state_bucket}/deployments/*"
    }]
  })
}

resource "aws_iam_instance_profile" "database_profile" {
  name = "${var.project_name}-database-profile"
  role = aws_iam_role.database_role.name
}

resource "aws_instance" "database" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.database_instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.database_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.database_profile.name
  associate_public_ip_address = true

  user_data_replace_on_change = true

  depends_on = [
    aws_iam_role_policy_attachment.database_ssm,
    aws_iam_role_policy.database_s3_deploy,
    aws_iam_instance_profile.database_profile
  ]

  root_block_device {
    volume_size = var.database_volume_size
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data_database.sh", {
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  })

  tags = {
    Name = "${var.project_name}-database"
  }
}