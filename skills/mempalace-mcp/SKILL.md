# Skill: MemPalace MCP (structured memory + knowledge graph)

## What this is

MemPalace is a **local-first memory palace** that stores verbatim information and exposes **19 MCP tools** (search, filing, knowledge graph, and an agent diary).

In Tal Shiar, MemPalace is registered as an MCP server named **`mempalace`** via MCPorter (`/config/mcporter.json` inside the container).

### When to use MemPalace vs QMD

- Use **QMD / `memory_search`** when you need *broad fuzzy retrieval* over Markdown (wiki + memory notes) and citations.
- Use **MemPalace MCP** when you need *structured retrieval*:
  - facts about people/projects and how they changed over time
  - relationships between entities
  - timelines ("what was true in March")
  - durable decisions, incidents, and outcomes that should be queryable later
  - end-of-session diary logging

## First probe (always do this before relying on it)

1. Call `mempalace_status`
   - confirms the palace is reachable
   - returns the memory protocol + AAAK dialect spec
   - includes `palace_path` so you can confirm you're using the persisted palace

2. Then call `mempalace_search` with a narrow query.

## Tool cheat sheet

### Palace read
- `mempalace_status()`
- `mempalace_search(query, wing?, room?, n_results?)`
- `mempalace_list_wings()` / `mempalace_list_rooms(wing)`
- `mempalace_get_taxonomy()`

### Knowledge graph (time-aware)
- `mempalace_kg_query(entity, relation?, as_of?, since?, until?)`
- `mempalace_kg_timeline(entity)`
- `mempalace_kg_stats()`

### Palace write (verbatim filing)
- `mempalace_add_drawer(wing, room, content, source?, tags?)`
  - Store key verbatim snippets/decisions/outcomes.
  - Prefer short, high-signal content blocks.
- `mempalace_delete_drawer(id)` (rare)

### Diary (end of session)
- `mempalace_diary_write(agent, content)`
- `mempalace_diary_read(agent, last_n?)`

## Operating rules

- **Do not guess** about past decisions or identity facts. If it matters, query MemPalace first.
- Prefer:
  1) `mempalace_kg_query` for factual/relational questions
  2) `mempalace_search` when you want verbatim context
- After completing a significant task or incident response, write a short diary entry with:
  - what changed
  - what was learned
  - what to do next

## Troubleshooting (container ops)

If MemPalace tools are missing/unhealthy:

1. Verify the container has a mcporter config:
   - inside container: `/config/mcporter.json`

2. Verify MCP server registration from inside the container:
   - `mcporter list --config /config/mcporter.json`

3. If `mempalace` entry is missing from mcporter.json on the host:
   - run (host): `./scripts/ensure-mcporter-mempalace.sh ~/openclaw-config/mcporter.json`
   - then restart the service: `systemctl --user restart openclaw-compose.service`

4. Verify MemPalace itself:
   - `mempalace status`
   - if not initialized: run `./setup-wiki.sh` (host)
