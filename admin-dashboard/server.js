const express = require('express');
const axios = require('axios');
const Docker = require('dockerode');
const cors = require('cors');
const path = require('path');
const { spawn } = require('child_process');

const app = express();
const docker = new Docker();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// OpenSearch connection
const OPENSEARCH_URL = process.env.OPENSEARCH_URL || 'http://opensearch:9200';

// Helper function to calculate CPU percentage
function calculateCPUPercentage(stats) {
  const cpuDelta = stats.cpu_stats.cpu_usage.total_usage - stats.precpu_stats.cpu_usage.total_usage;
  const systemDelta = stats.cpu_stats.system_cpu_usage - stats.precpu_stats.system_cpu_usage;
  const numberCpus = stats.cpu_stats.online_cpus;
  
  if (systemDelta > 0 && cpuDelta > 0) {
    return (cpuDelta / systemDelta) * numberCpus * 100;
  }
  return 0;
}

// API Routes
app.get('/api/health', async (req, res) => {
  try {
    const response = await axios.get(`${OPENSEARCH_URL}/_cluster/health`);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'OpenSearch health check failed' });
  }
});

app.get('/api/indices', async (req, res) => {
  try {
    const response = await axios.get(`${OPENSEARCH_URL}/_cat/indices/suricata-*?format=json&h=index,health,status,docs.count,store.size,creation.date`);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch indices' });
  }
});

app.get('/api/containers', async (req, res) => {
  try {
    const containers = await docker.listContainers({ all: true });
    const suricataContainers = containers.filter(container => 
      container.Names.some(name => 
        name.includes('suricata') || 
        name.includes('logstash') || 
        name.includes('opensearch') ||
        name.includes('admin-dashboard') ||
        name.includes('pihole')
      )
    );

    const containerStats = await Promise.all(
      suricataContainers.map(async (container) => {
        try {
          const containerObj = docker.getContainer(container.Id);
          const [stats, inspect] = await Promise.all([
            containerObj.stats({ stream: false }).catch(() => null),
            containerObj.inspect().catch(() => null)
          ]);

          const result = {
            name: container.Names[0].replace('/', ''),
            status: container.State,
            created: container.Created,
            restart_count: inspect?.RestartCount || 0,
            last_started: inspect?.State?.StartedAt,
            exit_code: inspect?.State?.ExitCode,
            error: inspect?.State?.Error
          };

          if (stats) {
            result.cpu_usage = calculateCPUPercentage(stats);
            result.memory_usage = stats.memory_stats.usage || 0;
            result.memory_limit = stats.memory_stats.limit || 0;
            result.network_rx = stats.networks?.eth0?.rx_bytes || 0;
            result.network_tx = stats.networks?.eth0?.tx_bytes || 0;
          }

          return result;
        } catch (error) {
          return {
            name: container.Names[0].replace('/', ''),
            status: container.State,
            created: container.Created,
            error: 'Stats unavailable: ' + error.message
          };
        }
      })
    );

    res.json(containerStats);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch container stats: ' + error.message });
  }
});

app.get('/api/logs/:service', async (req, res) => {
  const serviceName = req.params.service;
  const lines = req.query.lines || '50';
  
  try {
    const containers = await docker.listContainers();
    const container = containers.find(c => 
      c.Names.some(name => name.includes(serviceName))
    );

    if (!container) {
      return res.status(404).send(`Container ${serviceName} not found`);
    }

    const containerObj = docker.getContainer(container.Id);
    const logs = await containerObj.logs({
      stdout: true,
      stderr: true,
      tail: parseInt(lines),
      timestamps: true
    });

    // Clean up Docker log format
    const cleanLogs = logs.toString()
      .split('\n')
      .map(line => line.replace(/^\x01\x00\x00\x00.{4}/, '').replace(/^\x02\x00\x00\x00.{4}/, ''))
      .filter(line => line.trim())
      .join('\n');

    res.set('Content-Type', 'text/plain');
    res.send(cleanLogs);
  } catch (error) {
    res.status(500).send(`Error fetching logs: ${error.message}`);
  }
});

app.get('/api/validate', async (req, res) => {
  const checks = [];

  try {
    // Check OpenSearch connectivity
    try {
      await axios.get(`${OPENSEARCH_URL}/_cluster/health`, { timeout: 5000 });
      checks.push({
        name: 'OpenSearch Connection',
        status: 'pass',
        message: 'Successfully connected to OpenSearch'
      });
    } catch (error) {
      checks.push({
        name: 'OpenSearch Connection',
        status: 'fail',
        message: 'Cannot connect to OpenSearch: ' + error.message
      });
    }

    // Check for Suricata logs
    try {
      const containers = await docker.listContainers();
      const suricataContainer = containers.find(c => 
        c.Names.some(name => name.includes('suricata'))
      );
      
      if (suricataContainer) {
        if (suricataContainer.State === 'running') {
          checks.push({
            name: 'Suricata Status',
            status: 'pass',
            message: 'Suricata is running'
          });
        } else {
          checks.push({
            name: 'Suricata Status',
            status: 'fail',
            message: `Suricata is ${suricataContainer.State}`
          });
        }
      } else {
        checks.push({
          name: 'Suricata Status',
          status: 'fail',
          message: 'Suricata container not found'
        });
      }
    } catch (error) {
      checks.push({
        name: 'Suricata Status',
        status: 'fail',
        message: 'Cannot check Suricata status: ' + error.message
      });
    }

    // Check Logstash status
    try {
      const containers = await docker.listContainers();
      const logstashContainer = containers.find(c => 
        c.Names.some(name => name.includes('logstash'))
      );
      
      if (logstashContainer && logstashContainer.State === 'running') {
        checks.push({
          name: 'Logstash Status',
          status: 'pass',
          message: 'Logstash is running'
        });
      } else {
        checks.push({
          name: 'Logstash Status',
          status: 'warning',
          message: logstashContainer ? `Logstash is ${logstashContainer.State}` : 'Logstash container not found'
        });
      }
    } catch (error) {
      checks.push({
        name: 'Logstash Status',
        status: 'fail',
        message: 'Cannot check Logstash status: ' + error.message
      });
    }

    // Check for data in OpenSearch
    try {
      const response = await axios.post(`${OPENSEARCH_URL}/suricata-*/_search`, {
        size: 1,
        query: { match_all: {} }
      });
      
      const hitCount = response.data.hits.total.value || response.data.hits.total;
      if (hitCount > 0) {
        checks.push({
          name: 'Data Pipeline',
          status: 'pass',
          message: `Found ${hitCount} documents in Suricata indices`
        });
      } else {
        checks.push({
          name: 'Data Pipeline',
          status: 'warning',
          message: 'No data found in Suricata indices - check if logs are being generated'
        });
      }
    } catch (error) {
      checks.push({
        name: 'Data Pipeline',
        status: 'warning',
        message: 'Cannot verify data pipeline: ' + error.message
      });
    }

    // Check disk space
    try {
      const stats = await axios.get(`${OPENSEARCH_URL}/_nodes/stats/fs`);
      const nodeStats = Object.values(stats.data.nodes)[0];
      const freeBytes = nodeStats.fs.total.free_in_bytes;
      const totalBytes = nodeStats.fs.total.total_in_bytes;
      const freePercent = (freeBytes / totalBytes) * 100;
      
      if (freePercent > 15) {
        checks.push({
          name: 'Disk Space',
          status: 'pass',
          message: `${freePercent.toFixed(1)}% free space available`
        });
      } else if (freePercent > 5) {
        checks.push({
          name: 'Disk Space',
          status: 'warning',
          message: `Only ${freePercent.toFixed(1)}% free space remaining`
        });
      } else {
        checks.push({
          name: 'Disk Space',
          status: 'fail',
          message: `Critical: Only ${freePercent.toFixed(1)}% free space remaining`
        });
      }
    } catch (error) {
      checks.push({
        name: 'Disk Space',
        status: 'warning',
        message: 'Cannot check disk space: ' + error.message
      });
    }

    res.json({ checks });
  } catch (error) {
    res.status(500).json({ error: 'Validation failed: ' + error.message });
  }
});

// Enhanced stats endpoint
app.get('/api/stats', async (req, res) => {
  try {
    const [healthResponse, indicesResponse, alertsResponse] = await Promise.all([
      axios.get(`${OPENSEARCH_URL}/_cluster/health`),
      axios.get(`${OPENSEARCH_URL}/_cat/indices/suricata-*?format=json`),
      axios.post(`${OPENSEARCH_URL}/suricata-*/_search`, {
        size: 0,
        query: { 
          range: { 
            "@timestamp": { 
              gte: "now-1h" 
            } 
          } 
        },
        aggs: {
          event_types: {
            terms: { field: 'event_type', size: 10 }
          },
          alerts_by_severity: {
            terms: { field: 'alert.severity', size: 10 }
          },
          hourly_events: {
            date_histogram: {
              field: '@timestamp',
              calendar_interval: '1h'
            }
          },
          recent_events: {
            date_histogram: {
              field: '@timestamp',
              calendar_interval: '1m'
            }
          }
        }
      })
    ]);

    const totalDocs = indicesResponse.data.reduce((sum, index) => sum + parseInt(index['docs.count'] || 0), 0);
    const totalSize = indicesResponse.data.reduce((sum, index) => {
      const sizeStr = index['store.size'] || '0b';
      const sizeValue = parseFloat(sizeStr.replace(/[kmgt]b/i, ''));
      const unit = sizeStr.toLowerCase().slice(-2);
      let multiplier = 1;
      if (unit.includes('k')) multiplier = 1024;
      else if (unit.includes('m')) multiplier = 1024 * 1024;
      else if (unit.includes('g')) multiplier = 1024 * 1024 * 1024;
      return sum + (sizeValue * multiplier);
    }, 0);

    // Calculate ingestion rate
    const recentBuckets = alertsResponse.data.aggregations?.recent_events?.buckets || [];
    const lastMinute = recentBuckets[recentBuckets.length - 1];
    const ingestionRate = lastMinute ? (lastMinute.doc_count / 60).toFixed(2) : '0';

    res.json({
      cluster_health: healthResponse.data,
      total_documents: totalDocs,
      total_size: totalSize / (1024 * 1024 * 1024), // Convert to GB
      indices_count: indicesResponse.data.length,
      ingestion_rate: ingestionRate,
      last_update: new Date().toLocaleTimeString(),
      aggregations: alertsResponse.data.aggregations
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch stats: ' + error.message });
  }
});

// Pi-hole API endpoints
app.get('/api/pihole/status', async (req, res) => {
  try {
    const response = await axios.get('http://pihole:80/admin/api.php');
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Pi-hole status check failed: ' + error.message });
  }
});

app.get('/api/pihole/summary', async (req, res) => {
  try {
    const response = await axios.get('http://pihole:80/admin/api.php?summary');
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Pi-hole summary failed: ' + error.message });
  }
});

app.get('/api/pihole/querytypes', async (req, res) => {
  try {
    const response = await axios.get('http://pihole:80/admin/api.php?queryTypesOverTime');
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Pi-hole query types failed: ' + error.message });
  }
});

// Serve the dashboard
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Admin dashboard running on port ${PORT}`);
});
