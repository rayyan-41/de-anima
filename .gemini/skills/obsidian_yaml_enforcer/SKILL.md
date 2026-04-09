---
title: "SKILL"
date: 2026-04-05
domain: 
category: 
status: complete
tags:
  - cli
---
# Obsidian YAML Enforcer

## Purpose

This skill is the authoritative schema and tag-policy engine for De Anima notes.
It ensures every note has valid frontmatter, canonical fields, and relevance-safe tags.

If any local prompt instruction conflicts with this skill, this skill wins.

## Canonical Frontmatter Schema

Every note must begin with:

```yaml
---
title: "[Note Title]"
domain: [art|history|islam|literature|reason|science]
category: [canonical category value]
status: [complete|incomplete]
---
```

Required fields:

- `title`
- `domain`
- `category`
- `status`
- `tags`

## Domain and Category Policy

Use lowercase canonical values.

Allowed domains:

- `art`
- `history`
- `islam`
- `literature`
- `reason`
- `science`

Allowed category families (normalize equivalent spellings):

- Art: `art-history`, `art-theory`
- History: `medieval-and-late-medieval`, `contemporary`, `biographies`, `empire`, `biography`, `geopolitical`, `history`
- Islam: `aqeedah`, `fiqh`, `fiqh/ibadat`, `fiqh/muamalat`, `fiqh/contemporary`, `ibadat`, `muamalat`, `contemporary-fiqh`
- Literature: `books`, `myths-and-legends`, `short-stories`, `reference`, `literature`
- Reason: `philosophy`, `logic`, `metaphysics`, `ethics`, `epistemology`, `reason/philosophy`
- Science: `astronomy`, `mathematics`, `computer-science`, `ai`, `web-dev`, `science`, `science/math`, `science/cs`, `science/ai`, `science/web`

Normalization rules:

- Convert spaces/underscores to hyphens where applicable.
- Preserve slash form when category is hierarchical (for example `fiqh/ibadat`).

## Tag Construction Policy

Canonical order:

1. domain tag
2. category tag
3. exactly one structural tag
4. core topic tags
5. optional supporting tags
6. `cli` (always last)

Formatting rules:

- Use plain values in YAML array, no `#` prefix.
- Lowercase tags.
- Prefer kebab-case for multi-word tags.
- No duplicates.

Structural tags by domain:

- History: `empire`, `biography`, `history`
- Islam: `aqeedah`, `fiqh`
- Art: `art/history`, `art/theory`
- Science: `science`, `science/math`, `science/cs`, `science/ai`, `science/web`
- Literature: `literature`
- Reason: `reason/philosophy`

Tag quantity constraints:

- Core topic tags: 3-6
- Supporting topic tags: 0-4
- Total topic tags: 3-10

Relevance rules:

- Mentions are not tags.
- Incidental entities must not be tagged.
- Tag only concepts/figures that are materially analyzed.

## Validation Procedure

After constructing tags, run:

```powershell
powershell -File "C:\Users\Pc\.gemini\tools\validate_tags.ps1" -TagLine "[comma-separated tags without #]"
```

Interpretation:

- `PASS`: write frontmatter
- `FAIL`: correct and rerun until PASS

## Rewrite Scope Rules

When fixing existing notes:

- You may edit frontmatter fields only.
- Do not rewrite body prose.
- Do not alter headings/content sections except for YAML normalization.

## Report Contract

Output a compact machine-readable summary:

```text
YAML_ENFORCER_REPORT
note_path: [path]
status: [PASS|CORRECTED]
frontmatter_fields: [list]
tags_final: [list]
issues_fixed: [list or none]
```

## Failure Guardrails

- If domain/category cannot be resolved confidently, keep file unchanged and report explicit uncertainty.
- Never fabricate taxonomy values.
- Never drop `cli`.
