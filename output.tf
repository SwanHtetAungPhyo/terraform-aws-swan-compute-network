output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main-vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_instance_ids" {
  description = "List of NAT instance IDs"
  value       = aws_instance.nat-instance[*].id
}

output "nat_instance_public_ips" {
  description = "Elastic IPs of NAT instances"
  value       = aws_eip.nat_instance[*].public_ip
}

output "nat_instance_private_ips" {
  description = "Private IPs of NAT instances"
  value       = aws_instance.nat-instance[*].private_ip
}

output "ec2_instance_ids" {
  description = "Map of EC2 instance IDs"
  value       = { for k, v in aws_instance.main : k => v.id }
}

output "ec2_private_ips" {
  description = "Map of EC2 private IPs"
  value       = { for k, v in aws_instance.main : k => v.private_ip }
}

output "ec2_public_ips" {
  description = "Map of EC2 public IPs (if in public subnet)"
  value       = { for k, v in aws_instance.main : k => v.public_ip if v.public_ip != "" }
}

output "security_group_ids" {
  description = "Map of security group IDs"
  value       = { for k, v in aws_security_group.ec2 : k => v.id }
}