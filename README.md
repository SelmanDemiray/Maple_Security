# Suricata -> Logstash -> OpenSearch -> Dashboard Stack

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

4. **Access the services**:
   - **OpenSearch Dashboard**: http://localhost:5601
   - **OpenSearch API**: http://localhost:9200

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
```

## 🆕 Current Stack Status

Your stack is now **running successfully**! All containers are operational:

- ✅ **Suricata**: Network traffic monitoring active
- ✅ **OpenSearch**: Data storage and indexing ready  
- ✅ **Logstash**: Log processing pipeline active
- ✅ **OpenSearch Dashboard**: Web interface available

## Network Security Setup

### **Router Configuration (Recommended)**
1. Set your router's primary DNS to your server IP
2. Set secondary DNS to: `1.1.1.1` (fallback)
3. All network devices will automatically use your DNS for resolution

### **Individual Device Setup**
Configure DNS settings on devices:
- **Primary DNS**: your server IP
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
# View all container logs
docker compose logs -f

# Stop everything
docker compose down

# Complete cleanup (destroys everything)
./cleanup.sh
```

## Dashboard Visualization Ideas

- Alert severity over time
- Top source/destination IPs
- Geographic distribution of traffic
- Protocol distribution
- HTTP status codes
- Network flow patterns

## Network Configuration

**For network-wide DNS protection:**
1. **Router Method (Recommended)**:
   - Log into your router's admin panel
   - Find DNS settings (usually under DHCP or Internet settings)
   - Set Primary DNS to: your server IP
   - Set Secondary DNS to: `1.1.1.1` (backup)
   - Save and restart router

2. **Individual Device Method**:
   - Go to device's network settings
   - Change DNS to: Primary your server IP, Secondary `1.1.1.1`
   - Apply settings

**Testing DNS:**
```bash
# Test DNS resolution through your server
nslookup google.com your_server_ip
```

## Complete Cleanup

To destroy all Docker resources and start fresh:
```bash
chmod +x cleanup.sh
./cleanup.sh
```

This will remove:
- All containers
- All volumes
- All networks
- All related Docker images
- Build cache

**Note**: Configuration files will remain intact for redeployment.

## Next Steps

Now that your stack is running:

1. **Configure DNS**: Point your devices or router to your server IP
2. **Monitor Traffic**: Check OpenSearch Dashboard at http://localhost:5601
3. **Create Visualizations**: Set up dashboards in OpenSearch Dashboard
4. **Review Logs**: Use OpenSearch Dashboard's log viewer for troubleshooting
5. **Customize Rules**: Add custom Suricata rules in `suricata/rules/suricata.rules`

## Security Benefits

This stack now provides comprehensive network security:

1. **Network Traffic Analysis**: Suricata monitors all network traffic
2. **Real-time Monitoring**: OpenSearch indexes all security events
3. **Visual Analytics**: Dashboards for network security
4. **Automated Threat Detection**: Pre-configured rules
5. **Privacy Protection**: Blocks tracking and telemetry at DNS level
