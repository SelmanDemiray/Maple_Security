# Pi-hole Setup Issues & Solutions

## 🔍 Issues Identified

Based on your Pi-hole dashboard showing only "exit" domain and minimal blocked domains, here are the main issues:

### 1. **Blocklist Problem**
- Pi-hole is only using 1/205,191 lists effectively
- Multiple blocklists were added but not properly processed
- Gravity database is not incorporating all the configured lists

### 2. **Client Detection Problem**
- Only seeing localhost, router (192.168.0.1), and one client (192.168.0.219)
- Missing proper client name resolution
- Devices are not using Pi-hole as their DNS server

### 3. **"exit" Domain Issue**
- This is likely caused by health check queries or container communication
- The high frequency (417 hits) suggests it's from automated system queries

## 🔧 Solutions Applied

### Fixed Docker Configuration
I corrected the Pi-hole environment variables in `docker-compose.yml`:
- Fixed `FTLCONF_PRIVACYLEVEL` → `FTLCONF_dns_privacyLevel`
- Added proper listening mode configuration
- Improved query logging settings

### Fixed Blocklist Loading
- Updated gravity database
- Added multiple security-focused blocklists
- Currently shows ~206K blocked domains (should increase with all lists)

## 🚀 Next Steps Required

### 1. **Router Configuration** (Most Important)
You need to configure your router to use Pi-hole as the DNS server:

1. **Access your router** (usually http://192.168.0.1)
2. **Go to DHCP/DNS Settings**
3. **Set DNS servers:**
   - Primary DNS: `192.168.0.99` (your Pi-hole server)
   - Secondary DNS: `1.1.1.1` (CloudFlare as backup)
4. **Disable DNS Proxy/Relay** if present
5. **Save and restart router**

### 2. **Pi-hole Web Interface Setup**
Access http://localhost:8080/admin and configure:

1. **Settings > DNS > Conditional Forwarding:**
   - Enable "Use Conditional Forwarding"
   - Local network: `192.168.0.0/24`
   - Router IP: `192.168.0.1`
   - Local domain: `local`

2. **Settings > DNS > Interface listening behavior:**
   - Select "Listen on all interfaces"

### 3. **Verify Client Configuration**
Check that devices are getting the new DNS settings:
- **Windows:** `ipconfig /all` (look for DNS Servers)
- **Mac:** System Preferences > Network > Advanced > DNS
- **Linux:** `cat /etc/resolv.conf`
- **Mobile:** Check WiFi network settings

### 4. **Test DNS Resolution**
From any device on your network:
```bash
nslookup doubleclick.google.com 192.168.0.99
```
Should return: `0.0.0.0` (blocked) or similar

## 📊 Expected Results After Fix

Once properly configured, you should see:
- **Blocked domains:** 200K+ instead of just thousands
- **Client names:** All your network devices showing with proper names
- **Blocked queries:** Significant increase in blocked requests
- **Query types:** More diverse query patterns

## 🔍 Monitoring Progress

1. **Check Pi-hole dashboard** every 10-15 minutes for changes
2. **Monitor "Top Clients"** section for new devices appearing
3. **Watch "Top Blocked Domains"** for real ad/tracking domains
4. **Use Tools > Network Scan** in Pi-hole to detect devices

## ⚠️ Important Notes

- Changes may take 10-15 minutes to propagate
- Some devices cache DNS settings - restart them if needed
- Router changes affect all connected devices
- The "exit" domain should decrease once proper DNS routing is established

## 🆘 If Issues Persist

1. **Restart router** after DNS changes
2. **Flush DNS cache** on client devices
3. **Check firewall settings** (port 53 should be open)
4. **Try manual device DNS configuration** as a test
5. **Use `./diagnose-pihole-clients.sh`** for detailed troubleshooting
