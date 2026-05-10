output "database_instance_id" {
  value = aws_instance.database.id
}

output "database_private_ip" {
  value = aws_instance.database.private_ip
}