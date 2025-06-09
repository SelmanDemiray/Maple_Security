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

3. **Access the services**:
   - **Admin Dashboard**: http://localhost:3000 (NEW!)
   - **OpenSearch Dashboard**: http://localhost:5601
   - **OpenSearch API**: http://localhost:9200

## Project Structure
```
/Users/Seli/Projects/sec/
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
└── admin-dashboard/            # NEW! Web monitoring dashboard
    ├── Dockerfile
    ├── package.json
    ├── server.js
    └── public/
        └── index.html
```

## 🆕 Admin Dashboard Features

The new admin dashboard (http://localhost:3000) provides:

- **Real-time System Health**: OpenSearch cluster status and health metrics
- **Container Monitoring**: Status of all stack containers (Suricata, Logstash, OpenSearch)
- **Data Statistics**: Total documents, indices count, and storage usage
- **Visual Analytics**: 
  - Event types distribution (pie chart)
  - Alert severity breakdown (pie chart)
  - Hourly events timeline (line chart)
- **Auto-refresh**: Updates every 30 seconds automatically

## Setting up Dashboard

1. Go to OpenSearch Dashboard (http://localhost:5601)
2. Navigate to "Stack Management" -> "Index Patterns"
3. Create index pattern: `suricata-*`
4. Select `@timestamp` as time field
5. Go to "Discover" to view Suricata logs
6. Create visualizations in "Visualize" section

## Useful Commands

```bash
# View logs
docker compose logs -f suricata
docker compose logs -f logstash
docker compose logs -f opensearch
docker compose logs -f admin-dashboard

# Stop everything
docker compose down

# Stop and remove volumes (fresh start)
docker compose down -v

# Check Suricata logs directly
docker exec -it suricata tail -f /var/log/suricata/eve.json

# Complete cleanup (destroys everything)
./cleanup.sh
```

## Dashboard Visualization Ideas

- Alert severity over time
- Top source/destination IPs
- Geographic distribution of traffic
- Protocol distribution
- HTTP status codes
- DNS query types
- Network flow patterns

## Troubleshooting

### Common Issues

**Logstash Template Configuration Error**
- If you see "Invalid setting for opensearch output plugin: template", the Logstash configuration has been fixed
- Restart Logstash: `docker compose restart logstash`

**No Data Appearing**
- Check if Suricata is generating logs: `docker exec suricata tail -f /var/log/suricata/eve.json`
- Ensure your network interface has traffic to monitor
- Check Logstash logs for parsing errors: `docker compose logs logstash`
- Verify OpenSearch is receiving data via API calls

**Container Issues**
- If no data appears, check if Suricata is generating logs
- Ensure Logstash is running and processing logs
- Check OpenSearch cluster health via admin dashboard
- Run `./setup.sh` if you get mount errors
- Admin dashboard shows container stats - check if all services are running

**Index Template Issues**
- OpenSearch will automatically create index templates for `suricata-*` indices
- If you need custom mappings, they can be added via OpenSearch Dashboard or API calls

## Complete Cleanup

To destroy all Docker resources and start fresh:
```bash
chmod +x cleanup.sh
./cleanup.sh
```

This will remove:
- All containers
- All volumes (including data)
- All networks
- All related Docker images
- Build cache

**Note**: Configuration files will remain intact for redeployment.
