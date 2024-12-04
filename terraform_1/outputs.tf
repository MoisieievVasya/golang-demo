output "ec2_public_ip" {
  value = aws_instance.golang_demo.public_ip
}

output "rds_endpoint" {
  value = replace(aws_db_instance.postgres.endpoint, ":5432", "")
}
