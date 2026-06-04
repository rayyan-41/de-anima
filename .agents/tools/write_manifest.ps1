<#
.SYNOPSIS
    Writes a pre-flight manifest JSON to _tmp/ listing all expected chunk filenames.
    Must be called at the start of YOLO generation before any chunks are written.

.PARAMETER Slug
    The topic slug (e.g. "ottoman-empire"). Must match the slug used for chunk filenames.

.PARAMETER Headings
    Comma-separated list of section headings in order.
    Example: "Overview,Rise to Power,Decline,Legacy"

.PARAMETER TmpDir
    Path to the temp directory. Defaults to "E:\De Anima\_tmp"

.EXAMPLE
    powershell -File write_manifest.ps1 -Slug "ottoman-empire" -Headings "Overview,Rise,Decline,Legacy"
    Output: MANIFEST_WRITTEN: E:\De Anima\_tmp\ottoman-empire_manifest.json (4 chunks expected)
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$true)]
    [string]$Headings,

    [string]$TmpDir = ""
)
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }


if (-not (Test-Path $TmpDir)) {
    New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null
}

$headingList = $Headings -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

if ($headingList.Count -eq 0) {
    Write-Error "MANIFEST_ERROR: No headings provided."
    exit 1
}

$expected = @()
$i = 1
foreach ($heading in $headingList) {
    $expected += [PSCustomObject]@{
        index    = $i.ToString("D2")
        heading  = $heading
        filename = "${Slug}_chunk_$($i.ToString('D2')).md"
        status   = "pending"
    }
    $i++
}

$manifest = [PSCustomObject]@{
    slug           = $Slug
    created        = (Get-Date -Format "o")
    stage          = "pre-flight"
    expected_count = $expected.Count
    expected       = $expected
}

$manifestPath = Join-Path $TmpDir "${Slug}_manifest.json"
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Output "MANIFEST_WRITTEN: $manifestPath ($($expected.Count) chunks expected)"

