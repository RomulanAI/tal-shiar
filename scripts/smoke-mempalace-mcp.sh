#!/bin/bash
# smoke-mempalace-mcp.sh
#
# Host-run smoke test for MemPalace MCP availability inside the openclaw container.
# This repo doesn't have an automated test suite; use this as a repeatable check.
#
# Requirements:
#   - podman
#   - container named 'openclaw' running
#
# Usage:
#   ./scripts/smoke-mempalace-mcp.sh

set -euo pipefail

CONTAINER="openclaw"
MCPORTER_CONFIG_IN_CONTAINER="/config/mcporter.json"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

if ! command -v podman >/dev/null 2>&1; then
  echo "ERROR: podman not found" >&2
  exit 1
fi

if ! podman ps --filter name="$CONTAINER" --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERROR: container '$CONTAINER' is not running" >&2
  exit 1
fi

exec_() { podman exec "$CONTAINER" "$@"; }

log "MemPalace CLI status..."
exec_ mempalace status | sed -n '1,20p'

log "MCPorter config present?"
exec_ bash -lc "test -f '$MCPORTER_CONFIG_IN_CONTAINER' && echo OK || (echo MISSING; exit 1)"

log "Listing MCP servers (expect: mempalace + healthy)..."
if exec_ bash -lc "command -v mcporter >/dev/null 2>&1"; then
  exec_ mcporter list --config "$MCPORTER_CONFIG_IN_CONTAINER" | sed -n '1,80p'
else
  exec_ npx --yes mcporter list --config "$MCPORTER_CONFIG_IN_CONTAINER" | sed -n '1,80p'
fi

log "Calling mempalace_status via MCP (basic tool call)..."
if exec_ bash -lc "command -v mcporter >/dev/null 2>&1"; then
  exec_ mcporter call --config "$MCPORTER_CONFIG_IN_CONTAINER" mempalace.mempalace_status --output json | sed -n '1,40p'
else
  exec_ npx --yes mcporter call --config "$MCPORTER_CONFIG_IN_CONTAINER" mempalace.mempalace_status --output json | sed -n '1,40p'
fi

log "OK: MemPalace MCP smoke test passed"
