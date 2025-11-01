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

# Step 2: Remove IP alias
echo -e "\n2. Removing IP alias"
echo "------------------"
sudo ip addr del 10.1.1.30/24 dev lo
sleep 1

# Verify shutdown was successful
echo -e "\n${YELLOW}Verifying shutdown${NC}"
echo "==================="

./test-shutdown.sh

# Use the exit code from test-shutdown.sh
exit $?