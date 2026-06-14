param(
    [switch]$VerboseOutput
)

$VaultRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$domains = @("Art", "History", "Islam", "Literature", "Reason", "Science")

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "VAULT-WIDE STANDARDIZATION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

foreach ($domain in $domains) {
    if (Test-Path "$VaultRoot\$domain") {
        Write-Host "`n>>> Starting domain: $domain" -ForegroundColor Yellow
        # Call the parameterized run_standardize.ps1 script
        powershell -File "$PSScriptRoot\run_standardize.ps1" -domain $domain
    } else {
        Write-Host "`n>>> Skipping domain: $domain (Not found)" -ForegroundColor DarkGray
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "VAULT-WIDE STANDARDIZATION COMPLETE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
