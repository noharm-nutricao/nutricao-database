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

resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg"
  description = "Security group da Lambda"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database_sg" {
  name        = "${var.project_name}-database-sg"
  description = "Security group do PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "PostgreSQL somente da Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.lambda_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_instance" "database" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.database_instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.database_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.database_profile.name
  associate_public_ip_address = true

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

resource "aws_lambda_function" "app" {
  function_name = var.project_name
  role          = aws_iam_role.lambda_role.arn

  package_type = "Image"
  image_uri    = var.image_uri

  timeout     = 30
  memory_size = 512

  publish = true

  vpc_config {
    subnet_ids         = data.aws_subnets.default.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_instance.database.private_ip
      DB_PORT     = "5432"
      DB_NAME     = var.db_name
      DB_USER     = var.db_user
      DB_PASSWORD = var.db_password
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc
  ]
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = "Alias de produção"
  function_name    = aws_lambda_function.app.function_name
  function_version = aws_lambda_function.app.version
}

resource "aws_lambda_function_url" "app_url" {
  function_name      = aws_lambda_function.app.function_name
  qualifier          = aws_lambda_alias.live.name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}

resource "aws_lambda_permission" "allow_function_url" {
  statement_id           = "AllowPublicFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.app.function_name
  principal              = "*"
  qualifier              = aws_lambda_alias.live.name
  function_url_auth_type = "NONE"
}