#!/bin/bash

echo "🚀 Starting Medical Records Data Pipeline..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs
mkdir -p airflow/dags
mkdir -p elt
mkdir -p dbt
mkdir -p backend

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

echo "🐳 Starting Docker containers..."
docker-compose down -v
docker-compose up -d --build

echo "⏳ Waiting for services to be healthy..."
sleep 30

echo "✅ Services started successfully!"
echo ""
echo "🌐 Access the services at:"
echo "   - Airflow UI: http://localhost:8088 (airflow/password)"
echo "   - Backend API: http://localhost:5000"
echo "   - PostgreSQL: localhost:5432"
echo ""
echo "📊 To view logs: docker-compose logs -f"
echo "🛑 To stop: docker-compose down"