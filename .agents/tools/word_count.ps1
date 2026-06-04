<#
.SYNOPSIS
    Counts words in a markdown file, correctly excluding YAML frontmatter.
.PARAMETER FilePath
    Absolute path to the markdown file.
.EXAMPLE
    powershell -File word_count.ps1 -FilePath "E:\De Anima\Islam\Fiqh\Rafa al-Yadayn (Fiqh).md"
    Output: 9247
.NOTES
    Fix (2026-04-12): Replaced naive single-pass heuristic with a proper two-delimiter
    YAML frontmatter parser. The old version skipped only DATE:/TAGS: prefixed lines,
    causing all four YAML property lines (date, status, tags, note) to be counted as
    body content and inflating the word count.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

if (-not (Test-Path $FilePath)) {
    Write-Error "FILE_NOT_FOUND: $FilePath"
    exit 1
}

$lines = Get-Content $FilePath -Encoding UTF8

# ── Correctly strip YAML frontmatter ─────────────────────────────────────────
# Frontmatter is the block delimited by a leading --- and a closing ---.
# All lines between (and including) the delimiters are skipped.
# Lines after the closing --- are body content.

$inFrontmatter   = $false
$frontmatterDone = $false
$bodyLines       = @()

foreach ($line in $lines) {
    $trimmed = $line.Trim()

    if (-not $frontmatterDone) {
        if ($trimmed -eq '---') {
            if (-not $inFrontmatter) {
                $inFrontmatter = $true   # opening delimiter
            } else {
                $inFrontmatter   = $false  # closing delimiter
                $frontmatterDone = $true
            }
            continue
        }
        # Inside the YAML block — skip property lines (date:, status:, tags:, note:, etc.)
        if ($inFrontmatter) { continue }

        # No opening --- found at all (legacy file without frontmatter):
        # fall through and start counting from the first non-empty line.
        if ($trimmed -ne '') { $frontmatterDone = $true }
    }

    $bodyLines += $line
}

$bodyText = $bodyLines -join ' '

# Count words: split on whitespace, filter empty strings
$words     = $bodyText -split '\s+' | Where-Object { $_ -ne '' }
$wordCount = $words.Count

Write-Output $wordCount
