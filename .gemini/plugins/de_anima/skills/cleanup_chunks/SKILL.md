---
name: cleanup_chunks
description: Delete YOLO chunk files, manifest JSON, and pipeline state JSON from the _tmp/ directory after weaver assembly. Called after a note is saved to the vault to clean up temporary generation artifacts. Handles partial cleanup gracefully.
---

# Cleanup Chunks

## Goal
Remove all temporary chunk files (`[slug]_chunk_*.md`), the manifest file (`[slug]_manifest.json`), and the pipeline state file (`[slug]_pipeline_state.json`) from `_tmp/` after the weaver has assembled the final note.

## Instructions
1. Call this script **after** the weaver has successfully assembled and saved the final note.
2. Pass the same `-Slug` that was used during YOLO generation.
3. Parse the output to confirm deletion:
   - `DELETED: N chunk file(s), M sidecar file(s) (manifest + state)` — full cleanup succeeded.
   - `PARTIAL: ...` — some files could not be deleted; review the listed filenames.
   - `TMP_DIR_NOT_FOUND: ...` — the `_tmp/` directory does not exist; nothing to clean.

## Usage
```powershell
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\cleanup_chunks\scripts\cleanup_chunks.ps1" -Slug "rafa-al-yadayn"
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-Slug` | **Yes** | — | The topic slug matching chunk filenames (e.g. `"ottoman-empire"`). |
| `-TmpDir` | No | `E:\De Anima\_tmp` | Path to the temp directory containing chunks. |

## Output Format
- `DELETED: N chunk file(s), M sidecar file(s) (manifest + state)` — success
- `PARTIAL: Deleted N chunk(s), M sidecar(s). Failed K: [filenames]` — partial failure
- `TMP_DIR_NOT_FOUND: [path]` — nothing to clean

## Constraints
- Must be called **after** weaver assembly, never before.
- Uses the same slug convention as `write_manifest` and `verify_chunks`.
- Exit code is always `0` (non-fatal cleanup).
