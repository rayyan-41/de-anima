<#
.SYNOPSIS
    Generates a vault-wide index of all notes with their metadata.
    Outputs a structured summary useful for search, auditing, and context loading.

.DESCRIPTION
    Scans every .md file in the vault, extracts YAML frontmatter fields
    (date, status, tags, note) and outputs a structured index.
    Can output as plain text (default) or JSON for programmatic consumption.

    STATUS (E-5 audit note, 2026-04-12):
    This tool is NOT invoked automatically by any pipeline agent. It is a
    standalone utility for on-demand use. Recommended invocation contexts:
    - Before a large note-creation session: detect existing duplicates by title
      (pass -Domain to scope the scan).
    - Before/after technician standardize: cross-reference note count vs. MOC.
    - Ad-hoc vault health snapshots.
    Integration opportunity: could serve as a pre-computed tag cache for
    get_related_notes.ps1 on vaults exceeding ~500 notes to reduce scan time.

    Use cases:
    - Pre-flight duplicate detection before note creation
    - Feed to technician audit to cross-reference against MOC entries
    - Build a domain note count summary
    - Pre-computed candidate cache for get_related_notes.ps1 (large vaults)

.PARAMETER VaultRoot
    Root of the vault. Defaults to $VaultRoot

.PARAMETER Domain
    Optional. Filter output to a single domain.
    Valid values: Art, History, Islam, Literature, Reason, Science

.PARAMETER Format
    Output format. "text" (default) or "json".

.PARAMETER IncludeOrphans
    If set, also reports notes missing YAML frontmatter.

.EXAMPLE
    powershell -File generate_index.ps1
    Output: Full vault index, all domains, text format.

.EXAMPLE
    powershell -File generate_index.ps1 -Domain Islam -Format json
    Output: JSON array of Islam domain notes.

.EXAMPLE
    powershell -File generate_index.ps1 -IncludeOrphans
    Output: Full index plus a section listing notes with missing/broken frontmatter.
#>

param(
    [string]$VaultRoot = "",

    [ValidateSet("Art", "History", "Islam", "Literature", "Reason", "Science", "")]
    [string]$Domain = "",

    [ValidateSet("text", "json")]
    [string]$Format = "text",

    [switch]$IncludeOrphans
)
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }


# ── Helpers ───────────────────────────────────────────────────────────────────

function Extract-FrontmatterField {
    param([string]$content, [string]$field)
    if ($content -notmatch '(?s)^---\s*\n(.+?)\n---') { return $null }
    $fm = $matches[1]
    if ($fm -match "$field`:\s*[`"']?([^`"'\n]+)[`"']?") {
        return $matches[1].Trim()
    }
    return $null
}

function Extract-DomainFromTags {
    param([string[]]$tags)
    if ($tags.Count -ge 1) { return $tags[0].ToLower().Trim() }
    return $null
}

function Extract-CategoryFromTags {
    param([string[]]$tags)
    if ($tags.Count -ge 2) { return $tags[1].ToLower().Trim() }
    return $null
}

function Extract-Tags {
    param([string]$content)
    if ($content -notmatch '(?s)^---\s*\n(.+?)\n---') { return @() }
    $fm = $matches[1]
    if ($fm -match 'tags:\s*\[([^\]]+)\]') {
        return ($matches[1] -split ',') | ForEach-Object { $_.Trim().Trim('"').Trim("'").ToLower() } | Where-Object { $_ -ne '' }
    }
    elseif ($fm -match '(?s)tags:\s*\n((\s+-\s+\S[^\n]*\n?)+)') {
        $block = $matches[1]
        return ($block -split '\n') |
            Where-Object { $_ -match '^\s+-\s+' } |
            ForEach-Object { ($_ -replace '^\s+-\s+', '').Trim().ToLower() } |
            Where-Object { $_ -ne '' }
    }
    return @()
}

function Has-ValidFrontmatter {
    param([string]$content)
    # Canonical schema: date, status, tags, note (no title/domain/category)
    $requiredFields = @('date', 'status', 'tags', 'note')
    if ($content -notmatch '(?s)^---\s*\n(.+?)\n---') { return $false }
    $fm = $matches[1]
    foreach ($f in $requiredFields) {
        if ($fm -notmatch "$f`:") { return $false }
    }
    return $true
}

# ── Setup ─────────────────────────────────────────────────────────────────────

if (-not (Test-Path $VaultRoot)) {
    Write-Error "VAULT_NOT_FOUND: $VaultRoot"
    exit 1
}

$skipDirs    = @('_tmp', '.obsidian', 'paintings_source')
$sacredFiles = @('AGENTS.md', 'Chain Of Thoughts.md', 'REAS - Chain Of Thoughts.md')
$domains     = @('Art', 'History', 'Islam', 'Literature', 'Reason', 'Science')

# ── Scan ──────────────────────────────────────────────────────────────────────

$searchRoot = if ($Domain -ne "") { Join-Path $VaultRoot $Domain } else { $VaultRoot }

$allFiles = Get-ChildItem -Path $searchRoot -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue |
    Where-Object {
        $skip = $false
        foreach ($d in $skipDirs) {
            if ($_.FullName -like "*\$d\*") { $skip = $true; break }
        }
        if ($_.Name -match '^_.*Map of Contents') { $skip = $true }
        if ($sacredFiles -contains $_.Name)        { $skip = $true }
        -not $skip
    }

# ── Build index entries ───────────────────────────────────────────────────────

$entries  = @()
$orphans  = @()
$domainCounts = @{}

foreach ($file in $allFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $hasFM   = Has-ValidFrontmatter $content
    $status  = Extract-FrontmatterField $content 'status'
    $tags    = Extract-Tags $content
    $domain  = Extract-DomainFromTags $tags
    $cat     = Extract-CategoryFromTags $tags
    # Title falls back to filename — no title: property in schema
    $title   = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $words   = (($content -replace '(?s)^---.*?---', '') -split '\s+' | Where-Object { $_ -ne '' }).Count

    if (-not $hasFM) {
        if ($IncludeOrphans) {
            $orphans += [PSCustomObject]@{
                File   = $file.FullName
                Reason = "Missing or incomplete YAML frontmatter"
            }
        }
        continue
    }

    # Fallback: infer domain from path if tags are missing
    if (-not $domain) {
        foreach ($d in $domains) {
            if ($file.FullName -like "*\$d\*") { $domain = $d.ToLower(); break }
        }
    }

    $entry = [PSCustomObject]@{
        Title    = $title
        Domain   = $domain
        Category = $cat
        Status   = $status
        Tags     = $tags
        WordCount = $words
        Path     = $file.FullName
        Filename = $file.Name
    }
    $entries += $entry

    # Count by domain
    $dk = if ($domain) { $domain } else { "unknown" }
    if (-not $domainCounts.ContainsKey($dk)) { $domainCounts[$dk] = 0 }
    $domainCounts[$dk]++
}

# ── Output ────────────────────────────────────────────────────────────────────

$today = Get-Date -Format "yyyy-MM-dd HH:mm"

if ($Format -eq "json") {
    $output = [PSCustomObject]@{
        generated   = $today
        total_notes = $entries.Count
        domain_counts = $domainCounts
        notes       = $entries
    }
    $output | ConvertTo-Json -Depth 5
    exit 0
}

# Text format
Write-Output "════════════════════════════════════════════"
Write-Output "DE ANIMA VAULT INDEX"
Write-Output "Generated : $today"
Write-Output "Vault root: $VaultRoot"
if ($Domain -ne "") { Write-Output "Filter    : $Domain domain only" }
Write-Output "════════════════════════════════════════════"
Write-Output "TOTAL NOTES: $($entries.Count)"
Write-Output ""
Write-Output "BY DOMAIN:"
foreach ($dk in ($domainCounts.Keys | Sort-Object)) {
    Write-Output "  $($dk.PadRight(12)) $($domainCounts[$dk]) notes"
}
Write-Output ""
Write-Output "════════════════════════════════════════════"
Write-Output "NOTE LISTING"
Write-Output "════════════════════════════════════════════"

$grouped = $entries | Group-Object -Property Domain | Sort-Object Name

foreach ($group in $grouped) {
    Write-Output ""
    Write-Output "── $($group.Name.ToUpper()) ($($group.Count) notes) ──"
    foreach ($e in ($group.Group | Sort-Object Category, Title)) {
        $tagStr  = if ($e.Tags.Count -gt 0) { "[" + ($e.Tags -join ", ") + "]" } else { "[no tags]" }
        $wc      = "$($e.WordCount)w"
        $catStr  = if ($e.Category) { "[$($e.Category)]" } else { "[no category]" }
        Write-Output "  $($e.Title)"
        Write-Output "    $catStr  $wc  $tagStr"
        Write-Output "    $($e.Path)"
    }
}

if ($IncludeOrphans -and $orphans.Count -gt 0) {
    Write-Output ""
    Write-Output "════════════════════════════════════════════"
    Write-Output "ORPHAN NOTES (missing/incomplete frontmatter): $($orphans.Count)"
    Write-Output "════════════════════════════════════════════"
    foreach ($o in $orphans) {
        Write-Output "  $($o.File)"
        Write-Output "    Reason: $($o.Reason)"
    }
}

Write-Output ""
Write-Output "INDEX COMPLETE: $($entries.Count) notes indexed."

