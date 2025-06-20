#!/bin/bash

# Pi-hole Client Detection Troubleshooting Script
# Run this script to diagnose why clients aren't showing up

echo "🔍 Pi-hole Client Detection Diagnostics"
echo "========================================"
echo ""

# Check Pi-hole status
echo "📊 Pi-hole Status:"
echo "=================="
docker exec pihole pihole status
echo ""

# Check if Pi-hole is receiving queries
echo "🔍 Recent DNS Queries (last 20):"
echo "================================"
docker exec pihole pihole -t 2>/dev/null | head -20 &
sleep 5
kill $! 2>/dev/null
echo ""

# Check Pi-hole logs for client activity
echo "📝 Pi-hole Query Log (last 10 unique queries):"
echo "=============================================="
docker exec pihole tail -n 100 /var/log/pihole.log 2>/dev/null | grep -E "query|reply" | tail -10 || echo "No query logs found"
echo ""

# Check network configuration
echo "🌐 Network Configuration:"
echo "========================"
echo "Server IP: $(ip addr show | grep -E "inet.*192\.168|inet.*10\.|inet.*172\." | head -1 | awk '{print $2}' | cut -d'/' -f1)"
echo "Pi-hole Container Network Mode: host"
echo ""

# Check if Pi-hole is listening on port 53
echo "🔌 Port 53 Status:"
echo "=================="
docker exec pihole netstat -tuln | grep :53 || echo "Port 53 status check failed"
echo ""

# Check Pi-hole FTL configuration
echo "⚙️ Pi-hole FTL Configuration:"
echo "============================="
docker exec pihole cat /etc/pihole/pihole-FTL.conf | grep -E "PRIVACYLEVEL|QUERY_LOGGING|RESOLVE_IPV|NAMES_FROM_NETDB" 2>/dev/null || echo "FTL config not found"
echo ""

# Check dnsmasq configuration
echo "🔧 Dnsmasq Configuration:"
echo "========================="
docker exec pihole cat /etc/dnsmasq.d/99-custom.conf | head -10 2>/dev/null || echo "Custom dnsmasq config not found"
echo ""

# Test DNS resolution
echo "🧪 DNS Resolution Test:"
echo "======================="
echo "Testing DNS resolution from container:"
docker exec pihole nslookup google.com localhost 2>/dev/null || echo "DNS resolution test failed"
echo ""

# Check for DHCP leases (if available)
echo "📋 DHCP Lease Information:"
echo "=========================="
docker exec pihole cat /etc/pihole/dhcp.leases 2>/dev/null | head -5 || echo "No DHCP leases found (normal if router handles DHCP)"
echo ""

# Final recommendations
echo "💡 Troubleshooting Steps:"
echo "========================"
echo "1. Check if your router is set to use Pi-hole DNS (192.168.0.99)"
echo "2. Disable 'DNS Proxy' or 'DNS Relay' on your router"
echo "3. Set up 'Conditional Forwarding' in Pi-hole web interface:"
echo "   - Go to Settings > DNS > Conditional Forwarding"
echo "   - Enable: 'Use Conditional Forwarding'"
echo "   - Local network in CIDR notation: 192.168.0.0/24"
echo "   - IP address of your DHCP server (router): 192.168.0.1"
echo "   - Local domain name: local (or your router's domain)"
echo ""
echo "4. Access Pi-hole admin at: http://192.168.0.99:8080/admin"
echo "5. Check Tools > Network Scan to see if Pi-hole can detect devices"
echo ""
echo "🔍 If clients still don't appear, they may be cached. Wait 5-10 minutes"
echo "   or flush DNS cache on client devices."
