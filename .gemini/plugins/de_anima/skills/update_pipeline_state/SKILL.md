---
name: update_pipeline_state
description: Track note creation pipeline progress via a JSON state file in _tmp/. Writes or updates the pipeline state after each stage (preflight, yolo, weaver, tagger, formatter, linker) completes, starts, or fails. Enables crash recovery so an interrupted pipeline can resume from the last completed stage. State file is cleaned up by cleanup_chunks after final assembly.
---

# Update Pipeline State

## Goal
Persist the current state of the note creation pipeline to a JSON file in `_tmp/`, enabling crash recovery and pipeline progress tracking. Each stage's status (`running`, `complete`, `failed`) is recorded with a timestamp and optional note.

## Instructions
1. Call this script **after each pipeline stage** completes (or when a stage starts/fails).
2. The script creates or updates `_tmp/[slug]_pipeline_state.json` with the stage status.
3. On session resume, read the state file to determine the last completed stage and skip ahead.
4. The state file is automatically cleaned up by `cleanup_chunks.ps1` after assembly.

### Pipeline Stages (in order)
`preflight` → `yolo` → `weaver` → `tagger` → `formatter` → `linker`

## Usage
```powershell
# Mark preflight as complete
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\update_pipeline_state\scripts\update_pipeline_state.ps1" `
    -Slug "ottoman-empire" -Stage preflight -Status complete

# Mark yolo as failed with a note
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\update_pipeline_state\scripts\update_pipeline_state.ps1" `
    -Slug "ottoman-empire" -Stage yolo -Status failed -Note "chunk_05 missing after retry"

# Mark weaver as running
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\update_pipeline_state\scripts\update_pipeline_state.ps1" `
    -Slug "ottoman-empire" -Stage weaver -Status running
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-Slug` | **Yes** | — | The topic slug (e.g. `"ottoman-empire"`). |
| `-Stage` | **Yes** | — | Pipeline stage: `preflight`, `yolo`, `weaver`, `tagger`, `formatter`, `linker`. |
| `-Status` | **Yes** | — | Stage status: `running`, `complete`, `failed`. |
| `-Note` | No | `""` | Optional short note (e.g. `"3 of 8 chunks written"`). |
| `-TmpDir` | No | `E:\De Anima\_tmp` | Path to the temp directory. |

## Output Format
```
PIPELINE_STATE: [ottoman-empire] weaver → complete
PIPELINE_STATE: [ottoman-empire] yolo → failed | chunk_05 missing after retry
```

## State File Structure
```json
{
  "slug": "ottoman-empire",
  "created": "2026-04-12T10:00:00+05:00",
  "stages": {
    "preflight": { "status": "complete", "timestamp": "...", "note": "" },
    "yolo": { "status": "complete", "timestamp": "...", "note": "" }
  },
  "last_updated": "2026-04-12T10:15:00+05:00"
}
```

## Constraints
- State file is written to `_tmp/[slug]_pipeline_state.json`.
- Creates the `_tmp/` directory if it doesn't exist.
- The state file is cleaned up by `cleanup_chunks.ps1` — do not delete it manually before assembly.
- Multiple calls for the same stage overwrite the previous status for that stage.
