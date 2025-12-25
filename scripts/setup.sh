#!/bin/bash

# Nextcloud Docker Setup Script

set -e

echo "=== Nextcloud Docker Setup ==="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose plugin is available
if ! docker compose version &> /dev/null; then
    echo "Docker Compose plugin is not available. Please install Docker Compose plugin first."
    exit 1
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p nextcloud-docker/nginx/ssl
mkdir -p nextcloud-docker/nextcloud/config
mkdir -p nextcloud-docker/postgres

# Generate self-signed SSL certificate if it doesn't exist
SSL_CERT="nextcloud-docker/nginx/ssl/nextcloud.crt"
SSL_KEY="nextcloud-docker/nginx/ssl/nextcloud.key"

if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_KEY" \
        -out "$SSL_CERT" \
        -subj "/C=RU/ST=Asia/L=Yekaterinburg/O=Nextcloud/OU=IT/CN=10.1.9.60"
else
    echo "SSL certificate already exists, skipping generation."
fi

# Set proper permissions for SSL files
chmod 600 "$SSL_KEY"
chmod 644 "$SSL_CERT"

# Create PostgreSQL init script
cat > nextcloud-docker/postgres/init.sql << 'EOF'
-- PostgreSQL init script for Nextcloud
-- This script will be executed on the first run

-- Create database and user (if not exists)
-- The database and user are already handled by environment variables in docker-compose.yml
-- This is just for reference and additional setup if needed
EOF

echo "Configuration files created successfully."

echo "Configuration files created successfully."

echo "Stopping any existing Nextcloud services..."
cd nextcloud-docker
docker compose down

echo "Starting Nextcloud services..."
docker compose up -d

echo "Nextcloud setup in progress..."
echo "Access Nextcloud at: https://10.1.9.60:8443/"
echo "Note: You may see a security warning due to self-signed SSL certificate."
echo "After accessing the site, you can proceed with the initial configuration."

# Wait a bit and show status
sleep 30
echo "Service status:"
docker compose ps

echo ""
echo "Setup complete! Nextcloud should be accessible at https://10.1.9.60:8443/"