#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting complete Docker system prune...${NC}"
echo "This will remove:"
echo "  - all stopped containers"
echo "  - all unused networks"
echo "  - all unused images (not just dangling ones)"
echo "  - all build cache"
echo "  - all unused volumes"
echo "=============================================="

echo -e "\n${YELLOW}Current Docker disk usage:${NC}"
docker system df

echo -e "\n${YELLOW}Running 'docker system prune -a --volumes -f'${NC}"
docker system prune -a --volumes -f

echo -e "\n${GREEN}✓ Docker system prune complete.${NC}"

echo -e "\n${YELLOW}Docker disk usage after pruning:${NC}"
docker system df