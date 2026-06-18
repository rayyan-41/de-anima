$files = Get-ChildItem 'E:\De Anima\.agents\tools\*.ps1'
foreach ($f in $files) {
    try {
        $null = [scriptblock]::Create((Get-Content $f.FullName -Raw))
        Write-Host "$($f.Name): PASS"
    } catch {
        Write-Host "$($f.Name): FAIL - $($_.Exception.Message)"
    }
}
