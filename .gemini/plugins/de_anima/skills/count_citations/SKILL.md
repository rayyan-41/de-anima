---
name: count_citations
description: Count and validate inline citations in a note. Scans for [N]-style inline citations in the note body, cross-references them against the ## References section entries, detects missing references, and optionally checks citation density thresholds based on word count. Used as the citation integrity gate in NotebookLM mode and for source-grounded research notes.
---

# Count Citations

## Goal
Audit a note's citation integrity by counting unique `[N]`-style inline citations, verifying each has a matching `[N]` entry in the `## References` section, and optionally checking that citation density meets the minimum threshold for the note's word count.

## Instructions
1. Run this script on any assembled note that uses `[N]`-style inline citations.
2. The script automatically:
   - Extracts all `[N]` patterns from the note body (excluding the References section).
   - Extracts all `[N]` entries from the `## References` section.
   - Reports any cited numbers that lack a matching reference entry.
3. Optionally pass `-WordCount` to enable density threshold checking:
   - ≥4000 words → requires ≥25 citations
   - ≥2000 words → requires ≥15 citations
   - ≥1000 words → requires ≥8 citations
4. Parse the output for the `CITATION_INTEGRITY: PASS` or `CITATION_INTEGRITY: FAIL` verdict.

## Usage
```powershell
# Basic citation check
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\count_citations\scripts\count_citations.ps1" -FilePath "E:\De Anima\Science\CS\AI\Transformers.md"

# With density threshold checking
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\count_citations\scripts\count_citations.ps1" -FilePath "E:\De Anima\Science\CS\AI\Transformers.md" -WordCount 4500
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-FilePath` | **Yes** | — | Absolute path to the note to audit. |
| `-WordCount` | No | `0` | If provided (>0), enables density threshold checking. |

## Output Format
```
INLINE_CITATIONS: 28
REFERENCE_ENTRIES: 28
DENSITY_THRESHOLD: PASS (28/25)      # only if -WordCount provided
CITATION_INTEGRITY: PASS
```

On failure:
```
INLINE_CITATIONS: 8
REFERENCE_ENTRIES: 6
DENSITY_THRESHOLD: FAIL — 4500 words requires >=25 citations, found 8
MISSING_REFS: 7, 8
CITATION_INTEGRITY: FAIL
```

## Constraints
- The note must use `[N]` citation format and have a `## References` section.
- Exit code `0` = PASS, `1` = FAIL (missing refs or density failure).
- Do NOT use this for notes without inline citations — it will trivially pass with 0/0.
