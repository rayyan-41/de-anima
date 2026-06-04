<#
.SYNOPSIS
    Counts and validates inline citations against the References section of a note.
    Used by the orchestrator as the citation integrity gate in NotebookLM mode.

.DESCRIPTION
    Scans the note body for [N] style inline citations, extracts unique citation
    numbers, then reads the ## References section and verifies every cited number
    has a matching entry. Also checks minimum citation density thresholds based
    on the note's word count.

    Replaces the previous LLM-based citation counting (L-5 fix), which was
    unreliable for notes exceeding 4,000 words.

.PARAMETER FilePath
    Absolute path to the assembled note to audit.

.PARAMETER WordCount
    Optional. If provided, enables threshold checking against Haytham's
    citation density table. Pass the output of word_count.ps1 here.

.EXAMPLE
    powershell -File count_citations.ps1 -FilePath "E:\De Anima\Science\CS\AI\Transformers.md"
    Output:
    INLINE_CITATIONS: 28
    REFERENCE_ENTRIES: 28
    CITATION_INTEGRITY: PASS

.EXAMPLE
    powershell -File count_citations.ps1 -FilePath "E:\De Anima\Science\CS\AI\Transformers.md" -WordCount 4500
    Output:
    INLINE_CITATIONS: 8
    REFERENCE_ENTRIES: 8
    DENSITY_THRESHOLD: FAIL â€” 4500 words requires >=25 citations, found 8
    CITATION_INTEGRITY: FAIL
    MISSING_REFS: none
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,

    [int]$WordCount = 0
)
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }


if (-not (Test-Path $FilePath)) {
    Write-Error "FILE_NOT_FOUND: $FilePath"
    exit 1
}

$content = Get-Content $FilePath -Raw -Encoding UTF8

# â”€â”€ Extract inline citations: all [N] patterns in the note body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Exclude the References section itself to avoid double-counting entry numbers.
$bodyOnly = $content
if ($content -match '(?s)(## References\s*\n.+?)(\n## |\Z)') {
    $refsBlock = $matches[1]
    $bodyOnly  = $content.Replace($refsBlock, '')
}

$inlineMatches         = [regex]::Matches($bodyOnly, '\[(\d+)\]')
$uniqueInlineNumbers   = $inlineMatches |
    ForEach-Object { [int]$_.Groups[1].Value } |
    Sort-Object -Unique

# â”€â”€ Extract reference entries from the ## References section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$refSection = ''
if ($content -match '(?s)## References\s*\n(.+?)(\n## |\Z)') {
    $refSection = $matches[1]
}

$refEntries    = [regex]::Matches($refSection, '(?m)^\[(\d+)\]')
$refNumbers    = $refEntries |
    ForEach-Object { [int]$_.Groups[1].Value } |
    Sort-Object -Unique

# â”€â”€ Identify citation numbers in body that have no matching reference entry â”€â”€â”€
$missingRefs = $uniqueInlineNumbers | Where-Object { $refNumbers -notcontains $_ }

# â”€â”€ Density threshold check (Haytham's citation density table) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$densityResult = ''
if ($WordCount -gt 0) {
    $required = 0
    if     ($WordCount -ge 4000)                     { $required = 25 }
    elseif ($WordCount -ge 2000 -and $WordCount -lt 4000) { $required = 15 }
    elseif ($WordCount -ge 1000 -and $WordCount -lt 2000) { $required = 8  }

    if ($required -gt 0 -and $uniqueInlineNumbers.Count -lt $required) {
        $densityResult = "DENSITY_THRESHOLD: FAIL â€” $WordCount words requires >=$required citations, found $($uniqueInlineNumbers.Count)"
    } else {
        $densityResult = "DENSITY_THRESHOLD: PASS ($($uniqueInlineNumbers.Count)/$required)"
    }
}

# â”€â”€ Output â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Write-Output "INLINE_CITATIONS: $($uniqueInlineNumbers.Count)"
Write-Output "REFERENCE_ENTRIES: $($refNumbers.Count)"

if ($densityResult -ne '') {
    Write-Output $densityResult
}

if ($missingRefs.Count -gt 0) {
    Write-Output "MISSING_REFS: $($missingRefs -join ', ')"
    Write-Output "CITATION_INTEGRITY: FAIL"
    exit 1
} elseif ($densityResult -match 'FAIL') {
    Write-Output "CITATION_INTEGRITY: FAIL"
    exit 1
} else {
    Write-Output "CITATION_INTEGRITY: PASS"
}

