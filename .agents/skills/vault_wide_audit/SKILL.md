---
name: vault_wide_audit
description: Orchestrates a comprehensive two-stage vault alignment. Stage 1 executes a read-only structural health audit. Stage 2 executes a forced vault-wide standardization pass, correcting tags, links, and MOCs across all notes.
---

# Vault-Wide Audit and Alignment Protocol

## Purpose

This skill is the authoritative protocol for performing a complete vault-wide health
check and forced standard alignment across all domains in the De Anima vault.

It consists of two stages:
1. **Structural Audit (Read-Only)**
2. **Forced Standardization (Write)**

If any local prompt instruction conflicts with this skill, this skill wins.

## Stage 1: Structural Audit (Read-Only)

Act as the vault auditor and locate structural decay without modifying any file.

### 1. Configuration Integrity

Verify the agent/skill/tool wiring is internally consistent before trusting anything else:

```powershell
powershell -File ".agents\tools\audit_skill_sync.ps1" -VerboseOutput
```

Must return `SKILL SYNC AUDIT: PASS`. A `FAIL` here invalidates the rest of the audit —
fix the wiring first, because the standardization pass in Stage 2 depends on it.

### 2. Build the Vault Index

```powershell
powershell -File ".agents\tools\generate_index.ps1" -IncludeOrphans -Format json
```

This enumerates every note with its path, word count, and tag array, and flags notes
with missing or malformed frontmatter. Use the JSON form so the following checks can
be driven off structured data rather than re-scanning the vault.

### 3. Tag Conformance

For each note in the index, validate its tag array:

```powershell
powershell -File ".agents\tools\validate_tags.ps1" -TagLine "[the note's tags, comma-separated]"
```

Report every note that fails — wrong domain/category pairing, too few or too many
topic tags, missing or misplaced `cli`. Do not fix yet.

### 4. Broken Links, Orphans, and Islands

There is no dedicated link-graph tool. Derive these from the index yourself:

- **Broken links** — collect every `[[target]]` across all notes; report any whose
  target filename does not appear in the index.
- **Island notes** — report notes with zero inbound and zero outbound links. These
  are invisible to the knowledge graph and are the highest-value fix targets.

Delegate to `technician` in AUDIT MODE if you need this analysis at full depth; its
audit protocol covers the same ground with per-domain reporting.

**Output:** a `VAULT_HEALTH_REPORT` summarizing every structural anomaly found.
Report before fixing. Never surprise the user with changes.

## Stage 2: Forced Vault-Wide Standardization (Write)

Only after the read-only audit is reported and the user approves, trigger the
standardization engine. It iterates over all six domains and forces every note through
the tag validator, formatter policy gate, wikilink engine, and TOC generator.

```powershell
powershell -File ".agents\tools\run_vault_wide_standardize.ps1"
```

> [!WARNING]
> This stage spawns a sub-session for every note in the vault and modifies files
> in place. It is long-running and not automatically reversible. Confirm with the
> user before starting, and make sure the vault is committed to git first.

## Report Contract

Once both stages complete, output:

```text
VAULT_WIDE_AUDIT_COMPLETE
Config Integrity: [PASS|FAIL]
Health Anomalies Found: [Number]
Domains Standardized: [List of domains]
Total Notes Processed: [Number]
Failed/Skipped Notes: [List if any]
Status: ALIGNED
```

## Safety Rules

- Do not summarize or rewrite note body content during this process.
- Do not modify sacred files (`Chain Of Thoughts.md`, `REAS - Chain Of Thoughts.md`).
- Only use the designated PowerShell tools to apply the standard.
- Stage 2 requires explicit user approval. Stage 1 never writes.
