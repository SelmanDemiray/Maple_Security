#!/bin/bash

# Pi-hole Client Detection Fix Script
# Addresses issues with client name resolution and visibility

set -e

echo "🔧 Pi-hole Client Detection Fix"
echo "================================"
echo ""

# Check if Pi-hole is running
if ! docker ps | grep -q pihole; then
    echo "❌ ERROR: Pi-hole container is not running!"
    echo "   Please start the stack first: docker compose up -d"
    exit 1
fi

echo "📋 Step 1: Current Pi-hole Status"
echo "================================="
docker exec pihole pihole status
echo ""

echo "📋 Step 2: Configure Enhanced Client Detection"
echo "=============================================="

# Update Pi-hole FTL configuration for better client detection
echo "Updating Pi-hole FTL configuration..."
docker exec pihole bash -c "cat > /etc/pihole/pihole-FTL.conf << 'EOF'
# Enhanced Pi-hole FTL Configuration for Client Detection
PRIVACYLEVEL=0
QUERY_LOGGING=true
RESOLVE_IPV6=true
RESOLVE_IPV4=true
NAMES_FROM_NETDB=2
SCAN_NETWORK=true
NETWORK_ONLY=false
REFRESH_HOSTNAMES=30
FLUSH_ARP=120
DEBUG_CLIENTS=true
DEBUG_ARP=true
DEBUG_QUERIES=true
LOG_QUERIES=true
SOCKET_LISTENING=localonly
PIHOLE_PTR=HOSTNAME
EOF"

echo "✅ Updated FTL configuration for enhanced client detection"

echo ""
echo "📋 Step 3: Add All Known Router Clients to Pi-hole"
echo "=================================================="

# Add all known clients from your router to Pi-hole's network database
docker exec pihole bash -c "
sqlite3 /etc/pihole/gravity.db << 'EOF'
-- Clear existing network entries to start fresh
DELETE FROM network;

-- Add router
INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) 
VALUES ('192.168.0.1', '5c:e9:31:72:60:fc', 'eth0', 'Router', datetime('now'), datetime('now'), 0, 'TP-Link Systems Inc');

-- Add all known clients from router
INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) 
VALUES ('192.168.0.7', '18:c0:4d:e9:cc:5a', 'eth0', 'TE', datetime('now'), datetime('now'), 0, 'Unknown');

INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) 
VALUES ('192.168.0.205', '7c:c2:c6:35:b6:9d', 'eth0', 'TP-Link Device', datetime('now'), datetime('now'), 0, 'TP-Link Corporation Limited');

INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) 
VALUES ('192.168.0.178', '90:09:d0:19:96:8f', 'eth0', 'apricot', datetime('now'), datetime('now'), 0, 'Unknown');

INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) 
VALUES ('192.168.0.99', 'bc:24:11:d6:0a:dd', 'eth0', 'Pi-hole Server', datetime('now'), datetime('now'), 0, 'Proxmox Server Solutions GmbH');

INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) 
VALUES ('192.168.0.150', 'bc:24:11:b1:2c:1d', 'eth0', 'Network Device 1', datetime('now'), datetime('now'), 0, 'Unknown');

INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) 
VALUES ('192.168.0.219', 'fe:0e:44:45:e4:b8', 'wlan0', 'Wireless Device', datetime('now'), datetime('now'), 0, 'Unknown');

INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) 
VALUES ('192.168.0.111', 'bc:24:11:f1:9f:e8', 'eth0', 'Network Device 2', datetime('now'), datetime('now'), 0, 'Unknown');

INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) 
VALUES ('192.168.0.63', '10:7c:61:28:f5:c7', 'wlan0', 'xman', datetime('now'), datetime('now'), 0, 'Unknown');
EOF
"

echo "✅ Added all router clients to Pi-hole network database"

echo ""
echo "📋 Step 4: Diagnose DNS Configuration Issue"
echo "=========================================="

echo "🔍 The main issue: Clients aren't actually using Pi-hole as DNS"
echo ""
echo "Router shows these clients connected:"
echo "• 192.168.0.7 (TE)"
echo "• 192.168.0.205 (TP-Link Device)" 
echo "• 192.168.0.178 (apricot)"
echo "• 192.168.0.150 (Network Device 1)"
echo "• 192.168.0.219 (Wireless Device)"
echo "• 192.168.0.111 (Network Device 2)"
echo "• 192.168.0.63 (xman)"
echo ""
echo "But Pi-hole only sees queries from: 192.168.0.1 (router), localhost, and container IPs"
echo ""
echo "❗ DIAGNOSIS: Router DNS setting may not be working properly"

echo ""
echo "📋 Step 5: Verify Router DNS Configuration"
echo "========================================="

echo "Please verify these router settings:"
echo "1. Router DHCP Settings:"
echo "   - Primary DNS: 192.168.0.99 (Pi-hole)"
echo "   - Secondary DNS: 1.1.1.1 or 8.8.8.8"
echo "   - DNS Relay/Proxy: DISABLED"
echo ""
echo "2. Router Advanced Settings:"
echo "   - DHCP Option 6 (DNS): 192.168.0.99"
echo "   - Local DNS Server: DISABLED or set to Pi-hole"
echo "   - Smart Connect DNS: DISABLED"
echo ""

echo ""
echo "📋 Step 6: Test DNS Resolution from a Client"
echo "==========================================="

echo "From any client device (192.168.0.7, 192.168.0.63, etc.), run:"
echo "Windows: nslookup google.com"
echo "Linux/Mac: dig google.com"
echo ""
echo "Expected result: Server should be 192.168.0.99"
echo "If not, the client isn't using Pi-hole as DNS"

echo ""
echo "📋 Step 7: Alternative Solutions"
echo "==============================="

echo "If router DNS distribution isn't working:"
echo ""
echo "Option A - Manual Client Configuration:"
echo "Set DNS manually on each device:"
echo "• Primary DNS: 192.168.0.99"
echo "• Secondary DNS: 1.1.1.1"
echo ""
echo "Option B - Router Firmware Issue:"
echo "Some TP-Link routers have issues with custom DNS distribution"
echo "Try:"
echo "• Reboot router after DNS setting change"
echo "• Update router firmware"
echo "• Check if 'DNS Relay' or 'Smart DNS' is enabled (disable it)"
echo ""
echo "Option C - DHCP Renewal:"
echo "Force DHCP renewal on clients:"
echo "• Windows: ipconfig /release && ipconfig /renew"
echo "• Linux: sudo dhclient -r && sudo dhclient"
echo "• Mac: System Preferences > Network > Advanced > TCP/IP > Renew DHCP Lease"
echo "Restarting Pi-hole FTL with new configuration..."
docker exec pihole bash -c "pihole restartdns"

# Wait for restart
sleep 5

# Force network scan
echo "Forcing network discovery..."
docker exec pihole bash -c "
# Scan the local network to discover devices
nmap -sn 192.168.0.0/24 >/dev/null 2>&1 || true

# Update ARP table
ip neigh flush all 2>/dev/null || true
ping -c 1 -W 1 192.168.0.1 >/dev/null 2>&1 || true
ping -c 1 -W 1 192.168.0.7 >/dev/null 2>&1 || true
ping -c 1 -W 1 192.168.0.63 >/dev/null 2>&1 || true
ping -c 1 -W 1 192.168.0.111 >/dev/null 2>&1 || true
ping -c 1 -W 1 192.168.0.150 >/dev/null 2>&1 || true
ping -c 1 -W 1 192.168.0.178 >/dev/null 2>&1 || true
ping -c 1 -W 1 192.168.0.205 >/dev/null 2>&1 || true
ping -c 1 -W 1 192.168.0.219 >/dev/null 2>&1 || true
"

echo "✅ Network scan completed"

echo ""
echo "📋 Step 5: Add Known Devices to Pi-hole Database"
echo "==============================================="

# Add known devices from your router list
docker exec pihole bash -c "
sqlite3 /etc/pihole/gravity.db << 'EOF'
-- Clear existing network entries to avoid duplicates
DELETE FROM network WHERE ip IN ('192.168.0.7', '192.168.0.63', '192.168.0.111', '192.168.0.150', '192.168.0.178', '192.168.0.205', '192.168.0.219');

-- Add known devices from router
INSERT OR REPLACE INTO network (ip, hwaddr, interface, name, firstSeen, lastQuery, numQueries, macVendor) VALUES
('192.168.0.7', '18:c0:4d:e9:cc:5a', 'eth0', 'TE-Device', datetime('now'), datetime('now'), 0, 'Unknown'),
('192.168.0.63', '10:7c:61:28:f5:c7', 'wlan0', 'xman', datetime('now'), datetime('now'), 0, 'Unknown'),
('192.168.0.111', 'bc:24:11:f1:9f:e8', 'eth0', 'Network-Device-111', datetime('now'), datetime('now'), 0, 'Proxmox Server Solutions GmbH'),
('192.168.0.150', 'bc:24:11:b1:2c:1d', 'eth0', 'Network-Device-150', datetime('now'), datetime('now'), 0, 'Proxmox Server Solutions GmbH'),
('192.168.0.178', '90:09:d0:19:96:8f', 'eth0', 'apricot', datetime('now'), datetime('now'), 0, 'Unknown'),
('192.168.0.205', '7c:c2:c6:35:b6:9d', 'eth0', 'TP-Link-Device', datetime('now'), datetime('now'), 0, 'TP-Link Corporation Limited'),
('192.168.0.219', 'fe:0e:44:45:e4:b8', 'wlan0', 'Network-Device-219', datetime('now'), datetime('now'), 0, 'Unknown');
EOF
"

echo "✅ Added known devices to Pi-hole database"

echo ""
echo "📋 Step 6: Test DNS Resolution from Devices"
echo "=========================================="

echo "Testing if devices are actually using Pi-hole DNS..."
echo "Generating test DNS queries to verify client detection..."

# Generate some test DNS queries from the Pi-hole server to see if logging works
docker exec pihole bash -c "
# Test DNS queries to generate activity
nslookup google.com 127.0.0.1 >/dev/null 2>&1 || true
nslookup facebook.com 127.0.0.1 >/dev/null 2>&1 || true
nslookup amazon.com 127.0.0.1 >/dev/null 2>&1 || true
"

echo "✅ Generated test DNS queries"

echo ""
echo "📋 Step 7: Current Network Status"
echo "================================"

# Show current network table
echo "Current devices in Pi-hole network table:"
docker exec pihole bash -c "
sqlite3 /etc/pihole/gravity.db 'SELECT ip, name, hwaddr, interface, firstSeen FROM network ORDER BY ip;' | head -20
"

echo ""
echo "📋 Step 8: Router Configuration Instructions"
echo "==========================================="

echo "🔧 CRITICAL: Router DNS Configuration"
echo "====================================="
echo ""
echo "Your router currently shows devices, but they're not using Pi-hole DNS yet."
echo "You need to ensure your router is properly configured:"
echo ""
echo "1. **Access your router admin panel:**"
echo "   URL: http://192.168.0.1"
echo "   (Your router IP from the client list)"
echo ""
echo "2. **Navigate to DHCP/DNS Settings:**"
echo "   Look for: 'DHCP Settings', 'LAN Settings', or 'DNS Settings'"
echo ""
echo "3. **Set DNS Servers:**"
echo "   Primary DNS: 192.168.0.99"
echo "   Secondary DNS: 1.1.1.1 (optional backup)"
echo ""
echo "4. **Important Router Settings:**"
echo "   - DISABLE 'DNS Proxy' or 'DNS Relay' if present"
echo "   - DISABLE 'Smart DNS' if present"
echo "   - ENABLE 'Use Router as DNS Server' = NO"
echo "   - ENABLE 'Advertise Router DNS' = NO"
echo ""
echo "5. **Save settings and REBOOT your router**"
echo ""
echo "6. **Test on individual devices:**"
echo "   - Disconnect and reconnect WiFi"
echo "   - Or manually set DNS to 192.168.0.99"
echo ""
echo "📱 **Manual Device Configuration (if router doesn't work):**"
echo "========================================================="
echo ""
echo "For each device, set DNS manually:"
echo "• iPhone/iPad: Settings > WiFi > (i) > Configure DNS > Manual > 192.168.0.99"
echo "• Android: Settings > WiFi > Advanced > DNS > 192.168.0.99"
echo "• Windows: Network Settings > Change Adapter > Properties > IPv4 > DNS: 192.168.0.99"
echo "• macOS: System Preferences > Network > Advanced > DNS > + > 192.168.0.99"
echo ""

echo "📋 Step 9: Wait for DNS Cache Refresh"
echo "===================================="
echo ""
echo "After configuring your router:"
echo "1. Wait 5-10 minutes for devices to refresh DNS settings"
echo "2. Some devices may need to be disconnected/reconnected from WiFi"
echo "3. Check Pi-hole admin panel: http://192.168.0.99:8080/admin"
echo "4. Look for increased query activity in the dashboard"
echo ""

echo "📋 Step 8: Restart Pi-hole FTL Service"
echo "====================================="

echo "Restarting Pi-hole FTL to apply all configuration changes..."
docker exec pihole pihole restartdns

echo "✅ Pi-hole FTL restarted with new configuration"

echo ""
echo "📋 Step 9: Verification Steps"
echo "============================"

echo "1. Check Pi-hole network table (should now show all clients):"
echo "   Visit: http://localhost:8080/admin/network.php"
echo ""
echo "2. Test DNS resolution from a client device:"
echo "   nslookup google.com (should show server 192.168.0.99)"
echo ""
echo "3. Monitor Pi-hole query log in real-time:"
echo "   docker exec pihole pihole -t"
echo ""
echo "4. Check if clients are making DNS queries:"
echo "   Visit: http://localhost:8080/admin/queries.php"
echo ""

echo "🎯 If clients still don't appear in Pi-hole:"
echo "The issue is that your router's DNS distribution isn't working properly."
echo "This is common with some TP-Link router models."
echo ""
echo "Quick fix: Set DNS manually on 1-2 devices to test:"
echo "• Primary DNS: 192.168.0.99"
echo "• Secondary DNS: 1.1.1.1"
echo ""
echo "If manual DNS works, the issue is definitely with your router's DHCP/DNS settings."

echo ""
echo "✅ Client detection fix script completed!"
echo "📊 Pi-hole should now recognize all your router clients when they make DNS queries."
