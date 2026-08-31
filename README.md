# IT Infrastructure Lab

A home lab for systems administration: a segmented network, a Windows domain, shared file storage, and Windows/Linux monitoring.

**Stack:** VMware Workstation · MikroTik RouterOS CHR · Windows Server / Active Directory · Windows 11 · Ubuntu · Zabbix.

## Project goals

Practice building and maintaining a small IT infrastructure: configure networking, deploy domain services, control access, and validate the results. The project also develops troubleshooting skills and documents the reasoning behind configuration choices.

This is a **learning project**, not a production deployment. Successful individual tests do not constitute a comprehensive security audit, high-availability validation, or disaster recovery certification.

## Implemented features

| Area | Implementation |
|---|---|
| Networking | MikroTik CHR R1 and SW1, six VLANs, trunk/access ports, routing, and NAT |
| Access control | IPv4 firewall, management access restrictions from the client network, and Guest/IoT/CCTV isolation rules |
| DHCP | Guest/IoT/CCTV scopes on R1; relay from the client VLAN to Windows DHCP |
| Domain services | AD DS, internal DNS, department OUs and groups, 16 fictional employee accounts, and a domain-joined Windows client |
| Group Policy | Eight independent department user GPOs, a dedicated workstation auto-lock GPO, policy backup, and settings import test |
| File server | SMB with group-based access; access testing completed successfully |
| Monitoring | Zabbix on Ubuntu, Windows/Linux metrics, CPU/RAM/disk dashboards, and ICMP checks of VLAN gateways |

Component versions, configuration details, and test results: [current lab state](docs/current-state.md).

Published configuration files: [MikroTik R1 and SW1 exports](configs/mikrotik/README.md). Manual test results: [network validation](docs/network-validation.md).

Domain organization, account inventory, policy scope, and screenshots: [Active Directory and Group Policy](docs/active-directory.md).

Dashboards, host inventory, and measurement scope: [Zabbix monitoring](docs/monitoring.md).

## Architecture

R1 connects the upstream VMware NAT network to the lab VLANs. SW1 carries tagged traffic over a trunk and provides access ports for individual segments. Servers reside in VLAN20; the domain client resides in VLAN30.

| VLAN | Role | Subnet |
|---:|---|---|
| 10 | Management | `10.10.10.0/24` |
| 20 | Servers | `10.10.20.0/24` |
| 30 | Clients | `10.10.30.0/24` |
| 40 | Guests | `10.10.40.0/24` |
| 50 | IoT | `10.10.50.0/24` |
| 60 | CCTV | `10.10.60.0/24` |

The addresses in this documentation belong to the lab. See the [network plan](docs/architecture/network-plan.md) for interfaces, DHCP, and access rules.

## Validated scenarios

- Client DHCP address assignment in VLAN50 and VLAN60.
- Domain DNS SRV lookup and domain controller discovery.
- Group Policy refresh after disabling broad CLIENTS ↔ DC01 allow rules.
- AutoLock GPO application and actual workstation locking after 15 minutes of inactivity.
- Blocked TCP8291 connections from VLAN30 to R1/SW1.
- Successful SMB access with group-based permissions.
- Working DNS/NTP from VLAN60 and blocked HTTPS connections under the CCTV rules.
- Windows/Linux metrics and gateway ICMP results displayed in Zabbix.

These results were obtained through manual lab configuration and testing.

## Platform

Physical host: Ryzen 5 2600, 16 GB DDR4, VMware Workstation 26.0.0 (build 25388281). Guest operating systems: Windows Server 2025 Standard Evaluation, Windows 11 Pro, and Ubuntu 26.04 LTS. R1 and SW1 are virtual MikroTik CHR instances.

Network monitoring measures availability, packet loss, and latency to the VLAN gateway IP addresses on R1. It monitors the gateways, not every device in each segment.

## Publication stages

1. **Published:** overview, inventory, and architecture.
2. **Published:** sanitized MikroTik configurations and network test results.
3. **Published:** Active Directory structure, department GPOs, configuration screenshots, and workstation policy test results.
4. **Published:** Zabbix dashboards, host inventory, metrics, and monitoring scope.
5. Consolidated test results, troubleshooting, and design limitations.

## Repository structure

```text
README.md
LICENSE
.gitignore
configs/
  mikrotik/
    README.md
    R1-config.rsc
    SW1-config.rsc
docs/
  current-state.md
  network-validation.md
  active-directory.md
  monitoring.md
  architecture/
    network-plan.md
evidence/
  active-directory/
    README.md
    aduc-departments.png
    gpmc-policy-inventory.png
  monitoring/
    README.md
    hardware-overview.png
    network-health.png
    host-inventory.png
```

## Safe publication

Passwords, keys, tokens, raw Security logs, VM disks, binary backups, and real remote-access details are excluded. Screenshots and exports are reviewed manually before inclusion. `.gitignore` reduces accidental file inclusion but does not replace content review.

Do not import lab configurations into an existing network without reviewing addressing, interfaces, software versions, and a rollback plan.

## License

[MIT](LICENSE).
