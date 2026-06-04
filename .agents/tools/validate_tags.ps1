<#
.SYNOPSIS
    Validates tags against the De Anima canonical tag registry.
    Accepts YAML inline format: "islam, fiqh, prayer, ai-generated"
    Also accepts old inline format: "#islam #fiqh #prayer #ai-generated"
    Also accepts YAML array: "[islam, fiqh, prayer, ai-generated]"
.EXAMPLE
    powershell -File validate_tags.ps1 -TagLine "islam, fiqh, prayer, salah, hanafi, shafii, ibadat, hadith-analysis, ai-generated"
    Output: PASS
.EXAMPLE
    powershell -File validate_tags.ps1 -TagLine "islam, prayer"
    Output: FAIL: missing category tag; too few topic tags
.NOTES
    Fix (2026-04-12): Aligned $categoryMap with the exact tag strings agents produce.
    Previous version had mismatches for Reason (philosophy vs reason/philosophy),
    Art (art-history vs art/history), and Science (computer-science vs science/cs)
    that caused permanent FAIL for those domains.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$TagLine
)
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }


# Clean input â€” strip "TAGS:" prefix if present, handle both space and comma separated
$TagLine = $TagLine -replace '^\s*TAGS:\s*', ''
# Strip surrounding brackets if YAML inline array: [islam, fiqh, ...]
$TagLine = $TagLine -replace '^\[', '' -replace '\]$', ''
# Normalize: replace commas with spaces, strip # prefixes
$TagLine = $TagLine -replace ',', ' ' -replace '#', ''
$tags = ($TagLine.Trim() -split '\s+') | Where-Object { $_ -ne '' }


# --- REGISTRY (no # prefix) ---
$domainTags = @('art', 'history', 'literature', 'reason', 'science', 'islam')

$categoryMap = @{
    # Art â€” plain hyphenated strings matching tagger.md structural tag guidance
    'art'        = @('art-history', 'art-theory')
    # History â€” unchanged, agents produce these correctly
    'history'    = @('empire', 'biography', 'geopolitical', 'medieval', 'contemporary')
    # Literature â€” unchanged
    'literature' = @('book', 'myth', 'short-story', 'reference')
    # Reason â€” plain strings; tagger.md updated to match (removed reason/ prefix)
    'reason'     = @('philosophy', 'logic', 'metaphysics', 'ethics', 'epistemology')
    # Science â€” plain strings; tagger.md updated to match (removed science/ prefix)
    'science'    = @('astronomy', 'mathematics', 'computer-science', 'ai', 'web-dev', 'physics')
    # Islam â€” unchanged, was already correct
    'islam'      = @('aqeedah', 'fiqh')
}

# Flatten all category tags for quick lookup
$allCategoryTags = @()
foreach ($cats in $categoryMap.Values) {
    $allCategoryTags += $cats
}

$errors = @()

# 1. Check for exactly one domain tag
$foundDomains = $tags | Where-Object { $domainTags -contains $_ }
if ($foundDomains.Count -eq 0) {
    $errors += "missing domain tag (need one of: $($domainTags -join ', '))"
} elseif ($foundDomains.Count -gt 1) {
    $errors += "multiple domain tags found: $($foundDomains -join ', ') - need exactly one"
}

# 2. Check for exactly one category tag
$foundCategories = $tags | Where-Object { $allCategoryTags -contains $_ }
if ($foundCategories.Count -eq 0) {
    $errors += "missing category tag"
} elseif ($foundCategories.Count -gt 1) {
    $errors += "multiple category tags found: $($foundCategories -join ', ') - need exactly one"
}

# 3. Validate category matches domain
if ($foundDomains.Count -eq 1 -and $foundCategories.Count -eq 1) {
    $domain = $foundDomains[0]
    $category = $foundCategories[0]
    $validCats = $categoryMap[$domain]
    if ($validCats -and ($validCats -notcontains $category)) {
        $errors += "category '$category' is not valid for domain '$domain' (valid: $($validCats -join ', '))"
    }
}

# 4. Check topic tags (freeform - anything that isn't domain, category, or modifier)
$topicTags = $tags | Where-Object { 
    ($domainTags -notcontains $_) -and 
    ($allCategoryTags -notcontains $_) -and 
    ($_ -ne 'ai-generated') -and
    ($_ -ne 'incomplete') -and
    ($_ -ne 'original-insight')
}
if ($topicTags.Count -lt 3) {
    $errors += "too few topic tags ($($topicTags.Count)) - minimum is 3 (aim for 6-8)"
} elseif ($topicTags.Count -gt 10) {
    $errors += "too many topic tags ($($topicTags.Count)) - maximum is 10"
}

# 5. Check ai-generated is present and last
if ($tags -notcontains 'ai-generated') {
    $errors += "missing 'ai-generated' tag"
} elseif ($tags[-1] -ne 'ai-generated') {
    $errors += "'ai-generated' must be the last tag"
}

# 6. Check for duplicates
$uniqueTags = $tags | Select-Object -Unique
if ($uniqueTags.Count -ne $tags.Count) {
    $duplicates = $tags | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
    $errors += "duplicate tags: $($duplicates -join ', ')"
}

# --- OUTPUT ---
if ($errors.Count -eq 0) {
    Write-Output "PASS"
} else {
    Write-Output "FAIL: $($errors -join '; ')"
}

