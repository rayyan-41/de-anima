$vaultPath = "E:\De Anima"
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "Map of Contents*.md"

$quotes = @{
    "History" = "> *Those who cannot remember the past are condemned to repeat it.* - George Santayana"
    "Science" = "> *Somewhere, something incredible is waiting to be known.* - Carl Sagan"
    "Art" = "> *The aim of art is to represent not the outward appearance of things, but their inward significance.* - Aristotle"
    "Literature" = "> *That is part of the beauty of all literature. You discover that your longings are universal longings, that you are not lonely and isolated from anyone. You belong.* - F. Scott Fitzgerald"
    "Islam" = "> *Knowledge without action is vanity, and action without knowledge is insanity.* - Al-Ghazali"
    "Reason" = "> *The unexamined life is not worth living.* - Socrates"
}

$updatedCount = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($null -eq $content) { continue }
    
    $domain = ""
    if ($file.FullName -match "\\History\\") { $domain = "History" }
    elseif ($file.FullName -match "\\Science\\") { $domain = "Science" }
    elseif ($file.FullName -match "\\Art\\") { $domain = "Art" }
    elseif ($file.FullName -match "\\Literature\\") { $domain = "Literature" }
    elseif ($file.FullName -match "\\Islam\\") { $domain = "Islam" }
    elseif ($file.FullName -match "\\Reason\\") { $domain = "Reason" }
    
    if ($domain -ne "") {
        $quote = $quotes[$domain]
        
        if ($content -match "(?s)^---\r?\n.*?\r?\n---\r?\n") {
            $content = $content -replace "(?s)^---\r?\n.*?\r?\n---\r?\n", "$quote`n`n"
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "Removed properties and added $domain quote to $($file.Name)"
            $updatedCount++
        } elseif (-not $content.StartsWith("> *")) {
            $content = "$quote`n`n" + $content
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "Added $domain quote to $($file.Name)"
            $updatedCount++
        }
    }
}

Write-Host "Total MOCs updated: $updatedCount"
