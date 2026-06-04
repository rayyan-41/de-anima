function Add-FrontmatterUUID {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw
    
    # Check if frontmatter exists
    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $frontmatter = $matches[1]
        if ($frontmatter -notmatch 'id:\s*[a-f0-9\-]+') {
            $newId = [guid]::NewGuid().ToString()
            $newContent = $content -replace '(?s)^---\r?\n', "---\
id: $newId
"
            Set-Content $FilePath -Value $newContent
        }
    } else {
        # Create minimal frontmatter
        $newId = [guid]::NewGuid().ToString()
        $newContent = "---\
id: $newId
---\

$content"
        Set-Content $FilePath -Value $newContent
    }
}
