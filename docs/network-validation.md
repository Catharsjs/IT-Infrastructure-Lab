# Network validation

Lab review date: **2026-08-31**.

This record summarizes manual lab tests. Command-output results and user-confirmed tests are distinguished below. Export inspection checks configuration state; it does not replace a live network test.

## Manual test results

| Scenario | Source and target | Result | Evidence type |
|---|---|---|---|
| DHCP address assignment | Test client in VLAN50 and VLAN60 | Passed | Command output/screenshots reviewed during the lab |
| Domain DNS discovery | VLAN30 client → DC01 `10.10.20.10` | SRV lookup returned `dc01.local.domain`, LDAP port 389, and `10.10.20.10` | Command output |
| Domain controller discovery | USER-WS-001 → `local.domain` | `nltest /dsgetdc:local.domain /force` completed successfully | Command output after firewall changes |
| Group Policy refresh | USER-WS-001 → DC01 | Computer and user policy updates completed successfully | `gpupdate /force` output after firewall changes |
| SMB access | CLIENTS → FS01 `10.10.20.20` | Group-based SMB access tested successfully | User-confirmed hands-on test |
| WinBox access restriction | `10.10.30.50` → R1 `10.10.10.1` and SW1 `10.10.10.3`, TCP8291 | Both connection tests returned False | PowerShell output |
| CCTV management restriction | `10.10.60.200` → R1 and SW1, TCP8291 | Both connection tests returned False | PowerShell output |
| CCTV DNS/NTP and HTTPS | VLAN60 → WAN | DNS/NTP worked; HTTPS connection failed under the CCTV rules | Results reviewed during the lab |
| Gateway monitoring | Zabbix → six R1 VLAN gateway IPs | All six reported Up, 0% packet loss, and sub-millisecond latency in the reviewed snapshot | Zabbix dashboard screenshot |

Ping and TCP results are separate measurements. R1 answered ICMP from CLIENTS/CCTV while TCP8291 connections failed. Gateway ICMP results describe reachability from Zabbix, not the health of every endpoint in a VLAN.

## Configuration checks on the published exports

| Check | Result |
|---|---|
| RouterOS version | Both exports identify version 7.21.5 |
| Broad CLIENTS ↔ DC01 rules | Both have `disabled=yes` in the final R1 export |
| Domain service rules | Port-specific UDP and TCP rules precede the disabled broad rules |
| SMB rule | CLIENTS → `10.10.20.20`, TCP445, accept |
| CCTV rule order | PRIVATE-NETS drop, DNS/NTP exceptions, CCTV WAN drop, then general lab WAN accept |
| Default deny | Final input and forward rules drop remaining traffic |
| VLAN membership | R1 VLAN IDs match the six SW1 trunk/access VLAN entries |
| Management services | R1 and SW1 restrict SSH/WinBox source addresses to `10.10.10.0/24` |

## Commands used in the lab

Run these on the Windows test client in the relevant VLAN. Each command is on one line.

Domain DNS lookup:

```powershell
nslookup -type=SRV _ldap._tcp.dc._msdcs.local.domain 10.10.20.10
```

Domain controller discovery:

```powershell
nltest /dsgetdc:local.domain /force
```

Group Policy refresh (reapplies assigned policies):

```powershell
gpupdate /force
```

SMB port reachability, with FS01 running (this checks TCP connectivity, not share permissions):

```powershell
Test-NetConnection 10.10.20.20 -Port 445
```

R1 management port check:

```powershell
Test-NetConnection 10.10.10.1 -Port 8291
```

SW1 management port check:

```powershell
Test-NetConnection 10.10.10.3 -Port 8291
```

For group-based SMB validation, sign in with the relevant domain account and test access to the intended share; a successful TCP445 check alone does not validate permissions.
