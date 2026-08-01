<#
.SYNOPSIS
    Validates a word count from word_count.ps1 output against a template minimum.
    Outputs WORDCOUNT_PASS or WORDCOUNT_FAIL with deficit information.

.PARAMETER FilePath
    Absolute path to the assembled note to validate.

.PARAMETER MinWords
    The minimum word count required for this note's template.

.PARAMETER Template
    Optional. Template name for display in output (e.g. "fiqh", "empire", "cs").

.EXAMPLE
    powershell -File validate_wordcount.ps1 -FilePath "Islam\Fiqh\Tawassul.md" -MinWords 8000 -Template fiqh
    Output:
    WORDCOUNT: 9247
    MINIMUM:   8000 (fiqh)
    WORDCOUNT_PASS

.EXAMPLE
    powershell -File validate_wordcount.ps1 -FilePath "History\Ottoman Empire.md" -MinWords 1500
    Output:
    WORDCOUNT: 1102
    MINIMUM:   1500
    WORDCOUNT_FAIL: 398 words short. Return note to agent for expansion.

.NOTES
    This script delegates actual counting to word_count.ps1 to avoid frontmatter
    inclusion bugs. Do NOT duplicate the counting logic here.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,

    [Parameter(Mandatory=$true)]
    [int]$MinWords,

    [string]$Template = "",

    [string]$ToolsDir = ""
)
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }


if (-not (Test-Path $FilePath)) {
    Write-Error "WORDCOUNT_ERROR: file not found at $FilePath"
    exit 1
}

$wordCountScript = Join-Path $ToolsDir "word_count.ps1"
if (-not (Test-Path $wordCountScript)) {
    Write-Error "WORDCOUNT_ERROR: word_count.ps1 not found at $wordCountScript"
    exit 1
}

# Delegate to the canonical word_count.ps1 to avoid frontmatter bugs
$rawCount = & powershell -File $wordCountScript -FilePath $FilePath 2>&1
$wordCount = [int]($rawCount | Select-Object -Last 1)

$templateLabel = if ($Template -ne "") { " ($Template)" } else { "" }

Write-Output "WORDCOUNT: $wordCount"
Write-Output "MINIMUM:   $MinWords$templateLabel"

if ($wordCount -ge $MinWords) {
    Write-Output "WORDCOUNT_PASS"
    exit 0
} else {
    $deficit = $MinWords - $wordCount
    Write-Output "WORDCOUNT_FAIL: $deficit words short. Return note to agent for expansion of thinnest sections."
    exit 1
}

