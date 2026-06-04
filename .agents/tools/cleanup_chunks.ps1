<#
.SYNOPSIS
    Deletes all chunk files, manifest, and pipeline state files for a given topic
    slug from _tmp/. Called by Weaver after a note is saved to the vault.
.PARAMETER Slug
    The topic slug (e.g. "rafa-al-yadayn")
.PARAMETER TmpDir
    Path to the temp directory. Defaults to "E:\De Anima\_tmp"
.EXAMPLE
    powershell -File cleanup_chunks.ps1 -Slug "rafa-al-yadayn"
    Output: DELETED: 10 chunk files, 1 manifest, 1 state file
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [string]$TmpDir = ""
)
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }


if (-not (Test-Path $TmpDir)) {
    Write-Output "TMP_DIR_NOT_FOUND: $TmpDir - nothing to clean"
    exit 0
}

$pattern = "${Slug}_chunk_*.md"
$files = Get-ChildItem -Path $TmpDir -Filter $pattern -File -ErrorAction SilentlyContinue

$deleted = 0
$failed = @()

foreach ($file in $files) {
    try {
        Remove-Item $file.FullName -Force
        $deleted++
    } catch {
        $failed += $file.Name
    }
}

# Also remove manifest and pipeline state files created by the new tools
$sidecarFiles = @(
    (Join-Path $TmpDir "${Slug}_manifest.json"),
    (Join-Path $TmpDir "${Slug}_pipeline_state.json")
)
$sidecarDeleted = 0
foreach ($sc in $sidecarFiles) {
    if (Test-Path $sc) {
        try { Remove-Item $sc -Force; $sidecarDeleted++ } catch {}
    }
}

if ($failed.Count -gt 0) {
    Write-Output "PARTIAL: Deleted $deleted chunk(s), $sidecarDeleted sidecar(s). Failed $($failed.Count): $($failed -join ', ')"
} else {
    Write-Output "DELETED: $deleted chunk file(s), $sidecarDeleted sidecar file(s) (manifest + state)"
}

