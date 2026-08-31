#Requires -Version 5.1
<#
.SYNOPSIS
Converts the lab's demo GPOs into eight department-wide user policies.
.DESCRIPTION
Run elevated on DC01. Applies to ALL users in the corresponding department OU.
Renames owned demo GPOs rather than deleting them. Backs up existing policies.
Removes only exact, empty, script-owned Demo OUs. No users or groups are deleted,
moved, or created. Passwords, Default Domain Policy, and workstation GPOs are unchanged.
Use -WhatIf for read-only preflight. Do not run the old demo provisioner afterward.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$server='DC01.local.domain'
$domainName='local.domain'
$domainDN='DC=local,DC=domain'
$baseDN="OU=NETLAB,$domainDN"
$legacyMarker='IT-Infrastructure-Lab Demo v1'
$policyMarker='IT-Infrastructure-Lab Department Policies v1'

function Find-DepartmentOU {
    param([string]$DN)
    try {
        Get-ADOrganizationalUnit -Identity $DN -Properties Description,CanonicalName,gPLink,ProtectedFromAccidentalDeletion -Server $server
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] { return $null }
}

try {
    $principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run Windows PowerShell as administrator on DC01.' }
    Import-Module ActiveDirectory
    Import-Module GroupPolicy
    $domain=Get-ADDomain -Identity $domainName -Server $server
    if ($domain.DistinguishedName -ne $domainDN -or $domain.NetBIOSName -ne 'NETLAB') { throw 'Unexpected domain. This command is only for NETLAB / local.domain.' }
    if ((Get-ADDomainController -Identity $server -Server $server).IsReadOnly) { throw 'A writable DC is required.' }
    $departments=@(
        @{Key='Finance';Parent="OU=Finance,OU=Users,$baseDN";Restricted=$true}
        @{Key='HR';Parent="OU=HR,OU=Users,$baseDN";Restricted=$true}
        @{Key='IT-Admins';Parent="OU=Admins,OU=IT,OU=Users,$baseDN";Restricted=$false}
        @{Key='IT-Designers';Parent="OU=Designers,OU=IT,OU=Users,$baseDN";Restricted=$false}
        @{Key='IT-Developers';Parent="OU=Developers,OU=IT,OU=Users,$baseDN";Restricted=$false}
        @{Key='IT-QA';Parent="OU=QA,OU=IT,OU=Users,$baseDN";Restricted=$false}
        @{Key='Sales';Parent="OU=Sales,OU=Users,$baseDN";Restricted=$true}
        @{Key='Security';Parent="OU=Security,OU=Users,$baseDN";Restricted=$true}
    )
    $allGpos=@(Get-GPO -All -Domain $domainName -Server $server)
    $plan=@()
    $cleanup=@()
    foreach ($department in $departments) {
        $parent=Find-DepartmentOU $department.Parent
        if ($null -eq $parent) { throw "Missing department OU: $($department.Parent)" }
        $legacyName="GPO-DEMO-$($department.Key)-User"
        $newName="GPO-Dept-$($department.Key)-User"
        $old=@($allGpos | Where-Object DisplayName -EQ $legacyName)
        $current=@($allGpos | Where-Object DisplayName -EQ $newName)
        if ($old.Count -gt 1 -or $current.Count -gt 1 -or ($old.Count -and $current.Count)) { throw "Conflicting policies for $($department.Key). Nothing will be deleted or merged." }
        $candidate=$null
        if ($old.Count) { $candidate=$old[0] }
        if ($current.Count) { $candidate=$current[0] }
        $legacyDN="OU=Demo,$($department.Parent)"
        $legacyOU=Find-DepartmentOU $legacyDN
        if ($null -ne $legacyOU) {
            if ($legacyOU.Description -ne $legacyMarker) { throw "Unowned Demo OU: $legacyDN" }
            if (@(Get-ADObject -Filter * -SearchBase $legacyDN -SearchScope OneLevel -Server $server).Count) { throw "Demo OU is not empty: $legacyDN. Move its contents first; no objects have been deleted." }
            $links=@((Get-GPInheritance -Target $legacyDN -Domain $domainName -Server $server).GpoLinks | Where-Object { $null -ne $_ })
            foreach ($link in $links) {
                if ($null -eq $candidate -or $link.GpoId -ne $candidate.Id) { throw "Unrelated GPO link in $legacyDN. Review it before removal." }
            }
            $cleanup += $legacyOU
        }
        $id=$null
        if ($null -ne $candidate) {
            if (@($legacyMarker,$policyMarker) -notcontains $candidate.Description) { throw "Unowned GPO: $($candidate.DisplayName)" }
            if ($null -ne $candidate.WmiFilter) { throw "Unexpected WMI filter on $($candidate.DisplayName). Review it before widening scope." }
            # Reject links outside this department and its old, empty Demo OU.
            [xml]$report=Get-GPOReport -Guid $candidate.Id -Domain $domainName -Server $server -ReportType Xml
            $allowedPaths=@($parent.CanonicalName.TrimEnd('/'),($parent.CanonicalName.TrimEnd('/')+'/Demo'))
            foreach ($som in $report.SelectNodes('//*[local-name()="LinksTo"]/*[local-name()="SOMPath"]')) {
                if ($allowedPaths -notcontains $som.InnerText.TrimEnd('/')) { throw "GPO has a link outside its department: $($candidate.DisplayName) -> $($som.InnerText)" }
            }
            $id=$candidate.Id
        }
        $plan += [pscustomobject]@{Department=$department.Key;TargetOU=$department.Parent;LegacyOU=$legacyDN;GPO=$newName;ExistingId=$id;SettingsBlocked=$department.Restricted}
    }
    $legacyGroupsOU=Find-DepartmentOU "OU=Demo,OU=Groups,$baseDN"
    if ($null -ne $legacyGroupsOU) {
        if ($legacyGroupsOU.Description -ne $legacyMarker) { throw 'Unowned Groups/Demo OU.' }
        if (@(Get-ADObject -Filter * -SearchBase $legacyGroupsOU.DistinguishedName -SearchScope OneLevel -Server $server).Count) { throw 'Groups/Demo is not empty. Move the groups to NETLAB/Groups first.' }
        if ((@($legacyGroupsOU.gPLink) -join '').Trim().Length -gt 0) { throw 'Groups/Demo still has GPO links.' }
        $cleanup += $legacyGroupsOU
    }

    $plan | Select-Object Department,GPO,SettingsBlocked | Format-Table -AutoSize
    Write-Host 'These user GPOs will apply to ALL users in their department OUs, including existing accounts.'
    Write-Host 'All: 900-second protected screen saver. Finance/HR/Sales/Security: block Settings and Control Panel. IT: allow them.'
    if (-not $PSCmdlet.ShouldProcess($domainName,'Back up and convert eight GPOs to department-wide policies; remove empty owned Demo OUs')) { return }

    $reportDirectory=Join-Path ([Environment]::GetFolderPath('MyDocuments')) ('NETLAB-DepartmentPolicies-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $reportDirectory | Out-Null
    $plan | Export-Csv -LiteralPath (Join-Path $reportDirectory 'plan.csv') -NoTypeInformation -Encoding UTF8
    $cleanup | Select-Object DistinguishedName,Description,CanonicalName,gPLink,ProtectedFromAccidentalDeletion | Export-Clixml -LiteralPath (Join-Path $reportDirectory 'legacy-ous.xml')
    # Finish ALL existing-GPO backups before the first directory/policy change.
    foreach ($entry in $plan) {
        if ($null -ne $entry.ExistingId) {
            Backup-GPO -Guid $entry.ExistingId -Domain $domainName -Server $server -Path $reportDirectory | Out-Null
            Get-GPOReport -Guid $entry.ExistingId -Domain $domainName -Server $server -ReportType Xml -Path (Join-Path $reportDirectory ($entry.GPO+'-before.xml'))
        }
    }
    $authenticatedUsers=([Security.Principal.SecurityIdentifier]'S-1-5-11').Translate([Security.Principal.NTAccount]).Value
    foreach ($entry in $plan) {
        if ($null -eq $entry.ExistingId) {
            $gpo=New-GPO -Name $entry.GPO -Comment $policyMarker -Domain $domainName -Server $server
        } else {
            $gpo=Get-GPO -Guid $entry.ExistingId -Domain $domainName -Server $server
            if (@($legacyMarker,$policyMarker) -notcontains $gpo.Description) { throw "GPO ownership changed: $($gpo.DisplayName)" }
            if ($gpo.DisplayName -ne $entry.GPO) {
                Rename-GPO -Guid $gpo.Id -TargetName $entry.GPO -Domain $domainName -Server $server | Out-Null
            }
            # Description is AD metadata; no policy commands or SYSVOL content are replaced here.
            Set-ADObject -Identity "CN={$($gpo.Id)},CN=Policies,CN=System,$domainDN" -Replace @{description=$policyMarker} -Server $server
        }
        $desktopKey='HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
        foreach ($setting in @(
            @{Name='ScreenSaveActive';Value='1'},
            @{Name='ScreenSaverIsSecure';Value='1'},
            @{Name='ScreenSaveTimeOut';Value='900'},
            @{Name='SCRNSAVE.EXE';Value='scrnsave.scr'}
        )) {
            Set-GPRegistryValue -Guid $gpo.Id -Domain $domainName -Server $server -Key $desktopKey -ValueName $setting.Name -Type String -Value $setting.Value | Out-Null
        }
        $blockedValue=0
        if ($entry.SettingsBlocked) { $blockedValue=1 }
        Set-GPRegistryValue -Guid $gpo.Id -Domain $domainName -Server $server -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ValueName NoControlPanel -Type DWord -Value $blockedValue | Out-Null

        # OU placement now defines applicability; computer accounts retain read access.
        Set-GPPermission -Guid $gpo.Id -DomainName $domainName -Server $server -TargetName $authenticatedUsers -TargetType Group -PermissionLevel GpoApply -Replace | Out-Null
        $legacyGroupName="GG-DEMO-$($entry.Department)"
        $legacyGroups=@(Get-ADGroup -Filter "SamAccountName -eq '$legacyGroupName'" -Server $server)
        if ($legacyGroups.Count -gt 1) { throw "Ambiguous legacy group: $legacyGroupName" }
        if ($legacyGroups.Count -eq 1) {
            $legacySid=$legacyGroups[0].SID.Value
            $permissions=@(Get-GPPermission -Guid $gpo.Id -All -DomainName $domainName -Server $server)
            if ($permissions | Where-Object { $_.Trustee.Sid.Value -eq $legacySid }) {
                Set-GPPermission -Guid $gpo.Id -DomainName $domainName -Server $server -TargetName $legacyGroupName -TargetType Group -PermissionLevel None -Replace | Out-Null
            }
        }
        $permissions=@(Get-GPPermission -Guid $gpo.Id -All -DomainName $domainName -Server $server)
        $authPermission=@($permissions | Where-Object { $_.Trustee.Sid.Value -eq 'S-1-5-11' -and $_.Permission -eq 'GpoApply' })
        if ($authPermission.Count -ne 1 -or @($permissions | Where-Object { $_.Permission -eq 'GpoCustom' }).Count) { throw "Review nonstandard permissions on $($entry.GPO)." }

        $links=@((Get-GPInheritance -Target $entry.TargetOU -Domain $domainName -Server $server).GpoLinks)
        if ($links | Where-Object { $_.GpoId -eq $gpo.Id }) {
            Set-GPLink -Guid $gpo.Id -Target $entry.TargetOU -Domain $domainName -Server $server -LinkEnabled Yes -Enforced No | Out-Null
        } else {
            New-GPLink -Guid $gpo.Id -Target $entry.TargetOU -Domain $domainName -Server $server -LinkEnabled Yes -Enforced No | Out-Null
        }
        if ($null -ne (Find-DepartmentOU $entry.LegacyOU)) {
            $oldLinks=@((Get-GPInheritance -Target $entry.LegacyOU -Domain $domainName -Server $server).GpoLinks)
            if ($oldLinks | Where-Object { $_.GpoId -eq $gpo.Id }) {
                Remove-GPLink -Guid $gpo.Id -Target $entry.LegacyOU -Domain $domainName -Server $server -Confirm:$false
            }
        }
        Get-GPOReport -Guid $gpo.Id -Domain $domainName -Server $server -ReportType Html -Path (Join-Path $reportDirectory ($entry.GPO+'-after.html'))
    }
    foreach ($candidate in $cleanup) {
        $ou=Find-DepartmentOU $candidate.DistinguishedName
        if ($null -eq $ou) { continue }
        if ($ou.ObjectGUID -ne $candidate.ObjectGUID -or $ou.Description -ne $legacyMarker) { throw 'OU identity changed; cleanup stopped.' }
        $children=@(Get-ADObject -Filter * -SearchBase $ou.DistinguishedName -SearchScope OneLevel -Server $server)
        if ($children.Count -or (@($ou.gPLink) -join '').Trim().Length) { Write-Warning "Preserved non-empty or linked OU: $($ou.DistinguishedName)"; continue }
        $protection=$ou.ProtectedFromAccidentalDeletion
        Set-ADOrganizationalUnit -Identity $ou.ObjectGUID -ProtectedFromAccidentalDeletion $false -Server $server
        try {
            Remove-ADOrganizationalUnit -Identity $ou.ObjectGUID -Server $server -Confirm:$false
            Write-Host "Removed empty OU: $($ou.DistinguishedName)"
        } catch {
            Set-ADOrganizationalUnit -Identity $ou.ObjectGUID -ProtectedFromAccidentalDeletion $protection -Server $server -ErrorAction SilentlyContinue
            throw
        }
    }
    Write-Host "Completed. GPO backups and reports: $reportDirectory" -ForegroundColor Green
    Write-Host 'Refresh GPMC and ADUC. On the workstation, sign in as a department user and run: gpupdate /force; gpresult /r /scope:user'
    Write-Host 'GG-DEMO groups and existing accounts are preserved; the groups are no longer required to apply these GPOs.'
    Write-Host 'Do not run the old New-NetLabDemo provisioner again: it describes the previous policy layout.'
} catch {
    Write-Warning 'Stopped. Earlier successful changes remain. Read the error before retrying; there is no automatic rollback.'
    throw
}
