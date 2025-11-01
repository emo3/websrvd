#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="websrvd_backup_${TIMESTAMP}"

echo -e "${YELLOW}Creating backup: ${BACKUP_NAME}${NC}"

# Create backup directory
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

# Backup configuration files
echo "Backing up configuration files..."
cp -r Dockerfile docker-compose.yml nginx.conf startup.sh shutdown.sh test-setup.sh test-shutdown.sh "${BACKUP_DIR}/${BACKUP_NAME}/"

# Backup certificates (if they exist)
if [ -f "websrv.pem" ] && [ -f "websrv-key.pem" ]; then
    echo "Backing up SSL certificates..."
    cp websrv.pem websrv-key.pem "${BACKUP_DIR}/${BACKUP_NAME}/"
else
    echo -e "${YELLOW}Warning: SSL certificates not found, skipping certificate backup${NC}"
fi

# Backup environment file (if exists)
if [ -f ".env" ]; then
    echo "Backing up environment configuration..."
    cp .env "${BACKUP_DIR}/${BACKUP_NAME}/"
fi

# Create archive
echo "Creating compressed archive..."
cd "${BACKUP_DIR}" && tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"

# Cleanup uncompressed backup
rm -rf "${BACKUP_NAME}"

echo -e "${GREEN}✓ Backup completed: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz${NC}"
echo -e "${YELLOW}Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)${NC}"

# Keep only last 5 backups
echo "Cleaning up old backups..."
cd "${BACKUP_DIR}" && ls -t *.tar.gz | tail -n +6 | xargs -r rm -f

echo -e "${GREEN}✓ Backup process completed${NC}"
