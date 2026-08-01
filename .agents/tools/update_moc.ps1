<#
.SYNOPSIS
    Adds a note to its domain Map of Contents, or rebuilds a MOC from the vault.

.DESCRIPTION
    Only the six core domains have a MOC. Nested / sub-category MOCs were retired --
    do not reintroduce them without the vault owner's decision.

    The MOC lives at:  <Domain>\Map of Contents - <Domain>.md

    Notes are grouped by their CATEGORY tag (tags[1]), which is derived from the
    folder the note lives in. The Topic Area column is the category, so every
    category occupies exactly one row listing all of its notes.

    -Rebuild regenerates the entire MOC by scanning the domain folder. This is the
    self-healing path: it cannot drift, prunes dead links by construction, and is
    safe to run at any time.

.PARAMETER Rebuild
    Ignore -NoteTitle/-NoteFilename and regenerate the MOC from every note in the domain.

.EXAMPLE
    powershell -File update_moc.ps1 -Domain Islam -NoteTitle "Rafa al-Yadayn" -NoteFilename "Rafa al-Yadayn.md" -Category fiqh
    MOC_UPDATED: Map of Contents - Islam.md - added 'Rafa al-Yadayn' under 'fiqh'

.EXAMPLE
    powershell -File update_moc.ps1 -Domain Science -Rebuild
    MOC_REBUILT: Map of Contents - Science.md - 14 notes across 4 categories
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Art", "History", "Islam", "Literature", "Reason", "Science")]
    [string]$Domain,

    [string]$NoteTitle = "",
    [string]$NoteFilename = "",
    [string]$Category = "",

    [switch]$Rebuild,

    [string]$VaultRoot = ""
)

if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }

$mocFilename = "Map of Contents - $Domain.md"
$domainDir   = Join-Path $VaultRoot $Domain
$mocPath     = Join-Path $domainDir $mocFilename
$today       = Get-Date -Format "yyyy-MM-dd"

if (-not (Test-Path $domainDir)) {
    Write-Output "MOC_ERROR: domain folder not found at $domainDir"
    exit 1
}

# -- Helpers ------------------------------------------------------------------
function Get-NoteTags {
    param([string]$Path)
    $raw = Get-Content $Path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $raw) { return @() }
    if ($raw -match '(?s)^---\s*\n(.*?)\n---') {
        $fm = $matches[1]
        if ($fm -match '(?m)^tags:\s*\[(.*?)\]\s*$') {
            return @($matches[1] -split ',' | ForEach-Object { $_.Trim().ToLower() } |
                     Where-Object { $_ -ne '' })
        }
    }
    return @()
}

function Write-Moc {
    param([hashtable]$Groups, [int]$Total)
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("date: $today")
    [void]$sb.AppendLine("status: complete")
    [void]$sb.AppendLine("tags: [$($Domain.ToLower()), moc, cli]")
    [void]$sb.AppendLine('note: ""')
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Metadata:**")
    [void]$sb.AppendLine("- Last Major Reorganization: $today")
    [void]$sb.AppendLine("- Total Notes: $Total")
    [void]$sb.AppendLine("- - -")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Structure")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Topic Area | Notes | Last Updated |")
    [void]$sb.AppendLine("|------------|-------|--------------|")
    foreach ($cat in ($Groups.Keys | Sort-Object)) {
        $links = ($Groups[$cat] | Sort-Object | ForEach-Object { "[[$_]]" }) -join ", "
        [void]$sb.AppendLine("| $cat | $links | $today |")
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- - -")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("*Last MOC Update: $today by De Anima Orchestrator*")
    # UTF-8 without BOM, to match the rest of the vault.
    [System.IO.File]::WriteAllText($mocPath, $sb.ToString().TrimEnd() + "`n",
        (New-Object System.Text.UTF8Encoding($false)))
}

function Get-DomainGroups {
    $groups = @{}
    $count = 0
    $notes = Get-ChildItem -Path $domainDir -Recurse -Filter "*.md" -File |
             Where-Object { $_.Name -notlike "Map of Contents*" -and
                            $_.FullName -notlike "*\paintings_source\*" -and
                            $_.BaseName -notlike "*Chain Of Thoughts*" }
    foreach ($n in $notes) {
        $tags = Get-NoteTags $n.FullName
        if ($tags.Count -lt 2) { continue }
        if ($tags[1] -eq 'moc') { continue }
        $cat = $tags[1]
        if (-not $groups.ContainsKey($cat)) { $groups[$cat] = @() }
        $groups[$cat] += $n.BaseName
        $count++
    }
    return @{ Groups = $groups; Count = $count }
}

# -- Rebuild ------------------------------------------------------------------
if ($Rebuild) {
    $r = Get-DomainGroups
    Write-Moc -Groups $r.Groups -Total $r.Count
    Write-Output "MOC_REBUILT: $mocFilename - $($r.Count) notes across $($r.Groups.Keys.Count) categories"
    exit 0
}

# -- Incremental add ----------------------------------------------------------
if (-not $NoteTitle -or -not $NoteFilename) {
    Write-Output "MOC_ERROR: -NoteTitle and -NoteFilename are required unless -Rebuild is used"
    exit 1
}

$stem = [System.IO.Path]::GetFileNameWithoutExtension($NoteFilename)

if (-not (Test-Path $mocPath)) {
    $r = Get-DomainGroups
    Write-Moc -Groups $r.Groups -Total $r.Count
    Write-Output "MOC_CREATED: $mocFilename - built from $($r.Count) notes"
    exit 0
}

$content = Get-Content $mocPath -Raw -Encoding UTF8
if ($content -match [regex]::Escape("[[$stem]]")) {
    Write-Output "ALREADY_LISTED: '$stem' is already in $mocFilename"
    exit 0
}

# A rebuild is cheaper and safer than surgical row editing, and guarantees the
# counts, grouping, and dead-link pruning all stay correct.
$r = Get-DomainGroups
Write-Moc -Groups $r.Groups -Total $r.Count

$reread = Get-Content $mocPath -Raw -Encoding UTF8
if ($reread -match [regex]::Escape("[[$stem]]")) {
    Write-Output "MOC_UPDATED: $mocFilename - added '$stem' under '$Category'"
    exit 0
}

Write-Output "MOC_WARNING: $mocFilename rebuilt, but '$stem' was not found on disk in $Domain"
exit 0
