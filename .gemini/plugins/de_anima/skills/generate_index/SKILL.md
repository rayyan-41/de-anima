---
name: generate_index
description: Generate a vault-wide index of all notes with metadata. Scans every .md file in the De Anima vault, extracts YAML frontmatter (date, status, tags, note), and outputs a structured index. Supports domain filtering, JSON or text output, orphan note detection, and domain note counts. Useful for duplicate detection before note creation, technician audit cross-referencing, vault health snapshots, and pre-computed tag caching for large vaults.
---

# Generate Index

## Goal
Scan the De Anima vault and produce a structured index of all notes, including their domain, category, tags, word count, and file path. Supports filtering by domain, choosing output format (text or JSON), and optionally reporting orphan notes with missing/incomplete frontmatter.

## Instructions
1. Run the script to generate a full vault index. No arguments required for a basic scan.
2. Use `-Domain` to scope the scan to a single domain (e.g., `Islam`, `Science`).
3. Use `-Format json` for programmatic consumption.
4. Use `-IncludeOrphans` to also list notes with missing or incomplete YAML frontmatter.
5. The script automatically skips `_tmp/`, `.obsidian/`, `paintings_source/`, Map of Contents files, and sacred files (`GEMINI.md`, `Chain Of Thoughts.md`).

### Use Cases
- **Pre-flight duplicate detection**: Run before creating a new note to check if a similar title already exists.
- **Technician audit support**: Cross-reference note count vs. MOC entries.
- **Vault health snapshots**: Quick domain-by-domain note count summary.

## Usage
```powershell
# Full vault index (text format)
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\generate_index\scripts\generate_index.ps1"

# Single domain, JSON format
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\generate_index\scripts\generate_index.ps1" -Domain Islam -Format json

# Include orphan notes
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\generate_index\scripts\generate_index.ps1" -IncludeOrphans
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-VaultRoot` | No | `E:\De Anima` | Root of the vault. |
| `-Domain` | No | `""` (all) | Filter to a single domain: `Art`, `History`, `Islam`, `Literature`, `Reason`, `Science`. |
| `-Format` | No | `text` | Output format: `text` or `json`. |
| `-IncludeOrphans` | No | `$false` | Switch. Also report notes with missing/incomplete frontmatter. |

## Output Format
**Text mode**: Structured report with domain counts and per-note listings (title, category, word count, tags, path).

**JSON mode**: JSON object with `generated`, `total_notes`, `domain_counts`, and `notes` array.

## Constraints
- This is a **read-only** scan — it does not modify any files.
- Not part of the automatic pipeline — it is an on-demand utility.
- Skips files in `_tmp/`, `.obsidian/`, `paintings_source/`, and sacred files.
