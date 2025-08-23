#!/bin/bash

echo "🔧 Setting up Maple Security Stack directories and permissions..."

# Create required directories
echo "Creating directory structure..."
mkdir -p suricata/config suricata/rules
mkdir -p logstash/config logstash/pipeline

# Set proper permissions
echo "Setting permissions..."
chmod 755 suricata/config suricata/rules
chmod 755 logstash/config logstash/pipeline

# Ensure log directory permissions for Docker
echo "Setting up log directory permissions..."
sudo chown -R 1000:1000 . 2>/dev/null || true

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: docker compose up -d"
echo "2. Wait 3-5 minutes for all services to initialize"
echo "3. Access services:"
echo "   - OpenSearch Dashboard: http://localhost:5601"
echo ""
echo "Note: Initial blocklist download and processing may take 2-3 minutes."
echo "   - OpenSearch Dashboard: http://localhost:5601"
echo ""
echo "Note: Initial blocklist download and processing may take 2-3 minutes."
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: docker compose up -d"
echo "2. Wait 3-5 minutes for all services to initialize"
echo "3. Set Pi-hole password: ./pihole-password.sh"
echo "4. Access services:"
echo "   - Admin Dashboard: http://localhost:3000"
echo "   - Pi-hole Admin: http://localhost:8080/admin"
echo "   - Pi-hole Admin: http://192.168.0.99:8080/admin (if using host IP)"
echo "   - OpenSearch Dashboard: http://localhost:5601"
echo ""
echo "🛡️ Pi-hole DNS Protection Setup:"
echo "Configure your devices to use Pi-hole as DNS server:"
echo "- Router DNS: Set to 192.168.0.99 (or your server IP)"
echo "- Individual devices: Primary DNS = 192.168.0.99, Secondary DNS = 1.1.1.1"
echo ""
echo "Note: Pi-hole may restart once during initial setup - this is normal."
echo "Initial blocklist download and processing may take 2-3 minutes."
echo "Use './pihole-password.sh' to set/reset the admin password anytime."
