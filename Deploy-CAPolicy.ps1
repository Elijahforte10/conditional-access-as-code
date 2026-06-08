<#
.SYNOPSIS
    Deploy an Entra ID Conditional Access policy from a JSON file.

.DESCRIPTION
    Creates a new Conditional Access policy from a JSON template.
    Defaults to report-only (enabledForReportingButNotEnforced) so the policy
    is NEVER enforced until you explicitly pass -State enabled.

    Always review sign-in logs for 24-48 h in report-only mode before enabling.

.PARAMETER PolicyFile
    Path to the JSON file describing the policy (see .\baseline\ for examples).

.PARAMETER State
    Policy state to deploy with.
    Allowed: disabled | enabledForReportingButNotEnforced | enabled
    Default: enabledForReportingButNotEnforced  (SAFE default — never enforces)

.EXAMPLE
    .\Deploy-CAPolicy.ps1 -PolicyFile .\baseline\block-legacy-auth.json
    .\Deploy-CAPolicy.ps1 -PolicyFile .\baseline\require-mfa-for-admins.json -State enabled -WhatIf

.NOTES
    Required Graph scope: Policy.ReadWrite.ConditionalAccess
    Requires: Microsoft.Graph PowerShell module
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$PolicyFile,

    [ValidateSet("disabled", "enabledForReportingButNotEnforced", "enabled")]
    [string]$State = "enabledForReportingButNotEnforced"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess" -NoWelcome

$json   = Get-Content -Raw -Encoding UTF8 -Path $PolicyFile
$policy = $json | ConvertFrom-Json

# Override state with the parameter (never silently enforce what the file says)
$policy.State = $State

$displayName = $policy.displayName
if (-not $displayName) { throw "Policy JSON must contain a 'displayName' field." }

if ($PSCmdlet.ShouldProcess($displayName, "Create Conditional Access policy ($State)")) {
    $body = $policy | ConvertTo-Json -Depth 20

    $created = Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" `
        -Body $body `
        -ContentType "application/json"

    Write-Host "Created policy '$displayName'" -ForegroundColor Green
    Write-Host "  ID:    $($created.id)"
    Write-Host "  State: $($created.state)"

    if ($State -eq "enabledForReportingButNotEnforced") {
        Write-Host "`n[REPORT-ONLY] Monitor sign-in logs before enabling enforcement." -ForegroundColor Yellow
    }
}
