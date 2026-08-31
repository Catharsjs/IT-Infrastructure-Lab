# Мережевий план

Стан на **31.08.2026**. Таблиці відображають прочитані експорти, подальшу ручну зміну порядку правил та результати практики. Це опис конфігурації, не готовий сценарій імпорту.

## Топологія та ролі

Зовнішня VMware NAT-мережа підключена до WAN R1. Інтерфейс TRUNK-SW1 на R1 з'єднаний із TRUNK-R1 на SW1. SW1 розподіляє VLAN через access-порти; R1 має шлюзи всіх шести VLAN та виконує маршрутизацію.

## VLAN, шлюзи та DHCP

| VLAN | Назва | Підмережа | Шлюз R1 | DHCP / DNS |
|---:|---|---|---|---|
| 10 | MGMT | `10.10.10.0/24` | `10.10.10.1` | Статичні адреси R1/SW1 |
| 20 | SERVERS | `10.10.20.0/24` | `10.10.20.1` | Адреси DC01, FS01 і Zabbix наведені нижче |
| 30 | CLIENTS | `10.10.30.0/24` | `10.10.30.1` | DHCP relay до DC01; доменний DNS `10.10.20.10` |
| 40 | GUESTS | `10.10.40.0/24` | `10.10.40.1` | R1: `.100–.200`, 4h; DNS `1.1.1.1,9.9.9.9` |
| 50 | IOT | `10.10.50.0/24` | `10.10.50.1` | R1: `.100–.200`, 4h; DNS `1.1.1.1,9.9.9.9` |
| 60 | CCTV | `10.10.60.0/24` | `10.10.60.1` | R1: `.100–.200`, 4h; DNS `1.1.1.1,9.9.9.9` |

DC01 — `10.10.20.10`, FS01 — `10.10.20.20`, Ubuntu/Zabbix — `10.10.20.30`. Zabbix розміщений у SERVERS, не в окремому VLAN50.

R1 отримує WAN через DHCP. Динамічна WAN-адреса не фіксується текстовим експортом статичної конфігурації.

## Інтерфейси R1

| Початковий NIC | Ім'я | Призначення |
|---|---|---|
| ether1 | WAN | VMware NAT, DHCP client, вихід через masquerade |
| ether2 | TRUNK-SW1 | VLAN-інтерфейси 10,20,30,40,50,60 до SW1 |

## Порти SW1

| Початковий NIC | Ім'я | Режим | VLAN / PVID |
|---|---|---|---|
| ether1 | TRUNK-R1 | Admit only VLAN tagged | Tagged 10,20,30,40,50,60 у bridge VLAN table |
| ether2 | ACCESS-MGMT | Untagged / priority-tagged | PVID10 |
| ether3 | ACCESS-SERVERS | Untagged / priority-tagged | PVID20 |
| ether4 | ACCESS-CLIENTS | Untagged / priority-tagged | PVID30 |
| ether5 | ACCESS-GUEST | Untagged / priority-tagged | PVID40 |
| ether6 | ACCESS-IOT | Untagged / priority-tagged | PVID50 |
| ether7 | ACCESS-CCTV | Untagged / priority-tagged | PVID60 |

BR-SW1 має `vlan-filtering=yes`. Bridge/CPU включений tagged для VLAN10; management VLAN-інтерфейс має адресу `10.10.10.3/24`. Default route SW1 — через `10.10.10.1`.

## Принципи IPv4 Firewall

- `input` перевіряє пакети до самого R1; `forward` — через R1 до іншого вузла; `output` — пакети самого R1.
- Правила перевіряються згори вниз у відповідному ланцюжку; `accept` і `drop` завершують перевірку пакета в ньому.
- В обох input/forward спочатку приймаються `established,related,untracked`, потім відкидається `invalid`.
- `INPUT default deny` та `FORWARD default deny` відкидають залишок; обмежувальних output-правил у перевіреному експорті немає.
- NAT `masquerade` на WAN змінює адресу джерела, але не замінює дозволи Firewall.

## Матриця доступу

Політика нижче описує новий трафік, який не збігся з попереднім правилом. У таблиці наведено налаштовані дії Firewall і результати відповідних ручних тестів.

| Джерело → призначення | Протокол/порт | Дія / результат |
|---|---|---|
| MGMT → R1 | Усі | Широкий input accept; SSH/WinBox додатково обмежені мережею MGMT у IP Services |
| MGMT → інші мережі | Усі | Широкий forward accept |
| Будь-яке джерело → R1 | ICMP | Accept; ping R1 із CLIENTS/CCTV проходив |
| WAN → DHCP client R1 | UDP67 → 68 | Accept лише через WAN |
| VLAN30/40/50/60 → DHCP/relay R1 | UDP, destination 67/68 | Окремі accept за вхідним VLAN-інтерфейсом |
| DC01 → DHCP relay R1 | UDP67 → 67/68 | Accept від `10.10.20.10` через VLAN20 |
| Інше → R1 | Інше | INPUT default deny |
| CLIENTS → DC01 | UDP53,88,123,389,464 | Accept; DNS і пошук DC перевірені |
| CLIENTS → DC01 | TCP53,88,135,389,445,464,636,3268,3269,9389,49152–65535 | Accept; gpupdate виконано успішно |
| CLIENTS ↔ DC01 | Решта нових з'єднань | Два широкі accept вимкнені; відповіді на дозволені з'єднання пропускає established |
| CLIENTS → FS01 | TCP445 | Accept; перевірка SMB-доступу успішна |
| CLIENTS → R1/SW1 | TCP8291 | Не дозволено; обидва TCP-тести з VLAN30 — False |
| GUESTS/IOT/CCTV → PRIVATE-NETS | Усі | Drop трьома окремими правилами |
| CCTV → WAN | UDP53,123; TCP53 | Accept після PRIVATE-NETS drop; DNS/NTP працювали |
| CCTV → WAN | Решта | Drop перед загальним виходом лабораторії; TCP443 не встановився |
| DC01 → WAN | UDP123 | Окремий accept перед широким дозволом SERVERS |
| SERVERS → WAN | Усі | Широкий accept |
| `10.10.0.0/16` → WAN | Усе, не відкинуте раніше | Загальний accept; попередній CCTV drop має пріоритет |
| Решта транзитного трафіку | Усі | FORWARD default deny |

PRIVATE-NETS: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`. Список включає і приватні upstream-мережі через WAN, не лише VLAN стенда.

## Порядок forward після змін

1. Established/related/untracked; invalid drop.
2. Окремий DNS UDP CLIENTS → DC01; management accept.
3. AD UDP/TCP CLIENTS → DC01.
4. Два широкі правила CLIENTS ↔ DC01 — вимкнені, не видалені.
5. SMB CLIENTS → FS01.
6. DC01 NTP; SERVERS → WAN.
7. Ізоляція GUESTS, IOT, CCTV від PRIVATE-NETS.
8. CCTV DNS/NTP; CCTV DNS TCP; drop решти CCTV → WAN.
9. Загальний вихід лабораторії; default deny.

## Особливості правил і моніторингу

- Окремий DNS UDP-дозвіл дублює порт 53 в AD UDP-правилі.
- CCTV дозволені DNS/NTP-порти до довільних неприватних WAN-призначень, не лише до двох DNS із DHCP. Вміст протоколу не перевіряється.
- Загальний WAN accept не примушує доменних клієнтів користуватися лише внутрішнім DNS і не фільтрує застосунки/сайти.
- MANAGEMENT довіряється широко за source IP.
- Трафік усередині VLAN може не проходити через R1; ці правила не замінюють endpoint firewall.
- На SW1 у перевіреному export немає `/ip firewall filter`; IP Services обмежені, але це не повний host firewall.
- На R1/SW1 налаштовані NTP clients.
- ICMP до VLAN-шлюзів не доводить працездатність access-портів, кінцевих пристроїв або пропускну здатність мережі.
