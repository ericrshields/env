#!/bin/bash
echo "=== System Health Check - $(date) ==="
echo -e "\n=== Memory Usage ==="
free -h
echo -e "\n=== Disk Usage ==="
df -h | grep -E "/$|/workspace"
echo -e "\n=== Docker Usage ==="
docker system df
echo -e "\n=== Top 5 Memory Consumers ==="
ps aux --sort=-%mem | head -6
echo "======================================="
