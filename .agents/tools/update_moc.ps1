<#
.SYNOPSIS
    Appends a note entry to the specified domain's Map of Contents file.
.PARAMETER Domain
    The vault domain: Art, History, Islam, Literature, Reason, Science
.PARAMETER NoteTitle
    The display title of the note (e.g. "Rafa al-Yadayn (Fiqh)")
.PARAMETER NoteFilename
    The filename without path (e.g. "Rafa al-Yadayn (Fiqh).md")
.PARAMETER Category
    The subcategory within the domain (e.g. "Fiqh/Ibadat", "Medieval", "Books")
.PARAMETER VaultRoot
    Root of the vault. Defaults to $VaultRoot
.EXAMPLE
    powershell -File update_moc.ps1 -Domain Islam -NoteTitle "Rafa al-Yadayn (Fiqh)" -NoteFilename "Rafa al-Yadayn (Fiqh).md" -Category "Fiqh/Ibadat"
    Output: MOC_UPDATED: _Islam - Map of Contents.md — added "Rafa al-Yadayn (Fiqh)"
.NOTES
    Fixes (2026-04-12):
      C-4: Wikilinks now use filename stem (no .md extension) — Obsidian requires this.
      C-5: Duplicate detection normalized to stem on both sides to prevent double-entries.
      C-6: Total Notes counter regex updated to match canonical bullet format "- Total Notes: N".
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Art", "History", "Islam", "Literature", "Reason", "Science")]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$NoteTitle,

    [Parameter(Mandatory=$true)]
    [string]$NoteFilename,

    [Parameter(Mandatory=$true)]
    [string]$Category,

    [string]$VaultRoot = ""
)
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }


$mocFilename = "_${Domain} - Map of Contents.md"
$mocPath = Join-Path $VaultRoot (Join-Path $Domain $mocFilename)

# ── Derive wikilink target: always strip .md extension (Obsidian requirement) ─
$wikilinkTarget   = [System.IO.Path]::GetFileNameWithoutExtension($NoteFilename)
$noteFilenameStem = $wikilinkTarget  # reuse for duplicate detection

if (-not (Test-Path $mocPath)) {
    # Create a new MOC with canonical YAML frontmatter
    $today = Get-Date -Format "yyyy-MM-dd"
    $mocContent = @"
---
date: $today
status: complete
tags: [$($Domain.ToLower()), moc, cli]
note: ""
---

**Metadata:**
- Last Major Reorganization: $today
- Total Notes: 1
- - -

## Structure

| Topic Area | Notes | Last Updated |
|------------|-------|--------------|
| $Category | [[$wikilinkTarget|$NoteTitle]] | $today |

- - -

*Last MOC Update: $today by De Anima Orchestrator*
*Next Review: $((Get-Date).AddMonths(3).ToString("yyyy-MM-dd"))*
"@
    Set-Content -Path $mocPath -Value $mocContent -Encoding UTF8
    Write-Output "MOC_CREATED: $mocFilename - created with '$NoteTitle'"
    exit 0
}

# MOC exists — read it
$content = Get-Content $mocPath -Raw -Encoding UTF8
$today = Get-Date -Format "yyyy-MM-dd"

# Strategy: loop through lines, prune decrepit links, then append the new row.
$lines = $content -split "`n"
$validLines = @()
$lastTableRowIndex = -1
$domainDir = Join-Path $VaultRoot $Domain
$alreadyExists = $false

foreach ($line in $lines) {
    if ($line.Trim() -match '^\|') {
        if ($line -match '\[\[(.*?)(\|.*?)?\]\]') {
            $linkFile = $matches[1]

            # ── C-5 fix: normalize both sides to stem before comparing ─────────
            $linkFileStem = [System.IO.Path]::GetFileNameWithoutExtension($linkFile)
            if ($linkFileStem -eq $noteFilenameStem) {
                $alreadyExists = $true
            }

            # Check if the target file actually exists — prune dead links.
            # Try both with and without .md extension for resilience.
            $exists = Get-ChildItem -Path $domainDir -Filter "$linkFile.md" -Recurse -File `
                          -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $exists) {
                $exists = Get-ChildItem -Path $domainDir -Filter $linkFile -Recurse -File `
                              -ErrorAction SilentlyContinue | Select-Object -First 1
            }
            if (-not $exists) {
                Write-Output "PRUNED_DECREPIT: '$linkFile'"
                continue # Omit this row from valid lines
            }
        }
        $lastTableRowIndex = $validLines.Count
    }
    $validLines += $line
}

$lines = $validLines

if (-not $alreadyExists) {
    # ── C-4 fix: wikilink uses stem (no .md extension) ───────────────────────
    $newRow = "| $NoteTitle | [[$wikilinkTarget|$NoteTitle]] | $today |"
    if ($lastTableRowIndex -ge 0) {
        $before = $lines[0..$lastTableRowIndex]
        $after = if ($lastTableRowIndex -lt $lines.Count - 1) {
            $lines[($lastTableRowIndex + 1)..($lines.Count - 1)]
        } else { @() }
        $newLines = $before + $newRow + $after
    } else {
        $newLines = $lines + "" + $newRow
    }
    $lines = $newLines
}

# Count actual data rows (exclude header and separator rows)
$newContent = $lines -join "`n"
$tableRowCount = ($lines | Where-Object {
    $_.Trim() -match '^\|' -and
    $_ -notmatch '\|-{2,}' -and          # separator row
    $_ -notmatch '^\|\s*Topic Area\s*\|'  # header row
}).Count

# ── C-6 fix: match canonical bullet format "- Total Notes: N" ────────────────
if ($newContent -match '- Total Notes:\s*\d+') {
    $newContent = $newContent -replace '- Total Notes:\s*\d+', "- Total Notes: $tableRowCount"
} elseif ($newContent -match '\*\*Total Notes:\*\*\s*\d+') {
    # Fallback for bold format in case it's used
    $newContent = $newContent -replace '\*\*Total Notes:\*\*\s*\d+', "**Total Notes:** $tableRowCount"
}

# Update Last MOC Update timestamp
$newContent = $newContent -replace '\*Last MOC Update:.*?\*', "*Last MOC Update: $today by De Anima Orchestrator*"

Set-Content -Path $mocPath -Value $newContent -Encoding UTF8

if ($alreadyExists) {
    Write-Output "MOC_PRUNED: $mocFilename - verified '$NoteTitle' already listed, pruned dead links"
} else {
    Write-Output "MOC_UPDATED: $mocFilename - added '$NoteTitle' (Total Notes: $tableRowCount)"
}

