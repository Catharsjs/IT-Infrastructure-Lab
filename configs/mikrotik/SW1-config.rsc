# 2026-08-31 13:41:44 by RouterOS 7.21.5
#
/interface bridge
add name=BR-SW1 vlan-filtering=yes
/interface ethernet
set [ find default-name=ether7 ] disable-running-check=no name=ACCESS-CCTV
set [ find default-name=ether4 ] disable-running-check=no name=ACCESS-CLIENTS
set [ find default-name=ether5 ] disable-running-check=no name=ACCESS-GUEST
set [ find default-name=ether6 ] disable-running-check=no name=ACCESS-IOT
set [ find default-name=ether2 ] disable-running-check=no name=ACCESS-MGMT
set [ find default-name=ether3 ] disable-running-check=no name=ACCESS-SERVERS
set [ find default-name=ether1 ] disable-running-check=no name=TRUNK-R1
/interface vlan
add interface=BR-SW1 name=VLAN10-MGMT vlan-id=10
/interface bridge port
add bridge=BR-SW1 frame-types=admit-only-vlan-tagged interface=TRUNK-R1
add bridge=BR-SW1 frame-types=admit-only-untagged-and-priority-tagged \
    interface=ACCESS-MGMT pvid=10
add bridge=BR-SW1 frame-types=admit-only-untagged-and-priority-tagged \
    interface=ACCESS-SERVERS pvid=20
add bridge=BR-SW1 frame-types=admit-only-untagged-and-priority-tagged \
    interface=ACCESS-CLIENTS pvid=30
add bridge=BR-SW1 frame-types=admit-only-untagged-and-priority-tagged \
    interface=ACCESS-GUEST pvid=40
add bridge=BR-SW1 frame-types=admit-only-untagged-and-priority-tagged \
    interface=ACCESS-IOT pvid=50
add bridge=BR-SW1 frame-types=admit-only-untagged-and-priority-tagged \
    interface=ACCESS-CCTV pvid=60
/interface bridge vlan
add bridge=BR-SW1 tagged=BR-SW1,TRUNK-R1 untagged=ACCESS-MGMT vlan-ids=10
add bridge=BR-SW1 tagged=TRUNK-R1 untagged=ACCESS-SERVERS vlan-ids=20
add bridge=BR-SW1 tagged=TRUNK-R1 untagged=ACCESS-CLIENTS vlan-ids=30
add bridge=BR-SW1 tagged=TRUNK-R1 untagged=ACCESS-GUEST vlan-ids=40
add bridge=BR-SW1 tagged=TRUNK-R1 untagged=ACCESS-IOT vlan-ids=50
add bridge=BR-SW1 tagged=TRUNK-R1 untagged=ACCESS-CCTV vlan-ids=60
/ip address
add address=10.10.10.3/24 interface=VLAN10-MGMT network=10.10.10.0
/ip dhcp-client
add disabled=yes interface=TRUNK-R1
/ip dns
set servers=1.1.1.1,9.9.9.9
/ip route
add comment="Default via R1" dst-address=0.0.0.0/0 gateway=10.10.10.1
/ip service
set ftp disabled=yes
set ssh address=10.10.10.0/24
set telnet disabled=yes
set www disabled=yes
set winbox address=10.10.10.0/24
set api disabled=yes
set api-ssl disabled=yes
/system clock
set time-zone-name=Europe/Kyiv
/system identity
set name=MikroTik-SW1
/system ntp client
set enabled=yes
/system ntp client servers
add address=time.cloudflare.com
