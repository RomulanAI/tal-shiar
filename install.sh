#!/bin/bash
# install.sh — Set up the OpenClaw container deployment from scratch.
#
# What this does:
#   1. Creates host directories for config, workspace, and state
#   2. Copies example config if no config exists
#   3. Builds the container image
#   4. Installs the systemd user service
#   5. Installs cron jobs (watchdog + mempalace maintenance)
#   6. Starts the service
#   7. Runs wiki bootstrap (setup-wiki.sh)
#
# Safe to re-run — skips steps that are already done.
#
# Usage:
#   ./install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/openclaw-config"
WORKSPACE_DIR="$HOME/openclaw-workspace"
STATE_DIR="$HOME/openclaw-state"
SERVICE_NAME="container-openclaw.service"
SERVICE_DIR="$HOME/.config/systemd/user"
CONTAINER="openclaw"
IMAGE="localhost/openclaw-jeeves:latest"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
warn() { echo "[$(date '+%H:%M:%S')] WARNING: $*" >&2; }

# ──────────────────────────────────────────────────────
# 1. Create host directories
# ──────────────────────────────────────────────────────

log "Creating host directories..."
mkdir -p "$CONFIG_DIR" "$WORKSPACE_DIR" "$STATE_DIR" "$SERVICE_DIR"

# ──────────────────────────────────────────────────────
# 2. Config file
# ──────────────────────────────────────────────────────

if [ ! -f "$CONFIG_DIR/openclaw.json" ]; then
    cp "$REPO_DIR/openclaw.json.example" "$CONFIG_DIR/openclaw.json"
    log "Copied example config to $CONFIG_DIR/openclaw.json"
    warn "You MUST edit $CONFIG_DIR/openclaw.json before starting the bot:"
    warn "  - Set your GEMINI_API_KEY (or other LLM provider key)"
    warn "  - Set your Mattermost botToken and baseUrl"
    warn "  - Change the gateway auth token from the default"
    echo ""
    echo "  Edit now:  \$EDITOR $CONFIG_DIR/openclaw.json"
    echo ""
    read -p "  Press Enter when done editing (or Ctrl-C to abort)... "
else
    log "Config exists: $CONFIG_DIR/openclaw.json (skipped)"
fi

# Sanity check: warn if config still has placeholder values
if grep -q "CHANGE_ME" "$CONFIG_DIR/openclaw.json" 2>/dev/null; then
    warn "Config still contains CHANGE_ME placeholders — the bot won't work until you fix them."
    warn "  Edit: $CONFIG_DIR/openclaw.json"
fi

# ──────────────────────────────────────────────────────
# 3. Build the container image
# ──────────────────────────────────────────────────────

log "Building container image..."
podman build -f "$REPO_DIR/Containerfile.jeeves" -t openclaw-jeeves:latest "$REPO_DIR"
log "Image built: $IMAGE"

# ──────────────────────────────────────────────────────
# 4. Install systemd service
# ──────────────────────────────────────────────────────

log "Installing systemd service..."
cp "$REPO_DIR/$SERVICE_NAME" "$SERVICE_DIR/$SERVICE_NAME"
systemctl --user daemon-reload
log "Service installed: $SERVICE_DIR/$SERVICE_NAME"

# Enable linger so the service survives logout
if ! loginctl show-user "$USER" --property=Linger 2>/dev/null | grep -q "yes"; then
    loginctl enable-linger "$USER" 2>/dev/null || warn "Could not enable linger — service may stop when you log out"
fi

# ──────────────────────────────────────────────────────
# 5. Install cron jobs
# ──────────────────────────────────────────────────────

log "Installing cron jobs..."

install_cron() {
    local marker="$1"
    local schedule="$2"
    local command="$3"
    local comment="$4"

    if crontab -l 2>/dev/null | grep -qF "$marker"; then
        log "  cron exists: $comment (skipped)"
    else
        (crontab -l 2>/dev/null; echo ""; echo "# $comment"; echo "$schedule $command") | crontab -
        log "  installed: $comment"
    fi
}

install_cron "openclaw-watchdog.sh" "*/5 * * * *" "$REPO_DIR/openclaw-watchdog.sh" \
    "OpenClaw watchdog — restart if Mattermost websocket silently dies"

install_cron "mempalace-cron.sh" "0 3 * * *" "$REPO_DIR/mempalace-cron.sh" \
    "MemPalace daily maintenance — re-mine workspace + compress drawers"

# ──────────────────────────────────────────────────────
# 6. Start the service
# ──────────────────────────────────────────────────────

log "Starting the service..."
systemctl --user enable --now "$SERVICE_NAME"
sleep 8

if systemctl --user is-active "$SERVICE_NAME" > /dev/null 2>&1; then
    log "Service is running."
else
    warn "Service failed to start. Check: journalctl --user -u $SERVICE_NAME -n 30"
    exit 1
fi

# Wait for gateway to initialize
log "Waiting for gateway to connect..."
for i in $(seq 1 12); do
    if podman logs --tail 5 "$CONTAINER" 2>&1 | grep -q "connected as"; then
        log "Gateway connected to Mattermost."
        break
    fi
    sleep 5
done

# ──────────────────────────────────────────────────────
# 7. Bootstrap wiki knowledgebase
# ──────────────────────────────────────────────────────

log "Running wiki bootstrap..."
"$REPO_DIR/setup-wiki.sh"

# ──────────────────────────────────────────────────────
# Done
# ──────────────────────────────────────────────────────

echo ""
log "========================================="
log "  Installation complete!"
log "========================================="
log ""
log "  Bot status:     systemctl --user status $SERVICE_NAME"
log "  Bot logs:       podman logs --tail 50 $CONTAINER"
log "  Control UI:     http://$(hostname -I | awk '{print $1}'):18789/"
log "  Config:         $CONFIG_DIR/openclaw.json"
log "  Wiki vault:     $STATE_DIR/workspace/wiki/"
log "  Obsidian:       Open above path as vault in Obsidian desktop"
log ""
log "  To re-run wiki bootstrap:  $REPO_DIR/setup-wiki.sh"
log "  To rebuild image:          podman build -f $REPO_DIR/Containerfile.jeeves -t openclaw-jeeves:latest $REPO_DIR"
log ""
