# Terraform AWS SWAN Compute Network Module

A Terraform module for deploying a complete AWS VPC infrastructure with compute resources, including public/private subnets, NAT instances, and EC2 instances with customizable security groups.

## Features

- **VPC with DNS support** - Fully configured VPC with DNS hostnames and resolution
- **Multi-AZ deployment** - Support for multiple availability zones
- **Public and private subnets** - Separate subnet tiers for different workload types
- **Cost-effective NAT** - NAT instances instead of NAT Gateway (free tier eligible)
- **Flexible NAT configuration** - Single NAT instance or one per AZ
- **Dynamic EC2 provisioning** - Deploy multiple EC2 instances with custom configurations
- **Security group management** - Per-instance security groups with custom rules
- **Encrypted storage** - All EBS volumes encrypted by default
- **IMDSv2 enforcement** - Enhanced EC2 metadata security

## Usage

### Basic Example

```hcl
module "swan_network" {
  source = "SwanHtetAungPhyo/swan-compute-network/aws"

  project_name = "myapp"
  environment  = "dev"
  
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  
  nat_key_name         = "my-ssh-key"
  nat_instance_type    = "t3.micro"
  single_nat_instance  = true

  ec2_instances = {
    web-server = {
      instance_type           = "t3.micro"
      ami_id                  = "ami-0c55b159cbfafe1f0"
      subnet_type             = "public"
      availability_zone_index = 0
      key_name                = "my-ssh-key"
      root_volume_size        = 20
      
      security_group_rules = {
        ingress = [
          {
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            description = "Allow HTTP"
          },
          {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            description = "Allow HTTPS"
          }
        ]
        egress = [
          {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
            description = "Allow all outbound"
          }
        ]
      }
      
      tags = {
        Role = "WebServer"
      }
    }
  }
}
```

### Advanced Example with Multiple Instances

```hcl
module "swan_network" {
  source = "SwanHtetAungPhyo/swan-compute-network/aws"

  project_name = "myapp"
  environment  = "prod"
  
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  nat_key_name         = "prod-key"
  nat_instance_type    = "t3.small"
  single_nat_instance  = false  # One NAT per AZ for HA

  ec2_instances = {
    bastion = {
      instance_type           = "t3.micro"
      ami_id                  = "ami-0c55b159cbfafe1f0"
      subnet_type             = "public"
      availability_zone_index = 0
      key_name                = "prod-key"
      root_volume_size        = 10
      
      security_group_rules = {
        ingress = [
          {
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            cidr_blocks = ["203.0.113.0/24"]
            description = "SSH from office"
          }
        ]
        egress = [
          {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
            description = "Allow all outbound"
          }
        ]
      }
      
      tags = {
        Role = "Bastion"
      }
    }
    
    app-server = {
      instance_type           = "t3.medium"
      ami_id                  = "ami-0c55b159cbfafe1f0"
      subnet_type             = "private"
      availability_zone_index = 0
      key_name                = "prod-key"
      root_volume_size        = 50
      user_data               = file("${path.module}/user-data.sh")
      
      security_group_rules = {
        ingress = [
          {
            from_port   = 8080
            to_port     = 8080
            protocol    = "tcp"
            cidr_blocks = ["10.0.0.0/16"]
            description = "App port from VPC"
          }
        ]
        egress = [
          {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
            description = "Allow all outbound"
          }
        ]
      }
      
      tags = {
        Role = "Application"
      }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Resources

This module creates the following resources:

- VPC with DNS support
- Internet Gateway
- Public and private subnets across multiple AZs
- Route tables and associations
- NAT instances (Amazon Linux 2)
- Elastic IPs for NAT instances
- EC2 instances with custom configurations
- Security groups with custom rules

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Project name for resource naming | `string` | n/a | yes |
| environment | Environment (dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| availability_zones | List of availability zones | `list(string)` | `["us-east-1a", "us-east-1b"]` | no |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| private_subnet_cidrs | CIDR blocks for private subnets | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24"]` | no |
| nat_instance_type | Instance type for NAT instance | `string` | `"t3.micro"` | no |
| nat_key_name | SSH key name for NAT instance | `string` | n/a | yes |
| single_nat_instance | Use single NAT instance for all private subnets (cost-effective) | `bool` | `true` | no |
| ec2_instances | Map of EC2 instance configurations | `map(object)` | n/a | yes |

### EC2 Instance Configuration Object

```hcl
{
  instance_type           = string           # EC2 instance type
  ami_id                  = string           # AMI ID to use
  subnet_type             = string           # "public" or "private"
  availability_zone_index = number           # Index of AZ (0, 1, 2, etc.)
  key_name                = string           # SSH key name
  user_data               = optional(string) # User data script
  root_volume_size        = optional(number) # Root volume size in GB (default: 20)
  
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
  
  tags = optional(map(string)) # Additional tags
}
```

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| nat_instance_ids | List of NAT instance IDs |
| nat_instance_public_ips | Elastic IPs of NAT instances |
| nat_instance_private_ips | Private IPs of NAT instances |
| ec2_instance_ids | Map of EC2 instance IDs |
| ec2_private_ips | Map of EC2 private IPs |
| ec2_public_ips | Map of EC2 public IPs (if in public subnet) |
| security_group_ids | Map of security group IDs |

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                          VPC                               │
│                                                            │
│  ┌──────────────────┐              ┌──────────────────┐    │
│  │  Public Subnet   │              │  Public Subnet   │    │
│  │    (AZ-1)        │              │    (AZ-2)        │    │
│  │                  │              │                  │    │
│  │  ┌────────────┐  │              │  ┌────────────┐  │    │
│  │  │ NAT Inst.  │  │              │  │ NAT Inst.  │  │    │
│  │  │ (optional) │  │              │  │ (optional) │  │    │
│  │  └────────────┘  │              │  └────────────┘  │    │
│  │                  │              │                  │    │
│  │  ┌────────────┐  │              │                  │    │
│  │  │ EC2 (pub)  │  │              │                  │    │
│  │  └────────────┘  │              │                  │    │
│  └──────────────────┘              └──────────────────┘    │
│           │                                 │              │
│           └────────────┬────────────────────┘              │
│                        │                                   │
│                 Internet Gateway                           │
│                                                            │
│  ┌──────────────────┐              ┌──────────────────┐    │
│  │ Private Subnet   │              │ Private Subnet   │    │
│  │    (AZ-1)        │              │    (AZ-2)        │    │
│  │                  │              │                  │    │
│  │  ┌────────────┐  │              │  ┌────────────┐  │    │
│  │  │ EC2 (priv) │  │              │  │ EC2 (priv) │  │    │
│  │  └────────────┘  │              │  └────────────┘  │    │
│  └──────────────────┘              └──────────────────┘    │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## Security Features

- **Encrypted EBS volumes** - All root volumes are encrypted by default
- **IMDSv2 enforcement** - EC2 instances require IMDSv2 for metadata access
- **Source/destination checks disabled** - NAT instances properly configured
- **Custom security groups** - Per-instance security group configuration
- **Private subnet isolation** - Private instances route through NAT

## Cost Optimization

This module uses NAT instances instead of AWS NAT Gateway, which can save significant costs:

- **NAT Gateway**: ~$32/month per AZ + data transfer costs
- **NAT Instance (t3.micro)**: ~$7.50/month + data transfer costs

For development and small workloads, use `single_nat_instance = true` to share one NAT instance across all AZs.

## Notes

- NAT instances use Amazon Linux 2 AMI (automatically fetches latest)
- All resources are tagged with `Environment` and `ManagedBy` tags
- Public subnets have `map_public_ip_on_launch` enabled
- NAT instances are free tier eligible (t3.micro)

## License

MIT

## Author

Maintained by Swan Htet Aung Phyo

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
