variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance"
  type        = string
  default     = "t3.micro" # Eligible for free tier
}

variable "nat_key_name" {
  description = "SSH key name for NAT instance"
  type        = string
}

variable "single_nat_instance" {
  description = "Use single NAT instance for all private subnets"
  type        = bool
  default     = true
}

variable "ec2_instances" {
  description = "Map of EC2 instance configurations"
  type = map(object({
    instance_type           = string
    ami_id                  = string
    subnet_type             = string
    availability_zone_index = number
    key_name                = string
    user_data               = optional(string, "")
    root_volume_size        = optional(number, 20)
    security_group_rules = object({
      ingress = list(object({
        from_port   = number
        to_port     = number
        protocol    = string
        cidr_blocks = list(string)
        description = string
      }))
      egress = list(object({
        from_port   = number
        to_port     = number
        protocol    = string
        cidr_blocks = list(string)
        description = string
      }))
    })
    tags = optional(map(string), {})
  }))
}