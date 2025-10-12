output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS instance address"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
}

output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.postgres.db_name
}

output "connection_string" {
  description = "Database connection string (without password)"
  value       = "postgresql://${var.db_username}:****@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
  sensitive   = false
}

output "ssh_command" {
  description = "SSH command to connect to EC2 instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.web_server.public_ip}"
}