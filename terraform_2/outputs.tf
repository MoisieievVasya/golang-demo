output "ec2_public_ip" {
  value = aws_instance.golang_demo.public_ip
}