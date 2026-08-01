<#
.SYNOPSIS
    Writes or updates a pipeline state file in _tmp/ after each stage completes.
    Enables crash recovery — an interrupted pipeline can resume from the last completed stage.

.PARAMETER Slug
    The topic slug (e.g. "ottoman-empire").

.PARAMETER Stage
    The pipeline stage that just completed or started.
    Valid values: preflight, yolo, weaver, tagger, formatter, linker

.PARAMETER Status
    The status of the stage.
    Valid values: running, complete, failed

.PARAMETER Note
    Optional. A short note to record (e.g. "3 of 8 chunks written", "word count short by 400").

.PARAMETER TmpDir
    Path to the temp directory. Defaults to "_tmp"

.EXAMPLE
    powershell -File update_pipeline_state.ps1 -Slug "ottoman-empire" -Stage weaver -Status complete
    Output: PIPELINE_STATE: [ottoman-empire] weaver → complete

.EXAMPLE
    powershell -File update_pipeline_state.ps1 -Slug "ottoman-empire" -Stage yolo -Status failed -Note "chunk_05 missing after retry"
    Output: PIPELINE_STATE: [ottoman-empire] yolo → failed | chunk_05 missing after retry

.NOTES
    State file is written to: _tmp/[slug]_pipeline_state.json
    On session resume, read this file to determine the last completed stage and skip ahead.
    Weaver cleans up state file during cleanup_chunks call.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

    [Parameter(Mandatory=$true)]
    [ValidateSet("preflight", "yolo", "weaver", "tagger", "formatter", "linker")]
    [string]$Stage,

    [Parameter(Mandatory=$true)]
    [ValidateSet("running", "complete", "failed")]
    [string]$Status,

    [string]$Note = "",

    [string]$TmpDir = ""
)
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }


if (-not (Test-Path $TmpDir)) {
    New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null
}

$statePath = Join-Path $TmpDir "${Slug}_pipeline_state.json"

# Load existing state or create fresh
if (Test-Path $statePath) {
    $state = Get-Content $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
    # ConvertFrom-Json gives a PSCustomObject; convert stages to hashtable for mutation
    $stagesHash = @{}
    $state.stages.PSObject.Properties | ForEach-Object { $stagesHash[$_.Name] = $_.Value }
} else {
    $state = [PSCustomObject]@{
        slug         = $Slug
        created      = (Get-Date -Format "o")
        stages       = [PSCustomObject]@{}
        last_updated = ""
    }
    $stagesHash = @{}
}

# Update the specific stage
$stagesHash[$Stage] = [PSCustomObject]@{
    status    = $Status
    timestamp = (Get-Date -Format "o")
    note      = $Note
}

# Rebuild state object
$state = [PSCustomObject]@{
    slug         = $Slug
    created      = if ($state.created) { $state.created } else { (Get-Date -Format "o") }
    stages       = [PSCustomObject]$stagesHash
    last_updated = (Get-Date -Format "o")
}

$state | ConvertTo-Json -Depth 5 | Set-Content -Path $statePath -Encoding UTF8

$noteStr = if ($Note -ne "") { " | $Note" } else { "" }
Write-Output "PIPELINE_STATE: [$Slug] $Stage → $Status$noteStr"

