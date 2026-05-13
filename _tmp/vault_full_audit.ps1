$vault = "E:\De Anima"
$outputFile = "E:\De Anima\_tmp\full_audit_report.txt"

$notes = Get-ChildItem -Path $vault -Recurse -Filter "*.md" | Where-Object { $_.FullName -notmatch "\\_tmp\\" -and $_.FullName -notmatch "\\\.trash\\" -and $_.FullName -notmatch "\\\.obsidian\\" -and $_.FullName -notmatch "\\\.gemini\\" -and $_.Name -ne "GEMINI.md" -and $_.Name -ne "Chain Of Thoughts.md" -and $_.Name -ne "REAS - Chain Of Thoughts.md" }

$missingFrontmatter = @()
$missingFields = @()
$tagFormatIssues = @()
$missingCli = @()
$orphanLinks = @()
$allTags = @{}
$noteTitles = @{}
$duplicateTags = @()
$notesWithTitleField = @()
$notesWithDomainField = @()
$notesWithCategoryField = @()
$wrongTagOrder = @()
$invalidStatus = @()

# Index note titles
foreach ($f in $notes) {
    $base = $f.BaseName
    $noteTitles[$base.ToLower()] = $true
}

foreach ($f in $notes) {
    $content = Get-Content $f.FullName -Raw
    $isMoc = $f.Name -match "Map of Contents"
    $relPath = $f.FullName.Replace($vault, "").TrimStart("\", "/")
    
    if (-not ($content -match "(?s)^---\r?\n(.*?)\r?\n---")) {
        $missingFrontmatter += $relPath
        continue
    }
    
    $yaml = $matches[1]
    
    # Required fields
    $hasDate = $yaml -match "(?m)^date:\s*(\S+)"
    $hasStatus = $yaml -match "(?m)^status:\s*(\S+)"
    $hasTags = $yaml -match "(?m)^tags:\s*"
    $hasNote = $yaml -match "(?m)^note:\s*"
    
    if (-not $hasDate) { $missingFields += "$relPath [missing date]" }
    if (-not $hasStatus) { $missingFields += "$relPath [missing status]" }
    if (-not $hasTags) { $missingFields += "$relPath [missing tags]" }
    if (-not $hasNote) { $missingFields += "$relPath [missing note]" }
    
    # Legacy fields
    if ($yaml -match "(?m)^title:\s*") { $notesWithTitleField += $relPath }
    if ($yaml -match "(?m)^domain:\s*") { $notesWithDomainField += $relPath }
    if ($yaml -match "(?m)^category:\s*") { $notesWithCategoryField += $relPath }
    
    # Status check
    if ($hasStatus) {
        $status = $matches[1].Trim().ToLower()
        if ($status -ne "complete" -and $status -ne "incomplete" -and $status -ne "draft") {
            $invalidStatus += "$relPath [status='$status']"
        }
    }
    
    # Tag format
    $inlineFormat = $yaml -match "tags:\s*\["
    $listFormat = $yaml -match "tags:\s*\r?\n\s*-"
    if ($inlineFormat -and $listFormat) {
        $tagFormatIssues += $relPath
    }
    
    # Missing cli
    if (-not ($yaml -match "cli")) {
        $missingCli += $relPath
    }
    
    # Extract and check tags
    $tags = @()
    if ($yaml -match "(?m)^tags:\s*\[(.*?)\]") {
        $tags = $matches[1] -split "," | ForEach-Object { $_.Trim().Trim("'").Trim('"').ToLower() } | Where-Object { $_ }
    } elseif ($yaml -match "(?m)^tags:\s*\r?\n((?:\s+- .*\r?\n?)+)") {
        $tagLines = $matches[1] -split "\r?\n"
        foreach ($line in $tagLines) {
            if ($line -match "^\s+- (.+)") { $tags += $matches[1].Trim().Trim("'").Trim('"').ToLower() }
        }
    }
    
    # Check for duplicate tags
    $seen = @{}
    foreach ($t in $tags) {
        if ($seen.ContainsKey($t)) {
            $duplicateTags += "$relPath [duplicate: $t]"
        } else {
            $seen[$t] = $true
        }
        $allTags[$t] = ($allTags[$t] + 1)
    }
    
    # Check tag order for non-MOCs: domain should be first, cli last
    if (-not $isMoc -and $tags.Count -ge 2) {
        $relParts = $relPath -split "\\"
        $expectedDomain = $relParts[0].ToLower()
        if ($tags[0] -ne $expectedDomain) {
            $wrongTagOrder += "$relPath [first tag '$($tags[0])' != domain '$expectedDomain']"
        }
        if ($tags[$tags.Count - 1] -ne "cli") {
            $wrongTagOrder += "$relPath [last tag '$($tags[$tags.Count - 1])' != 'cli']"
        }
    }
    
    # Orphan wikilinks
    $linkMatches = [regex]::Matches($content, '\[\[(.*?)\]\]')
    foreach ($lm in $linkMatches) {
        $link = $lm.Groups[1].Value
        $clean = ($link -split '\|')[0].Trim()
        if ($clean -match "^#") { continue }
        $cleanLower = $clean.ToLower()
        if (-not $noteTitles.ContainsKey($cleanLower)) {
            $orphanLinks += "$relPath -> [[$clean]]"
        }
    }
}

# Write report
$report = @()
$report += "=== FULL VAULT STRUCTURAL AUDIT ==="
$report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "Total files scanned: $($notes.Count)"
$report += ""

$report += "--- 1. MISSING FRONTMATTER ---"
$report += "Count: $($missingFrontmatter.Count)"
foreach ($m in $missingFrontmatter) { $report += "  $m" }
$report += ""

$report += "--- 2. MISSING REQUIRED FIELDS (date/status/tags/note) ---"
$report += "Count: $($missingFields.Count)"
foreach ($m in $missingFields) { $report += "  $m" }
$report += ""

$report += "--- 3. LEGACY FIELDS (title/domain/category) ---"
$report += "Notes with 'title' field: $($notesWithTitleField.Count)"
foreach ($n in $notesWithTitleField) { $report += "  $n" }
$report += "Notes with 'domain' field: $($notesWithDomainField.Count)"
foreach ($n in $notesWithDomainField) { $report += "  $n" }
$report += "Notes with 'category' field: $($notesWithCategoryField.Count)"
foreach ($n in $notesWithCategoryField) { $report += "  $n" }
$report += ""

$report += "--- 4. INVALID STATUS VALUES ---"
$report += "Count: $($invalidStatus.Count)"
foreach ($s in $invalidStatus) { $report += "  $s" }
$report += ""

$report += "--- 5. MIXED TAG FORMATS ---"
$report += "Count: $($tagFormatIssues.Count)"
foreach ($t in $tagFormatIssues) { $report += "  $t" }
$report += ""

$report += "--- 6. MISSING 'cli' TAG ---"
$report += "Count: $($missingCli.Count)"
foreach ($m in $missingCli) { $report += "  $m" }
$report += ""

$report += "--- 7. DUPLICATE TAGS WITHIN A NOTE ---"
$report += "Count: $($duplicateTags.Count)"
foreach ($d in $duplicateTags) { $report += "  $d" }
$report += ""

$report += "--- 8. WRONG TAG ORDER (non-MOCs) ---"
$report += "Count: $($wrongTagOrder.Count)"
foreach ($w in $wrongTagOrder) { $report += "  $w" }
$report += ""

$report += "--- 9. ORPHAN WIKILINKS ---"
$report += "Count: $($orphanLinks.Count)"
$orphanSorted = $orphanLinks | Sort-Object -Unique
foreach ($o in $orphanSorted) { $report += "  $o" }
$report += ""

$report += "--- 10. ALL TAG FREQUENCIES ---"
$allTags.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { $report += "  $($_.Name) : $($_.Value)" }
$report += ""

$report += "=== AUDIT COMPLETE ==="

$report | Out-File -FilePath $outputFile -Encoding utf8
Write-Host "Audit complete. Report written to: $outputFile"
Write-Host "Missing frontmatter: $($missingFrontmatter.Count)"
Write-Host "Missing fields: $($missingFields.Count)"
Write-Host "Legacy fields: $($notesWithTitleField.Count + $notesWithDomainField.Count + $notesWithCategoryField.Count)"
Write-Host "Invalid status: $($invalidStatus.Count)"
Write-Host "Mixed formats: $($tagFormatIssues.Count)"
Write-Host "Missing cli: $($missingCli.Count)"
Write-Host "Duplicate tags: $($duplicateTags.Count)"
Write-Host "Wrong tag order: $($wrongTagOrder.Count)"
Write-Host "Orphan links: $($orphanLinks.Count)"
