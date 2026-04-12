$vaultPath = "E:\De Anima"
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | Where-Object { $_.FullName -notmatch "\\_tmp\\" -and $_.FullName -notmatch "\\\.trash\\" -and $_.FullName -notmatch "\\\.obsidian\\" -and $_.Name -notmatch "Map of Contents" -and $_.Name -ne "GEMINI.md" -and $_.Name -ne "Chain Of Thoughts.md" -and $_.Name -ne "REAS - Chain Of Thoughts.md" }

# --- CANONICAL REGISTRY (from validate_tags.ps1 and SKILL.md) ---
$domainTags = @('art', 'history', 'literature', 'reason', 'science', 'islam')

$categoryMap = @{
    'art'        = @('art-history', 'art-theory')
    'history'    = @('empire', 'biography', 'geopolitical', 'medieval', 'contemporary')
    'literature' = @('book', 'myth', 'short-story', 'reference')
    'reason'     = @('philosophy', 'logic', 'metaphysics', 'ethics', 'epistemology')
    'science'    = @('astronomy', 'mathematics', 'computer-science', 'ai', 'web-dev', 'physics')
    'islam'      = @('aqeedah', 'fiqh')
}

$allRegistryTags = $domainTags.Clone()
foreach ($cats in $categoryMap.Values) { $allRegistryTags += $cats }
$allRegistryTags += @('cli', 'incomplete', 'original-insight')

# Specific Normalization Map
$normMap = @{
    'biographies' = 'biography'
    'medieval-and-late-medieval' = 'medieval'
    'millenniumproblems' = 'millennium-problems'
    'romanempire' = 'roman-empire'
    'islamic-history' = 'history'
    'islamic-golden-age-scholars' = 'islamic-golden-age'
}

# Fluff Tags to Remove
$fluffTags = @(
    "analysis", "records", "timeline", "documentation", "retrospective", "worldview", 
    "insights", "research", "systems", "theory", "data", "concepts", "development", 
    "reasoning", "argument", "perspective", "thought-experiment", "reflection", 
    "chainofthoughts", "evolution", "tooling", "concept", "historical-analysis",
    "philosophical-analysis", "architecture", "footnote", "study", "general"
)

$auditReport = @()
$updatedCount = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($null -eq $content) { continue }
    
    if ($content -match "(?s)^---\r?\n(.*?)\r?\n---") {
        $yaml = $matches[1]
        
        # Extract existing properties
        $domain = ""
        if ($yaml -match "(?m)^domain:\s*(.+)") { $domain = $matches[1].Trim().Trim('"').Trim("'").ToLower() }
        $category = ""
        if ($yaml -match "(?m)^category:\s*(.+)") { $category = $matches[1].Trim().Trim('"').Trim("'").ToLower() }
        
        # Extract existing tags
        $originalTags = @()
        $tagsMatch = ""
        if ($yaml -match "(?m)^(tags:\s*\r?\n(?:\s+- .*\r?\n?)+)") {
            $tagsMatch = $matches[1]
            $tagLines = $tagsMatch -split "\r?\n"
            foreach ($line in $tagLines) {
                if ($line -match "^\s+- (.+)") { $originalTags += $matches[1].Trim().Trim("'").Trim('"') }
            }
        } elseif ($yaml -match "(?m)^(tags:\s*\[.*?\])") {
            $tagsMatch = $matches[1]
            if ($tagsMatch -match "\[(.*)\]") {
                $tagList = $matches[1] -split ","
                foreach ($t in $tagList) {
                    $val = $t.Trim().Trim("'").Trim('"')
                    if ($val) { $originalTags += $val }
                }
            }
        }
        
        if ($originalTags.Count -eq 0) { continue }

        $cleanedTags = @()
        $removedTags = @()
        $normalizedTags = @()

        foreach ($t in $originalTags) {
            $origT = $t
            $t = $t.ToLower()
            if ($t.StartsWith("#")) { $t = $t.Substring(1) }
            
            # Remove Fluff
            if ($fluffTags -contains $t) { $removedTags += $origT; continue }
            if ($t.StartsWith("footnote")) { $removedTags += $origT; continue }
            if ($t.Length -gt 40) { $removedTags += $origT; continue }
            if ($t -match "---") { $removedTags += $origT; continue }

            # Normalize
            if ($normMap.ContainsKey($t)) {
                $t = $normMap[$t]
                $normalizedTags += "$origT -> $t"
            }

            # Avoid duplication of Domain/Category/Modifiers in the Topic list for now
            if ($t -eq "cli" -or $t -eq "incomplete" -or $t -eq "original-insight") { continue }
            if ($t -eq $domain -or $t -eq $category) { continue }
            
            if (-not [string]::IsNullOrWhiteSpace($t) -and $cleanedTags -notcontains $t) {
                $cleanedTags += $t
            }
        }

        # Build Final Tag List according to Canonical Order
        $finalTags = @()
        
        # 1. Domain
        if ($domain -and $domainTags -contains $domain) {
            $finalTags += $domain
        } elseif ($domain) {
            # Try to fix domain if it's almost right
            if ($domain -eq "computerscience") { $domain = "science" }
            if ($domain -eq "islamic") { $domain = "islam" }
            if ($domainTags -contains $domain) { $finalTags += $domain }
        }

        # 2. Category
        if ($category) {
            # Normalize category
            if ($normMap.ContainsKey($category)) { $category = $normMap[$category] }
            
            # Check if category belongs to domain
            $validCats = $categoryMap[$domain]
            if ($validCats -and ($validCats -contains $category)) {
                $finalTags += $category
            } else {
                # Category mismatch or invalid category. 
                # If it's a valid category for another domain, we might have a problem.
                # But for now, just add it if it's in the allRegistryTags
                if ($allRegistryTags -contains $category) {
                    $finalTags += $category
                }
            }
        }

        # 3. Topic Tags (those remaining in cleanedTags)
        foreach ($t in $cleanedTags) {
            if ($finalTags -notcontains $t) {
                $finalTags += $t
            }
        }
        
        # 4. Modifiers
        if ($originalTags -contains "incomplete") { $finalTags += "incomplete" }
        if ($originalTags -contains "original-insight") { $finalTags += "original-insight" }

        # 5. AI Generated
        $finalTags += "cli"

        # Compare
        $isDifferent = $false
        if ($originalTags.Count -ne $finalTags.Count) {
            $isDifferent = $true
        } else {
            for ($i = 0; $i -lt $originalTags.Count; $i++) {
                if ($originalTags[$i] -ne $finalTags[$i]) {
                    $isDifferent = $true; break
                }
            }
        }

        if ($isDifferent) {
            $auditReport += [PSCustomObject]@{
                File = $file.Name
                Original = ($originalTags -join ", ")
                Fixed = ($finalTags -join ", ")
                Removed = ($removedTags -join ", ")
                Normalized = ($normalizedTags -join ", ")
            }

            # Apply Fix
            $newTagsYaml = "tags:`n" + ($finalTags | ForEach-Object { "  - $_" } | Out-String)
            $newTagsYaml = $newTagsYaml.TrimEnd()
            
            if ($tagsMatch) {
                $newYaml = $yaml.Replace($tagsMatch.TrimEnd(), $newTagsYaml)
                $newContent = $content.Replace($yaml, $newYaml)
                Set-Content -Path $file.FullName -Value $newContent -NoNewline
                $updatedCount++
            }
        }
    }
}

$auditReport | Export-Csv -Path "E:\De Anima\_tmp\audit_results.csv" -NoTypeInformation
Write-Host "Audit Complete. Total files updated: $updatedCount"
$auditReport | Format-Table -Property File, Removed, Normalized -AutoSize
