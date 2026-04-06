---
title: "SKILL"
date: 2026-04-06
domain: 
category: 
status: complete
tags:
  - ai-generated
---

# Obsidian Wikilink Engine

## Purpose

This skill is the authoritative link-construction engine for De Anima notes.
It optimizes for high-signal backlinks and suppresses mention-only noise.

If any local prompt instruction conflicts with this skill, this skill wins.

## Inputs

Required:
- `note_path`
- current note frontmatter (`domain`, `category`, `tags`)
- vault markdown index

Optional but preferred (from formatter):
- `core_tags`
- `supporting_tags`
- `excluded_mentions`
- link-policy thresholds

## Vault Index Build

Collect `.md` notes recursively under `E:\De Anima\`.
Exclude:
- `_tmp/`
- `.obsidian/`
- `paintings_source/`
- Sacred files where editing is forbidden

Build:
- title/filename map
- path map
- lightweight alias map (strip known prefixes for display aliases)

## Candidate Discovery

Use two parallel methods:

### Method A: Entity/Title Match

Find explicit entities in the source note that map to existing note titles.
Prefer exact and near-exact matches.

### Method B: Semantic Tag Overlap

Score candidates by taxonomy overlap:
- shared core tags
- shared supporting tags
- same category
- same domain

Suggested score:
- `+5` per shared core tag
- `+3` per shared supporting tag
- `+2` same category

## Relevance Gate (Mandatory)

Candidate must satisfy at least one:
- `>=2` shared core tags, OR
- `>=1` shared core tag AND same category

Hard rejects:
- self-links
- incidental mentions listed in `excluded_mentions`
- links with no meaningful topical overlap

## Insertion Rules

- First-mention rule is absolute.
- Max one new wikilink per paragraph.
- Prefer alias links in prose:
  `[[BIO - Ibn Taymiyyah|Ibn Taymiyyah]]`
- Do not over-link repeated mentions.

## Related Notes Section

Populate `## Related Notes` with strongest candidates first.
Sort by relevance score descending.

Include only policy-valid links.
If fewer than two exist, add what is valid and report warning.

## MOC Update

After link insertion, update MOC via:

```powershell
powershell -File "C:\Users\Pc\.gemini\tools\update_moc.ps1" -Domain "[Domain]" -NoteTitle "[Title]" -NoteFilename "[Filename]" -Category "[Category]"
```

Acceptable tool outcomes:
- `MOC_UPDATED`
- `MOC_CREATED`
- `ALREADY_LISTED`

## Conflict Handling

Ambiguous target (multiple close candidates):
- pick highest relevance score
- if tie, prefer same category then same domain
- report ambiguity in final output

Sparse vault condition:
- if `<2` policy-valid links exist, proceed and emit:
  `MINIMUM LINK WARNING: only [N] policy-valid wikilinks`

## Report Contract

```text
WIKILINK_ENGINE_REPORT
note_path: [path]
policy_used: [yes/no]
links_inserted: [N]
related_notes_added: [N]
moc_status: [MOC_UPDATED|MOC_CREATED|ALREADY_LISTED]
warnings: [none or list]
```

## Safety Rules

- Never fabricate non-existent targets.
- Never modify sacred files.
- Never bypass the relevance gate.
