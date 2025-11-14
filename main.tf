data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
locals {
  ManagedBy = "Terraform"
}

resource "aws_security_group" "nat_instance" {
  name        = "${var.project_name}-${var.environment}-nat-instance-sg"
  description = "Security group for NAT instance"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all from private subnets"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound"
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-instance-sg"
    Environment = var.environment
  }
}
resource "aws_instance" "nat-instance" {
  count         = var.single_nat_instance ? 1 : length(var.availability_zones)
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.nat_instance_type
  key_name      = var.nat_key_name

  source_dest_check = false

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-instance-${count.index + 1}"
    Environment = var.environment
    Role        = "NAT"
    ManagedBy   = local.ManagedBy
  }
}

resource "aws_eip" "nat_instance" {
  count    = var.single_nat_instance ? 1 : length(var.availability_zones)
  domain   = "vpc"
  instance = aws_instance.nat-instance[count.index].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main-igw]
}