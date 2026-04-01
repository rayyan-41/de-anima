---
name: obsidian_yaml_enforcer
description: "A strict technical blueprint for creating valid Obsidian frontend matter for the De Anima vault."
---

# Obsidian YAML Enforcer

## Purpose
This skill encapsulates the canonical rules for the De Anima vault's YAML frontmatter. Whenever an agent is tasked with creating, moving, or modifying a note (e.g., `@tagger`, `@technician`), they **MUST** execute these exact rules.

## Canonical Properties Schema

Every note in the vault MUST have a valid YAML frontmatter block at the top exactly matching this structure:

```yaml
---
title: "Note Title"
date: YYYY-MM-DD
domain: [Art | History | Islam | Literature | Reason | Science]
category: [sub-category]
status: complete
tags: [domain, category, topic1, topic2, ..., ai-generated]
---
```

## Field Constraints

1. **`title:`** String. Must match the filename (minus the prefix if applicable).
2. **`date:`** YYYY-MM-DD format.
3. **`domain:`** Exactly ONE value. Valid domains:
   - `Art`
   - `History`
   - `Literature`
   - `Reason`
   - `Science`
   - `Islam`
4. **`category:`** Exactly ONE value. It must correspond directly to the domain.
   - `Art`: `Art History` | `Art Theory`
   - `History`: `Empire` | `Biography` | `Geopolitical` | `Medieval` | `Contemporary`
   - `Literature`: `Books` | `Myths and Legends` | `Short Stories` | `Reference`
   - `Reason`: `Philosophy` | `Logic` | `Metaphysics` | `Ethics` | `Epistemology`
   - `Science`: `Astronomy` | `Mathematics` | `Computer Science` | `AI` | `Web Dev` | `Physics`
   - `Islam`: `Aqeedah` | `Fiqh`
5. **`status:`** Exactly ONE value: `complete` or `incomplete`.
6. **`tags:`** An inline array using `[]` syntax.
   - **NO HASHTAGS (#)**. Tags in the YAML frontmatter must not contain a preceding hashtag. Example: `tags: [islam, fiqh, ramadan, ai-generated]`
   - **1 Domain Tag**: Must match the domain.
   - **1 Category Tag**: Must match the category. Spaces should be replaced with hyphens (e.g., `art-history`).
   - **3-10 Topic Tags**: Must cover the subject, key figures, sub-topics, schools, era, etc.
   - **Special Islam Topic Tags**: `hanafi`, `maliki`, `shafii`, `hanbali`, `ibadat`, `muamalat`, `contemporary-fiqh`
   - **The `ai-generated` Tag**: This must ALWAYS be the final tag in the array for AI-written notes.

## Validation Script Protocol

Before finalizing a YAML frontmatter modification, you should execute this PowerShell script to validate the tag array. Call this script using the `shell` tool:

```powershell
powershell -File "C:\Users\Pc\.gemini\tools\validate_tags.ps1" -TagLine "[your constructed tags comma-separated without #]"
```
If the script fails, read the output, correct the errors in the `tags` array, and run the script again until it passes.
