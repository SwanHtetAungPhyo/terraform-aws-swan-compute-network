# EC2 Instances
resource "aws_instance" "main" {
  for_each = var.ec2_instances

  ami           = each.value.ami_id
  instance_type = each.value.instance_type

  subnet_id = each.value.subnet_type == "public" ? (
    aws_subnet.public[each.value.availability_zone_index].id
    ) : (
    aws_subnet.private[each.value.availability_zone_index].id
  )

  vpc_security_group_ids = [aws_security_group.ec2[each.key].id]
  key_name               = each.value.key_name
  user_data              = each.value.user_data != "" ? each.value.user_data : null

  root_block_device {
    volume_size           = each.value.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    each.value.tags
  )
}