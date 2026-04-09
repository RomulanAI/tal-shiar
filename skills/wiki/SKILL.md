---
name: wiki
description: Maintain the persistent wiki knowledgebase. Covers page creation, MOC management, ingestion of sources, cross-referencing, index maintenance, and lint/audit operations. Read wiki/_meta/SCHEMA.md for full conventions.
---

# Wiki Knowledgebase Skill

The wiki at `wiki/` is a persistent Obsidian-compatible vault with dual navigation: `_meta/index.md` for LLM search, `MOCs/` for human browsing.

## Quick Reference

- **Schema**: `wiki/_meta/SCHEMA.md` (conventions and rules)
- **Index**: `wiki/_meta/index.md` (machine catalog — update on every create/delete)
- **Log**: `wiki/_meta/log.md` (append on every operation)
- **Templates**: `wiki/_templates/` (use when creating pages)
- **Content**: `wiki/pages/` (all pages, flat)
- **Navigation**: `wiki/MOCs/` (Maps of Content for humans)

## Page Creation

1. Choose `wiki/pages/` (all content goes here)
2. Name: `kebab-case.md`
3. Copy template from `wiki/_templates/` matching the type
4. Fill frontmatter: `title` (QUOTED!), `type`, `tags`, `status: draft`, `created`, `updated`, `up: "[[MOC]]"`, `related`
5. Write content following template structure
6. Add `[[wikilinks]]` to related pages; update those pages to link back
7. Add to `wiki/_meta/index.md` under the correct MOC group
8. Append CREATE to `wiki/_meta/log.md`

## MOC Management

MOCs live in `wiki/MOCs/` and are the human navigation layer.

**Create a MOC when**: 5+ pages cluster around a theme.

**MOC structure**: Title, one-paragraph context, then grouped links with one-line descriptions. Use `wiki/_templates/moc.md`.

**Maintain MOCs**: when creating a page, always set `up: "[[MOC Name]]"`. If no MOC fits, create one.

## Ingest Workflow

1. Save raw document to `wiki/sources/`
2. Read thoroughly — identify concepts, entities, topics
3. For each: check if page exists (`memory_search`), create or update in `wiki/pages/`
4. Assign `up:` to appropriate MOC — create MOC if needed
5. Cross-reference with `[[wikilinks]]`
6. Update `wiki/_meta/index.md`
7. Append INGEST to `wiki/_meta/log.md`

## Lint Workflow

Run periodically or when asked:

1. **Orphans**: pages with no `up:` — assign to a MOC
2. **Stubs**: `status: stub` older than 30 days — flesh out or merge into a parent page
3. **Broken links**: `[[wikilinks]]` to non-existent pages — create or fix
4. **Missing frontmatter**: pages lacking required fields — add them
5. **Stale pages**: `status: complete` with `updated` over 90 days — review and update
6. **MOC drift**: pages that no longer fit their `up:` — reassign
7. **Index completeness**: verify all pages appear in `_meta/index.md`

Append LINT to `wiki/_meta/log.md` with findings.

## Quality Principles

- **Cleaner over time, not just bigger.** Merge stubs. Promote drafts to complete.
- **One thorough page beats five thin stubs.**
- **Always quote frontmatter titles.** Unquoted colons crash the wiki viewer.
- **Atomic pages.** One idea per file. Self-contained. Well-titled.
- **Every page has a home.** The `up:` field connects it to a MOC.
