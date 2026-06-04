<#
.SYNOPSIS
    Scans the De Anima vault for notes that share tag overlap with a source note.
    Returns a ranked list of candidate notes for backlink insertion.

.DESCRIPTION
    Reads frontmatter from every .md note in the vault, parses the tags: field,
    and computes an overlap score against the provided CoreTags and SupportingTags.
    Enforces the formatter link policy:
      - PRIMARY match:   >= 2 shared core tags
      - SECONDARY match: >= 1 shared core tag AND same category
    Returns results sorted by descending overlap score.

.PARAMETER NotePath
    Full path to the source note being processed. Used to exclude self from results
    and to infer the note's domain/category for secondary matching.

.PARAMETER CoreTags
    Comma-separated string of core tags from TAGGER_HANDOFF or FORMATTER_LINK_POLICY.
    Example: "islam, fiqh, prayer, salah"

.PARAMETER SupportingTags
    Optional. Comma-separated string of supporting tags. Used for secondary scoring.
    Example: "hanafi, hadith-analysis"

.PARAMETER ExcludedMentions
    Optional. Comma-separated string of entity names to exclude as backlink targets.
    Example: "Ibn Abbas, Al-Nawawi"

.PARAMETER VaultRoot
    Root of the vault. Defaults to "E:\De Anima"

.PARAMETER TopN
    Maximum number of results to return. Defaults to 15.

.PARAMETER MinScore
    Minimum overlap score required to include a candidate. Defaults to 1.

.EXAMPLE
    powershell -File get_related_notes.ps1 `
        -NotePath "E:\De Anima\Islam\Fiqh\Ibadat\Rafa al-Yadayn (Fiqh).md" `
        -CoreTags "islam, fiqh, prayer, salah, hanafi" `
        -SupportingTags "hadith-analysis, shafii" `
        -TopN 10

    Output:
    CANDIDATES_FOUND: 4
    ---
    SCORE:5 | MATCH:primary | PATH:E:\De Anima\Islam\Fiqh\Ibadat\Prayer (Fiqh).md | TAGS:islam,fiqh,prayer,ibadat,ai-generated
    SCORE:3 | MATCH:primary | PATH:E:\De Anima\Islam\Fiqh\Ibadat\Wudu (Fiqh).md | TAGS:islam,fiqh,purification,ibadat,ai-generated
    SCORE:2 | MATCH:secondary | PATH:E:\De Anima\Islam\Aqeedah\Niyyah (Aqeedah).md | TAGS:islam,aqeedah,intention,ai-generated
    SCORE:1 | MATCH:secondary | PATH:E:\De Anima\History\Biographies\Ibn Hanbal.md | TAGS:history,biography,hanbali,ai-generated
    ---
    EXCLUDED_BY_POLICY: 0
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$NotePath,

    [Parameter(Mandatory=$true)]
    [string]$CoreTags,

    [string]$SupportingTags = "",

    [string]$ExcludedMentions = "",

    [string]$VaultRoot = "E:\De Anima",

    [int]$TopN = 15,

    [int]$MinScore = 1
)

# ── Helpers ───────────────────────────────────────────────────────────────────

function Normalize-Name {
    # E-3 fix: normalize entity names for exclusion matching.
    # Lowercases, collapses hyphens/spaces to single space, trims.
    # Prevents space-vs-hyphen mismatches (e.g. "Ibn Khaldun" vs "ibn-khaldun")
    # and avoids over-broad substring exclusions.
    param([string]$s)
    return (($s.ToLower() -replace '[-\s]+', ' ')).Trim()
}

function Parse-TagsFromFrontmatter {
    param([string]$content)
    if ($content -notmatch '(?s)^---\s*\n(.+?)\n---') { return @() }
    $frontmatter = $matches[1]

    # Inline array:  tags: [islam, fiqh, prayer]
    if ($frontmatter -match 'tags:\s*\[([^\]]+)\]') {
        $raw = $matches[1]
        return ($raw -split ',') | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne '' }
    }
    # Block list:
    #   tags:
    #     - islam
    #     - fiqh
    elseif ($frontmatter -match '(?s)tags:\s*\n((\s+-\s+\S[^\n]*\n?)+)') {
        $block = $matches[1]
        return ($block -split '\n') |
            Where-Object { $_ -match '^\s+-\s+' } |
            ForEach-Object { ($_ -replace '^\s+-\s+', '').Trim().ToLower() } |
            Where-Object { $_ -ne '' }
    }
    return @()
}

function Parse-CategoryFromTags {
    # Category is tags[1] (second tag) — no separate category: property in the schema
    param([string[]]$tags)
    if ($tags.Count -ge 2) { return $tags[1].ToLower().Trim() }
    return ""
}

function Normalize-Tags {
    param([string]$tagString)
    if (-not $tagString -or $tagString.Trim() -eq '') { return @() }
    return ($tagString -split ',') |
        ForEach-Object { $_.Trim().ToLower().TrimStart('#') } |
        Where-Object { $_ -ne '' }
}

# ── Setup ─────────────────────────────────────────────────────────────────────

if (-not (Test-Path $VaultRoot)) {
    Write-Error "VAULT_NOT_FOUND: $VaultRoot"
    exit 1
}

$sourceNotePath = $NotePath.ToLower()
$coreTags       = Normalize-Tags $CoreTags
$supportTags    = Normalize-Tags $SupportingTags
$excluded       = Normalize-Tags $ExcludedMentions

# Parse source note's own tags and derive category (tags[1]) for secondary match rule
$sourceContent  = ""
if (Test-Path $NotePath) {
    $sourceContent = Get-Content $NotePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
}
$sourceTagsRaw  = Parse-TagsFromFrontmatter $sourceContent
$sourceCategory = Parse-CategoryFromTags $sourceTagsRaw

# Directories and files to skip entirely
$skipDirs   = @('_tmp', '.obsidian', 'paintings_source')
$sacredFiles = @('GEMINI.md', 'Chain Of Thoughts.md', 'REAS - Chain Of Thoughts.md')

# ── Vault scan ────────────────────────────────────────────────────────────────

$allNotes = Get-ChildItem -Path $VaultRoot -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue |
    Where-Object {
        $skip = $false
        foreach ($d in $skipDirs) {
            if ($_.FullName -like "*\$d\*" -or $_.FullName -like "*/$d/*") {
                $skip = $true; break
            }
        }
        if ($_.Name -match '^_.*Map of Contents') { $skip = $true }
        if ($sacredFiles -contains $_.Name)        { $skip = $true }
        if ($_.FullName.ToLower() -eq $sourceNotePath) { $skip = $true }
        -not $skip
    }

# ── Score candidates ──────────────────────────────────────────────────────────

$candidates    = @()
$excludedCount = 0

foreach ($note in $allNotes) {
    $content = Get-Content $note.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $noteTags     = Parse-TagsFromFrontmatter $content
    $noteCategory = Parse-CategoryFromTags $noteTags

    if ($noteTags.Count -eq 0) { continue }

    # ── E-3 fix: normalize both sides before exclusion matching ─────────────────
    # Old code used raw lowercase comparison, causing space-vs-hyphen mismatches
    # (e.g. excluding "Al-Ghazali" failed to match note "Al Ghazali (Biography)").
    # Normalize-Name collapses hyphens and spaces to single space on both sides.
    $noteTitle     = Normalize-Name ([System.IO.Path]::GetFileNameWithoutExtension($note.Name))
    $isExcluded    = $false
    foreach ($ex in $excluded) {
        $normEx = Normalize-Name $ex
        if ($normEx -ne '' -and ($noteTitle -like "*$normEx*" -or $normEx -like "*$noteTitle*")) {
            $isExcluded = $true
            break
        }
    }
    if ($isExcluded) { $excludedCount++; continue }

    # Count shared core tags
    $sharedCore    = ($coreTags | Where-Object { $noteTags -contains $_ }).Count
    # Count shared supporting tags
    $sharedSupport = ($supportTags | Where-Object { $noteTags -contains $_ }).Count

    # Determine match tier using formatter policy
    $matchTier = $null
    if ($sharedCore -ge 2) {
        $matchTier = "primary"
    }
    elseif ($sharedCore -ge 1 -and $noteCategory -ne "" -and $noteCategory -eq $sourceCategory) {
        $matchTier = "secondary"
    }

    if (-not $matchTier) { continue }

    # Composite score: core overlap weighted 2x + support overlap 1x
    $score = ($sharedCore * 2) + $sharedSupport

    if ($score -lt $MinScore) { continue }

    $candidates += [PSCustomObject]@{
        Score    = $score
        Match    = $matchTier
        Path     = $note.FullName
        Filename = $note.Name
        Tags     = ($noteTags -join ',')
        Category = $noteCategory
    }
}

# ── Sort, deduplicate by path, and trim ───────────────────────────────────────

$sorted = $candidates |
    Sort-Object -Property Score -Descending |
    Group-Object -Property Path |
    ForEach-Object { $_.Group | Select-Object -First 1 } |
    Sort-Object -Property Score -Descending |
    Select-Object -First $TopN

# ── Output ────────────────────────────────────────────────────────────────────

if ($sorted.Count -eq 0) {
    Write-Output "CANDIDATES_FOUND: 0"
    Write-Output "NO_POLICY_VALID_CANDIDATES: No notes meet the link policy threshold (primary: >=2 shared core tags, secondary: >=1 shared core tag + same category)."
    Write-Output "EXCLUDED_BY_POLICY: $excludedCount"
    exit 0
}

Write-Output "CANDIDATES_FOUND: $($sorted.Count)"
Write-Output "---"
foreach ($c in $sorted) {
    Write-Output "SCORE:$($c.Score) | MATCH:$($c.Match) | PATH:$($c.Path) | TAGS:$($c.Tags)"
}
Write-Output "---"
Write-Output "EXCLUDED_BY_POLICY: $excludedCount"
