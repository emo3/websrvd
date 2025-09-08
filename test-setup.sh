#!/bin/bash
echo "Testing IP aliases..."
for ip in 10.1.1.{30,50}; do
    if ping -c 1 -W 1000 $ip > /dev/null 2>&1; then
        echo "✓ $ip is reachable"
    else
        echo "✗ $ip is not reachable"
    fi
done

echo "Testing Docker network..."
if docker network inspect local_network > /dev/null 2>&1; then
    echo "✓ Docker network exists"
else
    echo "✗ Docker network missing"
fi
