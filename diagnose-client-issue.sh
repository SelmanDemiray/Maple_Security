#!/bin/bash

# Pi-hole Client Detection Diagnostic Script
# This script identifies why clients aren't showing up in Pi-hole

echo "🔍 Pi-hole Client Detection Diagnostic"
echo "======================================"
echo ""

# Check if Pi-hole is running
if ! docker ps | grep -q pihole; then
    echo "❌ ERROR: Pi-hole container is not running!"
    exit 1
fi

echo "📊 Step 1: Current Pi-hole Network Status"
echo "========================================="
docker exec pihole pihole status
echo ""

echo "📋 Step 2: Pi-hole Network Database"
echo "==================================="
echo "Current clients in Pi-hole network table:"
docker exec pihole sqlite3 /etc/pihole/gravity.db "SELECT ip, name, hwaddr, interface, firstSeen, lastQuery, numQueries FROM network ORDER BY ip;" 2>/dev/null || echo "Could not read network database"
echo ""

echo "📋 Step 3: Recent DNS Queries"
echo "============================="
echo "Recent DNS queries to Pi-hole (last 10):"
docker exec pihole tail -20 /var/log/pihole.log 2>/dev/null | grep -E "query|reply" | tail -10 || echo "No query logs found"
echo ""

echo "📋 Step 4: Real-time DNS Query Test"
echo "==================================="
echo "Testing DNS resolution from Pi-hole server itself:"
docker exec pihole nslookup google.com 127.0.0.1
echo ""

echo "📋 Step 5: Network Interface and Routing"
echo "========================================"
echo "Pi-hole container network configuration:"
docker exec pihole ip addr show eth0 2>/dev/null || docker exec pihole ip addr show 2>/dev/null | head -20
echo ""

echo "📋 Step 6: ARP Table (Network Discovery)"
echo "======================================="
echo "ARP table from Pi-hole container:"
docker exec pihole arp -a 2>/dev/null || echo "ARP table not available"
echo ""

echo "📋 Step 7: DNS Query Statistics"
echo "==============================="
echo "Pi-hole query statistics:"
docker exec pihole pihole -c 2>/dev/null || echo "Could not get query count"
echo ""

echo "🔬 DIAGNOSIS SUMMARY"
echo "==================="
echo ""
echo "Your router shows these clients connected:"
echo "• 192.168.0.7 (TE)"
echo "• 192.168.0.205 (TP-Link Device)"
echo "• 192.168.0.178 (apricot)" 
echo "• 192.168.0.150 (Network Device 1)"
echo "• 192.168.0.219 (Wireless Device)"
echo "• 192.168.0.111 (Network Device 2)"
echo "• 192.168.0.63 (xman)"
echo ""
echo "But Pi-hole only sees queries from a few sources."
echo ""
echo "❗ PRIMARY ISSUE: Clients are NOT using Pi-hole as their DNS server"
echo ""
echo "🔧 SOLUTIONS TO TRY:"
echo ""
echo "1. TEST MANUAL DNS CONFIGURATION:"
echo "   On device 192.168.0.63 (xman) or 192.168.0.178 (apricot):"
echo "   • Set DNS manually to 192.168.0.99"
echo "   • Test: nslookup google.com"
echo "   • Should show server 192.168.0.99"
echo ""
echo "2. ROUTER CONFIGURATION ISSUES:"
echo "   Your TP-Link router may have these problems:"
echo "   • DNS Relay/Proxy enabled (disable it)"
echo "   • Smart DNS or Auto DNS enabled (disable it)"
echo "   • DHCP not distributing custom DNS servers"
echo "   • Router needs reboot after DNS change"
echo ""
echo "3. VERIFY ROUTER SETTINGS:"
echo "   Check your router's DHCP settings:"
echo "   • Primary DNS Server: 192.168.0.99"
echo "   • Secondary DNS Server: 1.1.1.1"
echo "   • Disable any DNS proxy/relay features"
echo ""
echo "4. FORCE DHCP RENEWAL:"
echo "   On client devices, renew DHCP lease:"
echo "   • Windows: ipconfig /release && ipconfig /renew"
echo "   • Linux: sudo dhclient -r && sudo dhclient"
echo ""
echo "5. IMMEDIATE TEST:"
echo "   To verify Pi-hole works, manually set DNS on one device:"
echo "   • Go to network settings on 192.168.0.63 (xman)"
echo "   • Set DNS servers: 192.168.0.99, 1.1.1.1"
echo "   • Visit a website, then check Pi-hole admin panel"
echo "   • You should see queries from that device"
echo ""
echo "✅ Run this test first, then we'll know if the issue is:"
echo "   A) Pi-hole not working (unlikely)"
echo "   B) Router not distributing DNS settings (most likely)"

echo ""
echo "🎯 NEXT STEPS:"
echo "1. Test manual DNS on one device"
echo "2. If that works, fix router DHCP/DNS distribution"
echo "3. If that doesn't work, check Pi-hole configuration"
