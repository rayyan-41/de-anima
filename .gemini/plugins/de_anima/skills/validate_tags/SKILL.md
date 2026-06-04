---
name: validate_tags
description: Validate a tag line against the De Anima canonical tag registry. Checks for exactly one domain tag, exactly one category tag, category-domain compatibility, minimum 3 topic tags (max 10), presence and position of ai-generated tag, and no duplicates. Accepts YAML inline, comma-separated, hash-prefixed, and bracket-wrapped tag formats. Used by the formatter agent in the post-note pipeline to enforce tag conformance.
---

# Validate Tags

## Goal
Validate a comma-separated (or space-separated) tag string against the De Anima vault's canonical tag registry, enforcing structural rules for domain tags, category tags, topic tags, and the `ai-generated` sentinel.

## Instructions
1. Call this script during the **formatter** stage of the post-note pipeline.
2. Pass the tag line from the note's YAML frontmatter.
3. The script validates six rules:
   1. **Exactly one domain tag**: `art`, `history`, `literature`, `reason`, `science`, `islam`.
   2. **Exactly one category tag**: Must be from the valid set for the detected domain.
   3. **Domain-category compatibility**: Category must be valid for the domain.
   4. **Topic tag count**: Minimum 3, maximum 10 freeform topic tags.
   5. **`ai-generated` tag**: Must be present and must be the **last** tag.
   6. **No duplicates**: All tags must be unique.
4. Parse the output: `PASS` or `FAIL: [reasons]`.
5. If `FAIL`, correct the tags and re-run until `PASS`.

### Canonical Category Map
| Domain | Valid Categories |
|--------|----------------|
| `art` | `art-history`, `art-theory` |
| `history` | `empire`, `biography`, `geopolitical`, `medieval`, `contemporary` |
| `literature` | `book`, `myth`, `short-story`, `reference` |
| `reason` | `philosophy`, `logic`, `metaphysics`, `ethics`, `epistemology` |
| `science` | `astronomy`, `mathematics`, `computer-science`, `ai`, `web-dev`, `physics` |
| `islam` | `aqeedah`, `fiqh` |

## Usage
```powershell
# Valid tag line
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\validate_tags\scripts\validate_tags.ps1" `
    -TagLine "islam, fiqh, prayer, salah, hanafi, shafii, ibadat, hadith-analysis, ai-generated"

# Also accepts hash-prefixed format
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\validate_tags\scripts\validate_tags.ps1" `
    -TagLine "#islam #fiqh #prayer #salah #hanafi #shafii #ibadat #hadith-analysis #ai-generated"

# Also accepts YAML array format
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\validate_tags\scripts\validate_tags.ps1" `
    -TagLine "[islam, fiqh, prayer, salah, hanafi, shafii, ibadat, hadith-analysis, ai-generated]"
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-TagLine` | **Yes** | — | Tag string in any supported format (comma-separated, hash-prefixed, bracket-wrapped). |

## Output Format
- `PASS` — all validation rules satisfied.
- `FAIL: missing domain tag; too few topic tags (2) - minimum is 3` — semicolon-separated failure reasons.

## Constraints
- Tags must NOT include `#` prefixes in the canonical form (the script strips them automatically).
- `ai-generated` must always be the **last** tag.
- Domain and category tags are NOT counted as topic tags.
- Modifiers (`incomplete`, `original-insight`) are also excluded from topic tag count.
