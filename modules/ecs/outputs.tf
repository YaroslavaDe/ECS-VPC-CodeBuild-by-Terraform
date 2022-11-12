# outputs.tf

output "alb_hostname" {
  value = aws_alb.main.dns_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnets" {
  value = values(aws_subnet.private)[*].id
}
