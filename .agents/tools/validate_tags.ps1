<#
.SYNOPSIS
    Validates a De Anima tag array against the canonical taxonomy.

.DESCRIPTION
    The tag array is positional:

        [domain, category, type, theme(s), entity(ies), cli]

    - domain    exactly 1, from taxonomy.domains
    - category  exactly 1, valid for that domain (or a universal category)
    - type      exactly 1, from taxonomy.types
    - themes    1-3, from taxonomy.themes  <- the linking substrate
    - entities  0-6, open vocabulary (kebab-case proper nouns / specifics)
    - cli       always last

    Map of Contents files are exempt: [domain, moc, cli] is complete and valid.

    Every registry is read from .agents\taxonomy.json. This script contains no
    tag lists of its own, so the tool and the documentation cannot drift apart.

.PARAMETER TagLine
    Comma- or space-separated tags, with or without a leading '#', with or
    without surrounding brackets.

.PARAMETER Explain
    Print the parsed slot assignment alongside the verdict.

.EXAMPLE
    powershell -File validate_tags.ps1 -TagLine "history, biography, biography, islamic-golden-age, al-ghazali, cli"
    PASS

.EXAMPLE
    powershell -File validate_tags.ps1 -TagLine "[literature, moc, cli]"
    PASS
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$TagLine,

    [switch]$Explain,

    [string]$TaxonomyPath = ""
)

$VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
if (-not $TaxonomyPath) { $TaxonomyPath = Join-Path $PSScriptRoot "..\taxonomy.json" }

if (-not (Test-Path $TaxonomyPath)) {
    Write-Output "FAIL: taxonomy not found at $TaxonomyPath"
    exit 1
}
$tax = Get-Content $TaxonomyPath -Raw -Encoding UTF8 | ConvertFrom-Json

$MARKERS     = @($tax.schema.markers)
$MARKER      = $tax.schema.marker
$types       = @($tax.types)
$themes      = @($tax.themes)
$universal   = @($tax.universalCategories)
$modifiers   = @($tax.reservedModifiers)
$domainNames = @($tax.domains.PSObject.Properties.Name)

# Flatten every valid category once.
$allCategories = @()
foreach ($d in $domainNames) { $allCategories += @($tax.domains.$d) }
$allCategories += $universal

# -- Parse --------------------------------------------------------------------
$TagLine = $TagLine -replace '^\s*\[', '' -replace '\]\s*$', ''
$TagLine = $TagLine -replace ',', ' ' -replace '#', ''
$tags = @($TagLine.Trim() -split '\s+' | Where-Object { $_ -ne '' } |
          ForEach-Object { $_.ToLower() })

$errors = @()

if ($tags.Count -eq 0) {
    Write-Output "FAIL: no tags supplied"
    exit 1
}

# -- Duplicates ---------------------------------------------------------------
$dupes = @($tags | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($dupes.Count -gt 0) { $errors += "duplicate tags: $($dupes -join ', ')" }

# -- Marker must be present, singular, and last ------------------------------
$foundMarkers = @($tags | Where-Object { $MARKERS -contains $_ })
if ($foundMarkers.Count -eq 0) {
    $errors += "missing marker tag (one of: $($MARKERS -join ', '))"
} elseif ($foundMarkers.Count -gt 1) {
    $errors += "multiple marker tags: $($foundMarkers -join ', ') - need exactly one"
} elseif ($MARKERS -notcontains $tags[-1]) {
    $errors += "marker '$($foundMarkers[0])' must be the last tag"
}
$marker = if ($MARKERS -contains $tags[-1]) { $tags[-1] } else { $MARKER }

# -- Slot 1: domain -----------------------------------------------------------
$domain = $tags[0]
if ($domainNames -notcontains $domain) {
    $errors += "position 1 must be a domain (one of: $($domainNames -join ', ')) - found '$domain'"
    $domain = $null
}

# -- Slot 2: category ---------------------------------------------------------
$category = if ($tags.Count -ge 2) { $tags[1] } else { $null }
$isMoc = $false

if (-not $category) {
    $errors += "position 2 must be a category"
} elseif ($universal -contains $category) {
    $isMoc = $true
} elseif ($allCategories -notcontains $category) {
    $errors += "position 2 '$category' is not a known category"
} elseif ($domain -and (@($tax.domains.$domain) -notcontains $category)) {
    $valid = (@($tax.domains.$domain) + $universal) -join ', '
    $errors += "category '$category' is not valid for domain '$domain' (valid: $valid)"
}

# -- MOC files stop here ------------------------------------------------------
if ($isMoc) {
    if ($tags.Count -ne 3) {
        $errors += "a Map of Contents must be exactly [domain, moc, marker] - found $($tags.Count) tags"
    }
    if ($errors.Count -gt 0) {
        Write-Output "FAIL: $($errors -join '; ')"
        exit 1
    }
    if ($Explain) { Write-Output "SLOTS: domain=$domain category=moc marker=$marker (Map of Contents - exempt)" }
    Write-Output "PASS"
    exit 0
}

# -- Slot 3: type -------------------------------------------------------------
$type = if ($tags.Count -ge 3) { $tags[2] } else { $null }
if (-not $type) {
    $errors += "position 3 must be a type"
} elseif ($types -notcontains $type) {
    $errors += "position 3 '$type' is not a known type (one of: $($types -join ', '))"
}

# -- Remaining slots: themes, entities, marker --------------------------------
$rest = @()
if ($tags.Count -gt 3) { $rest = @($tags[3..($tags.Count - 1)]) }
$rest = @($rest | Where-Object { $MARKERS -notcontains $_ -and $modifiers -notcontains $_ })

$foundThemes   = @($rest | Where-Object { $themes -contains $_ })
$foundEntities = @($rest | Where-Object { $themes -notcontains $_ })

# Themes must lead the tail, before any entity.
if ($foundThemes.Count -gt 0 -and $foundEntities.Count -gt 0) {
    $firstEntityAt = [array]::IndexOf($rest, $foundEntities[0])
    $lastThemeAt   = [array]::IndexOf($rest, $foundThemes[-1])
    if ($lastThemeAt -gt $firstEntityAt) {
        $errors += "theme tags must come before entity tags (found '$($foundThemes[-1])' after '$($foundEntities[0])')"
    }
}

$minT = $tax.schema.arity.themes[0]
$maxT = $tax.schema.arity.themes[1]
if ($foundThemes.Count -lt $minT) {
    $errors += "too few theme tags ($($foundThemes.Count)) - need at least $minT from the theme registry; themes are what make notes linkable"
} elseif ($foundThemes.Count -gt $maxT) {
    $errors += "too many theme tags ($($foundThemes.Count)) - maximum is $maxT"
}

$maxE = $tax.schema.arity.entities[1]
if ($foundEntities.Count -gt $maxE) {
    $errors += "too many entity tags ($($foundEntities.Count)) - maximum is $maxE"
}

foreach ($e in $foundEntities) {
    if ($e -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        $errors += "entity tag '$e' must be lowercase kebab-case"
    }
}

# -- Total arity --------------------------------------------------------------
$min = $tax.schema.totalRange[0]
$max = $tax.schema.totalRange[1]
if ($tags.Count -lt $min -or $tags.Count -gt $max) {
    $errors += "tag count $($tags.Count) outside allowed range $min-$max"
}

# -- Report -------------------------------------------------------------------
if ($errors.Count -gt 0) {
    Write-Output "FAIL: $($errors -join '; ')"
    exit 1
}

if ($Explain) {
    Write-Output "SLOTS: domain=$domain category=$category type=$type themes=[$($foundThemes -join ',')] entities=[$($foundEntities -join ',')] marker=$marker"
}
Write-Output "PASS"
exit 0
