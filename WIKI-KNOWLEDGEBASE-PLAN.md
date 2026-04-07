# Persistent Wiki Knowledgebase for Psmith

## Problem

Psmith's memory is episodic — flat daily logs and a single `MEMORY.md`. Knowledge doesn't compound. The same facts get re-derived, context gets lost across sessions, and there's no structured artifact a human can browse. We want a persistent, growing knowledgebase that the agent maintains and both agent and human can navigate.

## Research Summary

### Karpathy's LLM Wiki Pattern ([gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f))

Three-layer architecture:
1. **Raw Sources** — immutable curated documents (papers, articles, data)
2. **The Wiki** — LLM-generated Markdown: entity pages, concept pages, cross-references
3. **The Schema** — config defining structure, conventions, and workflows

Core operations:
- **Ingest**: process source → create/update wiki pages, update index, log the operation
- **Query**: search wiki → synthesize answer → optionally file results back as new pages
- **Lint**: periodic health checks (contradictions, orphan pages, broken links, stale claims)

Key insight: *"The tedious part of maintaining a knowledge base is not the reading or the thinking — it's the bookkeeping."* LLMs handle the bookkeeping; humans curate and direct.

### QMD ([github.com/tobi/qmd](https://github.com/tobi/qmd))

Local-first search engine for Markdown. Three search layers:
- **BM25** (keyword), **Vector** (semantic), **Hybrid + Reranking** (LLM-powered)

Stores index in SQLite. Runs fully local via Bun + node-llama-cpp (auto-downloads GGUF models). Exposes CLI, MCP server, HTTP server, and Node.js library API.

**Already integrated into OpenClaw** as an optional backend (`memory.backend: "qmd"`). The gateway manages QMD lifecycle automatically — collection creation, periodic update+embed, fallback to builtin SQLite if QMD fails.

### Obsidian ([obsidian.md/cli](https://obsidian.md/cli))

An Obsidian vault is just a folder of Markdown files with a `.obsidian/` config directory. Provides `[[wikilinks]]`, graph view, backlinks panel, and search. CLI supports programmatic note creation, search, and link management.

**Already has a bundled skill** in OpenClaw at `openclaw/skills/obsidian/`. The agent doesn't need Obsidian itself — it writes plain Markdown with `[[wikilinks]]`. Obsidian is the human's browsing layer.

### MemPalace ([github.com/milla-jovovich/mempalace](https://github.com/milla-jovovich/mempalace))

Structured memory system using a spatial metaphor:
- **Wings** = people/projects, **Rooms** = topics, **Halls** = memory types, **Tunnels** = cross-wing connections
- **Drawers** = verbatim originals, **Closets** = compressed summaries

Unique capabilities that QMD lacks:
| Feature | QMD | MemPalace |
|---------|-----|-----------|
| Full-text search | BM25 | via ChromaDB |
| Semantic search | Vector embeddings | Vector embeddings |
| LLM reranking | Yes | No (structure compensates) |
| Knowledge graph | No | Yes (SQLite triples with temporal validity) |
| Contradiction detection | No | Yes (auto-flags conflicts) |
| Entity tracking over time | No | Yes ("What was true in January?") |
| Compression | No | AAAK dialect (30x compression, lossless) |
| Multi-agent diaries | No | Yes (per-agent wings) |
| MCP server | Yes (search tools) | Yes (19 tools across 5 categories) |
| Storage | SQLite | SQLite + ChromaDB |

MemPalace scored **96.6% on LongMemEval** with zero API calls. Its spatial structure provides a documented **34% retrieval improvement** over flat semantic search.

**MCP integration**: `mempalace` exposes 19 tools via MCP server — palace read/write, knowledge graph CRUD, navigation, agent diaries. Can be added to OpenClaw as an MCP skill.

## Architecture Decision

**These tools are complementary, not competing.** They operate on different layers:

```
                    Human Navigation
                   ┌─────────────────┐
                   │   Obsidian       │  Graph view, backlinks, visual browse
                   │   (reads .md)    │
                   └────────┬────────┘
                            │
              Plain Markdown Files (source of truth)
         ┌──────────────────┼──────────────────┐
         │                  │                  │
    ┌────┴─────┐     ┌─────┴──────┐    ┌──────┴───────┐
    │   QMD     │     │  MemPalace  │    │  Agent I/O    │
    │ (search)  │     │ (knowledge  │    │  read/write   │
    │ BM25 +    │     │  graph +    │    │  edit tools   │
    │ vector +  │     │  structure + │    │               │
    │ rerank    │     │  temporal)   │    │               │
    └───────────┘     └─────────────┘    └───────────────┘
```

- **Wiki files** = the artifact (plain Markdown with `[[wikilinks]]`, YAML frontmatter)
- **QMD** = search layer (powers `memory_search`, already wired into OpenClaw)
- **MemPalace** = structured memory layer (knowledge graph, contradiction detection, temporal queries)
- **Obsidian** = human UX layer (graph view, backlinks, visual navigation)

## Recommended Implementation

### Phase 1: Wiki + QMD + Obsidian (immediate)

Minimal new code. Leverages existing OpenClaw QMD support.

#### 1.1 Install QMD in the container

**File**: `Containerfile.jeeves`

```dockerfile
# After the existing apt-get block, before USER node:
RUN curl -fsSL https://bun.sh/install | bash \
    && /root/.bun/bin/bun install -g https://github.com/tobi/qmd
ENV PATH="/root/.bun/bin:$PATH"

USER node
ENV PATH="/home/node/.bun/bin:/root/.bun/bin:$PATH"
```

#### 1.2 Create the wiki directory

Location: `~/openclaw-workspace/wiki/` (persisted via existing bind mount)

```
wiki/
  .obsidian/app.json        # Obsidian vault config (wikilinks enabled)
  SCHEMA.md                 # Conventions, structure, templates, lint rules
  index.md                  # Content catalog (maintained by agent)
  log.md                    # Append-only operations log
  sources/                  # Layer 1: raw curated documents
  concepts/                 # Layer 2: concept pages
  entities/                 # Layer 2: entity pages (people, projects, tools)
  topics/                   # Layer 2: topic summaries, how-tos
  templates/                # Page templates for the agent
    concept.md
    entity.md
    topic.md
    source-summary.md
```

#### 1.3 Enable QMD backend in config

**File**: `~/openclaw-config/openclaw.json` — add top-level `"memory"` block:

```json
"memory": {
  "backend": "qmd",
  "citations": "auto",
  "qmd": {
    "includeDefaultMemory": true,
    "searchMode": "search",
    "update": { "interval": "5m", "onBoot": true, "waitForBootSync": false },
    "limits": { "maxResults": 8, "timeoutMs": 5000 },
    "scope": {
      "default": "deny",
      "rules": [
        { "action": "allow", "match": { "chatType": "direct" } }
      ]
    },
    "paths": [
      { "name": "wiki", "path": "wiki", "pattern": "**/*.md" }
    ]
  }
}
```

- `includeDefaultMemory: true` keeps existing `memory/*.md` + `MEMORY.md` indexed
- Wiki pages appear in `memory_search` results alongside daily notes
- No new tools needed — existing `memory_search` / `memory_get` work with QMD

#### 1.4 Add agent instructions

**File**: `~/openclaw-workspace/AGENTS.md` — append wiki section with ingest/query/lint workflows, `[[wikilink]]` conventions, reference to `wiki/SCHEMA.md`.

**File**: `~/openclaw-workspace/skills/wiki/SKILL.md` — detailed operational skill covering ingest workflow, query workflow, lint checklist, page creation rules, cross-referencing rules.

#### 1.5 Rebuild and deploy

```bash
podman build -f Containerfile.jeeves -t openclaw-jeeves:latest .
systemctl --user restart container-openclaw.service
```

### Phase 2: Add MemPalace (after Phase 1 is stable)

MemPalace adds the knowledge graph layer. It mines the wiki content and provides structured retrieval, temporal queries, and contradiction detection.

#### 2.1 Install MemPalace in the container

Add to `Containerfile.jeeves`:

```dockerfile
RUN pip3 install --break-system-packages mempalace
```

#### 2.2 Initialize MemPalace for the workspace

```bash
podman exec openclaw mempalace init /home/openclaw/workspace
```

This creates `~/.mempalace/` (inside the container's state directory — persisted via bind mount at `~/openclaw-state/`).

#### 2.3 Mine the wiki

```bash
podman exec openclaw mempalace mine /home/openclaw/workspace/wiki
```

Set up a cron job (via OpenClaw's built-in `cron` tool) to periodically re-mine:
```
mempalace mine /home/openclaw/workspace/wiki
```

#### 2.4 Add MemPalace as an MCP server

OpenClaw supports MCP skills. Create a workspace skill that wraps MemPalace's MCP server:

**File**: `~/openclaw-workspace/skills/mempalace/SKILL.md`

Or configure it directly in `openclaw.json` if OpenClaw supports MCP server config:

```json
"mcp": {
  "servers": {
    "mempalace": {
      "command": "python3",
      "args": ["-m", "mempalace.mcp_server"]
    }
  }
}
```

This gives Psmith 19 additional tools:
- **Palace read**: `search`, `list_wings`, `list_rooms`, `get_taxonomy`
- **Palace write**: `add_drawer`, `delete_drawer`
- **Knowledge graph**: `kg_query`, `kg_add`, `kg_invalidate`, `kg_timeline`
- **Navigation**: `traverse`, `find_tunnels`
- **Agent diary**: `diary_write`, `diary_read`

#### 2.5 How they work together

```
User asks: "What do we know about X?"

1. memory_search (QMD) → finds relevant wiki pages by content similarity
2. mempalace search → finds structured entity/relationship data
3. mempalace kg_query → "What was true about X in March?"
4. Agent synthesizes answer from both sources
5. If answer reveals new knowledge → write to wiki + mempalace add_drawer
```

QMD handles **content retrieval** (find the right pages). MemPalace handles **structured queries** (entity relationships, temporal facts, contradictions). They complement each other.

## What Each Layer Provides

| Need | Solution |
|------|----------|
| Agent creates/edits knowledge pages | Standard `write`/`edit` tools → wiki/*.md |
| Agent searches knowledge | `memory_search` → QMD hybrid search over wiki + memory |
| Agent tracks entities & relationships | MemPalace knowledge graph (`kg_query`, `kg_add`) |
| Agent detects contradictions | MemPalace contradiction detection |
| Agent asks temporal questions | MemPalace `kg_timeline` |
| Human browses knowledge | Obsidian desktop → open `~/openclaw-workspace/wiki/` as vault |
| Human sees connections | Obsidian graph view (follows `[[wikilinks]]`) |
| Knowledge persists across restarts | Files on host disk via existing bind mount |
| Knowledge grows over time | Agent follows ingest/lint workflows from SCHEMA.md |

## Files to Create/Modify

### Phase 1

| Action | File |
|--------|------|
| Modify | `Containerfile.jeeves` — add Bun + QMD |
| Modify | `~/openclaw-config/openclaw.json` — add memory/QMD config |
| Modify | `~/openclaw-workspace/AGENTS.md` — add wiki section |
| Create | `~/openclaw-workspace/wiki/.obsidian/app.json` |
| Create | `~/openclaw-workspace/wiki/SCHEMA.md` |
| Create | `~/openclaw-workspace/wiki/index.md` |
| Create | `~/openclaw-workspace/wiki/log.md` |
| Create | `~/openclaw-workspace/wiki/{sources,concepts,entities,topics}/` |
| Create | `~/openclaw-workspace/wiki/templates/{concept,entity,topic,source-summary}.md` |
| Create | `~/openclaw-workspace/skills/wiki/SKILL.md` |

### Phase 2

| Action | File |
|--------|------|
| Modify | `Containerfile.jeeves` — add `pip install mempalace` |
| Create | `~/openclaw-workspace/skills/mempalace/SKILL.md` (or MCP config) |

## Risks

| Risk | Mitigation |
|------|-----------|
| Bun install fails in container | Fall back to `npm install -g @tobilu/qmd` |
| QMD first search slow (GGUF download) | Accept it; optionally pre-warm in Containerfile |
| File ownership mismatch | Create wiki dirs from inside container via `podman exec` |
| MemPalace ChromaDB adds memory overhead | Phase 2 is optional; monitor with `podman stats` |
| Agent over-writes to wiki (noise) | SCHEMA.md lint rules + periodic human review |
| Wiki grows too large for QMD indexing | QMD handles large corpora well; monitor embed times |

## Implementation Status

All phases have been implemented. For current verification, run:

```bash
podman exec openclaw qmd --version                # QMD search engine
podman exec openclaw mempalace status              # MemPalace drawers + rooms
podman exec openclaw npx mcporter list             # MCP server (19 tools)
```

Components deployed:
- **QMD** — installed via Containerfile (`npm install -g @tobilu/qmd`), enabled in `openclaw.json`
- **MemPalace** — installed via Containerfile (`pip install mempalace`), initialized per deployment by `setup-wiki.sh`
- **Wiki structure** — bootstrapped by `setup-wiki.sh` at `~/openclaw-state/workspace/wiki/`
- **MCP server** — registered in `~/openclaw-config/mcporter.json`, created by `install.sh`
- **Cron jobs** — watchdog (every 5 min) + mempalace maintenance (daily 3 AM), installed by `install.sh`
- **Agent instructions** — wiki + mempalace sections appended to `AGENTS.md` in the state workspace

See README.md for the full setup and operations guide.
