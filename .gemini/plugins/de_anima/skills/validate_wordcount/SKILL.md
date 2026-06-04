---
name: validate_wordcount
description: Validate a note's word count against template-specific minimums. Delegates actual counting to word_count.ps1 (which correctly strips YAML frontmatter), then compares against the provided minimum threshold. Outputs WORDCOUNT_PASS or WORDCOUNT_FAIL with deficit information. Used by the weaver during Stage 5 of the note creation pipeline. Template minimums — empire/biography 1500, geopolitical 5000, fiqh 8000, aqeedah 3000, cs/ai 4000, notebooklm 4000, general 1000.
---

# Validate Word Count

## Goal
Verify that an assembled note meets the minimum word count threshold for its template type. Delegates the actual word counting to `word_count.ps1` to avoid frontmatter inclusion bugs.

## Instructions
1. Call this script during **Stage 5** of the pipeline, after weaver assembly.
2. Pass the note path, the minimum word count for the template, and optionally the template name.
3. The script:
   - Calls `word_count.ps1` to get the accurate body word count (frontmatter excluded).
   - Compares against `-MinWords`.
   - Outputs `WORDCOUNT_PASS` or `WORDCOUNT_FAIL` with the deficit.
4. If `WORDCOUNT_FAIL`: return the note to the content agent with the deficit count for expansion of thinnest sections, then re-run this script.

### Template Minimums
| Template | Minimum Words |
|----------|--------------|
| `empire` / `biography` | 1,500 |
| `geopolitical` | 5,000 |
| `fiqh` | 8,000 |
| `aqeedah` | 3,000 |
| `cs` / `ai` (haytham) | 4,000 |
| `notebooklm` | 4,000 |
| `general` | 1,000 |

## Usage
```powershell
# Validate a fiqh note (8000 minimum)
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\validate_wordcount\scripts\validate_wordcount.ps1" `
    -FilePath "E:\De Anima\Islam\Fiqh\Tawassul.md" -MinWords 8000 -Template fiqh

# Validate a history note (1500 minimum)
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\validate_wordcount\scripts\validate_wordcount.ps1" `
    -FilePath "E:\De Anima\History\Ottoman Empire.md" -MinWords 1500
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-FilePath` | **Yes** | — | Absolute path to the assembled note. |
| `-MinWords` | **Yes** | — | Minimum word count required for this template. |
| `-Template` | No | `""` | Template name for display (e.g. `"fiqh"`, `"empire"`). |
| `-ToolsDir` | No | `C:\Users\Pc\.antigravity\tools` | Directory containing `word_count.ps1`. |

## Output Format
```
WORDCOUNT: 9247
MINIMUM:   8000 (fiqh)
WORDCOUNT_PASS
```

On failure:
```
WORDCOUNT: 1102
MINIMUM:   1500
WORDCOUNT_FAIL: 398 words short. Return note to agent for expansion of thinnest sections.
```

## Constraints
- Delegates counting to `word_count.ps1` — do NOT duplicate counting logic.
- Exit code `0` = PASS, `1` = FAIL or error.
- Requires `word_count.ps1` to be present at the `-ToolsDir` path.
