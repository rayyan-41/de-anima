---
name: word_count
description: Count words in a markdown file with correct YAML frontmatter exclusion. Uses a proper two-delimiter YAML parser to strip the frontmatter block (date, status, tags, note properties) before counting body words. Returns a single integer. Used by validate_wordcount.ps1 and directly by agents for word count checks. Fixes the legacy single-pass heuristic that inflated counts by including frontmatter lines.
---

# Word Count

## Goal
Accurately count the number of words in a markdown note's body content, correctly excluding the YAML frontmatter block.

## Instructions
1. Call this script on any markdown note to get its body word count.
2. The script:
   - Reads the file line by line.
   - Detects YAML frontmatter delimiters (`---`) and skips all lines between the opening and closing delimiters (inclusive).
   - Counts words in the remaining body content by splitting on whitespace.
3. The output is a single integer — the word count.

## Usage
```powershell
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\word_count\scripts\word_count.ps1" `
    -FilePath "E:\De Anima\Islam\Fiqh\Rafa al-Yadayn (Fiqh).md"
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-FilePath` | **Yes** | — | Absolute path to the markdown file. |

## Output Format
A single integer on stdout:
```
9247
```

## Constraints
- Exit code `0` = success, `1` = file not found.
- Does NOT count words inside the YAML frontmatter block (between `---` delimiters).
- Handles legacy files without frontmatter (starts counting from the first non-empty line).
- This is the **canonical** word counting script — `validate_wordcount.ps1` delegates to this. Do NOT duplicate this logic elsewhere.
