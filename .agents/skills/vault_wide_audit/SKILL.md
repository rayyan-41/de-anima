---
name: vault_wide_audit
description: Orchestrates a comprehensive two-stage vault alignment. Stage 1 executes a read-only structural health audit (using the technician agent's logic). Stage 2 executes a forced vault-wide standardization pass (correcting Tags, Formatter links, MOCs, and generating TOCs for all notes).
---

# Vault-Wide Audit and Alignment Protocol

## Purpose

This skill is the authoritative protocol for performing a complete vault-wide health check and forceful standard alignment across all domains in the De Anima vault.

It consists of two stages:
1. **Structural Audit (Read-Only)**
2. **Forced Standardization (Write)**

If any local prompt instruction conflicts with this skill, this skill wins.

## Stage 1: Structural Audit (Read-Only)

In this stage, you act as the Vault Auditor to locate structural decay without modifying files.

Run the following scripts sequentially to inspect vault health:

### 1. Tag Conformance Audit
Verify all notes comply with the canonical tag registry:
```powershell
powershell -File "E:\De Anima\.agents\tools\audit_skill_sync.ps1" -VerboseOutput
```
*(Report any warnings or failures.)*

### 2. Broken & Orphan Link Detection
Identify missing files that are linked from active notes:
```powershell
# Custom command or script to find orphan links if one exists,
# or inform the user that the linker engine handles this at creation.
```

### 3. Island Note Detection
Identify notes that have zero backlinks or outgoing links, isolating them from the knowledge graph.

**Output:** Generate a `VAULT_HEALTH_REPORT` summarizing structural anomalies found.

## Stage 2: Forced Vault-Wide Standardization (Write)

After the read-only audit, you must trigger the forced standardization engine across the entire vault. This engine iterates over all 6 domains (Art, History, Islam, Literature, Reason, Science) and forces every note through the Tag Validator, Formatter Policy Gate, Wikilink Engine, and TOC generator.

Execute the master wrapper script:
```powershell
powershell -File "E:\De Anima\.agents\tools\run_vault_wide_standardize.ps1"
```

> [!WARNING]
> This stage spawns sub-sessions for every single note in the vault and modifies files forcefully. It may take a significant amount of time and consume substantial API quota.

## Report Contract

Once both stages complete, you must output a final summary:

```text
VAULT_WIDE_AUDIT_COMPLETE
Health Anomalies Found: [Number]
Domains Standardized: [List of domains]
Total Notes Processed: [Number]
Failed/Skipped Notes: [List if any]
Status: ALIGNED
```

## Safety Rules

- Do not attempt to summarize or rewrite note body content during this process.
- Do not modify sacred files (`Chain Of Thoughts.md`).
- Only use the designated PowerShell scripts to apply the standard.
