#!/bin/bash

echo "🔥 DESTROYING ALL DOCKER RESOURCES FOR SURICATA STACK 🔥"
echo "This will remove ALL containers, volumes, networks, and images!"
echo ""

# Stop and remove all containers from this compose
echo "Stopping and removing containers..."
docker compose down --remove-orphans 2>/dev/null || true

# Remove all volumes (including data)
echo "Removing all volumes..."
docker compose down -v 2>/dev/null || true

# Remove any dangling volumes that might be left
echo "Cleaning up dangling volumes..."
docker volume prune -f

# Remove the specific volumes by name if they still exist
docker volume rm sec_suricata-logs 2>/dev/null || true
docker volume rm sec_opensearch-data 2>/dev/null || true
docker volume rm suricata-logs 2>/dev/null || true
docker volume rm opensearch-data 2>/dev/null || true

# Remove the custom network
echo "Removing custom networks..."
docker network rm sec_opensearch-net 2>/dev/null || true
docker network rm opensearch-net 2>/dev/null || true

# Clean up any dangling networks
docker network prune -f

# Remove all related images
echo "Removing Docker images..."
docker rmi jasonish/suricata:latest 2>/dev/null || true
docker rmi opensearchproject/logstash-oss-with-opensearch-output-plugin:latest 2>/dev/null || true
docker rmi opensearchproject/opensearch:latest 2>/dev/null || true
docker rmi opensearchproject/opensearch-dashboards:latest 2>/dev/null || true

# Clean up any dangling images
docker image prune -f

# Clean up build cache
echo "Cleaning up build cache..."
docker builder prune -f

# Final system cleanup
echo "Running final system cleanup..."
docker system prune -f

echo ""
echo "✅ CLEANUP COMPLETE!"
echo "All Docker resources have been destroyed."
echo "The local configuration files remain intact."
echo ""
echo "To rebuild the stack:"
echo "  docker compose up -d"
