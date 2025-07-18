#!/bin/bash

# Enhanced Pi-hole initialization script with better error handling
set -e

echo "=== Pi-hole Advanced Setup Starting ==="

# Wait for Pi-hole to be fully initialized
echo "Waiting for Pi-hole to be fully ready..."
timeout=300
counter=0

while [ $counter -lt $timeout ]; do
    if curl -s http://localhost/admin/ > /dev/null 2>&1; then
        echo "Pi-hole web interface is ready!"
        break
    fi
    echo "Waiting for Pi-hole web interface... ($counter/$timeout)"
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    echo "ERROR: Pi-hole web interface failed to start within $timeout seconds"
    exit 1
fi

# Additional wait to ensure database is ready
echo "Waiting additional 10 seconds for database initialization..."
sleep 10

# Function to add adlist via Pi-hole API with error handling
add_adlist() {
    local url="$1"
    local comment="$2"
    
    echo "Adding blocklist: $comment"
    if ! sqlite3 /etc/pihole/gravity.db "INSERT OR IGNORE INTO adlist (address, enabled, comment) VALUES ('$url', 1, '$comment');" 2>/dev/null; then
        echo "Warning: Failed to add $comment - database may not be ready yet"
        return 1
    fi
    return 0
}

# Wait for gravity database to be available
echo "Checking for gravity database..."
db_ready=false
for i in {1..30}; do
    if [ -f /etc/pihole/gravity.db ] && sqlite3 /etc/pihole/gravity.db "SELECT COUNT(*) FROM adlist;" > /dev/null 2>&1; then
        echo "Gravity database is ready!"
        db_ready=true
        break
    fi
    echo "Waiting for gravity database... (attempt $i/30)"
    sleep 2
done

if [ "$db_ready" = false ]; then
    echo "ERROR: Gravity database not ready, skipping blocklist setup"
    exit 1
fi

echo "Loading ad lists from configuration file..."

# Load ad lists from external file
ADLISTS_FILE="/usr/local/bin/adlists.txt"
if [ -f "$ADLISTS_FILE" ]; then
    echo "Reading ad lists from: $ADLISTS_FILE"
    added_count=0
    
    while IFS='|' read -r url comment || [ -n "$url" ]; do
        # Skip empty lines and comments
        if [[ -z "$url" || "$url" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Trim whitespace
        url=$(echo "$url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        comment=$(echo "$comment" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Use URL as comment if comment is empty
        if [ -z "$comment" ]; then
            comment="$url"
        fi
        
        if add_adlist "$url" "$comment"; then
            ((added_count++))
        fi
        
    done < "$ADLISTS_FILE"
    
    echo "Added $added_count ad lists from configuration file"
else
    echo "Warning: Ad lists file not found at $ADLISTS_FILE"
    echo "Adding default essential lists..."
    
    # Fallback to essential lists if file is missing
    add_adlist "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" "StevenBlack Unified Hosts"
    add_adlist "https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/filter.txt" "AdGuard DNS Filter"
    add_adlist "https://adaway.org/hosts.txt" "AdAway Default Blocklist"
fi

echo "All block lists added successfully!"

# Get count of added lists
list_count=$(sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM adlist WHERE enabled=1;' 2>/dev/null || echo "0")
echo "Total active block lists: $list_count"

# Force gravity update to download and process all lists
echo "Running gravity update to process all block lists..."
if ! pihole updateGravity; then
    echo "Warning: Gravity update failed, retrying in 30 seconds..."
    sleep 30
    pihole updateGravity || echo "Gravity update failed on retry - will try again later"
fi

# Enable Pi-hole (should already be enabled)
echo "Ensuring Pi-hole is enabled..."
pihole enable

# Set up some basic whitelist entries for common services
echo "Adding essential whitelist entries..."
pihole -w s.youtube.com yt3.ggpht.com googlevideo.com ytimg.com 2>/dev/null || true
pihole -w amazonaws.com s3.amazonaws.com 2>/dev/null || true
pihole -w cloudflare.com 2>/dev/null || true

# Final status check
echo "=== Pi-hole Setup Complete ==="
echo "Pi-hole Status: $(pihole status 2>/dev/null || echo 'Unknown')"
echo "Total domains blocked: $(pihole -q -exact | wc -l 2>/dev/null || echo 'Unknown')"
echo "Access Pi-hole admin at: http://$(hostname -I | awk '{print $1}'):8080/admin"
echo ""
echo "DNS Configuration:"
echo "- Primary DNS: 172.20.0.10 (Pi-hole)"
echo "- Secondary DNS: 1.1.1.1 (Cloudflare)"
echo ""
echo "NOTE: Use the pihole-password.sh script to set the admin password"
echo "Pi-hole initialization completed successfully!"
