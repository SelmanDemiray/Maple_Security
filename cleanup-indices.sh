#!/bin/bash
#
# Maple Security - OpenSearch Index Management Script
# This script consolidates all security data into a single unified index with ML features
#

set -e

# OpenSearch connection details
OPENSEARCH_URL=${OPENSEARCH_URL:-"http://localhost:9200"}
MAPLE_INDEX="maple-security"
FORCE_FLAG=false

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check for force flag
if [ "$1" == "--force" ]; then
    FORCE_FLAG=true
    echo -e "${YELLOW}⚠️  Force mode enabled - will delete existing indices without confirmation${NC}"
fi

# Function to check if OpenSearch is available
check_opensearch() {
    echo -e "${BLUE}📡 Checking OpenSearch availability...${NC}"
    
    for i in {1..30}; do
        if curl -s -f "${OPENSEARCH_URL}/_cluster/health" > /dev/null; then
            echo -e "${GREEN}✅ OpenSearch is running and accessible${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
    done
    
    echo -e "\n${RED}❌ Error: Could not connect to OpenSearch at ${OPENSEARCH_URL}${NC}"
    echo "Please ensure OpenSearch is running and accessible."
    exit 1
}

# Function to list all current indices
list_indices() {
    echo -e "${BLUE}📊 Current indices in OpenSearch:${NC}"
    curl -s "${OPENSEARCH_URL}/_cat/indices?v" | grep -v "^\\."
    echo ""
}

# Function to delete daily fragmented indices
delete_fragmented_indices() {
    echo -e "${YELLOW}🧹 Cleaning up fragmented daily indices...${NC}"
    
    # Get list of suricata daily indices
    DAILY_INDICES=$(curl -s "${OPENSEARCH_URL}/_cat/indices/suricata-*?h=index" | tr -d ' ')
    
    if [ -z "$DAILY_INDICES" ]; then
        echo -e "${GREEN}✅ No daily indices found to clean up${NC}"
        return
    fi
    
    echo -e "${YELLOW}The following indices will be deleted:${NC}"
    echo "$DAILY_INDICES" | tr ' ' '\n'
    
    if [ "$FORCE_FLAG" != "true" ]; then
        echo -e "${YELLOW}❓ Do you want to proceed with deletion? (y/n)${NC}"
        read -r confirm
        if [ "$confirm" != "y" ]; then
            echo "Aborted."
            exit 0
        fi
    fi
    
    # Delete each daily index
    for index in $DAILY_INDICES; do
        echo -e "🗑️  Deleting index: ${index}..."
        curl -s -X DELETE "${OPENSEARCH_URL}/${index}" > /dev/null
    done
    
    # Also delete top_queries indices
    TOP_QUERIES_INDICES=$(curl -s "${OPENSEARCH_URL}/_cat/indices/top_queries-*?h=index" | tr -d ' ')
    if [ -n "$TOP_QUERIES_INDICES" ]; then
        echo -e "${YELLOW}🧹 Cleaning up top_queries indices...${NC}"
        for index in $TOP_QUERIES_INDICES; do
            echo -e "🗑️  Deleting index: ${index}..."
            curl -s -X DELETE "${OPENSEARCH_URL}/${index}" > /dev/null
        done
    fi
    
    echo -e "${GREEN}✅ Successfully removed all fragmented indices${NC}"
}

# Function to create security index template with ML features
create_security_template() {
    echo -e "${BLUE}📝 Creating ML-ready security index template...${NC}"
    
    curl -s -X PUT "${OPENSEARCH_URL}/_template/maple-security-template" -H 'Content-Type: application/json' -d '{
        "index_patterns": ["maple-security*"],
        "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 1,
            "index.mapping.total_fields.limit": 2000,
            "index.plugins.index_state_management.rollover_alias": "maple-security"
        },
        "mappings": {
            "properties": {
                "@timestamp": {
                    "type": "date"
                },
                "event_type": {
                    "type": "keyword"
                },
                "src_ip": {
                    "type": "ip"
                },
                "dest_ip": {
                    "type": "ip"
                },
                "src_port": {
                    "type": "integer"
                },
                "dest_port": {
                    "type": "integer"
                },
                "proto": {
                    "type": "keyword"
                },
                "alert": {
                    "properties": {
                        "signature_id": {
                            "type": "integer"
                        },
                        "signature": {
                            "type": "keyword"
                        },
                        "category": {
                            "type": "keyword"
                        },
                        "severity": {
                            "type": "integer"
                        }
                    }
                },
                "ml_features": {
                    "properties": {
                        "risk_score": {
                            "type": "float"
                        },
                        "anomaly_score": {
                            "type": "float"
                        },
                        "is_anomaly": {
                            "type": "boolean"
                        },
                        "threat_level": {
                            "type": "keyword"
                        },
                        "predictions": {
                            "type": "object",
                            "enabled": false
                        }
                    }
                },
                "flow_id": {
                    "type": "keyword"
                },
                "network_segment": {
                    "type": "keyword"
                },
                "geoip": {
                    "properties": {
                        "country_name": {
                            "type": "keyword"
                        },
                        "city_name": {
                            "type": "keyword"
                        },
                        "latitude": {
                            "type": "float"
                        },
                        "longitude": {
                            "type": "float"
                        }
                    }
                }
            }
        }
    }' > /dev/null
    
    echo -e "${GREEN}✅ ML-ready template created successfully${NC}"
}

# Function to create unified security index
create_unified_index() {
    echo -e "${BLUE}🛠️ Creating unified security index: ${MAPLE_INDEX}${NC}"
    
    # Check if index already exists
    if curl -s -f "${OPENSEARCH_URL}/${MAPLE_INDEX}" > /dev/null; then
        if [ "$FORCE_FLAG" == "true" ]; then
            echo -e "${YELLOW}⚠️  Index ${MAPLE_INDEX} already exists, deleting...${NC}"
            curl -s -X DELETE "${OPENSEARCH_URL}/${MAPLE_INDEX}" > /dev/null
        else
            echo -e "${YELLOW}⚠️  Index ${MAPLE_INDEX} already exists.${NC}"
            echo -e "${YELLOW}❓ Do you want to delete and recreate it? (y/n)${NC}"
            read -r confirm
            if [ "$confirm" == "y" ]; then
                curl -s -X DELETE "${OPENSEARCH_URL}/${MAPLE_INDEX}" > /dev/null
            else
                echo "Skipping index creation."
                return
            fi
        fi
    fi
    
    # Create the index with proper settings and ML-ready mappings
    curl -s -X PUT "${OPENSEARCH_URL}/${MAPLE_INDEX}" -H 'Content-Type: application/json' -d '{
        "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 1,
            "index.mapping.total_fields.limit": 2000
        },
        "mappings": {
            "properties": {
                "@timestamp": {
                    "type": "date"
                },
                "event_type": {
                    "type": "keyword"
                },
                "ml_features": {
                    "properties": {
                        "risk_score": {
                            "type": "float"
                        },
                        "anomaly_score": {
                            "type": "float"
                        },
                        "is_anomaly": {
                            "type": "boolean"
                        }
                    }
                }
            }
        }
    }' > /dev/null
    
    echo -e "${GREEN}✅ Created unified security index: ${MAPLE_INDEX}${NC}"
}

# Function to create index lifecycle policy
create_index_policy() {
    echo -e "${BLUE}📜 Creating index lifecycle management policy...${NC}"
    
    curl -s -X PUT "${OPENSEARCH_URL}/_opendistro/_ism/policies/maple-security-policy" -H 'Content-Type: application/json' -d '{
        "policy": {
            "description": "Security data management policy",
            "default_state": "hot",
            "states": [
                {
                    "name": "hot",
                    "actions": [],
                    "transitions": [
                        {
                            "state_name": "warm",
                            "conditions": {
                                "min_index_age": "7d"
                            }
                        }
                    ]
                },
                {
                    "name": "warm",
                    "actions": [
                        {
                            "force_merge": {
                                "max_num_segments": 1
                            }
                        }
                    ],
                    "transitions": [
                        {
                            "state_name": "delete",
                            "conditions": {
                                "min_index_age": "30d"
                            }
                        }
                    ]
                },
                {
                    "name": "delete",
                    "actions": [
                        {
                            "delete": {}
                        }
                    ],
                    "transitions": []
                }
            ]
        }
    }' > /dev/null
    
    echo -e "${GREEN}✅ Index lifecycle policy created${NC}"
}

# Function to update Logstash configuration
update_logstash_config() {
    echo -e "${BLUE}🔄 Updating Logstash configuration to use unified index...${NC}"
    
    # Get logstash container ID
    LOGSTASH_ID=$(docker ps -qf "name=logstash")
    
    if [ -z "$LOGSTASH_ID" ]; then
        echo -e "${RED}❌ Logstash container not found. Cannot update configuration.${NC}"
        return 1
    fi
    
    echo "Restarting Logstash to apply new configuration..."
    docker restart "$LOGSTASH_ID" > /dev/null
    
    echo -e "${GREEN}✅ Logstash configuration updated and service restarted${NC}"
}

# Function to enable ML plugins in OpenSearch
enable_ml_plugins() {
    echo -e "${BLUE}🤖 Enabling ML plugins in OpenSearch...${NC}"
    
    # Check if ML plugin config index exists, if not create it
    if ! curl -s -f "${OPENSEARCH_URL}/.plugins-ml-config" > /dev/null; then
        curl -s -X PUT "${OPENSEARCH_URL}/.plugins-ml-config" -H 'Content-Type: application/json' -d '{
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 0,
                "auto_expand_replicas": "0-1"
            }
        }' > /dev/null
        
        echo "Created ML plugin configuration index"
    fi
    
    # Enable anomaly detection settings
    curl -s -X PUT "${OPENSEARCH_URL}/_cluster/settings" -H 'Content-Type: application/json' -d '{
        "persistent": {
            "plugins.anomaly_detection.enabled": true,
            "plugins.ml_commons.model_access_control_enabled": true,
            "plugins.ml_commons.native_memory_threshold": 90,
            "plugins.ml_commons.allow_custom_deployment_plan": true
        }
    }' > /dev/null
    
    echo -e "${GREEN}✅ ML plugins configured successfully${NC}"
}

# Main execution
echo -e "${BLUE}🍁 Maple Security - Index Management Script${NC}"
echo -e "${BLUE}=========================================${NC}"

# Check OpenSearch availability
check_opensearch

# Show current indices
list_indices

# Delete fragmented daily indices
delete_fragmented_indices

# Create ML-ready template
create_security_template

# Create unified index
create_unified_index

# Create index lifecycle policy
create_index_policy

# Enable ML plugins
enable_ml_plugins

# Update Logstash and restart service
update_logstash_config

echo -e "\n${GREEN}✅ Index management tasks completed successfully!${NC}"
echo -e "${BLUE}📊 Current indices after cleanup:${NC}"
list_indices

echo -e "\n${BLUE}🔍 ML features are now available in OpenSearch Dashboards:${NC}"
echo -e "  - Anomaly Detection"
echo -e "  - ML Commons"
echo -e "  - Index Lifecycle Management"
echo -e "  - Risk Scoring"
echo -e "\n${BLUE}📋 Next steps:${NC}"
echo -e "  1. Access OpenSearch Dashboards at http://localhost:5601"
echo -e "  2. Create visualizations using the new unified index: ${MAPLE_INDEX}"
echo -e "  3. Set up anomaly detectors in the ML section"
