output "instance_1_ip" {
  value = aws_instance.web-terraform-instance-1.public_ip
}

output "instance_2_ip" {
  value = aws_instance.web-terraform-instance-2.public_ip
}

output "lb-dns-name" {
  value = aws_lb.web-terraform-lb.dns_name
}
