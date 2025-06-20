#!/bin/bash

# Pi-hole Ad Lists Update Script
# This script reads ad lists from pihole/adlists.txt and updates Pi-hole with them

# Remove set -e to allow continuing on individual failures
# set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ADLISTS_FILE="$SCRIPT_DIR/pihole/adlists.txt"

echo "🛡️ Pi-hole Ad Lists Update Script"
echo "=================================="

# Check if running inside Pi-hole container or host with Pi-hole
if [ -f /usr/local/bin/pihole ]; then
    echo "Running inside Pi-hole container"
    EXEC_PREFIX=""
elif docker ps | grep -q pihole; then
    echo "Running on host with Pi-hole container"
    EXEC_PREFIX="docker exec pihole"
else
    echo "❌ ERROR: Pi-hole container is not running!"
    echo "Please start the stack first: docker compose up -d"
    exit 1
fi

# Check if adlists file exists
if [ ! -f "$ADLISTS_FILE" ]; then
    echo "❌ ERROR: Ad lists file not found: $ADLISTS_FILE"
    echo "Please ensure the pihole/adlists.txt file exists"
    exit 1
fi

# Function to add adlist via direct database insertion (Pi-hole v6.1.2 compatible)
add_adlist() {
    local url="$1"
    local comment="$2"
    
    echo "  📝 Adding: $comment"
    echo "     URL: $url"
    
    # Escape single quotes in URL and comment for SQL
    local escaped_url="${url//\'/\'\'}"
    local escaped_comment="${comment//\'/\'\'}"
    
    # Check if URL already exists in database
    local exists
    if [ -n "$EXEC_PREFIX" ]; then
        exists=$($EXEC_PREFIX pihole-FTL sqlite3 "/etc/pihole/gravity.db" "SELECT COUNT(*) FROM adlist WHERE address='$escaped_url';" 2>/dev/null)
    else
        exists=$(pihole-FTL sqlite3 "/etc/pihole/gravity.db" "SELECT COUNT(*) FROM adlist WHERE address='$escaped_url';" 2>/dev/null)
    fi
    
    if [[ "$exists" -gt 0 ]]; then
        echo "  ⚠️  Already exists: $comment"
        return 1
    else
        # Insert into database
        local current_time=$(date +%s)
        local sql_cmd="INSERT INTO adlist (address, enabled, date_added, date_modified, comment) VALUES ('$escaped_url', 1, $current_time, $current_time, '$escaped_comment');"
        
        if [ -n "$EXEC_PREFIX" ]; then
            $EXEC_PREFIX pihole-FTL sqlite3 "/etc/pihole/gravity.db" "$sql_cmd" 2>/dev/null
        else
            pihole-FTL sqlite3 "/etc/pihole/gravity.db" "$sql_cmd" 2>/dev/null
        fi
        
        if [[ $? -eq 0 ]]; then
            echo "  ✅ Successfully added to database: $comment"
            return 0
        else
            echo "  ❌ Failed to add to database: $comment"
            echo "  SQL: $sql_cmd"
            return 1
        fi
    fi
}

# Wait for Pi-hole to be ready
echo "🔍 Checking Pi-hole status..."
timeout=60
counter=0

while [ $counter -lt $timeout ]; do
    if $EXEC_PREFIX pihole status > /dev/null 2>&1; then
        echo "✅ Pi-hole is ready"
        break
    fi
    echo "Waiting for Pi-hole... ($counter/$timeout)"
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    echo "❌ ERROR: Pi-hole not ready within $timeout seconds"
    exit 1
fi

# Wait for gravity database to be available
echo "🔍 Checking gravity database..."
db_ready=false
for i in {1..30}; do
    if $EXEC_PREFIX test -f /etc/pihole/gravity.db 2>/dev/null; then
        db_ready=true
        echo "✅ Gravity database is available"
        break
    fi
    echo "Waiting for gravity database... ($i/30)"
    sleep 2
done

if [ "$db_ready" = false ]; then
    echo "❌ ERROR: Gravity database not available"
    exit 1
fi

# Get current status of Pi-hole
echo "📊 Checking current Pi-hole configuration..."
$EXEC_PREFIX pihole status

# Read and process ad lists file
echo "📖 Reading ad lists from: $ADLISTS_FILE"
echo "📝 Adding new ad lists to Pi-hole..."

added_count=0
skipped_count=0

# Process each line in the adlists file
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Parse URL and description (format: URL|Description)
    if [[ "$line" =~ ^([^|]+)\|(.+)$ ]]; then
        url="${BASH_REMATCH[1]}"
        description="${BASH_REMATCH[2]}"
        
        # Add the adlist
        if add_adlist "$url" "$description"; then
            ((added_count++))
        else
            ((skipped_count++))
        fi
    else
        echo "  ⚠️  Skipping malformed line: $line"
    fi
done < "$ADLISTS_FILE"

echo ""
echo "📈 Summary:"
echo "  - New lists added: $added_count"
echo "  - Lists skipped (already exist): $skipped_count"

# Run gravity update to process all lists
if [ $added_count -gt 0 ]; then
    echo ""
    echo "🔄 Running gravity update to download and process all block lists..."
    echo "This may take several minutes depending on the number of lists..."
    
    if $EXEC_PREFIX pihole updateGravity; then
        echo "✅ Gravity update completed successfully!"
    else
        echo "⚠️  Gravity update failed, attempting retry..."
        if $EXEC_PREFIX pihole updateGravity; then
            echo "✅ Gravity update completed on retry!"
        else
            echo "❌ Gravity update failed on retry - you may need to run it manually"
            echo "Manual command: docker exec pihole pihole updateGravity"
        fi
    fi
    
    # Get final statistics
    echo ""
    echo "📊 Final Pi-hole Statistics:"
    $EXEC_PREFIX pihole status
    
    # Show basic statistics using Pi-hole commands
    echo "  - Use 'pihole -c' to see detailed statistics"
    echo "  - Check web interface for complete domain counts"
    
else
    echo ""
    echo "ℹ️  No new lists were added, skipping gravity update"
fi

echo ""
echo "🎯 Pi-hole Ad Lists Update Complete!"
echo "=================================="
echo "Access Pi-hole admin interface at: http://localhost:8080/admin"
echo "Use './pihole-password.sh' to set/reset admin password if needed"
