$files = Get-ChildItem "E:\De Anima\Reason\*.md" -File
foreach ($f in $files) {
    if ($f.Name -match 'Chain Of Thoughts' -or $f.Name -match 'Map of Contents') { continue }
    $count = & "E:\De Anima\.agents\tools\word_count.ps1" -FilePath $f.FullName
    $content = Get-Content $f.FullName -Raw
    $hasTOC = ($content -match '> \[!abstract\] Table of Contents')
    
    if ($count -gt 4000 -and -not $hasTOC) {
        Write-Output "MISSING_TOC: $($f.Name) ($count words)"
    } elseif ($count -le 4000 -and $hasTOC) {
        Write-Output "UNNECESSARY_TOC: $($f.Name) ($count words)"
    } else {
        Write-Output "OK: $($f.Name) ($count words, HasTOC: $hasTOC)"
    }
}
