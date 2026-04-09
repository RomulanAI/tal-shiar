#!/bin/bash
# mempalace-cron.sh — Daily maintenance for MemPalace knowledge graph
# Runs via crontab on the host, executes inside the tal-shiar container.
#
# Install: run install.sh, or manually add to user crontab (crontab -e):
#   0 3 * * * /path/to/tal-shiar/mempalace-cron.sh
#
# Logs to: ~/.local/share/mempalace-cron.log

set -euo pipefail

LOG="${HOME}/.local/share/mempalace-cron.log"
CONTAINER="openclaw"
WORKSPACE="/home/node/.openclaw/workspace"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() { echo "[$TIMESTAMP] $*" >> "$LOG"; }

# Check container is running
if ! podman ps --filter name="$CONTAINER" --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    log "SKIP: container $CONTAINER not running"
    exit 0
fi

log "START mempalace maintenance"

# Re-mine workspace (picks up new/changed files)
if podman exec "$CONTAINER" mempalace mine "$WORKSPACE" >> "$LOG" 2>&1; then
    log "OK: mine completed"
else
    log "WARN: mine failed (exit $?)"
fi

# Compress drawers (AAAK rule-based ~7x reduction for efficient retrieval)
if podman exec "$CONTAINER" mempalace compress >> "$LOG" 2>&1; then
    log "OK: compress completed"
else
    log "WARN: compress failed (exit $?)"
fi

# Log status
podman exec "$CONTAINER" mempalace status >> "$LOG" 2>&1

log "END mempalace maintenance"
