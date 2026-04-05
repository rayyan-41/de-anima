$vaultPath = "E:\De Anima"
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | Where-Object { $_.FullName -notmatch "\\_tmp\\" -and $_.FullName -notmatch "\\\.trash\\" -and $_.FullName -notmatch "\\\.obsidian\\" }

$tocCount = 0
$dateCount = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($null -eq $content) { continue }
    
    $modified = $false
    
    # 1. Remove old DATE: TIME: TAGS: blocks
    # Sometimes it's a block: DATE \n TAGS \n - - -
    $patternBlock = "(?m)^DATE:\s*.*?\r?\n(^TIME:\s*.*?\r?\n)?(^TAGS:\s*.*?\r?\n)?(^- - -\r?\n)?"
    if ($content -match $patternBlock) {
        $content = $content -replace $patternBlock, ""
        $modified = $true
        $dateCount++
    }
    
    # Remove any standalone DATE: / TIME: / TAGS: lines left over
    if ($content -match "(?m)^DATE:\s*.*?\r?\n") {
        $content = $content -replace "(?m)^DATE:\s*.*?\r?\n", ""
        $modified = $true
        $dateCount++
    }
    if ($content -match "(?m)^TIME:\s*.*?\r?\n") {
        $content = $content -replace "(?m)^TIME:\s*.*?\r?\n", ""
        $modified = $true
        $dateCount++
    }
    if ($content -match "(?m)^TAGS:\s*.*?\r?\n(^- - -\r?\n)?") {
        $content = $content -replace "(?m)^TAGS:\s*.*?\r?\n(^- - -\r?\n)?", ""
        $modified = $true
        $dateCount++
    }

    # 2. Check for duplicate TOCs
    # If the file has an abstract or callout TOC, remove the standard heading one
    if ($content -match "(?i)> \[!abstract\] Table of Contents" -or $content -match "(?i)> \[!info\] Table of Contents") {
        $tocPattern = "(?s)## Table of Contents\s*\r?\n(.*?)(?=\r?\n#|\r?\n>)"
        
        # A safer pattern for the generated TOCs which are just bullet lists
        $safeTocPattern = "(?s)## Table of Contents\s*\r?\n(\s*- \[.*?\].*?\r?\n)*\r?\n?"
        
        if ($content -match $safeTocPattern) {
            $content = $content -replace $safeTocPattern, ""
            $modified = $true
            $tocCount++
        }
    }
    
    if ($modified) {
        # fix double blank lines if they were introduced
        $content = $content -replace "\r?\n\r?\n\r?\n", "`n`n"
        Set-Content -Path $file.FullName -Value $content -NoNewline
    }
}

Write-Host "Removed old DATE/TIME/TAGS from $dateCount files."
Write-Host "Removed duplicate TOCs from $tocCount files."