---
name: update_frontmatter_uuid
description: Add a unique UUID to a note's YAML frontmatter. Inserts an 'id' field with a generated GUID into existing frontmatter, or creates minimal frontmatter with the id if none exists. Skips notes that already have an id field. Use for ensuring every note has a stable unique identifier for cross-referencing and sync.
---

# Update Frontmatter UUID

## Goal
Ensure a markdown note has a unique `id` field in its YAML frontmatter. If frontmatter exists but lacks an `id`, one is inserted. If no frontmatter exists, minimal frontmatter with just the `id` is created.

## Instructions
1. This script defines a **function** `Add-FrontmatterUUID` — it is a library, not a standalone executable.
2. Dot-source the script, then call the function with the target file path.
3. The function:
   - Checks if YAML frontmatter (`---` delimited) exists.
   - If frontmatter exists but has no `id:` field → inserts `id: <new-guid>` at the top of the frontmatter block.
   - If no frontmatter exists → wraps the content with new `---` frontmatter containing just the `id`.
   - If `id:` already exists → does nothing (idempotent).

## Usage
```powershell
# Dot-source the library
. "C:\Users\Pc\.gemini\antigravity\skills\update_frontmatter_uuid\scripts\update_frontmatter_uuid.ps1"

# Add UUID to a note
Add-FrontmatterUUID -FilePath "E:\De Anima\History\Ottoman Empire.md"
```

### Function Parameters
| Parameter | Required | Description |
|-----------|----------|-------------|
| `-FilePath` | **Yes** | Absolute path to the markdown file to update. |

## Constraints
- This is a **function library** — dot-source it (`. script.ps1`), do not run with `powershell -File`.
- The function **modifies the file in-place** using `Set-Content`.
- Idempotent: will not add a second `id` if one already exists.
- Does not validate other frontmatter fields — only concerned with the `id` property.
