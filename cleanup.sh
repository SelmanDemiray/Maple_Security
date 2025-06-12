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
docker volume rm maple_security_suricata-logs 2>/dev/null || true
docker volume rm maple_security_opensearch-data 2>/dev/null || true

# Remove the custom network
echo "Removing custom networks..."
docker network rm sec_opensearch-net 2>/dev/null || true
docker network rm opensearch-net 2>/dev/null || true
docker network rm maple_security_opensearch-net 2>/dev/null || true

# Clean up any dangling networks
docker network prune -f

# Remove ALL related images (more comprehensive approach)
echo "Removing Docker images..."

# Remove Suricata images (all versions)
docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "suricata|jasonish" | xargs -r docker rmi 2>/dev/null || true

# Remove OpenSearch images (all versions)
docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "opensearch" | xargs -r docker rmi 2>/dev/null || true

# Remove Logstash images (all versions)
docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "logstash" | xargs -r docker rmi 2>/dev/null || true

# Remove admin dashboard images
docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "admin-dashboard|maple_security" | xargs -r docker rmi 2>/dev/null || true

# Remove Node.js base images that were used for building
docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "^node:" | xargs -r docker rmi 2>/dev/null || true

# Alternative approach - remove by image ID for anything that might be missed
echo "Removing any remaining related images by pattern..."
docker images | grep -E "(suricata|opensearch|logstash|admin-dashboard|maple_security)" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true

# Clean up any dangling images
echo "Cleaning up dangling images..."
docker image prune -f

# More aggressive cleanup for untagged images
echo "Removing untagged images..."
docker image prune -a -f

# Clean up build cache
echo "Cleaning up build cache..."
docker builder prune -f --all 2>/dev/null || docker system prune -f

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

# Check for remaining images
echo ""
echo "Checking for remaining related images..."
REMAINING_IMAGES=$(docker images | grep -E "(suricata|opensearch|logstash|admin-dashboard|maple_security)" || true)
if [ -n "$REMAINING_IMAGES" ]; then
  echo "⚠️  WARNING: Some related images still remain:"
  echo "$REMAINING_IMAGES"
  echo ""
  echo "To force remove these images, run:"
  echo "docker rmi -f \$(docker images | grep -E '(suricata|opensearch|logstash|admin-dashboard|maple_security)' | awk '{print \$3}')"
else
  echo "✅ All related images successfully removed!"
fi

# Final system cleanup
echo ""
echo "Running final system cleanup..."
docker system prune -a -f --volumes

echo ""
echo "✅ CLEANUP COMPLETE!"
echo "All Docker resources have been destroyed."
echo "The local configuration files remain intact."
echo ""
echo "Current Docker storage usage:"
docker system df
echo ""
echo "To rebuild the stack:"
echo "  docker compose up -d"