---
name: write_manifest
description: Write a pre-flight manifest JSON to _tmp/ listing all expected YOLO chunk filenames and their headings. Must be called at the start of YOLO generation (Stage 2 pre-flight gate) before any chunks are written. Creates the _tmp/ directory if needed. The manifest enables verify_chunks.ps1 to validate completeness and cleanup_chunks.ps1 to locate all artifacts for deletion.
---

# Write Manifest

## Goal
Create a JSON manifest file in `_tmp/` that declares all expected chunk files for a YOLO generation session. This manifest is the source of truth for how many chunks are expected, what headings they map to, and their filenames.

## Instructions
1. Call this script during **Stage 2 (Pre-flight Gate)**, immediately after the agent's heading outline is declared.
2. Pass the topic slug and a comma-separated list of section headings.
3. The script:
   - Creates `_tmp/` if it doesn't exist.
   - Generates a manifest with zero-padded chunk filenames (`[slug]_chunk_01.md`, `[slug]_chunk_02.md`, etc.).
   - Saves to `_tmp/[slug]_manifest.json`.
4. Confirm the output contains `MANIFEST_WRITTEN` before proceeding to YOLO generation.

## Usage
```powershell
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\write_manifest\scripts\write_manifest.ps1" `
    -Slug "ottoman-empire" `
    -Headings "Overview,Rise to Power,Golden Age,Decline,Legacy"
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-Slug` | **Yes** | — | The topic slug. Must match the slug used for chunk filenames. |
| `-Headings` | **Yes** | — | Comma-separated list of section headings in order. |
| `-TmpDir` | No | `E:\De Anima\_tmp` | Path to the temp directory. |

## Output Format
```
MANIFEST_WRITTEN: E:\De Anima\_tmp\ottoman-empire_manifest.json (5 chunks expected)
```

On error (no headings provided):
```
MANIFEST_ERROR: No headings provided.
```

## Manifest File Structure
```json
{
  "slug": "ottoman-empire",
  "created": "2026-04-12T10:00:00+05:00",
  "stage": "pre-flight",
  "expected_count": 5,
  "expected": [
    { "index": "01", "heading": "Overview", "filename": "ottoman-empire_chunk_01.md", "status": "pending" },
    { "index": "02", "heading": "Rise to Power", "filename": "ottoman-empire_chunk_02.md", "status": "pending" }
  ]
}
```

## Constraints
- Must be called **before** any YOLO chunks are written.
- The slug must be consistent across `write_manifest`, YOLO chunk generation, `verify_chunks`, and `cleanup_chunks`.
- At least one heading must be provided or the script errors.
- Exit code `0` = success, `1` = error.
