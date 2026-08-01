---
name: obsidian_wikilink_engine
description: Authoritative link-construction engine for De Anima notes. Optimises for high-signal backlinks, enforces relevance gating, populates Related Notes sections, and updates domain MOCs after link insertion.
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

Collect `.md` notes recursively from the vault root.
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

Both are seeded by the candidate-ranking tool, which the linker runs first:

```powershell
powershell -File ".agents\tools\get_related_notes.ps1" -NotePath "[note path]" -CoreTags "[core tags]" -SupportingTags "[supporting tags]"
```

### Method A: Entity/Title Match

Find explicit entities in the source note that map to existing note titles.
Prefer exact and near-exact matches.

### Method B: Semantic Tag Overlap

Score candidates by taxonomy overlap:
- shared theme tags (the primary signal)
- shared entity tags
- same category
- same domain

Scoring is performed by `get_related_notes.ps1`, which computes:

```
score = (shared core tags x 2) + (shared supporting tags x 1)
```

Do not re-derive or re-weight this yourself — read the `SCORE:` value the tool
returns. In this vault "core tags" are the note's **theme** tags and "supporting
tags" are its **entity** tags, which is why a note with no themes scores against
nothing and ends up unlinkable.

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
  `[[Ibn Taymiyyah|his critique of kalam]]`
- Never link to a legacy prefixed filename (`BIO - `, `EMP - `) unless that
  file genuinely still carries the prefix on disk.
- Do not over-link repeated mentions.

## Related Notes Section

Populate `## Related Notes` with strongest candidates first.
Sort by relevance score descending.

Include only policy-valid links.
If fewer than two exist, add what is valid and report warning.

## MOC Update

After link insertion, update MOC via:

```powershell
powershell -File ".agents\tools\update_moc.ps1" -Domain "[Domain]" -NoteTitle "[Title]" -NoteFilename "[Filename]" -Category "[Category]"
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
