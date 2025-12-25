#!/bin/bash

# Determine the server IP address automatically
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    # Fallback to another method if hostname -I doesn't work
    SERVER_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
fi

# If we still don't have an IP, use a default one
if [ -z "$SERVER_IP" ] || [ "$SERVER_IP" = "127.0.0.1" ]; then
    SERVER_IP="10.1.9.60"
fi

echo "Detected server IP: $SERVER_IP"

# Update the .env file with the detected IP
sed -i "s/SERVER_IP=.*/SERVER_IP=$SERVER_IP/" ../.env

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
mkdir -p /srv/mergerfs/pool1/nextcloud

# Create the required .ocdata file
if [ ! -f "/srv/mergerfs/pool1/nextcloud/.ocdata" ]; then
    echo "# Nextcloud data directory" > /srv/mergerfs/pool1/nextcloud/.ocdata
fi

# Set proper permissions for the data directory
# Nextcloud in Docker runs as www-data user (UID 33 in Alpine)
chown -R 33:33 /srv/mergerfs/pool1/nextcloud 2>/dev/null || true
chmod -R 755 /srv/mergerfs/pool1/nextcloud 2>/dev/null || true

# Check if there's existing data in the old location and migrate if needed
# First, stop any running containers to ensure data consistency
echo "Checking for existing data to migrate..."

# Check if there's existing data in the old volume and migrate if needed
echo "Checking for existing data to migrate..."

# First, check if the named volume has data
if [ "$(docker volume ls -q | grep nextcloud_data)" ]; then
    # Create a temporary container to check old data location
    docker run --rm -v nextcloud_data:/data alpine sh -c "ls -la /data" > /tmp/old_volume_contents 2>/dev/null || true

    if [ -s /tmp/old_volume_contents ] && ! grep -q "No such file or directory" /tmp/old_volume_contents; then
        echo "Existing data found in old volume. Migrating to new location..."
        
        # Create a temporary container to copy data
        docker run --rm -v nextcloud_data:/source -v /srv/mergerfs/pool1/nextcloud:/destination alpine sh -c "cp -r /source/data/* /destination/ 2>/dev/null || true"
        
        echo "Data migration completed."
    else
        echo "No existing data found in old volume."
    fi

    # Clean up
    rm -f /tmp/old_volume_contents
else
    echo "No existing named volume found."
fi

# Clean up
rm -f /tmp/old_volume_contents

# Generate self-signed SSL certificate if it doesn't exist
SSL_CERT="nextcloud-docker/nginx/ssl/nextcloud.crt"
SSL_KEY="nextcloud-docker/nginx/ssl/nextcloud.key"

if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_KEY" \
        -out "$SSL_CERT" \
        -subj "/C=RU/ST=Asia/L=Yekaterinburg/O=Nextcloud/OU=IT/CN=$SERVER_IP"
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

# Create or update the overwrite.config.php with the correct server IP
mkdir -p nextcloud-docker/nextcloud/config
cat > nextcloud-docker/nextcloud/config/overwrite.config.php << EOF
<?php
\$CONFIG = array(
 'trusted_proxies' => array('nginx', '172.16.0.0/12'),
  'overwriteprotocol' => 'https',
  'overwritehost' => '$SERVER_IP:8443',
  'overwritewebroot' => '/',
  'overwritecondaddr' => '^.*$',
);
EOF

echo "Configuration files created successfully."

echo "Configuration files created successfully."

echo "Stopping any existing Nextcloud services..."
cd nextcloud-docker
docker compose down

echo "Starting Nextcloud services..."
docker compose up -d

echo "Nextcloud setup in progress..."
echo "Access Nextcloud at: https://$SERVER_IP:8443/"
echo "Note: You may see a security warning due to self-signed SSL certificate."
echo "After accessing the site, you can proceed with the initial configuration."

# Wait a bit and show status
sleep 30
echo "Service status:"
docker compose ps

echo ""
echo "Setup complete! Nextcloud should be accessible at https://$SERVER_IP:8443/"