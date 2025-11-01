#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running HTTPS Server Tests${NC}"
echo "================================="

# Step 1: Check SELinux status
echo -e "\n1. SELinux Status"
echo "----------------"
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce)
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        echo -e "${GREEN}✓ SELinux is Enforcing${NC}"
        # Test if we can still access the web server
        if curl -k --connect-timeout 5 -s https://10.1.1.30/ > /dev/null; then
            echo -e "${GREEN}✓ Web server works with SELinux enforcing${NC}"
        else
            echo -e "${YELLOW}! SELinux might be blocking web access${NC}"
            echo "Options:"
            echo "1. Set to permissive mode: sudo setenforce 0"
            echo "2. Configure proper SELinux context for web content"
        fi
    else
        echo -e "${GREEN}✓ SELinux is not enforcing${NC}"
    fi
else
    echo -e "${GREEN}✓ SELinux not found (not an issue)${NC}"
fi

# Step 2: Check IP configuration
echo -e "\n2. IP Configuration"
echo "------------------"
if ip addr show | grep -q "10.1.1.30"; then
    echo -e "${GREEN}✓ IP 10.1.1.30 is configured${NC}"
    # Test IP reachability
    if ping -c 1 -W 2 10.1.1.30 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ IP 10.1.1.30 is reachable${NC}"
    else
        echo -e "${YELLOW}! IP 10.1.1.30 is not reachable (expected with host networking)${NC}"
    fi
else
    echo -e "${RED}✗ IP 10.1.1.30 is not configured${NC}"
    echo "Fix: Run 'sudo ip addr add 10.1.1.30/24 dev lo'"
fi

# Step 3: Check Docker container
echo -e "\n3. Docker Container"
echo "-----------------"
if docker ps | grep -q websrv; then
    echo -e "${GREEN}✓ Container is running${NC}"
    
    # Check container networking mode
    if docker inspect websrv | grep -q '"NetworkMode": "host"'; then
        echo -e "${GREEN}✓ Container is using host networking${NC}"
    else
        echo -e "${RED}✗ Container is not using host networking${NC}"
        echo "Fix: Update docker-compose.yml to use network_mode: 'host'"
    fi
else
    echo -e "${RED}✗ Container is not running${NC}"
    echo "Fix: Run 'docker compose up -d'"
fi

# Step 4: Test HTTPS server
echo -e "\n4. HTTPS Server"
echo "--------------"
if curl -k --connect-timeout 5 -s https://10.1.1.30/ > /dev/null; then
    echo -e "${GREEN}✓ HTTPS server is responding${NC}"
    
    # Test directory listing
    if curl -k --connect-timeout 5 -s https://10.1.1.30/ | grep -q "Index of"; then
        echo -e "${GREEN}✓ Directory listing is working${NC}"
    else
        echo -e "${RED}✗ Directory listing is not working${NC}"
        echo "Check nginx.conf configuration"
    fi
else
    echo -e "${RED}✗ HTTPS server is not responding${NC}"
    echo "Troubleshooting steps:"
    echo "1. Check container logs: docker logs websrv"
    echo "2. Verify nginx configuration"
    echo "3. Check SSL certificate paths"
fi

# Final Status
echo -e "\nFinal Status"
echo "------------"
if docker ps | grep -q websrv && \
   curl -k --connect-timeout 5 -s https://10.1.1.30/ > /dev/null; then
    echo -e "${GREEN}✓ All critical checks passed${NC}"
else
    echo -e "${RED}✗ Some checks failed - review above messages${NC}"
    exit 1
fi
