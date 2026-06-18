$files = Get-ChildItem -Path "C:\Users\Pc\.gemini\config\plugins\de_anima\agents" -Recurse -Include *.md,*.yaml,*.json
foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match 'list_directory') {
        $content = $content -replace 'list_directory', 'list_dir'
        Set-Content -Path $f.FullName -Value $content -NoNewline
        Write-Host "Updated $($f.Name) in global config"
    }
}
