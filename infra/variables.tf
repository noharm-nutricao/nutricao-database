variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  type    = string
  default = "nitra-database"
}

variable "lambda_security_group_id" {
  type = string
}

variable "tf_state_bucket" {
  type = string
}

variable "database_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "database_volume_size" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "nitra"
}

variable "db_user" {
  type    = string
  default = "nitra"
}

variable "db_password" {
  type      = string
  sensitive = true
}