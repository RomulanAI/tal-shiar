# OpenClaw Jeeves — Containerised Mattermost Bot

A containerised [OpenClaw](https://github.com/openclaw/openclaw) deployment that runs as a Mattermost bot ("Jeeves"), managed by systemd on a Linux host via Podman.

## Architecture

```
Host (JOHNAIC)
├── openclaw-config/          # bind-mounted → /config (contains openclaw.json with secrets)
├── openclaw-workspace/       # bind-mounted → /home/openclaw/workspace (SOUL.md, skills, docs)
├── openclaw-state/           # bind-mounted → /home/node/.openclaw (agents, memory, sessions)
└── openclaw-container/       # this repo — Containerfiles, systemd unit, docs
```

The container image `openclaw-jeeves` extends the official `ghcr.io/openclaw/openclaw:latest` with additional tools (LaTeX, pandoc, ffmpeg, sqlite3, ripgrep, fd-find, python3-pip, jq).

All persistent state lives on the host via bind mounts — the container is disposable and can be rebuilt/replaced without data loss.

## Prerequisites

- Podman (tested with 5.2.3+)
- systemd with user session support (`loginctl enable-linger`)
- A Mattermost server with a bot account and token
- A Gemini API key (or other LLM provider)

## Quick Start

### 1. Build the image

```bash
cd openclaw-container
podman build -f Containerfile.jeeves -t openclaw-jeeves:latest .
```

### 2. Create host directories and config

```bash
mkdir -p ~/openclaw-config ~/openclaw-workspace ~/openclaw-state

# Copy and edit the example config
cp openclaw.json.example ~/openclaw-config/openclaw.json
# Edit ~/openclaw-config/openclaw.json — set your:
#   - Gemini API key
#   - Mattermost bot token and server URL
#   - Gateway auth token
```

### 3. Test run (manual)

```bash
podman run -d --name openclaw \
  --hostname $(hostname) \
  -e OPENCLAW_CONFIG_PATH=/config/openclaw.json \
  -e OPENCLAW_GATEWAY_TOKEN=your-gateway-token \
  -v ~/openclaw-config:/config \
  -v ~/openclaw-workspace:/home/openclaw/workspace \
  -v ~/openclaw-state:/home/node/.openclaw \
  localhost/openclaw-jeeves:latest

# Check it connected
podman logs -f openclaw
# Look for: [mattermost] connected as @jeeves
```

### 4. Install systemd service (recommended)

```bash
# Copy the service file
cp container-openclaw.service ~/.config/systemd/user/

# Edit the service file if your paths/tokens differ from defaults
# Then enable and start
systemctl --user daemon-reload
systemctl --user enable --now container-openclaw.service

# Enable linger so the service runs even when you're logged out
loginctl enable-linger $USER
```

### 5. Stop the manual container (if running)

If you tested with `podman run` first, stop it before starting the systemd service:

```bash
podman stop openclaw && podman rm openclaw
```

## Operations

### View logs

```bash
# Via podman
podman logs --tail 50 openclaw

# Via journalctl (when running under systemd)
journalctl --user -u container-openclaw.service -f
```

### Restart the bot

```bash
systemctl --user restart container-openclaw.service
```

### Check status

```bash
systemctl --user status container-openclaw.service
```

### Update to latest OpenClaw version

```bash
# Pull latest base image
podman pull ghcr.io/openclaw/openclaw:latest

# Rebuild
cd ~/openclaw-container
podman build -f Containerfile.jeeves -t openclaw-jeeves:latest .

# Restart the service (it uses --rm and --replace, so it picks up the new image)
systemctl --user restart container-openclaw.service

# Verify
podman logs --tail 20 openclaw
```

### Check processes inside container

```bash
podman exec openclaw ps aux
```

### Access the OpenClaw control UI

The gateway binds to the LAN interface. Access it at `http://<host-ip>:18789/` using the gateway auth token.

## Troubleshooting

### Bot not responding on Mattermost

This is usually a stale WebSocket connection. The process stays alive but the Mattermost WebSocket silently dies.

**Diagnosis:**
```bash
# Check if the container is running
podman ps -f name=openclaw

# Check recent logs — if there are no entries for hours, the websocket is dead
podman logs --tail 20 openclaw

# Verify Mattermost is reachable from the container
podman exec openclaw curl -s -o /dev/null -w "%{http_code}" https://your-mattermost-server/api/v4/system/ping

# Verify the bot token is still valid
podman exec openclaw curl -s -H "Authorization: Bearer YOUR_BOT_TOKEN" https://your-mattermost-server/api/v4/users/me | head -5
```

**Fix:**
```bash
systemctl --user restart container-openclaw.service
```

The systemd service is configured with `Restart=always` and `RestartSec=10`, so if the process crashes it will auto-recover. However, a silently stuck WebSocket (where the process stays alive) requires a manual restart or an external watchdog.

### Zombie processes accumulating

The container runs as PID 1 (no init system). Child processes (julia, curl, etc.) can become zombies. A restart clears them:

```bash
systemctl --user restart container-openclaw.service
```

For a permanent fix, consider adding `--init` to the podman run command in the systemd service file, which adds a tiny init process to reap zombies.

### Container won't start after reboot

Ensure linger is enabled:
```bash
loginctl enable-linger $USER
```

Check that the image exists:
```bash
podman images | grep openclaw-jeeves
```

## File Reference

| File | Purpose |
|------|---------|
| `Containerfile.jeeves` | Main Containerfile — extends official image with extra tools |
| `Dockerfile` | Original/minimal Containerfile (not currently used) |
| `container-openclaw.service` | systemd user service unit |
| `openclaw.json.example` | Example config (no secrets) |
| `.gitignore` | Excludes `openclaw/` dir and secret files |

| Host Path | Container Mount | Purpose |
|-----------|----------------|---------|
| `~/openclaw-config/` | `/config` | Configuration (openclaw.json with API keys) |
| `~/openclaw-workspace/` | `/home/openclaw/workspace` | Workspace (SOUL.md, skills, custom docs) |
| `~/openclaw-state/` | `/home/node/.openclaw` | Persistent state (agents, memory, sessions) |
