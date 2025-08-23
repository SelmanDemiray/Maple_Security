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

## 📊 Service Access

- **OpenSearch API**: http://localhost:9200
- **OpenSearch Dashboards**: http://localhost:5601

## 🛡️ Unified Security Index

### **Single Security Index: `maple-security`**
- ✅ **Unified Data**: All security events in one index
- ✅ **ML-Ready**: Built-in risk scoring and threat classification  
- ✅ **Clean Organization**: No more daily fragmented indices
- ✅ **Index Lifecycle Management**: Automatic data retention policies
- ✅ **Anomaly Detection**: ML-powered security event analysis

### **Machine Learning Features**
- 🤖 **Anomaly Detection**: Automatic detection of unusual security patterns
- 📊 **Risk Scoring**: AI-powered threat level assessment (0-100)
- 🔍 **Threat Classification**: Automatic categorization of security events
- 📈 **Behavioral Analysis**: Learning normal vs. abnormal network behavior

## 🔧 Working with OpenSearch Dashboards

After setting up the unified index, you can:

1. Log into OpenSearch Dashboards at http://localhost:5601
2. Create index pattern for `maple-security`
3. Create visualizations using the unified index
4. Set up anomaly detectors in the Machine Learning section
5. Use the pre-configured ML features for threat detection

## 📋 Index Management

The `cleanup-indices.sh` script manages the security indices:

```bash
# Run with --force to skip confirmations
./cleanup-indices.sh --force
```

This script will:
- Delete fragmented daily indices (suricata-YYYY.MM.DD)
- Create a unified `maple-security` index
- Set up ML-ready index templates
- Configure index lifecycle management
- Enable ML plugins and features
- Update Logstash to send data to the unified index
- Delete fragmented daily indices (suricata-YYYY.MM.DD)
- Create a unified `maple-security` index
- Set up ML-ready index templates
- Configure index lifecycle management
- Enable ML plugins and features
- Update Logstash to send data to the unified index
- Update Logstash to send data to the unified index
