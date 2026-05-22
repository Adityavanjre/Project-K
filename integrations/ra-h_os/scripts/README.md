# RA-H Scripts

Utility scripts for managing the RA-H knowledge management system.

## Directory Structure

```
scripts/
├── database/           # Database management
│   ├── backup.sh      # Create database backups
│   └── restore.sh     # Restore from backups
├── helpers/           # Helper management (CRITICAL - used by API)
│   ├── duplicate-helper.js  # Create new helpers
│   └── delete-helper.js     # Remove helpers
└── migrations/        # Completed one-time migrations
    └── (historical migration artifacts)
```

## Database Scripts

### Create a Backup
```bash
npm run backup
```
- Creates timestamped backup in `/backups/` folder
- Example: `rah_backup_20250902_102846.sql`
- Includes all nodes, chunks, edges, logs, chats, voice usage, and migration snapshots

### Restore from Backup
```bash
npm run restore backups/rah_backup_20250902_102846.sql
```
- ⚠️ **WARNING**: Replaces entire database
- Requires confirmation before proceeding
- Shows verification after restore

### List Backups
```bash
ls -lt backups/
```

## Helper Scripts

⚠️ **CRITICAL**: These scripts are used by the API at runtime. DO NOT modify or delete.

### Create New Helper
Called automatically by the API when creating helpers through the UI.
```bash
node scripts/helpers/duplicate-helper.js "HelperName"
```

### Delete Helper
Called automatically by the API when deleting helpers through the UI.
```bash
node scripts/helpers/delete-helper.js "helper-id"
```

## What Gets Backed Up
- All nodes (42,000+ knowledge items)
- Content chunks and embeddings
- Node connections/edges
- Metadata, logs, chats, voice usage, and migration snapshots
- Database schema and indexes

## Notes
- Backups typically ~250MB for 40k+ nodes
- Store backups safely - they contain your entire knowledge base
- Helper scripts are integrated with the application - modify with caution
