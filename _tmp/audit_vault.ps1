$vault = "E:\De Anima"
$mdFiles = Get-ChildItem -Path $vault -Recurse -Filter "*.md" -File | Where-Object {
    $_.FullName -notmatch "\\_tmp\\" -and
    $_.FullName -notmatch "\\\.agents\\" -and
    $_.FullName -notmatch "\\\.gemini\\" -and
    $_.FullName -notmatch "\\paintings_source\\"
}

# Build index of all notes (basename without extension)
$noteNames = @{}
foreach ($f in $mdFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $noteNames[$baseName] = $f.FullName
}

$orphanLinks = @()
$inDegree = @{}
$outDegree = @{}
foreach ($name in $noteNames.Keys) {
    $inDegree[$name] = 0
    $outDegree[$name] = 0
}

# Adjacency check
foreach ($f in $mdFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $links = [regex]::Matches($content, '\[\[([^\]\|]+)(?:\|[^\]]+)?\]\]')
    $uniqueTargets = $links | ForEach-Object { $_.Groups[1].Value.Trim() } | Sort-Object -Unique
    
    foreach ($target in $uniqueTargets) {
        if ($target -match '^http') { continue }
        if ($target -match '\.png$|\.jpg$') { continue }
        
        $outDegree[$baseName]++
        
        if ($noteNames.ContainsKey($target)) {
            $inDegree[$target]++
        } else {
            $orphanLinks += [PSCustomObject]@{
                Source = $f.FullName.Replace($vault, '')
                Target = $target
            }
        }
    }
}

$islandNotes = @()
foreach ($name in $noteNames.Keys) {
    if ($name -match 'Map of Contents' -or $name -match 'GEMINI' -or $name -match 'Chain Of Thoughts') { continue }
    if ($inDegree[$name] -eq 0 -and $outDegree[$name] -lt 2) {
        $islandNotes += $name
    }
}

$mocDesyncs = @()
$domains = @('Art', 'History', 'Islam', 'Literature', 'Reason', 'Science')
foreach ($d in $domains) {
    $mocPath = Join-Path $vault "$d\_$d - Map of Contents.md"
    if (-not (Test-Path $mocPath)) {
        if ($d -eq 'Reason') { $mocPath = Join-Path $vault "Reason\_Reason - Map of Contents.md" }
        # The structure is `_Domain - Map of Contents.md` or similar? Let's check the files directly
    }
    # Let's find the actual MOC file for the domain
    $mocFile = $mdFiles | Where-Object { $_.FullName -match "\\$d\\" -and $_.Name -match 'Map of Contents' } | Select-Object -First 1
    if (-not $mocFile) { continue }
    
    $mocContent = Get-Content $mocFile.FullName -Raw
    $domainNotes = $mdFiles | Where-Object { $_.FullName -match "\\$d\\" -and $_.Name -notmatch 'Map of Contents' }
    
    foreach ($n in $domainNotes) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($n.Name)
        if ($mocContent -notmatch "\[\[$([regex]::Escape($baseName))") {
            $mocDesyncs += [PSCustomObject]@{ Domain = $d; Note = $baseName }
        }
    }
}

Write-Output "=== ORPHAN LINKS ==="
foreach ($o in $orphanLinks) { Write-Output "$($o.Source) -> $($o.Target)" }
Write-Output "=== ISLAND NOTES ==="
foreach ($i in $islandNotes) { Write-Output $i }
Write-Output "=== MOC DESYNCS ==="
foreach ($m in $mocDesyncs) { Write-Output "$($m.Domain) -> $($m.Note)" }
