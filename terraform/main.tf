# Data source to get default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-web-server-sg"
  description = "Security group for EC2 web server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom API port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ec2-web-server-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-postgres-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  ingress {
    description = "PostgreSQL from allowed IPs"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_db_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "rds-postgres-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "postgres" {
  name       = "postgres-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name        = "Postgres DB Subnet Group"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# EC2 instance
resource "aws_instance" "web_server" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  
  # Use key pair for SSH access
  key_name = var.key_pair_name

  # Enable detailed monitoring
  monitoring = true

  # User data script to install dependencies
  user_data = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "medilink-web-server"
    Environment = var.environment
    Project     = "MediLink"
    ManagedBy   = "Terraform"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier             = "medilink-postgres-${var.environment}"
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_max_allocated_storage
  engine                 = "postgres"
  engine_version         = "16.2"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  # Enhanced monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn
  
  # Security settings
  storage_encrypted      = true
  deletion_protection    = var.environment == "production" ? true : false
  skip_final_snapshot    = var.environment == "production" ? false : true
  final_snapshot_identifier = var.environment == "production" ? "medilink-postgres-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  
  publicly_accessible    = var.db_publicly_accessible
  
  # Performance Insights
  performance_insights_enabled    = true
  performance_insights_retention_period = 7

  tags = {
    Name        = "medilink-postgres"
    Environment = var.environment
    Project     = "MediLink"
    ManagedBy   = "Terraform"
  }
}

# IAM role for RDS enhanced monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "rds-monitoring-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}