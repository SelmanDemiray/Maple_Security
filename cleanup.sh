#!/bin/bash

echo "🔥 DESTROYING ALL DOCKER RESOURCES FOR SECURITY MONITORING STACK 🔥"
echo "This will remove ALL containers, volumes, networks, and images!"
echo ""

# Stop and remove all containers from this compose
echo "Stopping and removing containers..."
docker compose down --remove-orphans 2>/dev/null || true

# Find and stop any remaining containers by name pattern
echo "Checking for remaining security stack containers..."
CONTAINERS=$(docker ps -a --filter "name=suricata" --filter "name=logstash" --filter "name=opensearch" --filter "name=opensearch-node" --filter "name=admin-dashboard" --format "{{.ID}}")

if [ -n "$CONTAINERS" ]; then
  echo "Found remaining containers, forcing removal..."
  docker stop $CONTAINERS 2>/dev/null || true
  docker rm $CONTAINERS 2>/dev/null || true
fi

# Remove all volumes (including data)
echo "Removing all volumes..."
docker compose down -v 2>/dev/null || true

# Remove any dangling volumes that might be left
echo "Cleaning up dangling volumes..."
docker volume prune -f

# Remove the specific volumes by name if they still exist
echo "Removing specific volumes..."
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

# Verify all containers are gone
REMAINING=$(docker ps -a --filter "name=suricata" --filter "name=logstash" --filter "name=opensearch" --filter "name=opensearch-node" --filter "name=admin-dashboard" --format "{{.Names}}")
if [ -n "$REMAINING" ]; then
  echo ""
  echo "⚠️  WARNING: Some containers still remain after cleanup:"
  echo "$REMAINING"
  echo "You may need to remove them manually with: docker rm -f [container_id]"
else
  echo ""
  echo "✅ All specified containers successfully removed!"
fi

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
