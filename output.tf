output "public_server_ip" {
  value = aws_instance.public.public_ip
}

output "private_server_ip" {
  value = aws_instance.private.private_ip
}

output "loadbalancer_dns" {
  value = aws_lb.mylb.dns_name

}