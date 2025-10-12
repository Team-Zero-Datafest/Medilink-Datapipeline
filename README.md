# Medilink Data Pipeline - Complete Documentation

![Medilink](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Python](https://img.shields.io/badge/python-3.10-blue.svg)
![Airflow](https://img.shields.io/badge/airflow-2.7.1-red.svg)

A comprehensive data pipeline for processing medical records from S3 to RDS PostgreSQL, with automated ETL using Apache Airflow, data transformation using dbt, and a RESTful API for data access.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#️-architecture)
- [Features](#-features)
- [Tech Stack](#️-tech-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [API Documentation](#-api-documentation)
- [dbt Models](#-dbt-models)
- [ETL Pipeline](#-etl-pipeline)
- [Monitoring & Logging](#-monitoring--logging)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

This project provides an end-to-end solution for managing and analyzing medical records data. It automates the process of extracting CSV files from S3, loading them into PostgreSQL RDS, transforming the data with dbt, and exposing the data through a RESTful API.

It is used with the medilink frontend to handle upload bulk patients, facilities or workers in a central repository in which medilink can then interface with individually entities specifically or collectively.

### Key Capabilities

- **Automated ETL**: Daily scheduled pipeline processing medical records from S3
- **ID Generation**: Automatic generation of unique IDs for all entities during transformation
- **Data Quality**: Comprehensive data validation and testing using dbt
- **Analytics Ready**: Pre-built analytics models for facilities, patients, and clinical data
- **RESTful API**: Full CRUD operations with pagination and filtering
- **Infrastructure as Code**: Complete Terraform configuration for AWS deployment
- **Scalable Architecture**: Containerized services with Docker Compose

---

## 🏗️ Architecture

```
┌─────────────┐
│   AWS S3    │ (CSV Files)
│   Bucket    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│         Apache Airflow (Docker)             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Extract  │→ │   Load   │→ │Transform │  │
│  │ from S3  │  │ to Stage │  │ with IDs │  │
│  └──────────┘  └──────────┘  └──────────┘  │
└────────────────────┬────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │   PostgreSQL RDS       │
        │  ┌──────────────────┐  │
        │  │ Production Tables│  │
        │  │  - facilities    │  │
        │  │  - patients      │  │
        │  │  - medical_records│ │
        │  │  - triage_visits │  │
        │  └──────────────────┘  │
        └───────────┬─────────────┘
                    │
        ┌───────────▼─────────────┐
        │    dbt (Analytics)      │
        │  ┌──────────────────┐   │
        │  │ Staging Models   │   │
        │  │ Marts Models     │   │
        │  │ Analytics Models │   │
        │  └──────────────────┘   │
        └───────────┬─────────────┘
                    │
                    ▼
        ┌────────────────────────┐
        │   Flask REST API       │
        │  (Docker Container)    │
        │                        │
        │ GET /api/facilities    │
        │ GET /api/patients      │
        │ POST /api/medical-...  │
        └────────────────────────┘
                    │
                    ▼
              ┌──────────┐
              │  Users/  │
              │ Analysts │
              └──────────┘
```

---

## ✨ Features

### Data Pipeline
- ✅ Automated extraction from S3 buckets
- ✅ Incremental loading with batch tracking
- ✅ Auto-generated sequential IDs for all entities
- ✅ Data validation and error handling
- ✅ Automatic file archiving after processing
- ✅ Comprehensive audit logging

### Data Modeling
- ✅ Staging layer for data cleansing
- ✅ Dimension tables (facilities, patients)
- ✅ Fact tables (medical records, triage visits)
- ✅ Pre-built analytics marts
- ✅ Data quality tests

### API
- ✅ RESTful endpoints for all entities
- ✅ Pagination and filtering
- ✅ Analytics endpoints
- ✅ Health check monitoring
- ✅ CORS enabled

### Infrastructure
- ✅ Terraform IaC for AWS
- ✅ VPC with public/private subnets
- ✅ EC2 instance with Docker
- ✅ RDS PostgreSQL database
- ✅ S3 bucket for data storage
- ✅ Security groups and IAM roles
- ✅ Automated bootstrap script

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| **Orchestration** | Apache Airflow 2.7.1 |
| **Data Warehouse** | PostgreSQL 14 (AWS RDS) |
| **Transformation** | dbt 1.6.6 |
| **API** | Flask 3.0.0 |
| **Cloud Storage** | AWS S3 |
| **Compute** | AWS EC2 |
| **Infrastructure** | Terraform |
| **Containerization** | Docker & Docker Compose |
| **Programming** | Python 3.10 |
| **Validation** | Pydantic 2.4.2 |

---

## 📂 Project Structure

```
medical-records-pipeline/
│
├── README.md                    # This file
├── LICENSE                      # MIT License
├── .gitignore                   # Git ignore rules
├── .env.example                 # Environment variables template
├── docker-compose.yaml          # Docker services configuration
├── Dockerfile                   # Airflow Docker image
├── requirements.txt             # Python dependencies (Airflow)
├── start.sh                     # Startup script
├── deploy-ec2.sh                # EC2 deployment script
│
├── terraform/                   # Infrastructure as Code
│   ├── provider.tf              # Terraform & AWS provider config
│   ├── variables.tf             # Input variables with validation
│   ├── main.tf                  # Core infrastructure resources
│   ├── outputs.tf               # Output values after deployment
│   ├── terraform.tfvars.example # Configuration template
│   └── user_data.sh             # EC2 bootstrap script
│
├── airflow/                     # Airflow DAGs and configuration
│   └── dags/
│       └── medical_records_pipeline.py  # Main ETL DAG
│
├── backend/                     # Flask REST API
│   ├── Dockerfile               # Backend Docker image
│   ├── requirements.txt         # Python dependencies
│   ├── app.py                   # Main Flask application
│   ├── models.py                # SQLAlchemy models
│   ├── schemas.py               # Pydantic schemas
│   └── api_documentation.md     # API endpoint documentation
│
├── dbt/                         # Data transformation
│   ├── dbt_project.yml          # dbt project configuration
│   ├── profiles.yml             # Database connection profiles
│   ├── models/
│   │   ├── staging/             # Staging models
│   │   │   ├── stg_facilities.sql
│   │   │   ├── stg_patients.sql
│   │   │   ├── stg_medical_records.sql
│   │   │   ├── stg_triage_visits.sql
│   │   │   └── schema.yml
│   │   └── marts/               # Analytics marts
│   │       ├── core/
│   │       │   ├── dim_facilities.sql
│   │       │   ├── dim_patients.sql
│   │       │   ├── fct_medical_records.sql
│   │       │   └── fct_triage_visits.sql
│   │       ├── clinical/
│   │       │   ├── patient_summary.sql
│   │       │   └── facility_performance.sql
│   │       └── analytics/
│   │           ├── triage_trends.sql
│   │           ├── condition_analysis.sql
│   │           └── schema.yml
│   └── macros/
│       ├── generate_schema_name.sql
│       └── test_positive_values.sql
│
├── elt/                         # ETL scripts
│   ├── requirements.txt         # Python dependencies for ETL
│   ├── init.sql                 # Database initialization script
│   ├── extract_from_s3.py       # S3 extraction logic
│   ├── load_to_postgres.py      # Data loading to staging
│   ├── generate_ids.py          # ID generation & transformation
│   ├── sample_data_generator.py # Generate test data
│   └── csv_templates/           # CSV file templates
│       ├── facilities_template.csv
│       ├── patients_template.csv
│       ├── medical_records_template.csv
│       └── triage_visits_template.csv
│
└── logs/                        # Application logs (gitignored)
```

---

## 📋 Prerequisites

### Local Development
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose 2.0+
- PostgreSQL Client (for database initialization)
- Git
- 4GB RAM minimum, 8GB recommended
- 20GB free disk space

### AWS Deployment
- AWS Account with appropriate permissions
- Terraform 1.0+
- AWS CLI configured
- SSH key pair for EC2 access

### Required AWS Permissions
- EC2 (create instances, security groups)
- RDS (create databases)
- S3 (create buckets, upload files)
- VPC (create networks, subnets)
- IAM (create roles, policies)

---

## 🚀 Installation & Setup

### Option 1: Local Development with External RDS

#### 1. Clone the Repository
```bash
git clone <repository-url>
cd medical-records-pipeline
```

#### 2. Configure Environment Variables
```bash
cp .env.example .env
nano .env  # Edit with your RDS credentials
```

**Important**: Remove `http://` from `POSTGRES_HOST` and ensure proper formatting:

```bash
POSTGRES_HOST=your-rds-endpoint.region.rds.amazonaws.com
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password
POSTGRES_DB=medical_records
```

#### 3. Initialize RDS Database
```bash
# Connect to your RDS instance
psql -h your-rds-endpoint.region.rds.amazonaws.com -U postgres -d postgres

# Create database
CREATE DATABASE medical_records;

# Connect to the database
\c medical_records

# Run initialization script
\i elt/init.sql

# Verify tables
\dt

# Exit
\q
```

#### 4. Start Services
```bash
chmod +x start.sh
./start.sh
```

#### 5. Verify Deployment
```bash
# Check services
docker-compose ps

# Check Airflow
curl http://localhost:8088/health

# Check API
curl http://localhost:5000/health
```

#### 6. Access Services
- **Airflow UI**: http://localhost:8088 (username: `airflow`, password: `password`)
- **Backend API**: http://localhost:5000
- **API Documentation**: http://localhost:5000/

---

### Option 2: Full AWS Deployment with Terraform

#### 1. Setup Terraform Configuration
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your values
```

**terraform.tfvars example**:
```hcl
aws_region         = "eu-west-1"
project_name       = "medical-records"
environment        = "production"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["eu-west-1a", "eu-west-1b"]

# EC2 Configuration
ec2_instance_type = "t3.medium"
ec2_key_name      = "your-key-pair-name"

# RDS Configuration
db_instance_class     = "db.t3.medium"
db_name               = "medical_records"
db_username           = "postgres"
db_password           = "your-secure-password"  # Change this!
db_allocated_storage  = 100

# S3 Configuration
s3_bucket_name = "medical-records-data-unique-name"

# Application Configuration
aws_access_key = "your-aws-access-key"
aws_secret_key = "your-aws-secret-key"

# Tags
tags = {
  Project     = "Medical Records Pipeline"
  Environment = "Production"
  ManagedBy   = "Terraform"
}
```

#### 2. Initialize Terraform
```bash
terraform init
```

#### 3. Review Infrastructure Plan
```bash
terraform plan
```

#### 4. Deploy Infrastructure
```bash
terraform apply
```
Type `yes` when prompted to confirm deployment.

#### 5. Retrieve Outputs
```bash
terraform output
```

You'll get outputs like:
```
ec2_public_ip  = "54.xxx.xxx.xxx"
rds_endpoint   = "medical-records-db.xxxxx.eu-west-1.rds.amazonaws.com"
s3_bucket_name = "medical-records-data-xxxxx"
airflow_url    = "http://54.xxx.xxx.xxx:8088"
api_url        = "http://54.xxx.xxx.xxx:5000"
```

#### 6. Access Your Deployment
- **Airflow**: http://<ec2_public_ip>:8088
  - Username: `airflow`
  - Password: `password`
- **API**: http://<ec2_public_ip>:5000

#### 7. Upload Sample Data to S3
```bash
# Generate sample data
cd elt
python sample_data_generator.py

# Upload to S3
aws s3 cp facilities.csv s3://your-bucket-name/medical_records/input/
aws s3 cp patients.csv s3://your-bucket-name/medical_records/input/
aws s3 cp medical_records.csv s3://your-bucket-name/medical_records/input/
aws s3 cp triage_visits.csv s3://your-bucket-name/medical_records/input/
```

---

## 🔧 Configuration

### Terraform Configuration Files

#### provider.tf
Configures Terraform version, AWS provider, and default tags for all resources.

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.tags
  }
}
```

#### variables.tf
Defines all input variables with validation rules and descriptions. Key variables:
- `aws_region`: AWS region for deployment
- `project_name`: Project identifier for resource naming
- `environment`: Environment (dev/staging/production)
- `vpc_cidr`: VPC CIDR block
- `ec2_instance_type`: EC2 instance size
- `db_instance_class`: RDS instance size
- `db_password`: PostgreSQL password (sensitive)

#### main.tf
Core infrastructure resources including:
- **VPC**: Virtual Private Cloud with public/private subnets
- **Security Groups**: EC2, RDS, and application security rules
- **EC2 Instance**: Application server with Docker
- **RDS**: PostgreSQL database
- **S3 Bucket**: Data storage with versioning
- **IAM Roles**: EC2 instance profile with S3 access

#### outputs.tf
Exports important values after deployment:
- EC2 public IP
- RDS endpoint
- S3 bucket name
- Application URLs

#### user_data.sh
Bootstrap script that runs when EC2 launches:
- Installs Docker and Docker Compose
- Installs PostgreSQL client
- Clones repository
- Sets up environment
- Initializes database schema
- Starts Docker containers

---

## 📖 Usage

### Running the ETL Pipeline

#### Manual Trigger (Airflow UI)
1. Navigate to http://localhost:8088 or http://<ec2-ip>:8088
2. Login with credentials (`airflow`/`password`)
3. Find DAG: `medical_records_etl_pipeline`
4. Click the "Play" button to trigger manually

#### Scheduled Run
The pipeline runs automatically **every day at 2 AM UTC**.

#### Pipeline Steps
1. **Extract from S3**: Downloads CSV files from S3 bucket
2. **Load Facilities**: Loads facility data to staging table
3. **Load Patients**: Loads patient data to staging table
4. **Load Medical Records**: Loads medical records to staging
5. **Load Triage Visits**: Loads triage visits to staging
6. **Generate IDs & Transform**: Transforms staging to production with auto-generated IDs
7. **dbt Run**: Executes dbt transformation models
8. **dbt Test**: Runs data quality tests
9. **Archive Files**: Moves processed files to S3 archive folder

---

### Using the API

#### Get All Facilities
```bash
curl http://localhost:5000/api/facilities
```

With filters:
```bash
curl "http://localhost:5000/api/facilities?state=LAGOS&page=1&per_page=10"
```

#### Get All Patients
```bash
curl http://localhost:5000/api/patients
```

With filters:
```bash
curl "http://localhost:5000/api/patients?facility_id=1&sex=F"
```

#### Create a New Facility
```bash
curl -X POST http://localhost:5000/api/facilities \
  -H "Content-Type: application/json" \
  -d '{
    "name": "General Hospital",
    "state": "LAGOS",
    "lga": "Ikeja",
    "lat": 6.6018,
    "lon": 3.3515,
    "type": "Hospital"
  }'
```

#### Create a New Patient
```bash
curl -X POST http://localhost:5000/api/patients \
  -H "Content-Type: application/json" \
  -d '{
    "facility_id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "sex": "M",
    "dob": "1990-01-01",
    "phone": "+2348012345678"
  }'
```

#### Get Analytics
```bash
curl http://localhost:5000/api/analytics/facility-stats
```

For specific facility:
```bash
curl "http://localhost:5000/api/analytics/facility-stats?facility_id=1"
```

---

### Running dbt Models

#### From Airflow
dbt models run automatically as part of the ETL pipeline.

#### Manually
```bash
# Enter the webserver container
docker-compose exec webserver bash

# Navigate to dbt directory
cd /opt/airflow/dbt

# Run all models
dbt run --profiles-dir /root/.dbt

# Run specific model
dbt run --models stg_patients --profiles-dir /root/.dbt

# Run tests
dbt test --profiles-dir /root/.dbt

# Generate documentation
dbt docs generate --profiles-dir /root/.dbt
```

---

## 📚 API Documentation

### Base URL
- `http://localhost:5000/api` or
- `http://<ec2-public-ip>:5000/api`

### Authentication
Currently, no authentication is required. Implement JWT or OAuth2 for production use.

### Endpoints

#### Health Check
```http
GET /health
```

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00",
  "database": "connected",
  "host": "your-rds-endpoint.rds.amazonaws.com"
}
```

#### Facilities

**List Facilities**
```http
GET /api/facilities?state=LAGOS&lga=Ikeja&type=Hospital&page=1&per_page=50
```

**Get Facility**
```http
GET /api/facilities/{id}
```

**Create Facility**
```http
POST /api/facilities
Content-Type: application/json

{
  "name": "General Hospital",
  "state": "LAGOS",
  "lga": "Ikeja",
  "lat": 6.6018,
  "lon": 3.3515,
  "type": "Hospital"
}
```

#### Patients

**List Patients**
```http
GET /api/patients?facility_id=1&sex=M&page=1&per_page=50
```

**Get Patient**
```http
GET /api/patients/{id}
```

**Create Patient**
```http
POST /api/patients
Content-Type: application/json

{
  "facility_id": 1,
  "first_name": "John",
  "last_name": "Doe",
  "sex": "M",
  "dob": "1990-01-01",
  "phone": "+2348012345678"
}
```

#### Medical Records

**List Medical Records**
```http
GET /api/medical-records?patient_id=1&facility_id=1&record_type=Consultation
```

**Get Medical Record**
```http
GET /api/medical-records/{id}
```

**Create Medical Record**
```http
POST /api/medical-records
Content-Type: application/json

{
  "patient_id": 1,
  "facility_id": 1,
  "record_type": "Consultation",
  "data": {
    "diagnosis": "Hypertension",
    "treatment": "Medication",
    "medications": "Amlodipine 5mg daily",
    "notes": "Patient advised to reduce salt intake"
  }
}
```

#### Triage Visits

**List Triage Visits**
```http
GET /api/triage-visits?patient_id=1&facility_id=1&triage_level=3
```

**Get Triage Visit**
```http
GET /api/triage-visits/{id}
```

#### Analytics

**Facility Statistics**
```http
GET /api/analytics/facility-stats
GET /api/analytics/facility-stats?facility_id=1
```

See `backend/api_documentation.md` for complete API documentation.

---

## 📊 dbt Models

### Staging Models (`models/staging/`)

#### stg_facilities
Cleans and standardizes facility data:
- Trims whitespace
- Standardizes state names
- Categorizes facilities
- Validates coordinates

#### stg_patients
Processes patient data:
- Calculates age from date of birth
- Creates age groups (Infant, Child, Adolescent, Adult, Senior)
- Validates phone numbers
- Concatenates full names

#### stg_medical_records
Standardizes medical records:
- Extracts common fields from JSONB
- Tracks record updates
- Calculates days since creation

#### stg_triage_visits
Processes triage visits:
- Maps triage levels to descriptions
- Categorizes priority (Critical, High, Medium, Low)
- Counts conditions and recommendations
- Validates triage levels (1-5)

---

### Mart Models (`models/marts/`)

#### Core Marts

**dim_facilities** - Facility dimension:
- Complete facility information
- Patient counts and metrics
- Activity indicators
- Triage statistics

**dim_patients** - Patient dimension:
- Demographics and contact info
- Medical record counts
- Triage history
- Health risk indicators
- Engagement scores

**fct_medical_records** - Medical records fact:
- All medical record transactions
- Patient demographics
- Facility information
- Date dimensions

**fct_triage_visits** - Triage visits fact:
- All triage transactions
- Patient demographics
- Time-of-day analysis
- Priority categorization

#### Clinical Marts

**patient_summary** - Clinical patient summary:
- Comprehensive medical history (12 months)
- Recent diagnoses and conditions
- Risk assessment
- Engagement metrics

**facility_performance** - Operational metrics:
- Volume categories
- Acuity levels
- Monthly averages
- Performance indicators

#### Analytics Marts

**triage_trends** - Time-series analysis:
- Daily triage patterns
- 7-day moving averages
- Week-over-week growth
- Priority distribution

**condition_analysis** - Medical condition insights:
- Common conditions by frequency
- Severity rankings
- Geographic distribution
- Demographic patterns

---

## 🔄 ETL Pipeline

### Data Flow

1. **S3 Input** → CSV files uploaded to `s3://bucket/medical_records/input/`
2. **Extract** → Files downloaded to `/tmp/medical_records/`
3. **Stage Load** → Raw data loaded to staging tables
4. **Transform** → Staging data transformed with ID generation
5. **dbt Run** → Analytics models materialized
6. **Archive** → Processed files moved to `s3://bucket/medical_records/archive/`

### ID Generation Strategy

IDs are auto-generated using PostgreSQL SERIAL type during transformation:

```sql
INSERT INTO facilities (name, state, lga, ...)
SELECT DISTINCT name, state, lga, ...
FROM staging_facilities
ON CONFLICT (name, state, lga) DO UPDATE ...
RETURNING id;
```

### Audit Logging

Every ETL run is logged in `etl_audit_log` table:
- Batch ID
- Table name
- Records processed/inserted/failed
- Timestamps
- Error messages

### Error Handling

- Failed records are logged but don't stop the pipeline
- Duplicate records are handled with upsert logic
- Missing foreign keys are filtered out
- Invalid data types are caught and logged

---

## 📈 Monitoring & Logging

### Airflow Monitoring

**Access Logs**:
```bash
docker-compose logs -f webserver
docker-compose logs -f scheduler
```

**View in UI**:
- Navigate to Airflow UI
- Click on DAG → Graph View
- Check task logs and status

### API Monitoring

**Health Check**:
```bash
curl http://localhost:5000/health
```

**Access Logs**:
```bash
docker-compose logs -f backend
```

### Database Monitoring

**Check Audit Logs**:
```sql
SELECT * FROM etl_audit_log 
ORDER BY started_at DESC 
LIMIT 10;
```

**Check Record Counts**:
```sql
SELECT 'facilities' as table_name, COUNT(*) as count FROM facilities
UNION ALL
SELECT 'patients', COUNT(*) FROM patients
UNION ALL
SELECT 'medical_records', COUNT(*) FROM medical_records
UNION ALL
SELECT 'triage_visits', COUNT(*) FROM triage_visits;
```

### Application Logs

All logs are stored in the `logs/` directory:
```bash
ls -lh logs/
tail -f logs/scheduler/*.log
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Cannot Connect to RDS

**Symptoms**:
- `ValueError: invalid literal for int() with base 10: ''`
- `psycopg2.OperationalError: could not connect to server`

**Solutions**:
- Remove `http://` from `POSTGRES_HOST` in `.env`
- Check RDS security group allows EC2 IP
- Verify RDS is in "Available" state
- Test connection: `psql -h <rds-endpoint> -U postgres`

#### 2. Docker Build Failures

**Symptoms**:
- `failed to solve: process did not complete successfully`

**Solutions**:
```bash
# Clean Docker cache
docker system prune -a --volumes -f

# Rebuild without cache
docker-compose build --no-cache

# Check disk space
df -h
```

#### 3. Permission Denied Errors

**Symptoms**:
- `mkdir: cannot create directory '/root': Permission denied`

**Solutions**:
- Ensure Dockerfile creates directories as root user before switching to airflow user
- Check volume mount permissions
- Use named volumes instead of host mounts

#### 4. dbt Connection Failures

**Symptoms**:
- `Runtime Error: Database Error`

**Solutions**:
```bash
# Verify environment variables
docker-compose exec webserver env | grep POSTGRES

# Test dbt connection
docker-compose exec webserver dbt debug --profiles-dir /root/.dbt

# Check profiles.yml
docker-compose exec webserver cat /root/.dbt/profiles.yml
```

#### 5. Airflow DAG Not Appearing

**Symptoms**:
- DAG doesn't show in UI

**Solutions**:
```bash
# Check for Python errors
docker-compose exec webserver airflow dags list

# View DAG parsing errors
docker-compose logs webserver | grep ERROR

# Restart scheduler
docker-compose restart scheduler
```

### Getting Help

**Check Logs**:
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs backend
docker-compose logs webserver
docker-compose logs scheduler
```

**Restart Services**:
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart backend
```

**Complete Reset**:
```bash
# Stop and remove everything
docker-compose down -v

# Clean Docker
docker system prune -a --volumes -f

# Start fresh
docker-compose up -d
```

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `pytest` (if applicable)
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Style

- **Python**: Follow PEP 8
- **SQL**: Use lowercase keywords, 2-space indentation
- **Documentation**: Update README.md for significant changes

### Testing

- Test locally before pushing
- Ensure Docker containers build successfully
- Verify API endpoints work as expected
- Run dbt tests: `dbt test`

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

```
MIT License

Copyright (c) 2025 Medical Records Data Pipeline

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Support

For questions, issues, or suggestions:

- **Issues**: Open an issue on GitHub
- **Documentation**: Check `backend/api_documentation.md`
- **Email**: [Your contact email]

---

## 🎉 Acknowledgments

- Apache Airflow community
- dbt Labs
- Flask framework
- PostgreSQL team
- AWS documentation

---

**Built with ❤️ for healthcare data management**

---

## 📝 Quick Start Guide

### For First-Time Users

**Step 1**: Clone and setup environment
```bash
git clone <repository-url>
cd medical-records-pipeline
cp .env.example .env
# Edit .env with your credentials
```

**Step 2**: Initialize database
```bash
psql -h your-rds-endpoint -U postgres -d postgres
CREATE DATABASE medical_records;
\c medical_records
\i elt/init.sql
```

**Step 3**: Start services
```bash
./start.sh
```

**Step 4**: Upload sample data
```bash
cd elt
python sample_data_generator.py
aws s3 cp *.csv s3://your-bucket/medical_records/input/
```

**Step 5**: Trigger pipeline
- Go to http://localhost:8088
- Login (airflow/password)
- Enable and trigger `medical_records_etl_pipeline`

**Step 6**: Access API
```bash
curl http://localhost:5000/api/facilities
```

---

## 🔐 Security Best Practices

### Production Deployment Checklist

- [ ] Change default Airflow credentials
- [ ] Enable API authentication (JWT/OAuth2)
- [ ] Use AWS Secrets Manager for credentials
- [ ] Configure SSL/TLS certificates
- [ ] Enable VPC security groups
- [ ] Implement database encryption at rest
- [ ] Set up CloudWatch monitoring
- [ ] Enable S3 bucket encryption
- [ ] Configure IAM roles with least privilege
- [ ] Implement rate limiting on API
- [ ] Enable audit logging
- [ ] Set up automated backups

### Environment Variables

Never commit sensitive data. Use `.env` file:

```bash
# Database
POSTGRES_HOST=your-rds-endpoint.amazonaws.com
POSTGRES_PASSWORD=strong-password-here

# AWS
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Airflow
AIRFLOW_ADMIN_PASSWORD=change-this-password
```

---

## 📊 Performance Optimization

### Database Optimization

**Indexes**:
```sql
CREATE INDEX idx_patients_facility ON patients(facility_id);
CREATE INDEX idx_medical_records_patient ON medical_records(patient_id);
CREATE INDEX idx_triage_visits_patient ON triage_visits(patient_id);
CREATE INDEX idx_medical_records_created ON medical_records(created_at);
```

**Partitioning** (for large datasets):
```sql
-- Partition medical_records by date
CREATE TABLE medical_records_2025_01 PARTITION OF medical_records
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

### API Optimization

- Enable response caching
- Implement pagination (default: 50 records)
- Use database connection pooling
- Add query result caching for analytics

### ETL Optimization

- Process files in parallel
- Use bulk insert operations
- Implement incremental loads
- Archive old data to S3 Glacier

---

## 🧪 Testing

### Unit Tests

```bash
# Run Python tests
pytest tests/

# Run specific test file
pytest tests/test_etl.py

# Run with coverage
pytest --cov=elt tests/
```

### Integration Tests

```bash
# Test API endpoints
pytest tests/test_api.py

# Test dbt models
cd dbt
dbt test --profiles-dir /root/.dbt
```

### Load Testing

```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost:5000/api/facilities

# Using Locust
locust -f tests/load_test.py --host http://localhost:5000
```

---

## 🔄 Backup & Recovery

### Database Backup

**Automated RDS Snapshots**:
```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier medical-records-db \
  --db-snapshot-identifier manual-backup-$(date +%Y%m%d)
```

**Export to S3**:
```bash
# Using pg_dump
pg_dump -h $POSTGRES_HOST -U $POSTGRES_USER $POSTGRES_DB | \
  gzip | aws s3 cp - s3://backup-bucket/db-backup-$(date +%Y%m%d).sql.gz
```

### Restore Procedure

```bash
# From RDS snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier medical-records-db-restored \
  --db-snapshot-identifier backup-snapshot-id

# From S3 backup
aws s3 cp s3://backup-bucket/db-backup.sql.gz - | \
  gunzip | psql -h $POSTGRES_HOST -U $POSTGRES_USER $POSTGRES_DB
```

---

## 📈 Scaling Considerations

### Horizontal Scaling

**Airflow Workers**:
```yaml
# docker-compose.yaml
worker:
  image: medical-records-airflow
  replicas: 3
  depends_on:
    - postgres
    - redis
```

**API Servers**:
```bash
# Behind load balancer
docker-compose up --scale backend=3
```

### Vertical Scaling

**RDS Instance**:
```hcl
# terraform/main.tf
db_instance_class = "db.r6g.2xlarge"  # Upgrade for more memory
```

**EC2 Instance**:
```hcl
ec2_instance_type = "t3.2xlarge"  # Upgrade for more CPU
```

### Data Partitioning

```sql
-- Partition by year and month
CREATE TABLE medical_records (
  id SERIAL,
  created_at TIMESTAMP NOT NULL,
  ...
) PARTITION BY RANGE (created_at);
```

---

## 🎓 Learning Resources

### Documentation
- [Apache Airflow Docs](https://airflow.apache.org/docs/)
- [dbt Documentation](https://docs.getdbt.com/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [PostgreSQL Manual](https://www.postgresql.org/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Tutorials
- ETL Best Practices
- Data Modeling for Analytics
- RESTful API Design
- Docker Container Orchestration
- AWS Infrastructure as Code

---

## 🗺️ Roadmap

### Planned Features

- [ ] Real-time data streaming with Apache Kafka
- [ ] Machine learning predictions for patient risk
- [ ] Advanced analytics dashboard (Superset/Metabase)
- [ ] Multi-tenancy support
- [ ] GraphQL API endpoint
- [ ] Automated data quality monitoring
- [ ] FHIR standard compliance
- [ ] Mobile app integration
- [ ] Enhanced security (RBAC, audit trails)
- [ ] Data anonymization for research

### Version History

**v1.0.0** (Current)
- Initial release
- Core ETL pipeline
- RESTful API
- dbt transformations
- Terraform deployment

---

## 💡 Best Practices

### Data Pipeline
1. Always validate input data before processing
2. Implement idempotent operations
3. Use batch processing for large datasets
4. Monitor pipeline performance metrics
5. Set up alerts for failures

### API Development
1. Version your APIs (e.g., `/api/v1/`)
2. Implement proper error handling
3. Use pagination for large result sets
4. Add request rate limiting
5. Document all endpoints

### Database Management
1. Regular vacuum and analyze operations
2. Monitor query performance
3. Implement proper indexing strategy
4. Use connection pooling
5. Regular backups and testing restores

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**Maintainer**: Medilink