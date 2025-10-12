variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

# EC2 Variables
variable "ec2_ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 - Update this for your region
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

# Database Variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "medilink"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 16
    error_message = "Database password must be at least 16 characters long."
  }
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial storage allocation in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage allocation in GB (for autoscaling)"
  type        = number
  default     = 100
}

variable "db_publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# Security Variables
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into EC2"
  type        = string
  default     = "0.0.0.0/0" # CHANGE THIS to your IP for production!
}

variable "allowed_db_cidr" {
  description = "CIDR block allowed to access database directly"
  type        = string
  default     = "0.0.0.0/0" # CHANGE THIS for production!
}