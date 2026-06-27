#!/bin/bash
set -euo pipefail

HOST_IPS=(10.1.1.30 10.1.1.50)
PORT="443"

# Prevent long hangs during network/TLS checks
PING_TIMEOUT_SECS=1
TLS_TIMEOUT_SECS=3

echo "Testing IP reachability / local bind prerequisites..."

# If host doesn't have the published IP, Docker will fail with:
# failed to bind host port <ip>:<port>: cannot assign requested address
# We only *report* here; actual fix is to add the IP alias or bind to 0.0.0.0 / your real IP.


# Verify whether the host actually has the IP configured. If not, Docker will fail with:
# failed to bind host port <ip>:<port>: cannot assign requested address
for ip in "${HOST_IPS[@]}"; do
    if ip addr show dev lo | grep -q "\b${ip}\b" 2>/dev/null; then
        echo "✓ Host has ${ip} configured on loopback (lo)"
    elif ip addr show | grep -q "\b${ip}\b" 2>/dev/null; then
        echo "✓ Host has ${ip} configured on a local interface"
    else
        echo "✗ Host does NOT have ${ip} assigned to any local interface (Docker port publish will fail)"
    fi
done

echo

echo "Testing IP aliases (ping)..."
for ip in "${HOST_IPS[@]}"; do
    if ping -c 1 -W "${PING_TIMEOUT_SECS}" "$ip" > /dev/null 2>&1; then
        echo "✓ $ip is reachable"
    else
        echo "✗ $ip is not reachable"
    fi
done


echo

echo "Testing Docker network..."
if docker network inspect local_network > /dev/null 2>&1; then
    echo "✓ Docker network exists"
else
    echo "✗ Docker network missing"
fi

echo

echo "Testing TLS reachability (no curl / with timeouts)..."
# Prefer openssl if available; otherwise fall back to a TCP connect attempt.
if command -v openssl >/dev/null 2>&1; then
    for ip in "${HOST_IPS[@]}"; do
        # -servername avoids SNI mismatches when server_name is set to localhost in nginx.conf
        if timeout "${TLS_TIMEOUT_SECS}" openssl s_client -connect "${ip}:${PORT}" -servername localhost -brief -ign_eof </dev/null 2>&1 | grep -E "Protocol|Cipher|subject=" >/dev/null; then
            echo "✓ TLS works on ${ip}:${PORT}"
        else
            echo "✗ TLS failed on ${ip}:${PORT}"
        fi
    done
else
    # Fallback: verify the TCP listener responds.
    if command -v nc >/dev/null 2>&1; then
        for ip in "${HOST_IPS[@]}"; do
            if timeout "${TLS_TIMEOUT_SECS}" nc -z -w "${TLS_TIMEOUT_SECS}" "$ip" "$PORT" >/dev/null 2>&1; then
                echo "✓ TCP open on ${ip}:${PORT} (TLS verification unavailable: openssl missing)"
            else
                echo "✗ TCP closed on ${ip}:${PORT}"
            fi
        done
    else
        echo "⚠ openssl and nc not found; cannot verify TLS reachability. Install openssl or netcat."
    fi
fi

