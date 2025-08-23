# Maple Security Stack - Unified ML-Enhanced Security Monitoring

## 🚀 Quick Start

1. **Initial Setup**:
```bash
chmod +x setup.sh
./setup.sh
```

2. **Start the Stack**:
```bash
docker compose up -d
```

3. **Clean & Setup Unified Index** (Important - Run after stack is up):
```bash
./cleanup-indices.sh --force
```

## 🔧 New Unified Security Index

### **Single Security Index: `maple-security`**
- ✅ **Unified Data**: All security events in one index
- ✅ **ML-Ready**: Built-in risk scoring and threat classification  
- ✅ **Clean Organization**: No more daily fragmented indices
- ✅ **Index Lifecycle Management**: Automatic data retention policies
- ✅ **Anomaly Detection**: ML-powered security event analysis

### **Machine Learning Features**
- 🤖 **Anomaly Detection**: Automatic detection of unusual security patterns
- 📊 **Risk Scoring**: AI-powered threat level assessment (0-100)
- 🔍 **Behavioral Analysis**: ML models for network traffic patterns
- 🎯 **Predictive Alerts**: Early warning system for potential threats
- 📈 **Trend Analysis**: ML-driven security trend identification

## 🎯 Access Your Services

- **🛡️ Security Dashboard**: http://localhost:5601 *(Main ML-enhanced security interface)*
- **📡 OpenSearch API**: http://localhost:9200 *(Direct API access)*

## 📊 Index Management

### **Primary Index**: `maple-security`
- **Index Pattern**: `maple-security*` 
- **Time Field**: `@timestamp`
- **Data Retention**: 1 year (configurable)
- **ML Features**: Risk scoring, anomaly detection, behavioral analysis

### **Index Lifecycle**:
- **Hot Phase**: 0-30 days (active indexing and searching)
- **Warm Phase**: 30-90 days (read-only, reduced replicas)  
- **Cold Phase**: 90-365 days (compressed storage)
- **Delete Phase**: After 365 days (automatic cleanup)

### **Key Security Fields**:
- `risk_score` (0-100) - ML-calculated threat level
- `threat_level` (critical/high/medium/low) - Human-readable severity
- `event_classification` - Security event categorization
- `service_type` - Network service identification
- `src_network_type` / `dest_network_type` - Internal/external classification

## 🛠️ Management Scripts

- **`cleanup-indices.sh`** - Clean old indices, create unified security index
- **`setup.sh`** - Initial directory and permission setup
- **`cleanup.sh`** - Complete stack removal and cleanup

## 🔍 Security Event Types

The unified index captures and enriches:
- **Network Alerts** - Suricata IDS/IPS detections
- **HTTP/HTTPS Traffic** - Web traffic monitoring
- **Flow Data** - Network connection analysis
- **TLS Events** - Certificate and encryption monitoring
- **Anomaly Detections** - ML-identified unusual patterns

## 📈 ML-Enhanced Analytics

### **Risk Scoring Algorithm**:
- Alert severity mapping (1=Critical:100, 2=High:75, 3=Medium:50, 4=Low:25)
- Geographic risk factors (external IPs weighted higher)
- Protocol and service risk assessment
- Historical pattern analysis
- Behavioral anomaly weighting

### **Anomaly Detection Models**:
- **Traffic Volume**: Unusual data transfer patterns
- **Connection Patterns**: Abnormal network behaviors  
- **Geographic Anomalies**: Unexpected source countries
- **Time-based Patterns**: Activities outside normal hours
- **Protocol Anomalies**: Unusual service interactions

## 🚨 Security Alerting

Configure alerts for:
- High-risk events (risk_score > 75)
- Critical threat levels
- Anomaly detection triggers
- Unusual geographic activity
- Potential data exfiltration patterns

## 📋 Project Structure
```
/root/maple_sec/Maple_Security/
├── docker-compose.yml               # Updated with ML features
├── setup.sh                        # Initial setup script
├── cleanup.sh                      # Complete cleanup script
├── cleanup-indices.sh              # NEW: Index cleanup & ML setup
├── README.md                       # This file
├── suricata/
│   ├── config/
│   │   └── suricata.yaml
│   └── rules/
│       └── suricata.rules
├── logstash/
│   ├── config/
│   │   └── logstash.yml
│   ├── pipeline/
│   │   └── logstash.conf           # Updated for unified index
│   └── templates/
│       └── maple-security-template.json  # NEW: ML-ready mappings
├── opensearch-dashboards/          # NEW: ML-enabled dashboards
│   ├── opensearch_dashboards.yml
│   └── security-dashboard.json
```

## 🆕 Migration from Old Setup

If you have an existing setup with multiple `suricata-*` indices:

1. **Backup Important Data** (optional):
```bash
# Export any important dashboards/visualizations first
```

2. **Run the Migration**:
```bash
./cleanup-indices.sh
```

3. **Restart Stack** (if needed):
```bash
docker compose down
docker compose up -d
```

The migration script will:
- Remove old fragmented daily indices (`suricata-2025.06.*`)
- Remove query tracking indices (`top_queries-*`)
- Create the new unified `maple-security` index
- Enable ML features and anomaly detection
- Set up index lifecycle management
- Configure dashboard index patterns

## 🔧 Troubleshooting

### **Index Issues**:
```bash
# Check current indices
curl http://localhost:9200/_cat/indices?v

# Check index health
curl http://localhost:9200/_cluster/health?pretty

# Manually clean indices if needed
./cleanup-indices.sh --force
```

### **ML Features Not Working**:
```bash
# Check ML plugin status
curl http://localhost:9200/_plugins/_ml/stats

# Restart OpenSearch if needed
docker restart opensearch
```

### **Dashboard Issues**:
```bash
# Check dashboard logs
docker logs opensearch-dashboards

# Restart dashboards
docker restart opensearch-dashboards
```

## 🎯 Next Steps

1. **Configure Alerts**: Set up notifications for high-risk events
2. **Custom ML Models**: Train models on your specific network patterns  
3. **Dashboard Customization**: Create custom visualizations for your needs
4. **API Integration**: Connect external security tools via REST API
5. **Advanced Analytics**: Set up correlation rules and threat hunting queries

---

## 🛡️ Security Best Practices

- Regularly review ML anomaly detections
- Monitor risk score trends for unusual spikes
- Set up automated alerts for critical events
- Keep Suricata rules updated
- Monitor index growth and retention policies
## 🛡️ Security Best Practices

- Regularly review ML anomaly detections
- Monitor risk score trends for unusual spikes
- Set up automated alerts for critical events
- Keep Suricata rules updated
- Monitor index growth and retention policies
- Keep Suricata rules updated
- Monitor index growth and retention policies
## 🎯 Next Steps

1. **Configure Alerts**: Set up notifications for high-risk events
2. **Custom ML Models**: Train models on your specific network patterns  
3. **Dashboard Customization**: Create custom visualizations for your needs
4. **API Integration**: Connect external security tools via REST API
5. **Advanced Analytics**: Set up correlation rules and threat hunting queries

---

## 🛡️ Security Best Practices

- Regularly review ML anomaly detections
- Monitor risk score trends for unusual spikes
- Set up automated alerts for critical events
- Review Pi-hole DNS blocking statistics
- Keep Suricata rules updated
- Monitor index growth and retention policies
