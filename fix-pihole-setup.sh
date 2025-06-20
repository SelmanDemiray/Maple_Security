#!/bin/bash

# Fix Pi-hole Setup Script
# This script addresses the issues with Pi-hole blocklist loading and client detection

set -e

echo "🔧 Pi-hole Setup Fix Script"
echo "==========================="

# Check if Pi-hole is running
if ! docker ps | grep -q pihole; then
    echo "❌ Pi-hole container is not running!"
    echo "Please start the stack first: docker compose up -d"
    exit 1
fi

echo "📋 Step 1: Checking current Pi-hole blocklist configuration..."

# Check current adlists via API
echo "Current adlists in Pi-hole:"
docker exec pihole bash -c "
    if [ -f /etc/pihole/gravity.db ]; then
        echo 'Gravity database exists'
        # Try to get a simple count
        ls -la /etc/pihole/gravity.db
    else
        echo 'No gravity database found'
    fi
"

echo ""
echo "📋 Step 2: Manually adding missing blocklists via Pi-hole API..."

# Function to add blocklist via Pi-hole API
add_blocklist() {
    local url="$1"
    local name="$2"
    
    echo "Adding: $name"
    docker exec pihole bash -c "
        # Add the blocklist using pihole command
        echo '$url' >> /etc/pihole/adlists.list
    " || echo "Failed to add $name"
}

# Add key blocklists manually
add_blocklist "https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/filter.txt" "AdGuard DNS Filter"
add_blocklist "https://adaway.org/hosts.txt" "AdAway"
add_blocklist "https://someonewhocares.org/hosts/zero/hosts" "Dan Pollock's Hosts"
add_blocklist "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt" "Windows Spy Blocker"
add_blocklist "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt" "Smart TV Blocklist"

echo ""
echo "📋 Step 3: Force complete gravity update..."
docker exec pihole pihole updateGravity

echo ""
echo "📋 Step 4: Checking final blocklist count..."
docker exec pihole pihole status

echo ""
echo "📋 Step 5: Configure conditional forwarding for better client detection..."
echo "Manual steps needed:"
echo "1. Open Pi-hole web interface: http://localhost:8080/admin"
echo "2. Go to Settings > DNS"
echo "3. Enable 'Use Conditional Forwarding'"
echo "4. Set:"
echo "   - Local network in CIDR: 192.168.0.0/24"
echo "   - IP address of your DHCP server: 192.168.0.1"
echo "   - Local domain name: local"

echo ""
echo "📋 Step 6: Router DNS Configuration"
echo "Configure your router to use Pi-hole as DNS:"
echo "1. Access your router's admin interface (usually 192.168.0.1)"
echo "2. Go to DHCP/DNS settings"
echo "3. Set Primary DNS to: 192.168.0.99"
echo "4. Set Secondary DNS to: 1.1.1.1"
echo "5. Disable any 'DNS Proxy' or 'DNS Relay' features"
echo "6. Save and restart router"

echo ""
echo "📋 Step 7: Client DNS Configuration (Alternative)"
echo "If router configuration doesn't work, configure devices manually:"
echo "- Primary DNS: 192.168.0.99"
echo "- Secondary DNS: 1.1.1.1"

echo ""
echo "✅ Pi-hole setup fix completed!"
echo "Wait 10-15 minutes for changes to propagate, then check:"
echo "- Pi-hole web interface for increased blocked domain counts"
echo "- Query logs for client activity"
echo "- Router/device DNS settings"
