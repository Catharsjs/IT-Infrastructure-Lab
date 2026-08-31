# 2026-08-31 15:26:56 by RouterOS 7.21.5
#
/interface ethernet
set [ find default-name=ether2 ] disable-running-check=no name=TRUNK-SW1
set [ find default-name=ether1 ] disable-running-check=no name=WAN
/interface vlan
add interface=TRUNK-SW1 name=VLAN10-MGMT vlan-id=10
add interface=TRUNK-SW1 name=VLAN20-SERVERS vlan-id=20
add interface=TRUNK-SW1 name=VLAN30-CLIENTS vlan-id=30
add interface=TRUNK-SW1 name=VLAN40-GUEST vlan-id=40
add interface=TRUNK-SW1 name=VLAN50-IOT vlan-id=50
add interface=TRUNK-SW1 name=VLAN60-CCTV vlan-id=60
/ip pool
add name=POOL-GUEST ranges=10.10.40.100-10.10.40.200
add name=POOL-IOT ranges=10.10.50.100-10.10.50.200
add name=POOL-CCTV ranges=10.10.60.100-10.10.60.200
/ip dhcp-server
add address-pool=POOL-GUEST interface=VLAN40-GUEST lease-time=4h name=\
    DHCP-GUEST
add address-pool=POOL-IOT interface=VLAN50-IOT lease-time=4h name=DHCP-IOT
add address-pool=POOL-CCTV interface=VLAN60-CCTV lease-time=4h name=DHCP-CCTV
/ip address
add address=10.10.10.1/24 interface=VLAN10-MGMT network=10.10.10.0
add address=10.10.20.1/24 interface=VLAN20-SERVERS network=10.10.20.0
add address=10.10.30.1/24 interface=VLAN30-CLIENTS network=10.10.30.0
add address=10.10.40.1/24 interface=VLAN40-GUEST network=10.10.40.0
add address=10.10.50.1/24 interface=VLAN50-IOT network=10.10.50.0
add address=10.10.60.1/24 interface=VLAN60-CCTV network=10.10.60.0
/ip dhcp-client
add interface=WAN
/ip dhcp-relay
add dhcp-server=10.10.20.10 disabled=no interface=VLAN30-CLIENTS \
    local-address=10.10.30.1 name=RELAY-CLIENTS
/ip dhcp-server network
add address=10.10.40.0/24 dns-server=1.1.1.1,9.9.9.9 gateway=10.10.40.1
add address=10.10.50.0/24 dns-server=1.1.1.1,9.9.9.9 gateway=10.10.50.1
add address=10.10.60.0/24 dns-server=1.1.1.1,9.9.9.9 gateway=10.10.60.1
/ip firewall address-list
add address=10.0.0.0/8 list=PRIVATE-NETS
add address=172.16.0.0/12 list=PRIVATE-NETS
add address=192.168.0.0/16 list=PRIVATE-NETS
/ip firewall filter
add action=accept chain=input comment="INPUT established" connection-state=\
    established,related,untracked
add action=drop chain=input comment="INPUT invalid" connection-state=invalid
add action=accept chain=input comment="INPUT management" src-address=\
    10.10.10.0/24
add action=accept chain=input comment="INPUT ICMP" protocol=icmp
add action=accept chain=input comment="INPUT WAN DHCP" dst-port=68 \
    in-interface=WAN protocol=udp src-port=67
add action=accept chain=input comment="INPUT client DHCP relay" dst-port=\
    67,68 in-interface=VLAN30-CLIENTS protocol=udp
add action=accept chain=input comment="INPUT guest DHCP" dst-port=67,68 \
    in-interface=VLAN40-GUEST protocol=udp
add action=accept chain=input comment="INPUT DHCP server replies" dst-port=\
    67,68 in-interface=VLAN20-SERVERS protocol=udp src-address=10.10.20.10 \
    src-port=67
add action=accept chain=input comment="INPUT IOT DHCP" dst-port=67,68 \
    in-interface=VLAN50-IOT protocol=udp
add action=accept chain=input comment="INPUT CCTV DHCP" dst-port=67,68 \
    in-interface=VLAN60-CCTV protocol=udp
add action=drop chain=input comment="INPUT default deny"
add action=accept chain=forward comment="FORWARD established" \
    connection-state=established,related,untracked
add action=drop chain=forward comment="FORWARD invalid" connection-state=\
    invalid
add action=accept chain=forward comment="ALLOW CLIENTS TO DC01 DNS UDP" \
    dst-address=10.10.20.10 dst-port=53 protocol=udp src-address=\
    10.10.30.0/24
add action=accept chain=forward comment="FORWARD management" src-address=\
    10.10.10.0/24
add action=accept chain=forward comment="ALLOW CLIENTS TO DC01 AD UDP" \
    dst-address=10.10.20.10 dst-port=53,88,123,389,464 protocol=udp \
    src-address=10.10.30.0/24
add action=accept chain=forward comment="ALLOW CLIENTS TO DC01 AD TCP" \
    dst-address=10.10.20.10 dst-port=\
    53,88,135,389,445,464,636,3268,3269,9389,49152-65535 protocol=tcp \
    src-address=10.10.30.0/24
add action=accept chain=forward comment="FORWARD clients to DC01" disabled=\
    yes dst-address=10.10.20.10 src-address=10.10.30.0/24
add action=accept chain=forward comment="FORWARD DC01 to clients" disabled=\
    yes dst-address=10.10.30.0/24 src-address=10.10.20.10
add action=accept chain=forward comment="FORWARD clients to FS01 SMB" \
    dst-address=10.10.20.20 dst-port=445 protocol=tcp src-address=\
    10.10.30.0/24
add action=accept chain=forward comment="ALLOW DC01 NTP" dst-port=123 \
    out-interface=WAN protocol=udp src-address=10.10.20.10
add action=accept chain=forward comment="ALLOW SERVERS TO INTERNET" \
    out-interface=WAN src-address=10.10.20.0/24
add action=drop chain=forward comment="FORWARD isolate guests" \
    dst-address-list=PRIVATE-NETS src-address=10.10.40.0/24
add action=drop chain=forward comment="FORWARD isolate IOT" dst-address-list=\
    PRIVATE-NETS src-address=10.10.50.0/24
add action=drop chain=forward comment="FORWARD isolate CCTV" \
    dst-address-list=PRIVATE-NETS src-address=10.10.60.0/24
add action=accept chain=forward comment="ALLOW CCTV DNS NTP" dst-port=53,123 \
    out-interface=WAN protocol=udp src-address=10.10.60.0/24
add action=accept chain=forward comment="ALLOW CCTV DNS TCP" dst-port=53 \
    out-interface=WAN protocol=tcp src-address=10.10.60.0/24
add action=drop chain=forward comment="DROP CCTV INTERNET" out-interface=WAN \
    src-address=10.10.60.0/24
add action=accept chain=forward comment="FORWARD lab to Internet" \
    out-interface=WAN src-address=10.10.0.0/16
add action=drop chain=forward comment="FORWARD default deny"
/ip firewall nat
add action=masquerade chain=srcnat comment="LAB VLANs to Internet" \
    out-interface=WAN
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
set name=MikroTik-R1
/system ntp client
set enabled=yes
/system ntp client servers
add address=time.cloudflare.com
add address=time.google.com
