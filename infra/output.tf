output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "lambda_function_name" {
  value = aws_lambda_function.app.function_name
}

output "lambda_alias_name" {
  value = aws_lambda_alias.live.name
}

output "function_url" {
  value = aws_lambda_function_url.app_url.function_url
}

output "database_instance_id" {
  value = aws_instance.database.id
}

output "database_private_ip" {
  value = aws_instance.database.private_ip
}