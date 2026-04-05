$vaultPath = "E:\De Anima"
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | Where-Object { $_.FullName -notmatch "\\_tmp\\" -and $_.FullName -notmatch "\\\.trash\\" -and $_.FullName -notmatch "\\\.obsidian\\" }
$tags = @{}

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($null -eq $content) { continue }
    
    if ($content -match "(?s)^---\r?\n(.*?)\r?\n---") {
        $yaml = $matches[1]
        
        # Match array format:
        # tags:
        #   - tag1
        #   - tag2
        if ($yaml -match "(?m)^tags:\s*\r?\n((?:\s+- .*\r?\n?)+)") {
            $tagList = $matches[1] -split "\r?\n"
            foreach ($tagLine in $tagList) {
                if ($tagLine -match "^\s+- (.+)") {
                    $tag = $matches[1].Trim().Trim("'").Trim('"')
                    $tags[$tag]++
                }
            }
        } 
        # Match inline format: tags: [tag1, tag2]
        elseif ($yaml -match "(?m)^tags:\s*\[(.*?)\]") {
            $tagList = $matches[1] -split ","
            foreach ($tag in $tagList) {
                $t = $tag.Trim().Trim("'").Trim('"')
                if ($t) { $tags[$t]++ }
            }
        }
    }
}

$tags.GetEnumerator() | Sort-Object Value -Descending | Format-Table Name, Value -AutoSize
