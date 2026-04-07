# OpenClaw Container — Agentic Mattermost Bot

A containerised [OpenClaw](https://github.com/openclaw/openclaw) deployment that runs as a Mattermost bot, managed by systemd on a Linux host via Podman. Includes a persistent wiki knowledgebase (Obsidian-compatible), QMD hybrid search, and MemPalace structured memory.

## Architecture

```
podman-compose up -d
├── openclaw container        (bot + QMD search + MemPalace)
└── quartz-wiki container     (wiki viewer on :9090)

Host
├── ~/openclaw-config/        # bind → /config         (openclaw.json, mcporter.json)
├── ~/openclaw-workspace/     # bind → /home/openclaw/workspace  (skills, skeleton files)
├── ~/openclaw-state/         # bind → /home/node/.openclaw      (workspace, memory, wiki, sessions)
│   ├── workspace/            #   The bot's actual working directory
│   │   ├── AGENTS.md         #   Operating instructions (curated)
│   │   ├── SOUL.md           #   Persona definition
│   │   ├── MEMORY.md         #   Long-term memory
│   │   ├── memory/           #   Daily notes (YYYY-MM-DD.md)
│   │   └── wiki/             #   Persistent wiki knowledgebase (Obsidian vault)
│   └── mempalace/            #   MemPalace knowledge graph (ChromaDB + SQLite)
└── openclaw-container/       # this repo
```

The container extends `ghcr.io/openclaw/openclaw:latest` with:
- **QMD** — hybrid BM25+vector search engine (indexes wiki + memory every 5 min)
- **MemPalace** — structured knowledge graph with 19 MCP tools (entity tracking, temporal queries, agent diary)
- LaTeX, pandoc, ffmpeg, sqlite3, ripgrep, fd-find, python3-pip, jq

All persistent state lives on the host via bind mounts — the container is disposable.

## Prerequisites

- Podman (tested with 5.2+)
- podman-compose (`pip install podman-compose`)
- systemd with user session support
- A Mattermost server with a bot account and token
- A Gemini API key (or other LLM provider key)

## Quick Start

### Option A: Automated install

```bash
git clone <this-repo> ~/openclaw-container
cd ~/openclaw-container
./install.sh
```

`install.sh` does everything: creates directories, copies config, builds the image, installs the systemd service and cron jobs, starts the bot, and bootstraps the wiki. It will pause and ask you to edit the config file with your API keys.

### Option B: Manual setup

#### 1. Build the image

```bash
cd ~/openclaw-container
podman build -f Containerfile.jeeves -t openclaw-jeeves:latest .
```

#### 2. Create host directories and config

```bash
mkdir -p ~/openclaw-config ~/openclaw-workspace ~/openclaw-state

# Copy and edit the example config
cp openclaw.json.example ~/openclaw-config/openclaw.json
```

Edit `~/openclaw-config/openclaw.json` — you must set:
- `env.GEMINI_API_KEY` — your Gemini API key (get one at https://aistudio.google.com/apikey)
- `channels.mattermost.botToken` — your Mattermost bot token
- `channels.mattermost.baseUrl` — your Mattermost server URL
- `gateway.auth.token` — a random secret string for the control UI

#### 3. Test run (manual)

```bash
podman run -d --name openclaw \
  --hostname $(hostname) \
  -e OPENCLAW_CONFIG_PATH=/config/openclaw.json \
  -v ~/openclaw-config:/config \
  -v ~/openclaw-workspace:/home/openclaw/workspace \
  -v ~/openclaw-state:/home/node/.openclaw \
  localhost/openclaw-jeeves:latest

# Check it connected
podman logs -f openclaw
# Look for: [mattermost] connected as @<your-bot-name>
```

#### 4. Install systemd service

```bash
mkdir -p ~/.config/systemd/user
cp openclaw-compose.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now openclaw-compose.service

# Keep the service running after logout
loginctl enable-linger $USER
```

This starts both the OpenClaw bot and Quartz wiki viewer via podman-compose.

#### 5. Bootstrap the wiki knowledgebase

```bash
./setup-wiki.sh
```

This creates the wiki directory structure, seed files, initializes MemPalace, and registers the MCP server. Safe to re-run.

#### 6. Install cron jobs

```bash
REPO="$(pwd)"

# Watchdog: restarts bot if Mattermost websocket silently dies (every 5 min)
(crontab -l 2>/dev/null; echo ""; echo "# OpenClaw watchdog"; echo "*/5 * * * * $REPO/openclaw-watchdog.sh") | crontab -

# MemPalace: re-mines workspace + compresses drawers (daily at 3 AM)
(crontab -l 2>/dev/null; echo ""; echo "# MemPalace maintenance"; echo "0 3 * * * $REPO/mempalace-cron.sh") | crontab -
```

## Wiki Knowledgebase

### Wiki Viewer (Quartz)

The wiki is served as a website via [Quartz](https://quartz.jzhao.xyz) in a separate container:

```
http://<host-ip>:9090/
```

Features: `[[wikilinks]]`, graph view, backlinks, full-text search, hot-reload on file changes. The Quartz container mounts the wiki directory read-only and auto-rebuilds when the bot creates or updates pages.

### Wiki Structure

The bot maintains a persistent wiki at `~/openclaw-state/workspace/wiki/` following [Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) with [Obsidian PKM](https://obsidian.md/) conventions (see `WIKI-STRUCTURE-DESIGN.md` for the full rationale):

- **`pages/`** — all content (flat, one idea per file; type is in frontmatter, not folder)
- **`MOCs/`** — Maps of Content: curated topic hubs for human navigation
- **`sources/`** — raw curated documents (immutable)
- **`_meta/`** — machine navigation: `index.md`, `log.md`, `SCHEMA.md`
- **`_templates/`** — page scaffolds

The wiki uses `[[wikilinks]]` and YAML frontmatter, making it an **Obsidian vault**. Open `~/openclaw-state/workspace/wiki/` in [Obsidian](https://obsidian.md/) to browse with graph view.

### How it works

| Layer | Tool | What it does |
|-------|------|-------------|
| Search | **QMD** | Hybrid BM25+vector indexing, auto-updates every 5 min, powers `memory_search` |
| Structure | **MemPalace** | Knowledge graph (entities, relationships, temporal facts), 19 MCP tools via mcporter |
| Navigation | **Obsidian** | Human browsing — graph view, backlinks, `[[wikilinks]]` |

The bot is instructed (via `AGENTS.md`) to create wiki pages when it learns durable knowledge, and to run lint passes periodically.

### MemPalace MCP tools

Registered via mcporter, available to the bot as first-class tools:

| Category | Tools |
|----------|-------|
| Palace | `status`, `list_wings`, `list_rooms`, `search`, `add_drawer`, `get_taxonomy` |
| Knowledge Graph | `kg_query`, `kg_add`, `kg_invalidate`, `kg_timeline`, `kg_stats` |
| Navigation | `traverse`, `find_tunnels`, `graph_stats` |
| Agent Diary | `diary_write`, `diary_read` |

## Operations

### View logs

```bash
podman logs --tail 50 openclaw                          # container logs
journalctl --user -u container-openclaw.service -f      # systemd journal
cat ~/.local/share/openclaw-watchdog.log                # watchdog log
cat ~/.local/share/mempalace-cron.log                   # mempalace maintenance log
```

### Restart

```bash
systemctl --user restart openclaw-compose.service
```

### Update to latest OpenClaw

```bash
podman pull ghcr.io/openclaw/openclaw:latest
podman build -f Containerfile.jeeves -t openclaw-jeeves:latest .
systemctl --user restart openclaw-compose.service
```

### Check wiki & memory status

```bash
podman exec openclaw qmd --version                     # QMD installed
podman exec openclaw mempalace status                   # MemPalace drawers
podman exec openclaw npx mcporter list                  # MCP servers
podman exec openclaw find /home/node/.openclaw/workspace/wiki -name '*.md' | wc -l  # wiki pages
```

### Access the control UI

The gateway binds to the LAN interface at `http://<host-ip>:18789/`. Authenticate with the token from `openclaw.json`.

## Troubleshooting

### Bot not responding on Mattermost

Usually a stale WebSocket. The watchdog cron handles this automatically, but you can force a restart:

```bash
systemctl --user restart openclaw-compose.service
```

Check logs for `[mattermost] connected as @<bot-name>` to confirm reconnection.

### Config has CHANGE_ME placeholders

The bot won't start properly until you edit `~/openclaw-config/openclaw.json` and replace all `CHANGE_ME` values with real credentials.

### Container won't start after reboot

```bash
loginctl enable-linger $USER     # ensure services survive logout
podman images | grep openclaw    # ensure image exists
```

### MemPalace not initialized

Run the wiki bootstrap:

```bash
./setup-wiki.sh
```

## File Reference

| File | Purpose |
|------|---------|
| `Containerfile.jeeves` | Container image — extends official OpenClaw with QMD, MemPalace, dev tools |
| `openclaw-compose.service` | systemd service — manages both containers via podman-compose |
| `container-openclaw.service` | Legacy systemd service for OpenClaw only (without Quartz) |
| `podman-compose.yml` | Compose file — orchestrates openclaw + quartz-wiki containers |
| `Containerfile.quartz` | Quartz wiki viewer container image |
| `install.sh` | Automated setup — builds image, installs service, cron, bootstraps wiki |
| `setup-wiki.sh` | Wiki bootstrap — creates vault structure, inits MemPalace, registers MCP |
| `mempalace-cron.sh` | Daily cron — re-mines workspace, compresses drawers |
| `openclaw-watchdog.sh` | Watchdog cron — restarts if Mattermost websocket stalls |
| `openclaw.json.example` | Config template (includes memory/QMD/wiki settings) |
| `WIKI-KNOWLEDGEBASE-PLAN.md` | Architecture reference for the wiki knowledgebase system |

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `~/openclaw-config/` | `/config` | Config files (openclaw.json, mcporter.json) |
| `~/openclaw-workspace/` | `/home/openclaw/workspace` | Skills and skeleton workspace files |
| `~/openclaw-state/` | `/home/node/.openclaw` | Persistent state (workspace, memory, wiki, sessions, mempalace) |
