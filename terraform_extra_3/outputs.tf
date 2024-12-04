output "ec2_public_ip_1" {
  value = aws_instance.silly_demo[0].public_ip
}

output "ec2_public_ip_2" {
  value = aws_instance.silly_demo[1].public_ip
}


