#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing Service Shutdown${NC}"
echo "========================"

# Track overall status
ISSUES=0

# Step 1: Check if container is already down
echo -e "\n1. Docker Container"
echo "-----------------"
if docker ps | grep -q websrv; then
    echo -e "${RED}✗ Container is still running${NC}"
    echo "Fix: Run 'docker compose down'"
    ((ISSUES++))
else
    echo -e "${GREEN}✓ Container is stopped${NC}"
fi

# Step 2: Check Docker network
echo -e "\n2. Docker Network"
echo "---------------"
if docker network ls | grep -q my_network; then
    echo -e "${YELLOW}! Docker network 'my_network' still exists${NC}"
    echo "Optional: Remove with 'docker network rm my_network'"
else
    echo -e "${GREEN}✓ Docker network is removed${NC}"
fi

# Step 3: Check IP alias
echo -e "\n3. IP Configuration"
echo "------------------"
if ip addr show | grep -q "10.1.1.30"; then
    echo -e "${RED}✗ IP alias 10.1.1.30 is still configured${NC}"
    echo "Fix: Run 'sudo ip addr del 10.1.1.30/32 dev lo'"
    ((ISSUES++))
else
    echo -e "${GREEN}✓ IP alias is removed${NC}"
fi

# Step 4: Check HTTPS accessibility
echo -e "\n4. HTTPS Server"
echo "--------------"
if curl -k --connect-timeout 2 -s https://10.1.1.30/ > /dev/null 2>&1; then
    echo -e "${RED}✗ HTTPS server is still responding${NC}"
    echo "Check for other services using port 443"
    ((ISSUES++))
else
    echo -e "${GREEN}✓ HTTPS server is not responding (expected)${NC}"
fi

# Final Status
echo -e "\nFinal Status"
echo "------------"
if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All services properly shut down${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $ISSUES issue(s) - review messages above${NC}"
    exit 1
fi