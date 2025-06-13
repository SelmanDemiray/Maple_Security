# Suricata -> Logstash -> OpenSearch -> Dashboard + Pi-hole Stack

## Project Setup

1. **First time setup** (creates necessary directories):
```bash
chmod +x setup.sh
./setup.sh
```

2. **Start the entire stack**:
```bash
docker compose up -d
```

3. **Set Pi-hole Password** (Important - Run after stack is up):
```bash
chmod +x pihole-password.sh
./pihole-password.sh
```

4. **Access the services**:
   - **Admin Dashboard**: http://localhost:3000 (System monitoring)
   - **Pi-hole Admin**: http://localhost:8080/admin (DNS filtering - Password: **MapleSecure2024!**)
   - **Pi-hole Admin (Host IP)**: http://192.168.0.99:8080/admin (Replace with your server IP)
   - **OpenSearch Dashboard**: http://localhost:5601
   - **OpenSearch API**: http://localhost:9200

## 🔑 Pi-hole Admin Access

- **Web Interface**: http://localhost:8080/admin
- **Username**: admin (default)
- **Password**: `MapleSecure2024!` (set via script)

**Setting/Resetting Password**: 
```bash
./pihole-password.sh
```

**If password script fails**:
```bash
# Manual method
docker exec -it pihole pihole setpassword
# Enter: MapleSecure2024!
```

This script is the **single source** for the Pi-hole admin password. Run it after the stack is up to set or reset the password.

## Project Structure
```
/root/maple_sec/Maple_Security/
├── docker-compose.yml
├── setup.sh                    # Initial setup script
├── cleanup.sh                  # Complete cleanup script
├── README.md
├── suricata/
│   ├── config/
│   │   └── suricata.yaml
│   └── rules/
│       └── suricata.rules
├── logstash/
│   ├── config/
│   │   └── logstash.yml
│   └── pipeline/
│       └── logstash.conf
├── pihole/                     # DNS ad-blocking & filtering
│   └── init-pihole.sh         # Automatic blocklist setup & password configuration
└── admin-dashboard/            # Web monitoring dashboard
    ├── Dockerfile
    ├── package.json
    ├── server.js
    └── public/
        └── index.html
```

## 🆕 Current Stack Status

Your stack is now **running successfully**! All containers are operational:

- ✅ **Suricata**: Network traffic monitoring active
- ✅ **OpenSearch**: Data storage and indexing ready  
- ✅ **Logstash**: Log processing pipeline active
- ✅ **OpenSearch Dashboard**: Web interface available
- ✅ **Admin Dashboard**: Real-time monitoring active
- ✅ **Pi-hole**: DNS protection with comprehensive blocklists

**Note**: Pi-hole may restart once during initial setup as it configures blocklists - this is normal behavior.

## 🆕 Pi-hole DNS Protection

Pi-hole provides network-wide ad and malware blocking with comprehensive protection:

### **Automatic Block Lists (Pre-configured)**
- **20+ premium block lists** automatically configured
- **General Ad Blocking**: StevenBlack, AdGuard, AdAway
- **Privacy Protection**: EasyPrivacy, Disconnect.me tracking
- **Malware Protection**: Anti-malware hosts, threat intelligence
- **Phishing Protection**: Phishing Army, scam blocklists
- **Social Media Tracking**: Facebook, Smart TV, Android tracking

### **Network Configuration**
- **DNS Server**: Configure devices to use Pi-hole IP (172.20.0.10)
- **Admin Interface**: http://localhost:8080/admin
- **Default Password**: `MapleSecure2024!`
- **Upstream DNS**: Cloudflare (1.1.1.1) + Google (8.8.8.8)

### **Zero Configuration Required**
- All block lists are automatically added on first startup
- Gravity update runs automatically after list installation
- No manual configuration needed - fully automated setup

## 🆕 Admin Dashboard Features

The admin dashboard (http://localhost:3000) now includes:

- **Real-time System Health**: OpenSearch cluster + Pi-hole status
- **Container Monitoring**: All stack containers including Pi-hole
- **DNS Analytics**: Pi-hole query statistics and blocking metrics
- **Data Statistics**: Total documents, indices count, and storage usage
- **Visual Analytics**: 
  - Event types distribution (pie chart)
  - Alert severity breakdown (pie chart)
  - Hourly events timeline (line chart)
  - DNS query statistics and blocking metrics
- **Auto-refresh**: Updates every 30 seconds automatically
- **Service Logs**: Real-time log viewing for all containers

## Network Security Setup

### **Router Configuration (Recommended)**
1. Set your router's primary DNS to Pi-hole container IP: `172.20.0.10`
2. Set secondary DNS to: `1.1.1.1` (fallback)
3. All network devices will automatically use Pi-hole for DNS resolution

### **Individual Device Setup**
Configure DNS settings on devices:
- **Primary DNS**: `172.20.0.10` (Pi-hole)
- **Secondary DNS**: `1.1.1.1` (Cloudflare)

## Setting up Dashboard

1. Go to OpenSearch Dashboard (http://localhost:5601)
2. Navigate to "Stack Management" -> "Index Patterns"
3. Create index pattern: `suricata-*`
4. Select `@timestamp` as time field
5. Go to "Discover" to view Suricata logs
6. Create visualizations in "Visualize" section

## Useful Commands

```bash
# Set/Reset Pi-hole admin password
./pihole-password.sh

# Manual password reset (if script fails)
docker exec -it pihole pihole setpassword

# View Pi-hole logs
docker logs -f pihole

# Check Pi-hole status
docker exec pihole pihole status

# Access Pi-hole shell
docker exec -it pihole bash

# Manual gravity update
docker exec pihole pihole updateGravity

# View Pi-hole statistics
docker exec pihole pihole -c -j

# Check Pi-hole health
docker inspect pihole | grep -A 10 Health

# Restart just Pi-hole
docker restart pihole

# View all container logs
docker compose logs -f

# Stop everything
docker compose down

# Complete cleanup (destroys everything)
./cleanup.sh
```

## Pi-hole Management

### **Password Management**
```bash
# Set or reset admin password (RECOMMENDED METHOD)
./pihole-password.sh

# Alternative manual method (if needed)
docker exec -it pihole pihole setpassword
```

### **Via Admin Interface** (http://localhost:8080/admin)
- Use `./pihole-password.sh` to get the current password
- View query logs and statistics
- Manage whitelist/blacklist
- Configure DNS settings
- Monitor blocked domains
- Update block lists

### **Via Command Line**
```bash
# Check Pi-hole status
docker exec pihole pihole status

# View recent queries
docker exec pihole pihole -q

# Add domain to whitelist
docker exec pihole pihole -w example.com

# Add domain to blacklist
docker exec pihole pihole -b ads.example.com

# Update gravity (refresh block lists)
docker exec pihole pihole updateGravity
```

## Dashboard Visualization Ideas

- Alert severity over time
- Top source/destination IPs
- Geographic distribution of traffic
- Protocol distribution
- HTTP status codes
- DNS query types
- Network flow patterns
- **Active**: Blocked vs allowed DNS queries
- **Active**: Top blocked domains
- **Active**: DNS query frequency by time

## Troubleshooting

### Pi-hole Issues

**Pi-hole password setup failing**
- **Most common**: Pi-hole container not fully initialized - wait 2-3 minutes after `docker compose up -d`
- Run the password script again: `./pihole-password.sh`
- Manual fallback: `docker exec -it pihole pihole setpassword`
- Check Pi-hole logs: `docker logs pihole`
- Restart Pi-hole if needed: `docker restart pihole`

**Pi-hole web interface not loading (502/503 errors)**
- **Most common**: Pi-hole is still initializing - wait 3-5 minutes
- Check Pi-hole logs: `docker logs pihole`
- Verify container is running: `docker ps | grep pihole`
- Check health status: `docker inspect pihole | grep Health`
- Restart Pi-hole: `docker restart pihole`
- **Default admin password**: `MapleSecure2024!`

**Pi-hole not blocking ads**
- Verify device DNS is set to Pi-hole IP (192.168.0.99 or 172.20.0.10)
- Check Pi-hole admin interface for query logs
- Ensure gravity update completed: `docker exec pihole pihole updateGravity`
- Test DNS resolution: `nslookup google.com 192.168.0.99`

**Cannot access Pi-hole from network devices**
- Ensure port 8080 is accessible from your network
- Check firewall settings on the host machine
- Verify the server IP address (192.168.0.99 in your case)
- Try accessing via different network interfaces

**Pi-hole container keeps restarting**
- Check available disk space
- Monitor memory usage
- Review Pi-hole logs for specific errors
- Ensure proper DNS upstream servers are configured

**Blocklists not updating**
- Check Pi-hole logs: `docker logs pihole`
- Manually trigger gravity update: `docker exec pihole pihole updateGravity`
- Verify internet connectivity from Pi-hole container
- Check if database is corrupted: `docker exec pihole pihole -g`

### Network Configuration

**For network-wide DNS protection:**
1. **Router Method (Recommended)**:
   - Log into your router's admin panel
   - Find DNS settings (usually under DHCP or Internet settings)
   - Set Primary DNS to: `192.168.0.99` (your Pi-hole server)
   - Set Secondary DNS to: `1.1.1.1` (backup)
   - Save and restart router

2. **Individual Device Method**:
   - Go to device's network settings
   - Change DNS to: Primary `192.168.0.99`, Secondary `1.1.1.1`
   - Apply settings

**Testing Pi-hole DNS:**
```bash
# Test DNS resolution through Pi-hole
nslookup google.com 192.168.0.99

# Test if ads are being blocked
nslookup ads.google.com 192.168.0.99
# Should return 0.0.0.0 if blocking is working
```

## Complete Cleanup

To destroy all Docker resources and start fresh:
```bash
chmod +x cleanup.sh
./cleanup.sh
```

This will remove:
- All containers (including Pi-hole)
- All volumes (including Pi-hole data)
- All networks
- All related Docker images
- Build cache

**Note**: Configuration files will remain intact for redeployment. Pi-hole will automatically reconfigure all block lists on next startup.

## Next Steps

Now that your stack is running:

1. **Set Pi-hole Password**: Run `./pihole-password.sh` to set the admin password
2. **Configure DNS**: Point your devices or router to Pi-hole (172.20.0.10)
3. **Monitor Traffic**: Check the admin dashboard at http://localhost:3000
4. **Create Visualizations**: Set up dashboards in OpenSearch Dashboard
5. **Review Logs**: Use the admin dashboard's log viewer for troubleshooting
6. **Customize Rules**: Add custom Suricata rules in `suricata/rules/suricata.rules`

## Security Benefits

This stack now provides comprehensive network security:

1. **Network Traffic Analysis**: Suricata monitors all network traffic
2. **DNS-level Protection**: Pi-hole blocks malicious domains before connections
3. **Real-time Monitoring**: OpenSearch indexes all security events
4. **Visual Analytics**: Dashboards for both network and DNS security
5. **Automated Threat Detection**: Pre-configured rules and block lists
6. **Privacy Protection**: Blocks tracking and telemetry at DNS level
