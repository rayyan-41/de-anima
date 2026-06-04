---
name: update_moc
description: Append a note entry to a domain's Map of Contents (MOC) file. Creates the MOC if it doesn't exist, adds a wikilink row to the structure table, prunes dead links to non-existent notes, prevents duplicate entries, and updates the Total Notes counter. Used by the linker agent after note assembly to keep domain MOCs current. Handles Obsidian wikilink format (no .md extension).
---

# Update MOC

## Goal
Add a newly created note to the appropriate domain's Map of Contents (`_[Domain] - Map of Contents.md`). If the MOC does not exist, create it with canonical YAML frontmatter and structure. If the note is already listed, skip insertion but still prune dead links.

## Instructions
1. Call this script during the **linker** stage of the post-note pipeline, after wikilinks have been inserted.
2. Pass the domain, note title, filename, and category.
3. The script:
   - Creates the MOC file if it doesn't exist, using canonical YAML frontmatter and the standard structure table.
   - Checks for existing entries (duplicate detection by filename stem).
   - Prunes table rows whose wikilink targets no longer exist on disk.
   - Appends a new row with `[[NoteTitle|DisplayName]]` format (no `.md` extension per Obsidian standard).
   - Updates the `Total Notes` counter.
   - Updates the `Last MOC Update` timestamp.
4. Parse the output for the result:
   - `MOC_CREATED: ...` — new MOC file was created.
   - `MOC_UPDATED: ...` — note was added to existing MOC.
   - `MOC_PRUNED: ...` — note already existed; dead links were cleaned.

## Usage
```powershell
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\update_moc\scripts\update_moc.ps1" `
    -Domain Islam `
    -NoteTitle "Rafa al-Yadayn (Fiqh)" `
    -NoteFilename "Rafa al-Yadayn (Fiqh).md" `
    -Category "Fiqh/Ibadat"
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-Domain` | **Yes** | — | The vault domain: `Art`, `History`, `Islam`, `Literature`, `Reason`, `Science`. |
| `-NoteTitle` | **Yes** | — | Display title of the note (e.g. `"Rafa al-Yadayn (Fiqh)"`). |
| `-NoteFilename` | **Yes** | — | Filename without path (e.g. `"Rafa al-Yadayn (Fiqh).md"`). |
| `-Category` | **Yes** | — | Subcategory within the domain (e.g. `"Fiqh/Ibadat"`, `"Medieval"`, `"Books"`). |
| `-VaultRoot` | No | `E:\De Anima` | Root of the vault. |

## Output Format
- `MOC_CREATED: _Islam - Map of Contents.md - created with 'NoteTitle'`
- `MOC_UPDATED: _Islam - Map of Contents.md - added 'NoteTitle' (Total Notes: N)`
- `MOC_PRUNED: _Islam - Map of Contents.md - verified 'NoteTitle' already listed, pruned dead links`
- `PRUNED_DECREPIT: 'dead-link-name'` — emitted for each dead link removed

## Constraints
- Wikilinks use filename stem (no `.md` extension) per Obsidian requirements.
- Duplicate detection is normalized to filename stem on both sides.
- Dead link pruning searches the domain directory recursively.
- The MOC filename follows the convention `_[Domain] - Map of Contents.md`.
