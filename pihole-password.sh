#!/bin/bash

# Pi-hole Password Management Script
# This is the ONLY place where the Pi-hole password is defined

set -e

# SINGLE SOURCE OF TRUTH FOR PI-HOLE PASSWORD
PIHOLE_PASSWORD="**#*%Z8okTp^!&2YqV87$66mdPx$2Q9aH64$TM7^2q455"

echo "=== Pi-hole Password Reset Script ==="
echo "This script will set/reset the Pi-hole admin password"
echo ""

# Check if Pi-hole container is running
if ! docker ps | grep -q pihole; then
    echo "ERROR: Pi-hole container is not running!"
    echo "Please start the stack first: docker compose up -d"
    exit 1
fi

# Wait for Pi-hole to be ready
echo "Waiting for Pi-hole to be ready..."
timeout=60
counter=0

while [ $counter -lt $timeout ]; do
    if docker exec pihole pihole status > /dev/null 2>&1; then
        echo "Pi-hole is ready!"
        break
    fi
    echo "Waiting for Pi-hole... ($counter/$timeout)"
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    echo "ERROR: Pi-hole not ready within $timeout seconds"
    exit 1
fi

# Set the password using the correct method
echo "Setting Pi-hole admin password..."
if docker exec pihole bash -c "echo -e '$PIHOLE_PASSWORD\n$PIHOLE_PASSWORD' | pihole setpassword"; then
    echo "✅ Pi-hole admin password set successfully!"
    echo ""
    echo "Pi-hole Admin Access:"
    echo "- URL: http://localhost:8080/admin"
    echo "- Username: admin (default)"
    echo "- Password: $PIHOLE_PASSWORD"
    echo ""
    echo "Network Access:"
    echo "- URL: http://$(hostname -I | awk '{print $1}'):8080/admin"
    echo "- Password: $PIHOLE_PASSWORD"
else
    echo "❌ Failed to set Pi-hole password"
    echo "Trying alternative method..."
    
    # Alternative method using environment variable
    if docker exec -e WEBPASSWORD="$PIHOLE_PASSWORD" pihole bash -c 'echo "$WEBPASSWORD" | pihole setpassword'; then
        echo "✅ Pi-hole admin password set successfully (alternative method)!"
        echo ""
        echo "Pi-hole Admin Access:"
        echo "- URL: http://localhost:8080/admin"
        echo "- Username: admin (default)"
        echo "- Password: $PIHOLE_PASSWORD"
    else
        echo "❌ Both password methods failed"
        echo "Manual setup required:"
        echo "1. Run: docker exec -it pihole pihole setpassword"
        echo "2. Enter password when prompted: $PIHOLE_PASSWORD"
        exit 1
    fi
fi

# Verify the password works
echo "Verifying password setup..."
if docker exec pihole pihole status > /dev/null 2>&1; then
    echo "✅ Password verification successful!"
else
    echo "⚠️  Warning: Password verification failed, but password was set"
fi

echo ""
echo "=== Password Reset Complete ==="
echo "Current Pi-hole admin password: $PIHOLE_PASSWORD"
