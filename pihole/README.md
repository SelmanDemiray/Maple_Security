# Pi-hole Ad Lists Management

This directory contains the new modular Pi-hole ad lists management system.

## Files

- **`adlists.txt`** - Configuration file containing all ad lists (URLs and descriptions)
- **`init-pihole.sh`** - Initialization script (runs during container startup)
- **`../update-pihole-lists.sh`** - Standalone script to update Pi-hole with new ad lists

## Usage

### Adding/Removing Ad Lists

1. Edit the `adlists.txt` file to add or remove ad lists
2. Format: `URL|Description` (one per line)
3. Lines starting with `#` are comments and ignored
4. Blank lines are ignored

### Updating Pi-hole with New Lists

Run the update script from the main directory:

```bash
# From /root/maple_sec/Maple_Security/
./update-pihole-lists.sh
```

This script will:
- Read all ad lists from `pihole/adlists.txt`
- Add new lists to Pi-hole database
- Skip lists that already exist
- Run gravity update to download and process all lists
- Show detailed statistics and status
- Handle errors gracefully with retries

### Initial Setup

The system works automatically with Docker Compose:

1. Ad lists are loaded from `adlists.txt` during container initialization
2. If the file is missing, falls back to essential default lists
3. The adlists.txt file is mounted read-only into the container

### Features

- **Modular**: All ad lists in one configuration file
- **Organized**: Lists grouped by category (security, privacy, tracking, etc.)
- **Flexible**: Easy to enable/disable lists by commenting/uncommenting
- **Safe**: Read-only mount prevents accidental modifications
- **Automated**: Works with existing Docker Compose setup
- **Manual Updates**: Standalone script for adding new lists anytime

### Example adlists.txt Entry

```
# Comment explaining the category
https://example.com/blocklist.txt|Descriptive Name for List
https://another-list.com/hosts|Another Blocklist
# https://disabled-list.com/list|Disabled List (commented out)
```

### Troubleshooting

- If update script fails, ensure Pi-hole container is running
- Check Docker logs: `docker logs pihole`
- Verify adlists.txt format (URL|Description)
- Run gravity update manually: `docker exec pihole pihole updateGravity`
