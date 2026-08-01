<#
.SYNOPSIS
    Inserts or refreshes the Table of Contents callout in a note.

.DESCRIPTION
    Every `cli` note carries a Table of Contents. There is no word-count
    threshold -- the only requirement is that the note actually has content
    headings to list.

    Rules:
      - Lists H2 headings only, in document order.
      - Skips structural footers: Related Notes, References, See Also,
        Table of Contents.
      - Needs at least -MinHeadings (default 2) content headings; a one-entry
        table of contents is noise, so such notes are reported as SKIPPED
        rather than being given an empty callout.
      - Placed immediately after the frontmatter, followed by a `- - -`.
      - Re-running replaces an existing callout, so it is safe to call
        repeatedly as headings change.
      - `manual` notes are left alone unless -Force is given.

.EXAMPLE
    powershell -File generate_toc.ps1 -FilePath "History\Map of Contents - History.md" -WhatIfOnly
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,

    [int]$MinHeadings = 2,

    [switch]$Force,

    [switch]$WhatIfOnly
)

if (-not (Test-Path $FilePath)) {
    Write-Output "TOC_ERROR: file not found - $FilePath"
    exit 1
}

$raw = Get-Content $FilePath -Raw -Encoding UTF8
if ($raw -notmatch '(?s)^---\s*\n(.*?)\n---\s*\n') {
    Write-Output "TOC_SKIPPED: no frontmatter - $([System.IO.Path]::GetFileName($FilePath))"
    exit 0
}
$fm      = $matches[1]
$fmBlock = $matches[0]
$body    = $raw.Substring($fmBlock.Length)

$tags = @()
if ($fm -match '(?m)^tags:\s*\[(.*?)\]\s*$') {
    $tags = @($matches[1] -split ',' | ForEach-Object { $_.Trim().ToLower() })
}
if ($tags -contains 'moc') {
    Write-Output "TOC_SKIPPED: Map of Contents - $([System.IO.Path]::GetFileName($FilePath))"
    exit 0
}
if (-not $Force -and $tags.Count -gt 0 -and $tags[-1] -ne 'cli') {
    Write-Output "TOC_SKIPPED: not a cli note (use -Force to override) - $([System.IO.Path]::GetFileName($FilePath))"
    exit 0
}

# Strip any existing callout so re-runs refresh rather than stack.
$body = [regex]::Replace($body, '(?ms)^>\s*\[!abstract\]\s*Table of Contents\s*\n(?:^>.*\n)*(?:^\s*-\s*-\s*-\s*\n)?', '')
# Strip a legacy "## Table of Contents" section too.
$body = [regex]::Replace($body, '(?ms)^##\s*Table of Contents\s*\n(?:(?!^##\s).*\n)*', '')

$skip = @('related notes', 'references', 'see also', 'table of contents')
$headings = @()
foreach ($m in [regex]::Matches($body, '(?m)^##\s+(.+?)\s*$')) {
    $h = $m.Groups[1].Value.Trim()
    if ($skip -notcontains $h.ToLower()) { $headings += $h }
}

$name = [System.IO.Path]::GetFileName($FilePath)
if ($headings.Count -lt $MinHeadings) {
    Write-Output "TOC_SKIPPED: only $($headings.Count) content heading(s) - $name"
    exit 0
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("> [!abstract] Table of Contents")
foreach ($h in $headings) { [void]$sb.AppendLine("> - [[#$h]]") }
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- - -")
[void]$sb.AppendLine("")

$newContent = $fmBlock + $sb.ToString() + $body.TrimStart("`r", "`n")

if ($WhatIfOnly) {
    Write-Output "TOC_WOULD_WRITE: $($headings.Count) headings - $name"
    exit 0
}

# Markdown in this vault is UTF-8 without a BOM; Set-Content -Encoding UTF8
# would add one, so write the bytes explicitly.
[System.IO.File]::WriteAllText($FilePath, $newContent, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "TOC_WRITTEN: $($headings.Count) headings - $name"
exit 0
