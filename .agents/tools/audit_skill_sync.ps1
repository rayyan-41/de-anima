<#
.SYNOPSIS
    Validates that the De Anima agent configuration is internally consistent.

.DESCRIPTION
    Checks the things that actually break the pipeline:
      1. Every required file exists (protocol, agents, skills, tools).
      2. Every path referenced by any config file resolves on disk.
      3. No provider-specific or absolute-path coupling has crept back in.
      4. No double-encoded UTF-8 (mojibake) in any config file.
      5. The tag policy in the enforcer skill matches validate_tags.ps1.

    The previous version of this script audited the wrong artifacts, and its
    path regex could not match the paths that were actually broken, so it
    reported PASS while the pipeline was unrunnable. Every check below is
    written to fail loudly instead.

.EXAMPLE
    powershell -File .agents\tools\audit_skill_sync.ps1 -VerboseOutput
#>
param(
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'
$VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $VaultRoot

$failures = New-Object System.Collections.Generic.List[string]
function Add-Failure { param([string]$m) $failures.Add($m) }

# Windows PowerShell's Get-Content assumes the ANSI code page for BOM-less files,
# which turns valid UTF-8 into mojibake in memory and would make the encoding
# check below fire on clean files. Always decode explicitly.
function Read-Utf8 {
    param([string]$Path)
    return [System.IO.File]::ReadAllText((Resolve-Path $Path).Path, [System.Text.Encoding]::UTF8)
}

$REQUIRED_AGENTS = @('avicenna','formatter','ghazali','haytham','linker','machiavelli',
                     'michelangelo','tagger','technician','tolstoy','weaver')
$REQUIRED_SKILLS = @('yolo_generation_protocol','obsidian_yaml_enforcer',
                     'obsidian_wikilink_engine','vault_wide_audit')

# -- 1. Required files -------------------------------------------------------
if (-not (Test-Path 'AGENTS.md')) { Add-Failure 'Missing master protocol: AGENTS.md' }

foreach ($a in $REQUIRED_AGENTS) {
    $p = ".agents\agents\$a.md"
    if (-not (Test-Path $p)) { Add-Failure "Missing agent: $p" }
}
foreach ($s in $REQUIRED_SKILLS) {
    $p = ".agents\skills\$s\SKILL.md"
    if (-not (Test-Path $p)) { Add-Failure "Missing skill: $p" }
}

# Reject leftovers from the pre-consolidation layout.
foreach ($stale in @('.gemini', 'GEMINI.md', '.agents\plugin.json', '.agents\settings.json')) {
    if (Test-Path $stale) { Add-Failure "Stale duplicate still present: $stale" }
}
if (@(Get-ChildItem '.agents\agents' -Filter *.yaml -ErrorAction SilentlyContinue).Count -gt 0) {
    Add-Failure 'Stale duplicate still present: .agents\agents\*.yaml'
}

# -- 2. Gather every config file --------------------------------------------
$configFiles = @('AGENTS.md')
$configFiles += (Get-ChildItem '.agents\agents' -Filter *.md | ForEach-Object { ".agents\agents\$($_.Name)" })
$configFiles += (Get-ChildItem '.agents\skills' -Directory | ForEach-Object { ".agents\skills\$($_.Name)\SKILL.md" })
$configFiles = @($configFiles | Where-Object { Test-Path $_ })

# -- 3. Referenced paths must resolve ---------------------------------------
foreach ($f in $configFiles) {
    $content = Read-Utf8 $f

    foreach ($m in [regex]::Matches($content, '\.agents\\tools\\([A-Za-z0-9_]+)\.ps1')) {
        $target = ".agents\tools\$($m.Groups[1].Value).ps1"
        if (-not (Test-Path $target)) { Add-Failure "$f references missing tool: $target" }
    }
    foreach ($m in [regex]::Matches($content, '\.agents\\skills\\([A-Za-z0-9_]+)\\SKILL\.md')) {
        $target = ".agents\skills\$($m.Groups[1].Value)\SKILL.md"
        if (-not (Test-Path $target)) { Add-Failure "$f references missing skill: $target" }
    }
}

# -- 4. Banned coupling ------------------------------------------------------
$banned = @(
    @{ Name = 'Gemini config reference';         Pattern = '\.gemini' },
    @{ Name = 'Antigravity path';                Pattern = 'antigravity' },
    @{ Name = 'agy CLI invocation';              Pattern = '(?<![A-Za-z])agy(?![A-Za-z])' },
    @{ Name = 'stale GEMINI.md reference';       Pattern = 'GEMINI\.md' },
    # \\+ so escaped variants (E:\\De Anima, E:\\\\De Anima) are caught too
    @{ Name = 'absolute vault path';             Pattern = '[A-Za-z]:\\+De Anima' },
    @{ Name = 'retired ai-generated tag';        Pattern = 'ai-generated' },
    # Written with \u escapes on purpose: embedding literal mojibake here
    # would make this file trip its own check and corrupt under non-UTF-8 readers.
    @{ Name = 'mojibake (double-encoded UTF-8)'
       Pattern = '[\u00C2\u00C3\u00E2][\u0080-\u00BF\u2013\u2014\u2018\u2019\u201C\u201D\u20AC\u2022\u2026\u2122]' }
)

# This script necessarily contains the banned strings as its own search patterns,
# so it is scanned for path resolution but excluded from the coupling check.
$scanFiles = $configFiles + @(Get-ChildItem '.agents\tools' -Filter *.ps1 |
    Where-Object { $_.Name -ne 'audit_skill_sync.ps1' } |
    ForEach-Object { ".agents\tools\$($_.Name)" })
foreach ($f in $scanFiles) {
    $content = Read-Utf8 $f
    foreach ($rule in $banned) {
        if ($content -match $rule.Pattern) {
            Add-Failure "$f contains $($rule.Name)"
        }
    }
}

# -- 5. Agent frontmatter ----------------------------------------------------
foreach ($a in $REQUIRED_AGENTS) {
    $p = ".agents\agents\$a.md"
    if (-not (Test-Path $p)) { continue }
    $head = (Get-Content $p -TotalCount 12) -join "`n"
    if ($head -notmatch '(?m)^name:\s*(\S+)\s*$') {
        Add-Failure "$p has no 'name:' in frontmatter"
    } elseif ($Matches[1] -ne $a) {
        Add-Failure "$p declares name '$($Matches[1])' but filename is '$a'"
    }
    if ($head -notmatch '(?m)^description:') { Add-Failure "$p has no 'description:' in frontmatter" }
    if ($head -notmatch '(?m)^type:')        { Add-Failure "$p has no 'type:' in frontmatter" }
}

# -- 6. Tag policy agreement -------------------------------------------------
$validator   = Get-Content '.agents\tools\validate_tags.ps1' -Raw
$enforcerDoc = '.agents\skills\obsidian_yaml_enforcer\SKILL.md'
if (Test-Path $enforcerDoc) {
    $enforcer = Get-Content $enforcerDoc -Raw

    # Every category tag listed in the skill's registry table must exist in the validator.
    foreach ($row in [regex]::Matches($enforcer, '(?m)^\|\s*(?:`(\w[\w-]*)`|\*\(any\)\*)\s*\|(.+?)\|\s*$')) {
        foreach ($tag in [regex]::Matches($row.Groups[2].Value, '`([a-z][a-z0-9-]*)`')) {
            $t = $tag.Groups[1].Value
            if ($validator -notmatch [regex]::Escape("'$t'")) {
                Add-Failure "Category '$t' is in the enforcer skill but not in validate_tags.ps1"
            }
        }
    }
    if ($enforcer -notmatch '`cli`') { Add-Failure 'Enforcer skill no longer designates `cli` as the final tag' }
}
if ($validator -notmatch "'cli'") { Add-Failure "validate_tags.ps1 no longer enforces the 'cli' final tag" }

# -- Report ------------------------------------------------------------------
if ($failures.Count -gt 0) {
    Write-Host 'SKILL SYNC AUDIT: FAIL' -ForegroundColor Red
    foreach ($f in $failures) { Write-Host " - $f" -ForegroundColor Red }
    exit 1
}

Write-Host 'SKILL SYNC AUDIT: PASS' -ForegroundColor Green
Write-Output "Agents verified : $($REQUIRED_AGENTS.Count)"
Write-Output "Skills verified : $($REQUIRED_SKILLS.Count)"
Write-Output "Tools present   : $(@(Get-ChildItem '.agents\tools' -Filter *.ps1).Count)"
Write-Output "Files scanned   : $($scanFiles.Count)"
if ($VerboseOutput) {
    Write-Output ''
    Write-Output 'Scanned files:'
    $scanFiles | ForEach-Object { Write-Output "  $_" }
}
exit 0
