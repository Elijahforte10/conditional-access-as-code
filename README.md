# Conditional Access as Code

Manage Entra ID Conditional Access (CA) policies the way mature orgs do:
exported to JSON, version-controlled, reviewed, and deployed **report-only
first**. This turns CA from click-ops into auditable infrastructure.

## Why this matters

Most tenants configure CA by hand in the portal — no history, no review, no
rollback. Treating policies as code gives you a git audit trail of every
change and a safe deployment path (report-only → validate in sign-in logs →
enforce).

## Workflow

```powershell
# 1) Back up everything you currently have
.\Export-CAPolicies.ps1            # -> .\export\*.json (commit these)

# 2) Edit / author a policy as JSON (see .\baseline\)
#    Replace the break-glass exclusion placeholder with your emergency account.

# 3) Deploy in REPORT-ONLY (default) and watch sign-in logs for impact
.\Deploy-CAPolicy.ps1 -PolicyFile .\baseline\require-mfa-for-admins.json

# 4) Once validated, re-deploy enforced
.\Deploy-CAPolicy.ps1 -PolicyFile .\baseline\block-legacy-auth.json -State enabled
```

## Files

| File | Purpose |
|---|---|
| `Export-CAPolicies.ps1` | Read-only backup of all CA policies to JSON |
| `Deploy-CAPolicy.ps1` | Create a policy from JSON (report-only by default) |
| `baseline/require-mfa-for-admins.json` | Sample: MFA for high-risk admin roles |
| `baseline/block-legacy-auth.json` | Sample: block basic/legacy auth |

## Safety rules baked in

- **`Deploy-CAPolicy.ps1` defaults to `enabledForReportingButNotEnforced`** — a
  new policy never enforces (and never locks anyone out) until you opt in.
- Every baseline policy **excludes a break-glass account placeholder**. Fill it
  in with a real emergency-access account before you ever enable enforcement.
- Deploy uses `ShouldProcess`, so you get a confirmation prompt.

## Required Graph scopes

| Script | Scope |
|---|---|
| Export | `Policy.Read.All` |
| Deploy | `Policy.ReadWrite.ConditionalAccess` |

> The role GUIDs in the baseline JSON are the well-known built-in Entra role
> template IDs (Global Admin, Privileged Role Admin, Security Admin, User
> Admin). Verify them against your tenant before enforcing.
