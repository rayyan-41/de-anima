---
name: get_vault_context
description: Discover the vault root directory and read vault configuration. Provides two PowerShell helper functions — Get-VaultRoot (walks up the directory tree to find .gemini/config.json) and Get-VaultConfig (parses the config JSON). Use when agents need to dynamically resolve the vault root path or load vault configuration settings.
---

# Get Vault Context

## Goal
Provide reusable PowerShell functions to dynamically discover the vault root directory and load vault configuration, enabling agents and scripts to work without hardcoded paths.

## Instructions
1. This script defines **two functions** (it is a library, not a standalone executable):
   - `Get-VaultRoot` — Walks up the directory tree from `$PWD` looking for a `.gemini/config.json` file. Returns the directory path containing it.
   - `Get-VaultConfig` — Calls `Get-VaultRoot`, reads the `config.json`, and returns the parsed JSON object.
2. **Dot-source** this script to import the functions into your session, then call them:

## Usage
```powershell
# Dot-source the library to import functions
. "C:\Users\Pc\.gemini\antigravity\skills\get_vault_context\scripts\get_vault_context.ps1"

# Get the vault root directory
$root = Get-VaultRoot

# Get the parsed config object
$config = Get-VaultConfig
```

### Functions
| Function | Returns | Description |
|----------|---------|-------------|
| `Get-VaultRoot` | `[string]` path | Walks up from `$PWD` to find the directory containing `.gemini/config.json`. Throws if not found. |
| `Get-VaultConfig` | `[PSCustomObject]` | Reads and parses `.gemini/config.json` from the vault root. |

## Constraints
- This is a **function library**, not a standalone script. It must be dot-sourced (`. script.ps1`), not run with `powershell -File`.
- The current working directory (`$PWD`) must be within the vault tree for `Get-VaultRoot` to succeed.
- Throws an error if `.gemini/config.json` is not found in any parent directory.
