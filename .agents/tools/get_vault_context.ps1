
if (-not $VaultRoot) { $VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path }
if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot "_tmp" }
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }
function Get-VaultRoot {
    $current = $PWD
    while ($current) {
        if (Test-Path (Join-Path $current ".gemini\config.json")) {
            return $current
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) { break }
        $current = $parent
    }
    throw "Vault root not found. Ensure .gemini\config.json exists."
}

function Get-VaultConfig {
    $root = Get-VaultRoot
    $configPath = Join-Path $root ".gemini\config.json"
    return Get-Content $configPath | ConvertFrom-Json
}

