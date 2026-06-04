---
name: verify_chunks
description: Verify YOLO chunk files exist in _tmp/ before weaver assembly. Checks that all expected chunk files (slug_chunk_01.md through slug_chunk_NN.md) are present. Supports two modes — verify (existence check only, returns ALL_PRESENT or MISSING list) and read (verifies AND returns concatenated chunk content with markers). Mandatory gate before weaver assembly to prevent incomplete notes.
---

# Verify Chunks

## Goal
Verify that all expected YOLO chunk files exist in `_tmp/` before the weaver begins assembly. Optionally read and concatenate all chunks with markers for direct handoff to the weaver.

## Instructions
1. Call this script at the start of **Stage 4 (Assembly)**, before the weaver reads any chunks.
2. Two modes:
   - **`verify`**: Only checks existence. Returns `ALL_PRESENT: N/N` or `MISSING: K/N` with a list of missing files.
   - **`read`**: Verifies existence AND returns all chunk contents concatenated, with `<!-- CHUNK NN START -->` / `<!-- CHUNK NN END -->` markers.
3. If `MISSING`:
   - Do NOT proceed with assembly.
   - Retry the failed chunks or report to the user.
4. If `ALL_PRESENT` (verify mode) or concatenated output (read mode): proceed with weaver assembly.

## Usage
```powershell
# Verify only (mandatory gate)
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\verify_chunks\scripts\verify_chunks.ps1" `
    -Slug "rafa-al-yadayn" -ExpectedCount 10 -Mode verify

# Verify and read for assembly
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\verify_chunks\scripts\verify_chunks.ps1" `
    -Slug "rafa-al-yadayn" -ExpectedCount 10 -Mode read
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-Slug` | **Yes** | — | The topic slug matching chunk filenames (e.g. `"rafa-al-yadayn"`). |
| `-ExpectedCount` | **Yes** | — | How many chunks to expect (e.g. `10`). |
| `-TmpDir` | No | `E:\De Anima\_tmp` | Path to the temp directory. |
| `-Mode` | No | `verify` | `verify` (existence check only) or `read` (verify + concatenate content). |

## Output Format

**Verify mode — success:**
```
ALL_PRESENT: 10/10
```

**Verify mode — failure:**
```
MISSING: 2/10
  - rafa-al-yadayn_chunk_05.md
  - rafa-al-yadayn_chunk_08.md
```

**Read mode — success:**
Concatenated content with chunk markers:
```
<!-- CHUNK 01 START -->
[chunk 01 content]
<!-- CHUNK 01 END -->

<!-- CHUNK 02 START -->
[chunk 02 content]
<!-- CHUNK 02 END -->
```

## Constraints
- Chunk filenames must follow the pattern `[slug]_chunk_[NN].md` with zero-padded two-digit indices.
- Exit code `0` = all present, `1` = missing chunks or `_tmp/` not found.
- This is the **mandatory gate** before assembly — never skip it.
