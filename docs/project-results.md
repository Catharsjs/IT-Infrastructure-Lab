# Project results and lessons learned

Portfolio review: **2026-08-31**.

This project brings together a segmented virtual network, a Windows domain, group-based file access, and Windows/Linux monitoring. The repository records the configuration, the manual tests performed during the lab, and the reasoning behind several troubleshooting decisions.

## Outcome

- Built a six-VLAN network with MikroTik CHR routing, VLAN-aware switching, DHCP/relay, NAT, and ordered IPv4 access rules.
- Deployed AD DS, DNS, and DHCP on Windows Server, joined a Windows client, and organized department and workstation OUs.
- Populated eight department OUs with 16 fictional users and configured eight independent department user GPOs.
- Applied a separate workstation AutoLock policy and observed locking after 15 minutes.
- Configured and tested group-based SMB access.
- Built Zabbix dashboards for Windows/Linux resource usage and ICMP measurements of six VLAN gateways.
- Practiced configuration export, GPO backup/settings import, and evidence-based troubleshooting.

## Consolidated validation record

The evidence categories below distinguish observed command output, user-confirmed hands-on tests, and configuration inspection. A configured policy is not automatically counted as a passed client test.

| Scenario | Recorded result | Evidence |
|---|---|---|
| Client address assignment in VLAN50 and VLAN60 | Passed | DHCP command output/screenshots reviewed during the lab |
| Domain DNS SRV lookup | Returned DC01 and the LDAP service record | Command output |
| Domain controller discovery | Completed successfully | `nltest` output after firewall changes |
| Group Policy refresh | Both computer and user updates succeeded | `gpupdate` output after firewall changes |
| WinBox restriction from CLIENTS | TCP8291 connections to R1 and SW1 failed as intended | Client-side connection tests |
| WinBox restriction from CCTV | TCP8291 connections to R1 and SW1 failed as intended | Client-side connection tests |
| CCTV internet policy | DNS/NTP worked; HTTPS was blocked | Manual test results reviewed during the lab |
| Group-based SMB access | Passed | Lab owner confirmed successful hands-on access testing |
| Workstation AutoLock | Policy listed as applied; workstation locked after 15 minutes | Computer-scope `gpresult` and lab owner observation |
| GPO backup and settings import | AutoLock settings imported into a recovery-test GPO; value 900 checked | Lab owner confirmed the recovery exercise |
| Department organization | Final OU hierarchy and eight enabled department GPOs recorded | ADUC/GPMC screenshots and provisioning completion |
| Windows/Linux monitoring | CPU, memory, filesystem values, and history displayed | Hardware dashboard screenshot |
| Gateway monitoring | Six Up rows with 0.0% loss and sub-millisecond latest latency values | Network Health screenshot |

Detailed supporting records: [network validation](network-validation.md), [AD and Group Policy](active-directory.md), and [Zabbix monitoring](monitoring.md).

The department GPO inventory documents configured state. It does not claim eight separate user sign-in tests. The Zabbix host snapshot also retains DC01's two-problem counter; resource data collection is not presented as a problem-free health assessment.

## Troubleshooting case studies

### 1. User-scope GPO results showed N/A

**Observation:** the initial user-scope report listed no applied GPOs, while the computer-scope report showed Default Domain Policy.

**Investigation:** GPMC showed no settings in Default Domain Policy's User Configuration. Computer and user scopes were inspected separately.

**Outcome:** the N/A result was consistent with that configuration, rather than evidence of failed domain communication. A dedicated computer AutoLock GPO was applied and tested; independent department user GPOs were configured later.

**Lesson:** interpret an effective-policy report in the context of OU placement and the configured user/computer section.

### 2. Computer-scope gpresult returned Access Denied

**Observation:** requesting computer policy results from the ordinary user console failed.

**Action and result:** the report was run from elevated PowerShell and returned the workstation's applied policies.

**Lesson:** distinguish a diagnostic permission error from a Group Policy delivery error.

### 3. Broad domain-service firewall rules were replaced

**Observation:** the configuration contained broad CLIENTS-to-DC01 and DC01-to-CLIENTS permits alongside more specific service rules.

**Action:** service-specific rules were ordered before default deny, and the two broad rules were disabled. They remain disabled in the published R1 export.

**Result:** DNS SRV lookup, domain controller discovery, and Group Policy refresh succeeded after the change. Management-port and CCTV checks were recorded separately.

**Lesson:** retain evidence of required functionality after narrowing access. A successful ping does not prove that a particular TCP service is reachable, and a failed connection alone does not identify which rule or device blocked it.

### 4. Network widgets were difficult to read

**Observation:** the first status table lacked a VLAN-name column and used bright green across all metric cells. An early latency graph used a scale reaching 100 seconds, compressing sub-millisecond measurements near zero.

**Action:** added the VLAN column, limited green highlighting to status, separated packet loss from latency, and adjusted the latency scale to milliseconds. The final hardware charts use distinct colors and lines without filled areas.

**Result:** the published screenshots identify each target and make the displayed latency variation visible.

**Lesson:** correct data still needs appropriate labels, units, scales, and color choices to be useful.

### 5. Empty Demo OUs survived cleanup

**Observation:** cleanup preserved eight legacy OUs even though the users had already been moved to department OUs.

**Investigation:** a read-only query returned zero child objects and zero direct GPO links for each OU, but the raw `gPLink` attribute contained a space.

**Action and result:** the emptiness check was corrected to trim whitespace. Cleanup checked the exact targets again and used non-recursive deletion. The final ADUC screenshot shows the department layout without Demo child OUs.

**Lesson:** validate actual directory attributes before deleting objects. An unexpected representation of an empty value should not lead to recursive deletion or the removal of policy objects.

## Design boundaries

This is a virtual systems-administration lab, not a production deployment or a comprehensive security assessment.

- The six gateway probes target addresses on one R1. They measure gateway reachability from Zabbix, not every endpoint, access port, or application path.
- The firewall describes IPv4 traffic handled by R1. It does not replace endpoint controls or establish a fully tested source/destination matrix.
- The recovery exercise restores GPO settings into a test object; it is not a full AD, file-server, or monitoring-system disaster recovery test.
- The monitoring frontend shown uses internal HTTP. Dashboard availability and a problem counter do not establish notification delivery or encrypted monitoring transport.

These boundaries define what the evidence supports; they are not additional claims of completed testing.

## Skills demonstrated

| Area | Practical work |
|---|---|
| Networking | VLAN membership, trunk/access ports, routing, DHCP relay, NAT, and firewall rule order |
| Windows administration | AD DS, DNS, domain membership, OU design, users/groups, and GPO scope |
| Access management | Department/role groups, file-permission groups, and SMB access validation |
| Monitoring | Templates, host tags, item values, multi-series charts, ICMP status/loss/latency |
| Troubleshooting | Separate symptoms from causes, inspect configuration, compare scopes, and verify changes |
| Change handling | Export configurations, back up policies, preserve identities, and constrain deletion targets |
| Documentation | Publish reviewed configurations and screenshots while separating configured state from tested behavior |

## Portfolio summary

Built a VMware-based IT infrastructure lab integrating MikroTik CHR networking, Windows Server Active Directory services, group-based SMB access, and Zabbix monitoring. Configured six VLANs, a departmental OU structure with 16 fictional users, eight department user policies, and a tested workstation AutoLock policy. Documented manual network and service checks, a GPO settings recovery exercise, and troubleshooting cases with configuration exports and screenshots.

## Suggested review order

1. [Project overview](../README.md) and [inventory](current-state.md).
2. [Network architecture](architecture/network-plan.md), [RouterOS exports](../configs/mikrotik/README.md), and [network test results](network-validation.md).
3. [Active Directory structure and policies](active-directory.md).
4. [Zabbix dashboards and measurement scope](monitoring.md).
5. This consolidated results and lessons-learned record.

PowerShell scripts are excluded from the current publication. Screenshots and sanitized RouterOS exports are the published implementation artifacts.
