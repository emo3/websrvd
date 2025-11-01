#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Shutting down services${NC}"
echo "======================="

# Step 1: Stop Docker container
echo -e "\n1. Stopping Docker container"
echo "------------------------"
docker compose down
sleep 2

# Step 2: Remove Docker network
echo -e "\n2. Removing Docker network"
echo "--------------------------"
if docker network ls | grep -q "my_network"; then
    docker network rm my_network
    echo -e "${GREEN}✓ Removed 'my_network' Docker network${NC}"
else
    echo -e "${GREEN}✓ 'my_network' Docker network not found${NC}"
fi

# Step 3: Remove hostname from /etc/hosts
echo -e "\n3. Removing hostname from /etc/hosts"
echo "-----------------------------------"
if grep -q "10.1.1.30 websrv" /etc/hosts; then
    sudo sed -i '/10.1.1.30 websrv/d' /etc/hosts
    echo -e "${GREEN}✓ Removed websrv from /etc/hosts${NC}"
else
    echo -e "${GREEN}✓ websrv not in /etc/hosts${NC}"
fi

# Step 4: Remove IP alias
echo -e "\n4. Removing IP alias"
echo "------------------"
sudo ip addr del 10.1.1.30/32 dev lo
sleep 1

# Verify shutdown was successful
echo -e "\n${YELLOW}Verifying shutdown${NC}"
echo "==================="

./test-shutdown.sh

# Use the exit code from test-shutdown.sh
exit $?