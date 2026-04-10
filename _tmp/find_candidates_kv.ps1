$core_tags = @("kv-cache", "ai-hardware", "llm-inference", "memory-bandwidth", "attention-mechanism")
$target_category = "Science/AI"
$excluded_files = @("KV Caches and AI Hardware Architecture.md")

$files = Get-ChildItem -Path "E:\De Anima" -Recurse -Filter "*.md" | Where-Object { 
    $_.FullName -notmatch "\\_tmp\\" -and 
    $_.FullName -notmatch "\\.obsidian\\" -and 
    $_.FullName -notmatch "\\paintings_source\\" -and 
    $_.FullName -notmatch "\\.trash\\" -and
    $excluded_files -notcontains $_.Name
}

$results = @()
foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullName -TotalCount 30 2>$null
    if ($null -eq $content) { continue }
    $inYaml = $false
    $cat = ""
    $tags = @()
    foreach ($line in $content) {
        if ($line -eq "---") {
            if ($inYaml) { break }
            $inYaml = $true
            continue
        }
        if ($inYaml) {
            if ($line -match "^category:\s*(.+)$") {
                $cat = $matches[1].Trim(" '`"")
            }
            if ($line -match "^tags:\s*\[(.*)\]$") {
                $tags = $matches[1] -split "," | ForEach-Object { $_.Trim(" '`"") }
            }
        }
    }
    
    $shared_core = 0
    foreach ($t in $tags) {
        if ($core_tags -contains $t) {
            $shared_core++
        }
    }
    
    $is_match = $false
    if ($shared_core -ge 2) {
        $is_match = $true
    } elseif ($shared_core -ge 1 -and $cat -eq $target_category) {
        $is_match = $true
    }
    
    if ($is_match) {
        $results += [PSCustomObject]@{
            Name = $file.BaseName
            Path = $file.FullName
            SharedCore = $shared_core
            Category = $cat
        }
    }
}
$results | ConvertTo-Json
