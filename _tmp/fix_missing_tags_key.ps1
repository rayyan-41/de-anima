$vaultPath = "E:\De Anima"
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | Where-Object { $_.FullName -notmatch "\\_tmp\\" -and $_.FullName -notmatch "\\\.trash\\" -and $_.FullName -notmatch "\\\.obsidian\\" }

$fixedCount = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($null -eq $content) { continue }
    
    if ($content -match "(?s)^---\r?\n(.*?)\r?\n---") {
        $yaml = $matches[1]
        
        if ($yaml -notmatch "(?m)^tags:" -and $yaml -match "(?m)^  - ") {
            # Find the first index of "  - " and insert "tags:`n" before it
            $firstDashIndex = $yaml.IndexOf("  - ")
            if ($firstDashIndex -ge 0) {
                $newYaml = $yaml.Insert($firstDashIndex, "tags:`n")
                $content = $content.Replace($yaml, $newYaml)
                Set-Content -Path $file.FullName -Value $content -NoNewline
                $fixedCount++
            }
        }
    }
}

Write-Host "Fixed tags: missing key in $fixedCount files."
