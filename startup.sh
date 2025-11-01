#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting up services${NC}"
echo "===================="

# Step 1: Configure IP alias
echo -e "\n1. Configuring IP alias"
echo "--------------------"
sudo ip addr add 10.1.1.30/32 dev lo
sleep 1

# Step 2: Add hostname to /etc/hosts
echo -e "\n2. Adding hostname to /etc/hosts"
echo "-------------------------------"
if ! grep -q "10.1.1.30 websrv" /etc/hosts; then
    echo "10.1.1.30 websrv" | sudo tee -a /etc/hosts > /dev/null
    echo -e "${GREEN}✓ Added websrv to /etc/hosts${NC}"
else
    echo -e "${GREEN}✓ websrv already in /etc/hosts${NC}"
fi

# Step 2: Start Docker container
echo -e "\n2. Starting Docker container"
echo "-------------------------"
docker compose up -d
sleep 2

# Verify startup was successful
echo -e "\n${YELLOW}Verifying startup${NC}"
echo "=================="

./test-setup.sh

# Use the exit code from test-setup.sh
exit $?