FROM apache/airflow:2.7.1-python3.10

USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    postgresql-client \
    libpq-dev \
    python3-dev \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create dbt directory for root user (used by docker-compose volumes)
RUN mkdir -p /root/.dbt && chmod -R 755 /root/.dbt

USER airflow

# Upgrade pip, setuptools, and wheel
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy requirements file
COPY requirements.txt /requirements.txt

# Install Python packages
RUN pip install --no-cache-dir \
    apache-airflow \
    apache-airflow-providers-postgres \
    apache-airflow-providers-amazon \
    boto3==1.28.85 \
    botocore==1.31.85 \
    pandas==2.1.1 \
    psycopg2-binary \
    sqlalchemy \
    python-dotenv \
    pydantic \
    dbt-core \
    dbt-postgres

# Create dbt directory for airflow user as well
RUN mkdir -p /home/airflow/.dbt && chmod -R 755 /home/airflow/.dbt

WORKDIR /opt/airflow