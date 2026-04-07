#!/usr/bin/env bash
# openclaw-watchdog.sh — Detects a silently stuck OpenClaw container and restarts it.
#
# The OpenClaw Mattermost websocket can silently die while the process stays alive.
# When this happens, log output stops entirely (no heartbeat, no reconnect attempts).
# This script checks the age of the last log entry and restarts if it's too old.
#
# Install: run install.sh, or manually add to user crontab (crontab -e):
#   */5 * * * * /path/to/openclaw-container/openclaw-watchdog.sh
#
# Logs to: ~/.local/share/openclaw-watchdog.log

set -euo pipefail

# Ensure user session bus is available (cron doesn't set these)
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

CONTAINER="openclaw"
SERVICE="container-openclaw.service"
STALE_THRESHOLD_MINUTES=30
LOG_FILE="${HOME}/.local/share/openclaw-watchdog.log"

log() {
    echo "$(date -Iseconds) $1" >> "$LOG_FILE"
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Check if container is running
if ! podman ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"; then
    log "WARN: container '$CONTAINER' not running — systemd should handle this, skipping"
    exit 0
fi

# Get the last log line's timestamp
last_log_line=$(podman logs --tail 1 "$CONTAINER" 2>&1)
if [[ -z "$last_log_line" ]]; then
    log "WARN: no log output from container"
    exit 0
fi

# Extract ISO timestamp with timezone from the log line (format: 2026-03-25T05:57:12.320+00:00)
last_ts=$(echo "$last_log_line" | grep -oP '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+[+-]\d{2}:\d{2}' | head -1)
if [[ -z "$last_ts" ]]; then
    log "WARN: could not parse timestamp from last log line: ${last_log_line:0:100}"
    exit 0
fi

last_epoch=$(date -d "$last_ts" +%s 2>/dev/null || echo "")
if [[ -z "$last_epoch" ]]; then
    log "WARN: could not convert timestamp '$last_ts' to epoch"
    exit 0
fi

now_epoch=$(date +%s)
age_minutes=$(( (now_epoch - last_epoch) / 60 ))

if [[ "$age_minutes" -ge "$STALE_THRESHOLD_MINUTES" ]]; then
    log "RESTART: last log entry is ${age_minutes}m old (threshold: ${STALE_THRESHOLD_MINUTES}m) — restarting $SERVICE"
    systemctl --user restart "$SERVICE" 2>&1 | while read -r line; do log "  systemctl: $line"; done
    log "RESTART: restart command issued"
else
    # Only log occasionally to avoid noise (every ~30 min = every 6th run at */5)
    minute=$(date +%M)
    if (( minute % 30 < 5 )); then
        log "OK: last log entry is ${age_minutes}m old"
    fi
fi
