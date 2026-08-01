<#
.SYNOPSIS
    Verifies all expected chunk files exist in _tmp/ and returns their content concatenated.
.PARAMETER Slug
    The topic slug (e.g. "rafa-al-yadayn")
.PARAMETER ExpectedCount
    How many chunks to expect (e.g. 10)
.PARAMETER TmpDir
    Path to the temp directory. Defaults to "_tmp"
.PARAMETER Mode
    "verify" — only checks existence, returns missing list
    "read" — verifies AND returns concatenated content with chunk markers
.EXAMPLE
    powershell -File verify_chunks.ps1 -Slug "rafa-al-yadayn" -ExpectedCount 10 -Mode verify
    Output: ALL_PRESENT: 10/10
.EXAMPLE
    powershell -File verify_chunks.ps1 -Slug "rafa-al-yadayn" -ExpectedCount 10 -Mode read
    Output: [concatenated chunk content with markers]
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$true)]
    [int]$ExpectedCount,

    [string]$TmpDir = "",

    [ValidateSet("verify", "read")]
    [string]$Mode = "verify"
)
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }


if (-not (Test-Path $TmpDir)) {
    Write-Error "TMP_DIR_NOT_FOUND: $TmpDir"
    exit 1
}

$missing = @()
$present = @()
$content = @()

for ($i = 1; $i -le $ExpectedCount; $i++) {
    $num = $i.ToString("D2")
    $filename = "${Slug}_chunk_${num}.md"
    $filepath = Join-Path $TmpDir $filename

    if (Test-Path $filepath) {
        $present += $filename
        if ($Mode -eq "read") {
            $chunkContent = Get-Content $filepath -Raw -Encoding UTF8
            $content += "<!-- CHUNK $num START -->"
            $content += $chunkContent
            $content += "<!-- CHUNK $num END -->"
            $content += ""
        }
    } else {
        $missing += $filename
    }
}

if ($missing.Count -gt 0) {
    Write-Output "MISSING: $($missing.Count)/$ExpectedCount"
    foreach ($m in $missing) {
        Write-Output "  - $m"
    }
    exit 1
} else {
    if ($Mode -eq "verify") {
        Write-Output "ALL_PRESENT: $($present.Count)/$ExpectedCount"
    } else {
        # Read mode - output concatenated content
        Write-Output ($content -join "`n")
    }
}

