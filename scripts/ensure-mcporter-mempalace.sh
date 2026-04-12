#!/bin/bash
# ensure-mcporter-mempalace.sh
#
# Idempotently ensure a MemPalace MCP server entry exists in a mcporter config JSON.
#
# Why: users often already have other MCP servers configured. We must *merge* rather
# than clobber, and we must pin MemPalace's palace location so the MCP server is
# deterministic and independent of cwd/global config.
#
# Usage:
#   ./scripts/ensure-mcporter-mempalace.sh ~/openclaw-config/mcporter.json

set -euo pipefail

MCPORTER_FILE="${1:-}"
if [ -z "$MCPORTER_FILE" ]; then
  echo "ERROR: missing path to mcporter.json" >&2
  exit 1
fi

PALACE_PATH="${MEMPALACE_PALACE_PATH:-/home/node/.openclaw/mempalace/palace}"

# If the file already exists, preserve its permissions. Users may have added other
# MCP servers with secrets/tokens embedded in args/env.
FILE_EXISTED=false
OLD_MODE=""
if [ -f "$MCPORTER_FILE" ]; then
  FILE_EXISTED=true
  # GNU coreutils stat. If this fails (non-GNU), we simply won't restore mode.
  OLD_MODE="$(stat -c '%a' "$MCPORTER_FILE" 2>/dev/null || true)"
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 not found; cannot safely merge JSON. Install python3 or create $MCPORTER_FILE manually." >&2
  exit 1
fi

MCPORTER_DIR="$(dirname "$MCPORTER_FILE")"
mkdir -p "$MCPORTER_DIR"

TMP_FILE="$(mktemp "$MCPORTER_DIR/.mcporter.json.tmp.XXXXXX")"
BACKUP_SUFFIX="$(date +%Y%m%d%H%M%S)"

merge_with_python() {
  python3 - "$MCPORTER_FILE" "$PALACE_PATH" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
palace = sys.argv[2]

mempalace_server = {
    "description": "MemPalace — structured memory (MCP)",
    "command": "python3",
    "args": ["-m", "mempalace.mcp_server", "--palace", palace],
}

data = {}
if path.exists():
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"ERROR: {path} is not valid JSON: {e}", file=sys.stderr)
        sys.exit(2)

if not isinstance(data, dict):
    print(f"ERROR: {path} must contain a JSON object at top-level", file=sys.stderr)
    sys.exit(2)

mcp_servers = data.get("mcpServers")
if mcp_servers is None:
    mcp_servers = {}
if not isinstance(mcp_servers, dict):
    print(f"ERROR: {path} has non-object 'mcpServers' key", file=sys.stderr)
    sys.exit(2)

data["mcpServers"] = mcp_servers
mcp_servers["mempalace"] = mempalace_server

print(json.dumps(data, indent=2, sort_keys=True))
PY
}

set +e
merge_with_python >"$TMP_FILE"
status=$?
set -e

if [ $status -ne 0 ]; then
  if [ $status -eq 2 ] && [ -f "$MCPORTER_FILE" ]; then
    cp "$MCPORTER_FILE" "${MCPORTER_FILE}.bak.${BACKUP_SUFFIX}" || true
    echo "WARNING: backed up invalid JSON to ${MCPORTER_FILE}.bak.${BACKUP_SUFFIX}" >&2

    # Create a minimal valid file. (Use Python to avoid JSON escaping issues.)
    python3 - "$PALACE_PATH" >"$TMP_FILE" <<'PY'
import json
import sys

palace = sys.argv[1]

data = {
  "mcpServers": {
    "mempalace": {
      "description": "MemPalace — structured memory (MCP)",
      "command": "python3",
      "args": ["-m", "mempalace.mcp_server", "--palace", palace],
    }
  }
}

print(json.dumps(data, indent=2, sort_keys=True))
PY
  else
    rm -f "$TMP_FILE" || true
    exit $status
  fi
fi

mv "$TMP_FILE" "$MCPORTER_FILE"

# Restore permissions.
# - If the file existed, keep its previous mode to avoid accidentally widening access.
# - If it's new, default to a readable config so the 'node' user in the container can read it
#   under rootless Podman UID mappings.
if [ "$FILE_EXISTED" = true ]; then
  if [ -n "$OLD_MODE" ]; then
    chmod "$OLD_MODE" "$MCPORTER_FILE" || true
  fi
else
  # New file: default to owner-readable only. mcporter.json may contain secrets for
  # other MCP servers.
  chmod 0600 "$MCPORTER_FILE" || true
fi
