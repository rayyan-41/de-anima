$vaultPath = "E:\De Anima"
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | Where-Object { $_.FullName -notmatch "\\_tmp\\" -and $_.FullName -notmatch "\\\.trash\\" -and $_.FullName -notmatch "\\\.obsidian\\" -and $_.Name -notmatch "Map of Contents" -and $_.Name -ne "GEMINI.md" -and $_.Name -ne "Chain Of Thoughts.md" -and $_.Name -ne "REAS - Chain Of Thoughts.md" }

# --- CANONICAL REGISTRY ---
$domainTags = @('art', 'history', 'literature', 'reason', 'science', 'islam')
$categoryMap = @{
    'art'        = @('art-history', 'art-theory')
    'history'    = @('empire', 'biography', 'geopolitical', 'medieval', 'contemporary')
    'literature' = @('book', 'myth', 'short-story', 'reference')
    'reason'     = @('philosophy', 'logic', 'metaphysics', 'ethics', 'epistemology')
    'science'    = @('astronomy', 'mathematics', 'computer-science', 'ai', 'web-dev', 'physics')
    'islam'      = @('aqeedah', 'fiqh')
}
$normMap = @{
    'biographies' = 'biography'
    'medieval-and-late-medieval' = 'medieval'
    'millenniumproblems' = 'millennium-problems'
    'romanempire' = 'roman-empire'
    'islamic-history' = 'history'
    'islamic-golden-age-scholars' = 'islamic-golden-age'
}
$fluffTags = @("analysis", "records", "timeline", "documentation", "retrospective", "worldview", "insights", "research", "systems", "theory", "data", "concepts", "development", "reasoning", "argument", "perspective", "thought-experiment", "reflection", "chainofthoughts", "evolution", "tooling", "concept", "historical-analysis", "philosophical-analysis", "architecture", "footnote", "study", "general")

$updatedCount = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($null -eq $content) { continue }
    
    # Infer Domain/Category from Path
    $inferredDomain = ""
    $inferredCategory = ""
    $relPath = $file.FullName.Replace($vaultPath, "")
    
    if ($relPath -match "\\Art\\") { $inferredDomain = "art" }
    elseif ($relPath -match "\\History\\") { $inferredDomain = "history" }
    elseif ($relPath -match "\\Islam\\") { $inferredDomain = "islam" }
    elseif ($relPath -match "\\Literature\\") { $inferredDomain = "literature" }
    elseif ($relPath -match "\\Reason\\") { $inferredDomain = "reason" }
    elseif ($relPath -match "\\Science\\") { $inferredDomain = "science" }

    if ($relPath -match "Biographies") { $inferredCategory = "biography" }
    elseif ($relPath -match "Medieval") { $inferredCategory = "medieval" }
    elseif ($relPath -match "Contemporary") { $inferredCategory = "contemporary" }
    elseif ($relPath -match "Aqeedah") { $inferredCategory = "aqeedah" }
    elseif ($relPath -match "Fiqh") { $inferredCategory = "fiqh" }
    elseif ($relPath -match "Art History") { $inferredCategory = "art-history" }
    elseif ($relPath -match "Art Theory") { $inferredCategory = "art-theory" }
    elseif ($relPath -match "Books") { $inferredCategory = "book" }
    elseif ($relPath -match "Myths") { $inferredCategory = "myth" }
    elseif ($relPath -match "Astronomy") { $inferredCategory = "astronomy" }
    elseif ($relPath -match "Mathematics") { $inferredCategory = "mathematics" }
    elseif ($relPath -match "Computer Science") { $inferredCategory = "computer-science" }
    elseif ($relPath -match "AI") { $inferredCategory = "ai" }

    # Parse YAML
    $yaml = ""
    $body = $content
    if ($content -match "(?s)^---\r?\n(.*?)\r?\n---(.*)") {
        $yaml = $matches[1]
        $body = $matches[2]
    }
    
    # Extract existing fields
    $title = ""
    if ($yaml -match "(?m)^title:\s*(.+)") { $title = $matches[1].Trim().Trim('"').Trim("'") }
    if (-not $title) { $title = $file.BaseName }

    $domain = ""
    if ($yaml -match "(?m)^domain:\s*(.+)") { $domain = $matches[1].Trim().Trim('"').Trim("'").ToLower() }
    if (-not $domain) { $domain = $inferredDomain }

    $category = ""
    if ($yaml -match "(?m)^category:\s*(.+)") { $category = $matches[1].Trim().Trim('"').Trim("'").ToLower() }
    if (-not $category) { $category = $inferredCategory }

    $status = ""
    if ($yaml -match "(?m)^status:\s*(.+)") { $status = $matches[1].Trim().Trim('"').Trim("'").ToLower() }
    if (-not $status) { $status = "complete" }

    $date = ""
    if ($yaml -match "(?m)^date:\s*(.+)") { $date = $matches[1].Trim().Trim('"').Trim("'") }
    if (-not $date) { $date = $file.LastWriteTime.ToString("yyyy-MM-dd") }

    # Extract Tags
    $tags = @()
    if ($yaml -match "(?m)^tags:\s*\r?\n((?:\s+- .*\r?\n?)+)") {
        $tagLines = $matches[1] -split "\r?\n"
        foreach ($line in $tagLines) { if ($line -match "^\s+- (.+)") { $tags += $matches[1].Trim().Trim("'").Trim('"') } }
    } elseif ($yaml -match "(?m)^tags:\s*\[(.*?)\]") {
        $tagList = $matches[1] -split ","
        foreach ($t in $tagList) { $v = $t.Trim().Trim("'").Trim('"'); if ($v) { $tags += $v } }
    }

    # Clean and Normalize Tags
    $cleanedTopicTags = @()
    foreach ($t in $tags) {
        $t = $t.ToLower()
        if ($t.StartsWith("#")) { $t = $t.Substring(1) }
        if ($fluffTags -contains $t) { continue }
        if ($t.StartsWith("footnote")) { continue }
        if ($t.Length -gt 40) { continue }
        if ($t -match "---") { continue }
        if ($normMap.ContainsKey($t)) { $t = $normMap[$t] }
        
        # Skip domain/category/modifiers for now
        if ($t -eq $domain -or $t -eq $category -or $t -eq "cli" -or $t -eq "incomplete" -or $t -eq "original-insight") { continue }
        
        if (-not [string]::IsNullOrWhiteSpace($t) -and $cleanedTopicTags -notcontains $t) {
            $cleanedTopicTags += $t
        }
    }

    # Build Final Tag Set
    $finalTags = @()
    if ($domain) { $finalTags += $domain }
    if ($category) { $finalTags += $category }
    foreach ($t in $cleanedTopicTags) { $finalTags += $t }
    if ($tags -contains "incomplete") { $finalTags += "incomplete" }
    if ($tags -contains "original-insight") { $finalTags += "original-insight" }
    $finalTags += "cli"

    # Construct New YAML
    $newYaml = "---`n"
    $newYaml += "title: `"$title`"`n"
    $newYaml += "date: $date`n"
    $newYaml += "domain: $domain`n"
    $newYaml += "category: $category`n"
    $newYaml += "status: $status`n"
    $newYaml += "tags:`n"
    foreach ($t in $finalTags) { $newYaml += "  - $t`n" }
    $newYaml += "---"

    # Save
    $newContent = $newYaml + $body
    Set-Content -Path $file.FullName -Value $newContent -NoNewline
    $updatedCount++
}

Write-Host "Structural Standardization Complete. Total files updated: $updatedCount"
