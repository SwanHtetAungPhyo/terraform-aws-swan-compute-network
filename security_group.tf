# Security Groups for EC2 instances
resource "aws_security_group" "ec2" {
  for_each = var.ec2_instances

  name        = "${var.project_name}-${var.environment}-${each.key}-sg"
  description = "Security group for ${each.key} EC2 instance"
  vpc_id      = aws_vpc.main-vpc.id

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}-sg"
      Environment = var.environment
    },
    each.value.tags
  )
}

# Ingress Rules
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for pair in flatten([
      for instance_key, instance in var.ec2_instances : [
        for idx, rule in instance.security_group_rules.ingress : {
          key         = "${instance_key}-ingress-${idx}"
          sg_id       = instance_key
          from_port   = rule.from_port
          to_port     = rule.to_port
          protocol    = rule.protocol
          cidr_blocks = rule.cidr_blocks
          description = rule.description
        }
      ]
    ]) : pair.key => pair
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.ec2[each.value.sg_id].id
}

# Egress Rules
resource "aws_security_group_rule" "egress" {
  for_each = {
    for pair in flatten([
      for instance_key, instance in var.ec2_instances : [
        for idx, rule in instance.security_group_rules.egress : {
          key         = "${instance_key}-egress-${idx}"
          sg_id       = instance_key
          from_port   = rule.from_port
          to_port     = rule.to_port
          protocol    = rule.protocol
          cidr_blocks = rule.cidr_blocks
          description = rule.description
        }
      ]
    ]) : pair.key => pair
  }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.ec2[each.value.sg_id].id
}