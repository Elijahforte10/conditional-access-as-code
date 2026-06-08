<#
.SYNOPSIS
    Back up all Entra ID Conditional Access policies to JSON files.

.DESCRIPTION
    Reads every CA policy in the tenant via Microsoft Graph and writes each
    one to .\export\<PolicyName>.json.  Read-only — it never modifies anything.

    Intended to be run before/after any change so your git history always
    reflects the real state of the tenant.

.EXAMPLE
    .\Export-CAPolicies.ps1
    .\Export-CAPolicies.ps1 -OutputFolder C:\Backup\CA

.NOTES
    Required Graph scope: Policy.Read.All
    Requires: Microsoft.Graph PowerShell module (Install-Module Microsoft.Graph)
#>
[CmdletBinding()]
param(
    [string]$OutputFolder = ".\export"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Connect with the minimum read scope
Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome

$null = New-Item -ItemType Directory -Force -Path $OutputFolder

Write-Host "Fetching Conditional Access policies..." -ForegroundColor Cyan
$policies = Get-MgIdentityConditionalAccessPolicy -All

if (-not $policies) {
    Write-Warning "No Conditional Access policies found in this tenant."
    return
}

$count = 0
foreach ($policy in $policies) {
    # Sanitise name for filesystem
    $safeName = $policy.DisplayName -replace '[\\/:*?"<>|]', '_'
    $outFile   = Join-Path $OutputFolder "$safeName.json"

    $policy | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 -Path $outFile
    Write-Host "  Exported: $($policy.DisplayName) -> $outFile"
    $count++
}

Write-Host "`nDone. $count polic$(if($count -eq 1){'y'}else{'ies'}) exported to $OutputFolder" -ForegroundColor Green
Write-Host "Commit the .\export folder to capture the current state." -ForegroundColor Yellow
