# Department policy automation

[`Set-NetLabDepartmentPolicies.ps1`](Set-NetLabDepartmentPolicies.ps1) configures the eight department user policies documented in [Active Directory and Group Policy](../../docs/active-directory.md).

## Requirements

- The existing `NETLAB` / `local.domain` lab and writable `DC01.local.domain`.
- Windows PowerShell 5.1 or later, elevated with appropriate AD and GPO permissions.
- ActiveDirectory and GroupPolicy modules installed.
- Existing department OUs from the documented NETLAB hierarchy.

This is not a domain installer or a fictional-account provisioner. It creates no users, groups, or department OUs. Review the fixed domain and OU targets before execution; do not use unchanged in another environment.

## Run

Review the script first. From its directory in elevated Windows PowerShell on DC01:

```powershell
# Read-only preflight and proposed scope.
.\Set-NetLabDepartmentPolicies.ps1 -WhatIf

# Apply the baseline to all users in the eight department OUs.
.\Set-NetLabDepartmentPolicies.ps1
```

Use the organization's approved script execution policy. No password, token, or credential is embedded in this file.

## Changes and safeguards

- Configures eight separate `GPO-Dept-...-User` policies and links each to its department OU.
- Gives Authenticated Users Read and Apply permissions, removing the prior `GG-DEMO-*` filter where present.
- Renames existing script-owned legacy policies without changing their GUIDs, or creates missing department policies.
- Stops for conflicting old/new names, unrelated ownership, WMI filters, out-of-department links, or nonempty legacy Demo OUs.
- Backs up existing target GPOs and records before/after reports under the executing account's Documents directory.
- Removes only exact script-owned empty legacy Demo OUs. It trims whitespace-only `gPLink` values, checks contents again, and never uses recursive deletion.
- Preserves users, passwords, group objects, default policies, and the workstation AutoLock policy.

Rerunning reapplies the documented baseline, including resetting values edited manually afterward. The script is not transactional: completed changes remain if a later operation fails. Review its output and saved reports before retrying. GPO backups and OU metadata are not a full AD backup or automatic undo.

## Validation

The conversion was run in the lab, and the resulting GPO inventory was reviewed in GPMC. Local checks cover PowerShell syntax and in-memory scenarios for read-only preflight, first creation, migration, repeated execution, whitespace-only legacy links, and rejection of nonempty OUs or external GPO links. These checks do not replace effective-policy testing in a signed-in client session.

## Microsoft references

- [Rename-GPO](https://learn.microsoft.com/en-us/powershell/module/grouppolicy/rename-gpo?view=windowsserver2025-ps)
- [Set-GPPermission](https://learn.microsoft.com/en-us/powershell/module/grouppolicy/set-gppermission?view=windowsserver2025-ps)
- [Remove-ADOrganizationalUnit](https://learn.microsoft.com/en-us/powershell/module/activedirectory/remove-adorganizationalunit?view=windowsserver2025-ps)
