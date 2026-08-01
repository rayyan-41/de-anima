---
name: obsidian_yaml_enforcer
description: Authoritative frontmatter schema and tag-policy engine for De Anima notes. Ensures every note has valid frontmatter and a canonical, relevance-gated tag array in the correct order.
---

# Obsidian YAML Enforcer

## Purpose

This skill is the authoritative schema and tag-policy engine for De Anima notes.
It ensures every note has valid frontmatter, canonical fields, and relevance-safe tags.

If any local prompt instruction conflicts with this skill, this skill wins.

Every rule below is enforced mechanically by `.agents\tools\validate_tags.ps1`.
**This document and that script must always agree.** If you find a disagreement,
report it rather than guessing — one of the two is out of date.

## Canonical Frontmatter Schema

Every note must begin with exactly these four fields, in this order:

```yaml
---
date: YYYY-MM-DD
status: [complete|incomplete]
tags: [domain, category, topic1, topic2, ..., cli]
note: ""
---
```

Required fields: `date`, `status`, `tags`, `note`.

There is **no** `title:`, `domain:`, or `category:` property. The note's title is its
filename; its domain and category are the first two entries of the `tags` array.
Do not add, restore, or infer those properties — earlier revisions of this vault used
them and they were deliberately removed.

## Tag Construction Policy

Canonical order:

1. domain tag (exactly one)
2. category tag (exactly one)
3. core topic tags (3-6)
4. optional supporting topic tags (0-4)
5. `cli` (always last)

The category tag **is** the note's structural classifier. There is no separate
structural-tag slot — adding one produces two category tags and fails validation.

Formatting rules:

- Plain values in a YAML inline array, no `#` prefix.
- Lowercase.
- kebab-case for multi-word tags.
- No slash-separated forms. Use `art-history`, never `art/history`.
- No duplicates.

## Canonical Registry

Allowed domain tags:

`art`, `history`, `islam`, `literature`, `reason`, `science`

Allowed category tags, by domain — these exact strings and no others:

| Domain | Valid category tags |
|---|---|
| `art` | `art-history`, `art-theory` |
| `history` | `empire`, `biography`, `geopolitical`, `medieval`, `contemporary` |
| `islam` | `aqeedah`, `fiqh` |
| `literature` | `book`, `myth`, `short-story`, `reference` |
| `reason` | `philosophy`, `logic`, `metaphysics`, `ethics`, `epistemology` |
| `science` | `astronomy`, `mathematics`, `computer-science`, `ai`, `web-dev`, `physics` |
| *(any)* | `moc` — Map of Contents files only |

`moc` is valid in every domain. MOC files are indexes rather than topic notes, so
they are exempt from the 3-topic-tag minimum: `[literature, moc, cli]` is complete
and valid.

Normalization rules:

- Convert spaces and underscores to hyphens.
- Collapse any legacy slash form to its flat equivalent (`fiqh/ibadat` → `fiqh`,
  `science/cs` → `computer-science`, `reason/philosophy` → `philosophy`).
- Singularize legacy plurals (`books` → `book`, `biographies` → `biography`,
  `myths-and-legends` → `myth`, `short-stories` → `short-story`).

Tag quantity constraints:

- Core topic tags: 3-6
- Supporting topic tags: 0-4
- Total topic tags: 3-10 (validation fails below 3 or above 10)

Relevance rules:

- Mentions are not tags.
- Incidental entities must not be tagged.
- Tag only concepts/figures that are materially analyzed.

## Validation Procedure

After constructing tags, run:

```powershell
powershell -File ".agents\tools\validate_tags.ps1" -TagLine "[comma-separated tags without #]"
```

Interpretation:

- `PASS`: write frontmatter.
- `FAIL`: correct the reported problem and rerun, **at most 3 attempts**.
- Still failing after 3 attempts: write your best-effort array, set `status: incomplete`,
  and report the final validator message. Never loop indefinitely.

## Rewrite Scope Rules

When fixing existing notes:

- You may edit frontmatter fields only.
- Do not rewrite body prose.
- Do not alter headings or content sections except for frontmatter normalization.

## Report Contract

Output a compact machine-readable summary:

```text
YAML_ENFORCER_REPORT
note_path: [path]
status: [PASS|CORRECTED|UNRESOLVED]
frontmatter_fields: [list]
tags_final: [list]
issues_fixed: [list or none]
```

## Failure Guardrails

- If domain/category cannot be resolved confidently, keep the file unchanged and
  report explicit uncertainty.
- Never fabricate taxonomy values.
- Never drop `cli`.
