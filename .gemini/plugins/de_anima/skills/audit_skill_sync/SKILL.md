---
name: audit_skill_sync
description: Audit vault agent files for skill reference integrity. Checks that domain agents reference required centralized skills (yolo_generation_protocol, obsidian_yaml_enforcer), detects banned legacy patterns (embedded YOLO prompts, old headers), and verifies all skill path references in architecture docs resolve to existing files. Use for vault health checks, post-migration validation, and CI-style sync audits.
---

# Audit Skill Sync

## Goal
Verify that all domain agent files correctly reference the centralized skill files and do not contain forbidden legacy patterns. Also validates that every skill path referenced in architecture documents (GEMINI.md, agent files) points to an existing file on disk.

## Instructions
1. Run the script from any directory — it automatically sets its working directory to the vault root (parent of `scripts/`).
2. The script checks three things:
   - **Required skill files exist**: `skills/yolo_generation_protocol/SKILL.md`, `skills/obsidian_yaml_enforcer/SKILL.md`, `skills/obsidian_wikilink_engine/SKILL.md`.
   - **Domain agents reference required skills**: Each of the six domain agents must contain path references to `yolo_generation_protocol` and `obsidian_yaml_enforcer`.
   - **No banned patterns**: Agents must not contain legacy embedded YOLO prompts, old sleep commands, or deprecated headers.
   - **Skill path resolution**: All `c:\Users\Pc\.gemini\skills\<name>\SKILL.md` references in active docs must resolve to existing files.
3. Parse the output:
   - `SKILL SYNC AUDIT: PASS` — all checks passed.
   - `SKILL SYNC AUDIT: FAIL` — followed by a list of specific failures.

## Usage
```powershell
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\audit_skill_sync\scripts\audit_skill_sync.ps1"
```

With verbose output:
```powershell
powershell -File "C:\Users\Pc\.gemini\antigravity\skills\audit_skill_sync\scripts\audit_skill_sync.ps1" -VerboseOutput
```

### Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-VerboseOutput` | No | `$false` | Switch. Prints counts of checked agents, docs, and skills. |

## Output Format
- `SKILL SYNC AUDIT: PASS` — all integrity checks passed
- `SKILL SYNC AUDIT: FAIL` — followed by indented failure descriptions

## Constraints
- This is a **read-only audit** — it does not modify any files.
- Must be run from a context where the vault `.gemini/` structure is accessible.
- Exit code `0` = pass, `1` = fail.
