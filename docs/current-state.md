# Поточний стан стенда

Дата звірки: **31.08.2026**.

Документ описує конфігурацію стенда та результати його перевірки. Джерела — експорти RouterOS, скриншоти, виводи команд і результати ручної практики.

## Фізична платформа

| Параметр | Значення |
|---|---|
| Призначення | Окремий домашній ПК для лабораторії |
| Гіпервізор | VMware Workstation 26.0.0, build 25388281 |
| CPU | AMD Ryzen 5 2600 |
| RAM | 16 GB DDR4 |
| GPU | NVIDIA GTX 1060 6 GB |

## Віртуальні машини

| Вузол | Роль | Лабораторна адреса | Версія / уточнення |
|---|---|---|---|
| MikroTik-R1 | Router, IPv4 Firewall, DHCP/relay, NAT | `10.10.10.1` | CHR, RouterOS 7.21.5 у перевіреному експорті |
| MikroTik-SW1 | VLAN-aware bridge, trunk/access | `10.10.10.3` | CHR, RouterOS 7.21.5; не фізичний switch |
| DC01 | AD DS, DNS, DHCP | `10.10.20.10` | Windows Server 2025 Standard Evaluation, 24H2, build 26100.33158 |
| FS01 | SMB File Server | `10.10.20.20` | Windows Server 2025 Standard Evaluation, 24H2, build 26100.33158 |
| Zabbix server | Моніторинг Windows/Linux і шлюзів | `10.10.20.30` | Ubuntu 26.04 LTS з GUI; Zabbix Server 7.0.29 |
| USER-WS-001 | Доменна робоча станція | DHCP у VLAN30; останній тест `10.10.30.50` | Windows 11 Pro, 25H2, build 26200.8037 |

## Active Directory та Group Policy

- Навчальний DNS-домен: `local.domain`; NetBIOS: `NETLAB`.
- Контролер домену: DC01.
- OU NETLAB містить Admin-Accounts, Disabled Objects, Groups, Servers, Service Accounts, Users і Workstations.
- Тестовий користувач розташований у `NETLAB/Users/IT/Developers`, комп'ютер — у `NETLAB/Workstations/Developers`.
- Користувач входить до GG-груп відділу/ролі й DL-груп файлових дозволів.
- Default Domain Policy застосовується до комп'ютера, її User Configuration порожня. Тому N/A у user-scope gpresult не був помилкою доставки.
- Окрема `GPO-WS-Developers-AutoLock` прив'язана до OU комп'ютерів Developers. Machine inactivity limit — 900 секунд. Отримання підтверджене gpresult, фактичне блокування — ручним тестом.
- Копії GPO створено на DC01 і перенесено на фізичний серверний ПК. Налаштування AutoLock імпортовано в неприв'язану `TEST-AutoLock-Recovery`, значення 900 перевірено.

## Мережа й файловий сервер

VLAN, DHCP, порти та доступ описані в [мережевому плані](architecture/network-plan.md).

Два широкі дозволи CLIENTS ↔ DC01 вимкнено під час практики. Після змін успішно виконані DNS SRV-запит, gpupdate і nltest /dsgetdc з /force.

SMB-доступ із груповим розмежуванням перевірено успішно.

## Моніторинг і журнали

- Zabbix Agent 2 7.0.30 на DC01: Running, TCP10050 Listen; шаблон Windows by Zabbix agent.
- Hardware dashboard показує CPU, RAM і зайнятість файлових систем Windows/Linux, а також графіки.
- Network Health містить шість ICMP-хостів для шлюзів VLAN, таблицю status/loss/latency і графіки.
- ICMP до адрес одного R1 не показує справність усіх кінцевих вузлів і access-портів.
- Frontend працює через HTTP на порту 8080.
- У Security Event Log DC01 розібрані події 4672 і 5379: призначення спеціальних привілеїв новому входу та читання облікових даних Credential Manager.

## Рівень перевірки

| Категорія | Що відомо |
|---|---|
| Підтверджено виводами/скриншотами | DHCP VLAN50/60, source VLAN30, DNS SRV, gpupdate, DC discovery, недоступність TCP8291 із VLAN30, CCTV DNS/NTP і невдалий HTTPS, dashboards |
| Підтверджено ручною практикою | Автоблокування через 15 хвилин, GPO backup/import, копії поза VM, успішна перевірка SMB-доступу |
| Видно в конфігурації | VLAN table, DHCP-пули, IPv4 Firewall, NAT, обмеження SSH/WinBox, NTP clients |
