# MikroTik configuration exports

Sanitized text exports from the lab's MikroTik CHR instances, running RouterOS **7.21.5**.

| File | Device role | Export timestamp (device local time) |
|---|---|---|
| [R1-config.rsc](R1-config.rsc) | VLAN gateways, routing, IPv4 firewall, DHCP/relay, NAT | 2026-08-31 15:26:56 |
| [SW1-config.rsc](SW1-config.rsc) | VLAN-aware bridge, trunk/access ports, management interface | 2026-08-31 13:41:44 |

## Publication changes

Only the device-specific `system id` header line was removed from each source export. RouterOS commands, rule order, disabled flags, interface names, addresses, and export timestamps are preserved. Line endings are normalized for repository storage.

The exports were reviewed for passwords, keys, tokens, and device identifiers. Lab addressing and device names are intentionally retained so that the configuration can be understood alongside the [network plan](../../docs/architecture/network-plan.md).

## R1 configuration highlights

- Six VLAN interfaces on TRUNK-SW1: VLAN10, VLAN20, VLAN30, VLAN40, VLAN50, and VLAN60.
- DHCP pools for GUESTS, IOT, and CCTV; VLAN30 DHCP relay to DC01 at `10.10.20.10`.
- Established/related/untracked accept and invalid drop rules in both input and forward, followed by explicit access rules and default deny.
- Port-specific CLIENTS → DC01 rules and TCP445 access to FS01.
- The broad `FORWARD clients to DC01` and `FORWARD DC01 to clients` rules are both **disabled** and retained in the export.
- PRIVATE-NETS isolation for GUESTS/IOT/CCTV; CCTV DNS/NTP exceptions followed by a WAN drop before the general lab internet allow rule.
- WAN masquerade and SSH/WinBox address restrictions to `10.10.10.0/24`.

## SW1 configuration highlights

- BR-SW1 with VLAN filtering enabled.
- Tagged trunk to R1 and six access ports with PVIDs 10, 20, 30, 40, 50, and 60.
- Bridge/CPU tagged membership in management VLAN10.
- Management address `10.10.10.3/24` and default route through `10.10.10.1`.
- SSH/WinBox address restrictions to the management subnet.

## Using these files

These are exports of the configured lab, not idempotent deployment scripts. Importing into an already configured router can create duplicates, produce errors, or interrupt access. They are not binary backups or a substitute for a full recovery procedure.

For a separate reproduction lab:

1. Use dedicated CHR instances and check compatibility with RouterOS 7.21.5.
2. Provide two Ethernet adapters for R1 and seven for SW1, mapped to the roles in the network plan.
3. Review interface names, VLAN assignments, IP addresses, and upstream connectivity before applying commands.
4. Keep access to the VM console and a recoverable copy of the starting configuration. Enabling VLAN filtering or management restrictions can interrupt a remote session.
5. Configure the external dependencies separately: DC01 domain/DNS/DHCP services, FS01, the domain client, and Zabbix.
6. Validate DHCP, domain access, SMB, management restrictions, and CCTV egress using the [network validation record](../../docs/network-validation.md).

A text export does not include VM adapter mapping, installed software, live DHCP leases, connection tracking state, or user credentials. The configuration controls the lab network; it should not be imported into a production network as-is.
