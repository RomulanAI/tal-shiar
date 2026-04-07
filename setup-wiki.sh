#!/bin/bash
# setup-wiki.sh — Bootstrap the wiki knowledgebase, MemPalace, and QMD indexing
#
# Run this AFTER the openclaw container is running (via systemd service).
# It creates the wiki directory structure, seed files, and initializes MemPalace.
#
# Safe to re-run: skips files that already exist, re-mines MemPalace idempotently.
#
# Usage:
#   ./setup-wiki.sh
#
# Prerequisites:
#   - openclaw container running (systemctl --user start container-openclaw.service)
#   - Container image built from Containerfile.jeeves (includes QMD + MemPalace)

set -euo pipefail

CONTAINER="openclaw"
WORKSPACE="/home/node/.openclaw/workspace"
WIKI="$WORKSPACE/wiki"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ──────────────────────────────────────────────────────
# Preflight
# ──────────────────────────────────────────────────────

if ! podman ps --filter name="$CONTAINER" --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "ERROR: container '$CONTAINER' is not running."
    echo "Start it first: systemctl --user start container-openclaw.service"
    exit 1
fi

log "Container '$CONTAINER' is running. Starting wiki bootstrap..."

exec_() { podman exec "$CONTAINER" "$@"; }
write_file() {
    local path="$1"
    # Only write if file doesn't exist or is empty
    if [ "$(exec_ bash -c "wc -c < '$path' 2>/dev/null || echo 0")" -le 1 ]; then
        if ! exec_ bash -c "cat > '$path'" <<< "$2"; then
            log "  ERROR: failed to write $path"
            return 1
        fi
        log "  created: $path"
    else
        log "  exists:  $path (skipped)"
    fi
}

# ──────────────────────────────────────────────────────
# 1. Create wiki directory structure
# ──────────────────────────────────────────────────────

log "Creating wiki directories..."
exec_ mkdir -p "$WIKI"/{.obsidian,_meta,_templates,MOCs,pages,sources/attachments,assets}

# ──────────────────────────────────────────────────────
# 2. Write seed files
# ──────────────────────────────────────────────────────

log "Writing seed files..."

write_file "$WIKI/.obsidian/app.json" '{
  "useMarkdownLinks": false,
  "newFileLocation": "folder",
  "newFileFolderPath": "topics",
  "attachmentFolderPath": "sources/attachments",
  "alwaysUpdateLinks": true,
  "showUnsupportedFiles": false,
  "promptDelete": true
}'

write_file "$WIKI/_meta/index.md" '---
title: Wiki Index
updated: '"$(date +%Y-%m-%d)"'
---

# Wiki Index

Master catalog of all wiki pages, maintained by Psmith. Grouped by category.

## Concepts

_No pages yet._

## Entities

_No pages yet._

## Topics

_No pages yet._

## Sources

_No sources ingested yet._'

write_file "$WIKI/_meta/log.md" '---
title: Wiki Operations Log
---

# Operations Log

Chronological record of wiki operations. Append-only.

| Timestamp | Operation | Pages Affected | Notes |
|-----------|-----------|----------------|-------|
| '"$(date +%Y-%m-%d)"' | INIT | — | Wiki knowledgebase initialized |'

write_file "$WIKI/sources/README.md" '---
title: Sources
type: readme
---

# Sources (Layer 1)

This directory holds **raw, immutable curated documents** — papers, articles, data files, transcripts, and other primary materials.

Sources are the input to the wiki. When a new source is added here, Psmith should:

1. Read the source document
2. Identify key concepts, entities, and topics
3. Create or update pages in `pages/`
4. Write a source summary in this directory (using the `source-summary` template)
5. Assign to a MOC via `up:` frontmatter field
6. Update `_meta/index.md` and append to `_meta/log.md`

Sources should not be modified after ingestion — they are the ground truth.'

write_file "$WIKI/_meta/SCHEMA.md" '---
title: Wiki Schema
type: schema
updated: '"$(date +%Y-%m-%d)"'
---

# Wiki Schema

This document governs how the wiki is structured, maintained, and grown. Read this before creating or modifying any wiki page.

## Directory Layout

| Directory | Contains |
|-----------|----------|
| `_meta/` | Machine navigation: index.md, log.md, SCHEMA.md |
| `_templates/` | Page scaffolds (ignored by Quartz) |
| `MOCs/` | Maps of Content — human navigation (curated topic hubs) |
| `pages/` | All content pages — flat, one idea per file |
| `sources/` | Raw/immutable curated documents |
| `assets/` | Images, PDFs, attachments |

**All content pages go in `pages/`.** Type is in frontmatter, not folder.

## Naming Conventions

- **Filenames**: `kebab-case.md` (lowercase, hyphens, no spaces)
- **Titles**: Title Case in the YAML frontmatter `title` field
- **Disambiguation**: Append qualifier in parens — `mercury-planet.md` vs `mercury-element.md`

## Required Frontmatter

Every wiki page (except templates and this schema) must have YAML frontmatter:

```yaml
---
title: "Page Title"           # ALWAYS quote — YAML breaks on colons
type: concept                 # concept | entity | topic | analysis | lesson | moc | source
tags: [tag1, tag2]
status: draft                 # stub | draft | complete | stale
created: YYYY-MM-DD
updated: YYYY-MM-DD
up: "[[Parent MOC]]"          # Which MOC this belongs to
related: ["[[other-page]]"]
---
```

**Title must always be quoted.** Unquoted colons break the wiki viewer.

## Cross-Referencing Rules

- Use `[[page-name]]` for all internal links (Obsidian wikilink syntax)
- Use `[[page-name|display text]]` when the display text differs from the filename
- Every page should have at least one inbound link (no orphans)
- Include a `## Related` section at the bottom of each page with relevant links
- When mentioning a concept, entity, or topic that has its own page, always link it

## Page Structure

Each page should follow the template for its type (see `_templates/`). General structure:

1. YAML frontmatter
2. H1 title (matches frontmatter `title`)
3. One-paragraph summary
4. Body sections (type-specific)
5. `## Related` section with `[[wikilinks]]`

## Operations Log Format

Every wiki operation must be appended to `log.md`:

| Timestamp | Operation | Pages Affected | Notes |
|-----------|-----------|----------------|-------|
| YYYY-MM-DD HH:MM | INGEST/CREATE/UPDATE/DELETE/LINT | page1, page2 | Brief description |

## Index Maintenance

`index.md` is the master catalog. When creating or deleting pages:

1. Add/remove the page entry under the correct category heading
2. Include a one-line description after the `[[wikilink]]`
3. Keep entries alphabetically sorted within each category

## Lint Rules

Periodically (or on request), run a lint pass checking for:

- **Orphan pages**: Pages with zero inbound `[[wikilinks]]`
- **Broken links**: `[[wikilinks]]` pointing to non-existent pages
- **Missing frontmatter**: Pages lacking required YAML fields
- **Stale pages**: Pages not updated in >90 days that reference fast-changing topics

Record lint results in `log.md` and fix issues found.

## Ingest Workflow

When processing a new source document:

1. Place the raw document in `sources/`
2. Read it thoroughly
3. Identify key concepts, entities, and topics mentioned
4. For each, check if a wiki page already exists:
   - If yes: update the existing page with new information, add source citation
   - If no: create a new page using the appropriate template
5. Create a source summary page in `sources/` (using `source-summary` template)
6. Add `[[wikilinks]]` between all related pages
7. Update `index.md` with any new pages
8. Append the operation to `log.md`'

# ──────────────────────────────────────────────────────
# 3. Write page templates
# ──────────────────────────────────────────────────────

log "Writing page templates..."

write_file "$WIKI/_templates/concept.md" '---
title: Concept Name
aliases: []
tags: []
type: concept
created: YYYY-MM-DD
updated: YYYY-MM-DD
related: []
---

# Concept Name

_One-paragraph summary of the concept._

## Description

Detailed explanation of the concept.

## Key Points

- Point 1
- Point 2

## Examples

Concrete examples or applications of this concept.

## Related

- [[related-page-1]]
- [[related-page-2]]'

write_file "$WIKI/_templates/entity.md" '---
title: Entity Name
aliases: []
tags: []
type: entity
created: YYYY-MM-DD
updated: YYYY-MM-DD
related: []
---

# Entity Name

_One-paragraph summary of what this entity is._

## Overview

What it is, what it does, why it matters.

## Key Details

- Detail 1
- Detail 2

## Context

How this entity fits into the broader picture.

## Related

- [[related-page-1]]
- [[related-page-2]]'

write_file "$WIKI/_templates/topic.md" '---
title: Topic Name
aliases: []
tags: []
type: topic
created: YYYY-MM-DD
updated: YYYY-MM-DD
related: []
---

# Topic Name

_One-paragraph summary of the topic._

## Background

Context and motivation for this topic.

## Details

Main content — instructions, analysis, or overview.

## Takeaways

Key conclusions or action items.

## Related

- [[related-page-1]]
- [[related-page-2]]'

write_file "$WIKI/_templates/source-summary.md" '---
title: "Summary: Source Title"
aliases: []
tags: []
type: source-summary
source: "sources/original-filename.md"
created: YYYY-MM-DD
updated: YYYY-MM-DD
related: []
---

# Summary: Source Title

_One-paragraph digest of the source document._

## Key Takeaways

1. Takeaway 1
2. Takeaway 2
3. Takeaway 3

## Concepts Identified

- [[concept-1]] — brief note on relevance
- [[concept-2]] — brief note on relevance

## Entities Mentioned

- [[entity-1]] — brief note on relevance
- [[entity-2]] — brief note on relevance

## Quotes / Key Passages

> Notable quote or passage from the source.

## Related

- [[related-page-1]]
- [[related-page-2]]'

# ──────────────────────────────────────────────────────
# 4. Initialize and mine MemPalace
# ──────────────────────────────────────────────────────

log "Initializing MemPalace..."

# Check if already initialized
if exec_ bash -c "test -f $WORKSPACE/mempalace.yaml" 2>/dev/null; then
    log "  MemPalace already initialized (mempalace.yaml exists)"
else
    # Non-interactive init: pipe enter to accept defaults
    printf '\n\n\n\n\n' | podman exec -i "$CONTAINER" mempalace init --yes "$WORKSPACE" 2>&1 | tail -5
    log "  MemPalace initialized"
fi

log "Mining workspace into MemPalace..."
exec_ mempalace mine "$WORKSPACE" 2>&1 | grep -E '(Done|Files processed|Drawers filed|skipped)'

log "Compressing MemPalace drawers (AAAK)..."
exec_ mempalace compress 2>&1 | grep -E '(Total|stored)' || true

# ──────────────────────────────────────────────────────
# 5. Register MemPalace MCP server via mcporter
# ──────────────────────────────────────────────────────

log "Checking MemPalace MCP server registration..."
MCPORTER_HOST="$HOME/openclaw-config/mcporter.json"
if [ -f "$MCPORTER_HOST" ]; then
    log "  mcporter.json exists on host"
else
    # Fallback: create it if install.sh wasn't used
    cat > "$MCPORTER_HOST" << 'MCPEOF'
{
  "mcpServers": {
    "mempalace": {
      "command": "python3 -m mempalace.mcp_server"
    }
  }
}
MCPEOF
    log "  created mcporter.json (MemPalace MCP server)"
fi
# Verify MCP server is reachable from inside the container
exec_ npx --yes mcporter list 2>&1 | grep -E '(mempalace|healthy)' | head -2

# ──────────────────────────────────────────────────────
# 6. Verify
# ──────────────────────────────────────────────────────

log ""
log "=== Verification ==="
log "QMD:       $(exec_ qmd --version 2>&1)"
log "MemPalace: $(exec_ mempalace status 2>&1 | head -2 | tail -1 | xargs)"
log "Wiki files: $(exec_ find "$WIKI" -name '*.md' -type f | wc -l) markdown files"
log "MCP:       $(exec_ npx --yes mcporter list 2>&1 | grep -o '[0-9]* tools' | head -1) via mempalace"
log ""
log "Wiki bootstrap complete!"
log "  - Wiki vault:    ~/openclaw-state/workspace/wiki/"
log "  - Open in Obsidian: File > Open Vault > navigate to above path"
log "  - QMD re-indexes every 5 minutes automatically"
log "  - MemPalace re-mines daily at 3 AM (cron)"
