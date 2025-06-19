#!/bin/bash

echo "🍁 Maple Security Stack - Service Status"
echo "========================================"
echo ""

# Check Docker containers
echo "📊 Container Status:"
echo "==================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|admin-dashboard|opensearch|logstash|suricata|pihole)"
echo ""

# Check OpenSearch health
echo "🔍 OpenSearch Health:"
echo "===================="
curl -s http://localhost:9200/_cluster/health?pretty | jq -r '. | "Status: \(.status) | Nodes: \(.number_of_nodes) | Shards: \(.active_shards)/\(.active_primary_shards)"'
echo ""

# Check indices
echo "📋 Security Indices:"
echo "==================="
curl -s "http://localhost:9200/_cat/indices/maple-security*?v"
echo ""

# Check OpenSearch Dashboards
echo "🎛️ OpenSearch Dashboards:"
echo "========================="
if curl -s http://localhost:5601/api/status | grep -q "green"; then
    echo "✅ OpenSearch Dashboards: HEALTHY"
else
    echo "❌ OpenSearch Dashboards: NOT RESPONDING"
fi
echo ""

# Check Admin Dashboard
echo "⚙️ Admin Dashboard:"
echo "=================="
if curl -s http://localhost:3000/api/health | grep -q "cluster_name"; then
    echo "✅ Admin Dashboard: HEALTHY"
else
    echo "❌ Admin Dashboard: NOT RESPONDING"
fi
echo ""

# Check Pi-hole
echo "🛡️ Pi-hole Status:"
echo "=================="
if docker exec pihole pihole status | grep -q "enabled"; then
    echo "✅ Pi-hole: ACTIVE & BLOCKING"
    docker exec pihole pihole -c | grep -E "(Domains|Blocklist)"
else
    echo "❌ Pi-hole: NOT ACTIVE"
fi
echo ""

echo "🌐 Service URLs:"
echo "==============="
echo "• Admin Dashboard: http://localhost:3000"
echo "• OpenSearch API: http://localhost:9200"
echo "• OpenSearch Dashboards: http://localhost:5601"
echo "• Pi-hole Admin: http://localhost:8080/admin"
echo "  - Username: admin"
echo "  - Password: MapleSecure2024!"
echo ""
echo "🚀 Stack is ready for security monitoring!"
