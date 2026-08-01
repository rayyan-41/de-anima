---
name: obsidian_yaml_enforcer
description: Authoritative frontmatter schema and tag-policy engine for De Anima notes. Defines the positional tag array - domain, category, type, themes, entities, marker - and how to derive each slot deterministically.
---

# Obsidian YAML Enforcer

## Purpose

This skill is the authoritative schema and tag-policy engine for De Anima notes.

If any local prompt instruction conflicts with this skill, this skill wins.

**The registries live in `.agents\taxonomy.json`, not in this file.** That file is
read directly by `validate_tags.ps1`. This document explains the *rules*; the JSON
holds the *values*. When you need the current list of categories, types, or themes,
read the JSON. Never hardcode a tag list anywhere else.

## Canonical Frontmatter

Every note carries exactly these four fields, in this order:

```yaml
---
date: YYYY-MM-DD
status: [complete|incomplete]
tags: [domain, category, type, theme(s), entity(ies), marker]
note: ""
---
```

There is **no** `title:`, `domain:`, or `category:` property. The filename is the
title; domain and category are the first two tags. If you find those legacy fields,
remove them.

`note:` is a free-text field owned by the user. Never write to it.

## The Tag Array Is Positional

Order is part of the schema, not a style preference. `validate_tags.ps1` reads slots
by position.

| # | Slot | Count | Source | Determinism |
|---|---|---|---|---|
| 1 | **domain** | exactly 1 | `taxonomy.domains` | mechanical — the top-level folder |
| 2 | **category** | exactly 1 | `taxonomy.domains[domain]` | mechanical — `taxonomy.folderMap` |
| 3 | **type** | exactly 1 | `taxonomy.types` | near-mechanical — the note's form |
| 4 | **themes** | 1–3 | `taxonomy.themes` | judgement, from a closed list |
| 5 | **entities** | 0–6 | open vocabulary | judgement, kebab-case |
| 6 | **marker** | exactly 1 | `cli` or `manual` | mechanical — who wrote it |

Total: 5–13 tags.

The four registries are **mutually disjoint by construction** — no string is both a
category and a type, or a type and a theme. This is what makes a tag's slot
unambiguous from the tag alone, and it is enforced by `audit_skill_sync.ps1`. If you
add a value to one registry, it must not collide with any other.

### Slot 1 — domain

The top-level folder, lowercased. No judgement.

### Slot 2 — category

Look up the note's folder in `taxonomy.folderMap`, longest prefix wins. A note in
`History/Early and Late Medieval (476- 1799)/The Crusades/` maps to `medieval`.
No judgement. If the folder is not in the map, stop and report — do not invent one.

### Slot 3 — type

What *form* the note takes, independent of subject:

| Type | Use for |
|---|---|
| `person` | a biography |
| `empire` | a polity or dynasty |
| `event` | a war, schism, revolution, discrete happening |
| `concept` | an idea, theory, mechanism, or method being explained |
| `work` | a specific book, painting, story, or artefact under analysis |
| `ruling` | a fiqh ruling |
| `creed` | an aqeedah / theological position |
| `technique` | a how-to or procedural note |
| `compendium` | a lookup table, lexicon, quote collection |
| `overview` | a survey spanning many subjects |

### Slot 4 — themes (1–3) — the linking substrate

**This is the most important slot and the one most often done badly.**

Themes come from a closed registry. They are the shared vocabulary that lets
`get_related_notes.ps1` find genuine relatives — the link policy matches on shared
core tags, and themes are what two different notes can actually have in common.
Entity tags almost never repeat across notes, so a note with no themes is a note
that can never be linked to anything.

Rules:
- At least one theme is mandatory. Validation fails without one.
- Pick themes the note **materially develops**, not ones it mentions.
- Prefer the more specific theme when two apply.
- If nothing in the registry fits, pick the closest and report the gap. Do not
  invent a theme — add it to `taxonomy.json` deliberately, as a schema change.

### Slot 5 — entities (0–6)

Open vocabulary: proper nouns and specific subjects the note actually analyses —
`al-ghazali`, `second-punic-war`, `barycentric-coordinates`.

- lowercase kebab-case, `^[a-z0-9]+(-[a-z0-9]+)*$`
- must not duplicate a domain, category, type, or theme already present
- **themes must all come before entities** in the array

Entities give precision in search. Themes give recall. You need both.

### Slot 6 — marker

- `cli` — produced by the generation pipeline.
- `manual` — written by hand by the vault owner.

Never relabel a `manual` note as `cli`. The distinction is what makes it possible to
filter human writing from generated writing, and only `cli` notes are subject to the
mandatory Table of Contents rule.

## Map of Contents Files

A MOC is exempt from the schema above. It is exactly three tags:

```yaml
tags: [<domain>, moc, cli]
```

Only the core domains have a MOC, and `Reason/` has none at all — its index is the
owner's hand-written `Chain Of Thoughts.md`. Do not create nested or sub-category
MOCs.

## Relevance Rules

- Mentions are not tags.
- Incidental entities must not be tagged.
- Tag only what the note materially analyses.
- A person is tagged only when their role is actually examined, not name-dropped.

## Validation

```powershell
powershell -File ".agents\tools\validate_tags.ps1" -TagLine "[comma-separated tags]"
```

Add `-Explain` to see how the tool assigned each slot — use this when a failure is
not obvious.

Interpretation:
- `PASS` — write the frontmatter.
- `FAIL` — correct the reported problem and rerun, **at most 3 attempts**.
- Still failing after 3 — write your best-effort array, set `status: incomplete`,
  report the final validator message. Never loop indefinitely.

## Rewrite Scope

When fixing existing notes:
- Frontmatter fields only.
- Never rewrite body prose, headings, or sections.

## Report Contract

```text
YAML_ENFORCER_REPORT
note_path: [path]
status: [PASS|CORRECTED|UNRESOLVED]
tags_final: [list]
slots: domain=[..] category=[..] type=[..] themes=[..] entities=[..] marker=[..]
issues_fixed: [list or none]
```

## Failure Guardrails

- If domain or category cannot be resolved from the folder, leave the file unchanged
  and report the uncertainty.
- Never fabricate a registry value.
- Never drop the marker tag.
