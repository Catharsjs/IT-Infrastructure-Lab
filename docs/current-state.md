# Current lab state

Review date: **2026-08-31**.

This document describes the lab configuration and validation results. Sources include RouterOS exports, screenshots, command output, and hands-on testing.

## Physical platform

| Parameter | Value |
|---|---|
| Purpose | Dedicated home PC for the lab |
| Hypervisor | VMware Workstation 26.0.0, build 25388281 |
| CPU | AMD Ryzen 5 2600 |
| RAM | 16 GB DDR4 |
| GPU | NVIDIA GTX 1060 6 GB |

## Virtual machines

| Host | Role | Lab address | Version / notes |
|---|---|---|---|
| MikroTik-R1 | Router, IPv4 firewall, DHCP/relay, NAT | `10.10.10.1` | CHR, RouterOS 7.21.5 in the reviewed export |
| MikroTik-SW1 | VLAN-aware bridge, trunk/access | `10.10.10.3` | CHR, RouterOS 7.21.5; virtual, not a physical switch |
| DC01 | AD DS, DNS, DHCP | `10.10.20.10` | Windows Server 2025 Standard Evaluation, 24H2, build 26100.33158 |
| FS01 | SMB file server | `10.10.20.20` | Windows Server 2025 Standard Evaluation, 24H2, build 26100.33158 |
| Zabbix server | Windows/Linux and gateway monitoring | `10.10.20.30` | Ubuntu 26.04 LTS with GUI; Zabbix Server 7.0.29 |
| USER-WS-001 | Domain workstation | DHCP in VLAN30; `10.10.30.50` in the latest test | Windows 11 Pro, 25H2, build 26200.8037 |

## Active Directory and Group Policy

- Lab DNS domain: `local.domain`; NetBIOS name: `NETLAB`.
- Domain controller: DC01.
- The NETLAB OU contains Admin-Accounts, Disabled Objects, Groups, Servers, Service Accounts, Users, and Workstations.
- The test user is in `NETLAB/Users/IT/Developers`; the computer is in `NETLAB/Workstations/Developers`.
- The user belongs to departmental/role GG groups and file-permission DL groups.
- Default Domain Policy applies to the computer; its User Configuration is empty. The N/A result in user-scope gpresult was therefore not a policy delivery failure.
- The dedicated `GPO-WS-Developers-AutoLock` is linked to the Developers computer OU. Machine inactivity limit is 900 seconds. Policy application was confirmed with gpresult; actual locking was confirmed manually.
- GPO backups were created on DC01 and copied to the physical host PC. AutoLock settings were imported into the unlinked `TEST-AutoLock-Recovery` GPO, and the value of 900 was verified.

## Networking and file server

VLANs, DHCP, interfaces, and access rules are described in the [network plan](architecture/network-plan.md).

The two broad CLIENTS ↔ DC01 allow rules were disabled during testing. DNS SRV lookup, gpupdate, and nltest /dsgetdc with /force all succeeded after the changes.

SMB access with group-based permissions was tested successfully.

## Monitoring and logs

- Zabbix Agent 2 7.0.30 on DC01: Running, listening on TCP10050; Windows by Zabbix agent template.
- The hardware dashboard displays Windows/Linux CPU, RAM, filesystem usage, and graphs.
- Network Health contains six ICMP hosts for VLAN gateways, a status/loss/latency table, and graphs.
- ICMP checks against addresses on the same R1 do not establish the health of all endpoints and access ports.
- The frontend uses HTTP on port 8080.
- DC01 Security Event Log events 4672 and 5379 were examined: special privileges assigned to a new logon and Credential Manager credentials being read.

## Validation evidence

| Category | Results or configuration |
|---|---|
| Confirmed by command output/screenshots | DHCP in VLAN50/60, VLAN30 source address, DNS SRV lookup, gpupdate, DC discovery, blocked TCP8291 from VLAN30, CCTV DNS/NTP and blocked HTTPS, dashboards |
| Confirmed through hands-on testing | Auto-lock after 15 minutes, GPO backup/import, backup copies outside the VM, successful SMB access |
| Present in configuration | VLAN table, DHCP pools, IPv4 firewall, NAT, SSH/WinBox restrictions, NTP clients |
