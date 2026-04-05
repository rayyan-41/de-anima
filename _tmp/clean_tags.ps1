$vaultPath = "E:\De Anima"
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | Where-Object { $_.FullName -notmatch "\\_tmp\\" -and $_.FullName -notmatch "\\\.trash\\" -and $_.FullName -notmatch "\\\.obsidian\\" -and $_.Name -notmatch "Map of Contents" }

$fluffTags = @(
    "analysis", "records", "timeline", "documentation", "retrospective", "worldview", 
    "insights", "research", "systems", "theory", "data", "concepts", "development", 
    "reasoning", "argument", "perspective", "thought-experiment", "reflection", 
    "chainofthoughts", "evolution", "tooling", "concept", "historical-analysis",
    "philosophical-analysis", "architecture"
)

$updatedCount = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($null -eq $content) { continue }
    
    if ($content -match "(?s)^---\r?\n(.*?)\r?\n---") {
        $yaml = $matches[1]
        
        $domain = ""
        if ($yaml -match "(?m)^domain:\s*(.+)") { $domain = $matches[1].Trim().Trim('"').Trim("'") }
        
        $category = ""
        if ($yaml -match "(?m)^category:\s*(.+)") { $category = $matches[1].Trim().Trim('"').Trim("'") }
        
        $tags = @()
        
        $tagsMatch = ""
        
        if ($yaml -match "(?m)^(tags:\s*\r?\n(?:\s+- .*\r?\n?)+)") {
            $tagsMatch = $matches[1]
            $tagLines = $tagsMatch -split "\r?\n"
            foreach ($line in $tagLines) {
                if ($line -match "^\s+- (.+)") {
                    $tags += $matches[1].Trim().Trim("'").Trim('"')
                }
            }
        } elseif ($yaml -match "(?m)^(tags:\s*\[.*?\])") {
            $tagsMatch = $matches[1]
            if ($tagsMatch -match "\[(.*)\]") {
                $tagList = $matches[1] -split ","
                foreach ($t in $tagList) {
                    $val = $t.Trim().Trim("'").Trim('"')
                    if ($val) { $tags += $val }
                }
            }
        }
        
        if ($tags.Count -eq 0 -and $domain -eq "") { continue }

        $cleanedTags = @()
        foreach ($t in $tags) {
            $t = $t.ToLower()
            if ($t.StartsWith("#")) { $t = $t.Substring(1) }
            
            if ($t.StartsWith("footnote")) { continue }
            if ($t.Length -gt 40) { continue }
            if ($t -match "---") { continue }
            if ($fluffTags -contains $t) { continue }
            if ($t -eq "ai-generated") { continue }
            if ($t -eq $domain) { continue }
            if ($t -eq $category) { continue }
            if ($t -eq "moc" -or $t -eq "sub-moc") { $cleanedTags += $t; continue }
            
            if (-not [string]::IsNullOrWhiteSpace($t) -and $cleanedTags -notcontains $t) {
                $cleanedTags += $t
            }
        }
        
        $finalTags = @()
        if ($domain) { $finalTags += $domain }
        if ($category) { $finalTags += $category }
        
        foreach ($t in $cleanedTags) {
            if ($finalTags -notcontains $t) {
                $finalTags += $t
            }
        }
        
        $finalTags += "ai-generated"
        
        $newTagsYaml = "tags:`n" + ($finalTags | ForEach-Object { "  - $_" } | Out-String)
        $newTagsYaml = $newTagsYaml.TrimEnd()
        
        if ($tagsMatch) {
            $newYaml = $yaml.Replace($tagsMatch.TrimEnd(), $newTagsYaml)
            $content = $content.Replace($yaml, $newYaml)
            Set-Content -Path $file.FullName -Value $content -NoNewline
            $updatedCount++
        }
    }
}
Write-Host "Total files updated: $updatedCount"
