# The Romulan Wiki: Structure for Humans and Machines

## The Problem

We have two audiences for the same knowledge base:

1. **The LLM agent (Jeeves/Psmith)** — navigates via `memory_search` (QMD semantic search), reads `index.md` to find pages, follows `[[wikilinks]]` for cross-references. Needs: structured frontmatter, consistent naming, a reliable index, parseable log.

2. **The human (pdawg)** — browses via Quartz web UI or Obsidian desktop. Needs: visual navigation (graph view, backlinks), scannable structure, context at a glance, not drowning in 14 Pozar chapter stubs when looking for ERPNext lessons.

Karpathy's LLM Wiki optimizes for #1. Obsidian PKM community optimizes for #2. We need both.

## Research Synthesis

### What Karpathy gets right (for LLMs)
- **Compilation over retrieval** — the wiki is a pre-built artifact, not re-derived each query
- **index.md as the map** — LLMs read this first to find relevant pages
- **log.md as history** — parseable record of what changed and when
- **Schema as law** — explicit conventions the agent follows mechanically
- **Three layers** — sources (immutable) → wiki pages (agent-maintained) → schema (governing)

### What the Obsidian/PKM community gets right (for humans)
- **Maps of Content (MOCs)** over flat indexes — a MOC is a curated note that links to related notes with context ("if links are roads, MOCs are maps"). Multiple MOCs can link to the same page. They're bottom-up: you create one when a cluster of notes starts feeling messy.
- **Folders for structure, links for discovery** — folders give a home address; `[[wikilinks]]` create the serendipitous connections. Tags are for actionable states (`#stub`, `#stale`, `#needs-review`), not categories.
- **PARA principle** — organize by actionability, not topic. Projects (active), Areas (ongoing), Resources (reference), Archives (done). This prevents the vault from becoming a graveyard of orphan reference pages.
- **Atomic notes** — one idea per page, well-titled, self-contained. Better for linking than monolithic docs.
- **Progressive summarization** — don't try to be complete on first write. Pages grow richer over time.

### Where they conflict
| Karpathy | Obsidian PKM | Resolution |
|----------|-------------|------------|
| Flat category folders (concepts/, entities/, topics/) | Deeper nesting or no folders (link-based) | **Keep shallow folders but add MOCs as navigation layer** |
| Single index.md listing everything | MOCs per topic cluster | **Both: index.md for the LLM, MOCs for the human** |
| Schema-driven page templates | Organic, grow-as-you-go | **Templates for new pages, but allow organic growth within them** |
| Source summaries as separate pages | Annotations inline or in source | **Keep source summaries separate (cleaner for both audiences)** |

## The Proposed Structure

```
wiki/
├── _meta/                    # Machine-readable navigation (LLM-first)
│   ├── index.md              # Master catalog — LLM reads this to find pages
│   ├── log.md                # Append-only operations log
│   └── SCHEMA.md             # Conventions, rules, templates
│
├── _templates/               # Page scaffolds (ignored by Quartz + QMD)
│   ├── concept.md
│   ├── entity.md
│   ├── topic.md
│   ├── moc.md
│   └── source-summary.md
│
├── MOCs/                     # Maps of Content (human-first navigation)
│   ├── RF Engineering.md     # Links to Pozar chapters, antenna theory, etc.
│   ├── ERPNext Training.md   # Links to lessons, curriculum, Ketki, etc.
│   └── Due Diligence.md      # Links to Karya, Logipix analyses
│
├── sources/                  # Layer 1: raw/immutable curated documents
│   ├── pozar-microwave-engineering.md
│   └── erpnext-skill-notes.md
│
├── pages/                    # Layer 2: all wiki content (flat, atomic)
│   ├── pozar-chapter-1.md
│   ├── ...
│   ├── erpnext-lesson-1.md
│   ├── karya-group.md
│   ├── karan-rele.md
│   ├── logipix.md
│   └── tufte-latex-framework.md
│
└── assets/                   # Images, PDFs, attachments
```

### Key design decisions

**1. Flat `pages/` instead of concepts/entities/topics/**

The current three-folder split (concepts vs entities vs topics) is a taxonomy headache. Is "ERPNext Lesson 1" a topic or a concept? Is "Tufte-LaTeX Framework" a concept or an entity? These distinctions help an LLM classify, but they confuse humans and create wrong-folder problems.

Instead: one flat `pages/` folder. The *type* goes in YAML frontmatter (`type: concept | entity | topic | analysis | lesson`). The LLM can filter by type via frontmatter; the human doesn't need to care about which folder.

**2. MOCs as the human navigation layer**

Instead of navigating folders, humans browse Maps of Content. A MOC is a curated page that groups related pages with context:

```markdown
# RF Engineering

The Pozar textbook forms the backbone of RF theory. Key chapters:
- [[pozar-chapter-1]] — Maxwell's equations, boundary conditions
- [[pozar-chapter-3]] — Transmission lines, impedance matching
- [[pozar-chapter-7]] — Power dividers, directional couplers

Related:
- [[balanis-antenna-theory-digestion]] — complementary antenna text
- [[tufte-latex-framework]] — used for typesetting RF notes
```

MOCs emerge organically: when a cluster of 5+ pages feels related, create a MOC. The LLM can create MOCs during its curation pass.

**3. `_meta/` for machine navigation**

`index.md`, `log.md`, and `SCHEMA.md` move to `_meta/`. The underscore signals "infrastructure, not content." The LLM reads `_meta/index.md` as its entry point; humans read `MOCs/`.

**4. Tags for status, not categories**

Tags like `#stub`, `#stale`, `#needs-review`, `#high-quality` mark page health — not topic. This helps both the LLM's lint pass and the human scanning for gaps.

**5. Frontmatter does double duty**

```yaml
---
title: "Lesson 1: The Atomic Unit"
type: lesson                    # concept | entity | topic | analysis | lesson | moc | source
tags: [erpnext, frappe]
status: complete                # stub | draft | complete | stale
created: 2026-04-07
updated: 2026-04-07
up: "[[ERPNext Training]]"      # parent MOC (human breadcrumb)
related: ["[[erpnext-lesson-2]]", "[[ketki-ghaisas]]"]
---
```

The `up` field is key — it tells both human and LLM which MOC this page belongs to. Quartz renders it as a breadcrumb. The LLM uses it to maintain MOC consistency.

## What changes from current wiki

| Current | Proposed | Why |
|---------|----------|-----|
| `concepts/`, `entities/`, `topics/` folders | Single `pages/` folder | Eliminates classification headaches |
| `index.md` at wiki root | `_meta/index.md` | Separates infrastructure from content |
| `log.md` at wiki root | `_meta/log.md` | Same |
| `SCHEMA.md` at wiki root | `_meta/SCHEMA.md` | Same |
| `templates/` at wiki root | `_templates/` (underscore) | Consistent with Obsidian convention for ignored folders |
| No MOCs | `MOCs/` directory with curated navigation pages | Human navigation layer |
| Type = folder location | Type = frontmatter field | More flexible, queryable |
| No status tracking | `status:` frontmatter field + tags | Enables lint and quality tracking |
| No `up:` link | `up:` points to parent MOC | Breadcrumb navigation for humans |

## Implementation plan

### Step 1: Restructure existing wiki
- Create `_meta/`, `MOCs/`, `pages/`, `_templates/`
- Move all existing pages from `concepts/`, `entities/`, `topics/` into `pages/`
- Move `index.md`, `log.md`, `SCHEMA.md` into `_meta/`
- Move templates into `_templates/`
- Update all `[[wikilinks]]` across pages (no folder prefix needed with flat structure)

### Step 2: Create initial MOCs from existing content
- `MOCs/RF Engineering.md` — group Pozar chapters + antenna theory
- `MOCs/ERPNext Training.md` — group lessons + curriculum + Ketki
- `MOCs/Due Diligence.md` — group Karya + Logipix analyses

### Step 3: Update SCHEMA.md with new conventions
- New folder structure
- MOC creation rules
- Frontmatter spec with `up:`, `status:`, `type:`
- Tag vocabulary (`#stub`, `#stale`, `#needs-review`)

### Step 4: Update AGENTS.md wiki section
- Reference new structure
- Instruct agent to create MOCs when clusters emerge
- Instruct agent to set `up:` links on every page

### Step 5: Update Quartz ignorePatterns
- Ignore `_templates/` (already ignoring `templates`)
- Ensure `_meta/` pages are rendered (they're valid content)

### Step 6: Update wiki skill (SKILL.md)

### Step 7: Update setup-wiki.sh to create new structure

## Files to modify
- All existing wiki pages (move + update frontmatter)
- `_meta/SCHEMA.md` (new)
- `_meta/index.md` (new)
- `MOCs/*.md` (new)
- `~/openclaw-workspace/skills/wiki/SKILL.md`
- `~/openclaw-state/workspace/AGENTS.md` (append)
- `~/tal-shiar/setup-wiki.sh`
- `~/tal-shiar/quartz/quartz.config.ts` (ignorePatterns)

## Verification
1. Quartz renders cleanly at `:9090` with MOCs navigable
2. Graph view shows MOCs as hub nodes connecting clusters
3. `memory_search` still finds wiki pages via QMD
4. Agent can create a new page following the schema
5. Agent can create a MOC when asked
