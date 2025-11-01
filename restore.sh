#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BACKUP_DIR="./backups"

if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Available backups:${NC}"
    ls -la "${BACKUP_DIR}"/*.tar.gz 2>/dev/null || echo "No backups found"
    echo -e "${YELLOW}Usage: $0 <backup_name.tar.gz>${NC}"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    echo -e "${RED}✗ Backup file not found: ${BACKUP_DIR}/${BACKUP_FILE}${NC}"
    exit 1
fi

echo -e "${YELLOW}Restoring from backup: ${BACKUP_FILE}${NC}"

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

# Extract backup
echo "Extracting backup..."
tar -xzf "../${BACKUP_DIR}/${BACKUP_FILE}"

# Stop services before restore
echo "Stopping services..."
cd ..
./shutdown.sh > /dev/null 2>&1

# Restore files
echo "Restoring configuration files..."
cp -r "${TEMP_DIR}"/*/* . 2>/dev/null || true

# Cleanup
rm -rf "${TEMP_DIR}"

echo -e "${GREEN}✓ Restore completed${NC}"
echo -e "${YELLOW}Note: You may need to restart services with ./startup.sh${NC}"
