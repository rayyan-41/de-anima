---
name: get_related_notes
description: Find related notes by tag overlap for wikilink insertion. Scans the entire De Anima vault, compares each note's tags against provided core and supporting tags, and returns a ranked list of backlink candidates. Enforces the formatter link policy with primary (>=2 shared core tags) and secondary (>=1 core tag + same category) match tiers. Used by the linker agent in the post-note pipeline to discover policy-valid wikilink targets.
---

# Get Related Notes

## Goal
Scan the vault for notes that share tag overlap with a source note and return a ranked list of candidates for backlink/wikilink insertion, enforcing the formatter's link policy thresholds.

## Instructions
1. Call this script during the **linker** stage of the post-note pipeline.
2. Pass the source note's path, its core tags (from the tagger), and optionally its supporting tags.
3. The script scans all `.md` files in the vault, parses their YAML frontmatter tags, and scores overlap:
   - **PRIMARY match**: ≥2 shared core tags (score = core×2 + support×1)
   - **SECONDARY match**: ≥1 shared core tag AND same category (tags[1])
4. Results are sorted by descending score, deduplicated by path, and trimmed to `-TopN`.
5. Use the output to insert `[[wikilinks]]` and populate the Related Notes section.

## Usage
```powershell
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\get_related_notes\scripts\get_related_notes.ps1" `
    -NotePath "E:\De Anima\Islam\Fiqh\Ibadat\Rafa al-Yadayn (Fiqh).md" `
    -CoreTags "islam, fiqh, prayer, salah, hanafi" `
    -SupportingTags "hadith-analysis, shafii" `
    -TopN 10
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-NotePath` | **Yes** | — | Full path to the source note (excluded from results). |
| `-CoreTags` | **Yes** | — | Comma-separated core tags from tagger handoff. |
| `-SupportingTags` | No | `""` | Comma-separated supporting tags for secondary scoring. |
| `-ExcludedMentions` | No | `""` | Comma-separated entity names to exclude as backlink targets. |
| `-VaultRoot` | No | `E:\De Anima` | Root of the vault. |
| `-TopN` | No | `15` | Maximum number of results to return. |
| `-MinScore` | No | `1` | Minimum overlap score required to include a candidate. |

## Output Format
```
CANDIDATES_FOUND: 4
---
SCORE:5 | MATCH:primary | PATH:E:\De Anima\Islam\Fiqh\Ibadat\Prayer (Fiqh).md | TAGS:islam,fiqh,prayer,ibadat,ai-generated
SCORE:3 | MATCH:primary | PATH:E:\De Anima\Islam\Fiqh\Ibadat\Wudu (Fiqh).md | TAGS:islam,fiqh,purification,ibadat,ai-generated
---
EXCLUDED_BY_POLICY: 0
```

If no matches: `NO_POLICY_VALID_CANDIDATES: ...`

## Constraints
- The source note is automatically excluded from results.
- Skips `_tmp/`, `.obsidian/`, `paintings_source/`, Map of Contents files, and sacred files.
- Entity exclusion uses normalized name matching (collapses hyphens/spaces).
- Exit code `0` in all cases (zero candidates is not an error).
