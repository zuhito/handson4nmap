# handson4nmap

nmapコマンドを試すためのハンズオン環境です。
Codespacesを開くとモックサーバが自動起動します。

## ポートとサービス

| ポート | プロトコル | サービス | 備考 |
| --- | --- | --- | --- |
| 102 | tcp | S7comm (ISO-TSAP) | |
| 123 | udp | NTP | |
| 110 | tcp | POP3 | |
| 143 | tcp | IMAP | |
| 161 | udp | SNMP | |
| 502 | tcp | Modbus/TCP | |
| 1194 | udp | OpenVPN | |
| 1883 | tcp | MQTT | 匿名接続を許可、ACL で `aichi/#` のみ公開 |
| 2455 | tcp | CoDeSys V2 | |
| 3000 | tcp | Grafana | |
| 3306 | tcp | MariaDB | |
| 4840 | tcp | OPC UA | 常に 2028-11-15 の時刻を返す |
| 5900 | tcp | VNC | |
| 8086 | tcp | InfluxDB | |
| 80 | tcp | HTTP | HMI 風のページを返し、Date は常に 2028-11-15 |
| なし | ethernet | PROFINET DCP | |
| 22 | tcp | SSH | |
| 25 | tcp | SMTP | |
| 53 | udp | DNS (dnsmasq) | `aichi.example` の名前を解決する |
| 67 | udp | DHCP (dnsmasq) | |

# TCP Scan

SSH サーバが 22 番で待ち受けています。

```bash
nmap -p 22 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000051s latency).

PORT   STATE SERVICE
22/tcp open  ssh

Nmap done: 1 IP address (1 host up) scanned in 0.04 seconds
```

</details>

```bash
nmap -p 80 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000046s latency).

PORT   STATE SERVICE
80/tcp open  http

Nmap done: 1 IP address (1 host up) scanned in 0.04 seconds
```

</details>

ページのタイトルを取得します。
```bash
nmap -p 80 --script http-title 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000053s latency).

PORT   STATE SERVICE
80/tcp open  http
|_http-title: Aichi Line1 HMI

Nmap done: 1 IP address (1 host up) scanned in 0.13 seconds
```

</details>

Webサーバーが返してくるヘッダー情報をシンプルに取得します。
```bash
nmap -p 80 --script http-headers 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000038s latency).

PORT   STATE SERVICE
80/tcp open  http
| http-headers: 
|   Server: AichiHTTP/1.0 
|   Date: Wed, 15 Nov 2028 00:00:00 GMT
|   Content-Type: text/html; charset=utf-8
|   Content-Length: 173
|   X-Powered-By: Aichi-HMI/2.1.4
|   X-Frame-Options: SAMEORIGIN
|   Cache-Control: no-store
|   
|_  (Request type: HEAD)

Nmap done: 1 IP address (1 host up) scanned in 0.10 seconds
```

</details>

ブローカが保持しているトピックと最新のペイロードを購読して表示します。
既定では `#` と `$SYS/#` を購読するため、ブローカの全トピックが対象になります。
テスト用のブローカは `sys_interval 0` で統計の配信を止めてあるので、
`mosquitto_pub -r` で retain 付き配信した2ライン分の5件だけが表示されます。

```bash
nmap -p 1883 --script mqtt-subscribe 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000071s latency).

PORT     STATE SERVICE
1883/tcp open  mqtt
| mqtt-subscribe: 
|   Topics and their most recent payloads: 
|     aichi/line1/status: running
|     aichi/line1/current: 12.7
|     aichi/line2/pressure: 0.0
|     aichi/line2/status: stopped
|_    aichi/line1/pressure: 101.3

Nmap done: 1 IP address (1 host up) scanned in 7.12 seconds
```

</details>

ACL で匿名クライアントは `aichi/#` しか読めません。`mqtt-subscribe.username` と
`mqtt-subscribe.password` を渡すと保守用アカウントとして接続し、
レシピの `recipe/#` も取得できます。

```bash
nmap -p 1883 --script mqtt-subscribe --script-args "mqtt-subscribe.username=username,mqtt-subscribe.password=passwprod" 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000049s latency).

PORT     STATE SERVICE
1883/tcp open  mqtt
| mqtt-subscribe: 
|   Topics and their most recent payloads: 
|     aichi/line2/pressure: 0.0
|     nagoya/line2/status: maintenance
|     aichi/line1/pressure: 101.3
|     aichi/line2/status: stopped
|     nagoya/line1/temperature: 180
|     aichi/line1/current: 12.7
|     nagoya/line1/status: running
|_    aichi/line1/status: running

Nmap done: 1 IP address (1 host up) scanned in 7.12 seconds
```

</details>

`mqtt-subscribe.topic` を指定すると購読するトピックを絞れます。
`aichi/line1/#` を指定した場合、停止中の line2 は出力されません。

```bash
nmap -p 1883 --script mqtt-subscribe --script-args 'mqtt-subscribe.topic=aichi/line1/#' 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000047s latency).

PORT     STATE SERVICE
1883/tcp open  mqtt
| mqtt-subscribe: 
|   Topics and their most recent payloads: 
|     aichi/line1/pressure: 101.3
|     aichi/line1/status: running
|_    aichi/line1/current: 12.7

Nmap done: 1 IP address (1 host up) scanned in 7.12 seconds
```

</details>

MySQL / MariaDB が接続直後に送るグリーティングから構成を取得します。

```bash
nmap -p 3306 --script mysql-info 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-31 08:42 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000057s latency).

PORT     STATE SERVICE
3306/tcp open  mysql
| mysql-info: 
|   Protocol: 10
|   Version: 5.5.5-10.11.14-MariaDB-0ubuntu0.24.04.1
|   Thread ID: 19
|   Capabilities flags: 63486
|   Some Capabilities: Speaks41ProtocolNew, SupportsTransactions, ConnectWithDatabase, Speaks41ProtocolOld, DontAllowDatabaseTableColumn, SupportsCompression, IgnoreSpaceBeforeParenthesis, IgnoreSigpipes, FoundRows, LongColumnFlag, ODBCClient, SupportsLoadDataLocal, Support41Auth, InteractiveClient, SupportsAuthPlugins, SupportsMultipleStatments, SupportsMultipleResults
|   Status: Autocommit
|   Salt: GBUcr3FFjd6~>Vwvg%!p
|_  Auth Plugin Name: mysql_native_password

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

SMTP サーバが EHLO に対して返す拡張の一覧を取得します。

```bash
nmap -p 25 --script smtp-commands 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-31 08:55 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000042s latency).

PORT   STATE SERVICE
25/tcp open  smtp
|_smtp-commands: mail.aichi.example, PIPELINING, SIZE 10485760, 8BITMIME, ENHANCEDSTATUSCODES, STARTTLS, AUTH PLAIN LOGIN, HELP

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

POP3 サーバが CAPA で返す機能の一覧を取得します。グリーティングに APOP の
チャレンジが含まれる場合は APOP も報告されます。

```bash
nmap -p 110 --script pop3-capabilities 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-31 09:08 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000041s latency).

PORT    STATE SERVICE
110/tcp open  pop3
|_pop3-capabilities: IMPLEMENTATION(Aichi-Mail-POP3 2) SASL(PLAIN LOGIN) USER PIPELINING RESP-CODES UIDL APOP TOP STLS

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

IMAP サーバが CAPABILITY で返す機能の一覧を取得します。

```bash
nmap -p 143 --script imap-capabilities 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-31 09:20 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000049s latency).

PORT    STATE SERVICE
143/tcp open  imap
|_imap-capabilities: STARTTLS NAMESPACE AUTH=PLAIN UIDPLUS completed IDA0001 AUTH=LOGIN CAPABILITY LOGINDISABLED OK IMAP4rev1 IDLE

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

VNC サーバのプロトコルバージョンと提示されるセキュリティタイプを取得します。

```bash
nmap -p 5900 --script vnc-info 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-31 12:21 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.00018s latency).

PORT     STATE SERVICE
5900/tcp open  vnc
| vnc-info: 
|   Protocol version: 3.8
|   Security types: 
|_    VNC Authentication (2)

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

S7comm に対応した PLC の装置情報を取得します。

```bash
nmap -p 102 --script s7-info 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000044s latency).

PORT    STATE SERVICE
102/tcp open  iso-tsap
| s7-info: 
|   Module: AIC-CPU-3150
|   Basic Hardware: AIC-CPU-3150
|   Version: 2.6.9
|   System Name: Aichi Line1 Controller
|   Module Type: AIC CPU 3150
|   Serial Number: AIC-0001-0042
|   Plant Identification: Aichi Company Plant 1
|_  Copyright: Original Aichi Company Equipment
Service Info: Device: specialized

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

Modbus のスレーブIDとデバイス情報を列挙します。

```bash
nmap -p 502 --script modbus-discover 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000044s latency).

PORT    STATE SERVICE
502/tcp open  modbus
| modbus-discover: 
|   sid 0x1: 
|     Slave ID data: Aichi Company-AIC-PLC-01-1.0.0\xFF
|_    Device identification: Aichi Company AIC-PLC-01 1.0.0

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

# clock skew
HTTP の Date ヘッダから時刻ずれを検出します。テスト用サーバは常に 2028-11-15 の時刻を返します。

```bash
nmap -p 80 --script http-date 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:50 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000044s latency).

PORT   STATE SERVICE
80/tcp open  http
|_http-date: Wed, 15 Nov 2028 00:00:00 GMT; +2y75d21h09m31s from local time.

Nmap done: 1 IP address (1 host up) scanned in 0.09 seconds
```

</details>

`clock-skew` はホストスクリプトで、`http-date` などが取得した時刻をまとめて
そのホストの時計のずれとして表示します。

```bash
nmap -p 80 --script http-date,clock-skew 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:50 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000047s latency).

PORT   STATE SERVICE
80/tcp open  http
|_http-date: Wed, 15 Nov 2028 00:00:00 GMT; +2y75d21h09m31s from local time.

Host script results:
|_clock-skew: 806d21h09m30s

Nmap done: 1 IP address (1 host up) scanned in 0.10 seconds
```

</details>

# UDP Scan (-sU option)

OpenVPNサーバへUDPで接続
```bash
nmap -sU -p 1194 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.00020s latency).

PORT     STATE SERVICE
1194/udp open  openvpn

Nmap done: 1 IP address (1 host up) scanned in 0.17 seconds
```

</details>

NTP サーバの時刻を取得します。テスト用サーバは 2028-11-15 の固定時刻を返します。

```bash
nmap -sU -p 123 --script ntp-info 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.00074s latency).

PORT    STATE SERVICE
123/udp open  ntp
| ntp-info: 
|_  receive time stamp: 2028-11-15T00:00:00

Nmap done: 1 IP address (1 host up) scanned in 10.16 seconds
```

</details>

SNMP エージェントのシステム情報を取得し、コミュニティ名を総当たりします。

```bash
nmap -sU -p 161 --script snmp-info 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:50 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.00025s latency).

PORT    STATE SERVICE
161/udp open  snmp
| snmp-info: 
|   enterprise: net-snmp
|   engineIDFormat: unknown
|   engineIDData: 3098d22257e5946a00000000
|   snmpEngineBoots: 1
|_  snmpEngineTime: 27m51s

Nmap done: 1 IP address (1 host up) scanned in 0.34 seconds
```

</details>

# Broadcast / Multicast
DHCP サーバの提供内容を確認します。

```bash
nmap --script broadcast-dhcp-discover
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:50 +0000
Pre-scan script results:
| broadcast-dhcp-discover: 
|   Response 1 of 1: 
|     Interface: veth-host
|     IP Offered: 192.168.50.141
|     DHCP Message Type: DHCPOFFER
|     Server Identifier: 192.168.50.1
|     IP Address Lease Time: 12h00m00s
|     Renewal Time Value: 6h00m00s
|     Rebinding Time Value: 10h30m00s
|     Subnet Mask: 255.255.255.0
|     Broadcast Address: 192.168.50.255
|     Domain Name: aichi.example
|     Domain Name Server: 192.168.50.1
|_    Router: 192.168.50.1
Nmap done: 0 IP addresses (0 hosts up) scanned in 10.11 seconds
WARNING: No targets were specified, so 0 hosts scanned.
```

</details>

MACアドレスを指定してDHCPリクエスト
```bash
nmap --script broadcast-dhcp-discover --script-args "broadcast-dhcp-discover.mac=00:11:22:33:44:55"
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:50 +0000
Pre-scan script results:
| broadcast-dhcp-discover: 
|   Response 1 of 1: 
|     Interface: veth-host
|     IP Offered: 192.168.50.141
|     DHCP Message Type: DHCPOFFER
|     Server Identifier: 192.168.50.1
|     IP Address Lease Time: 12h00m00s
|     Renewal Time Value: 6h00m00s
|     Rebinding Time Value: 10h30m00s
|     Subnet Mask: 255.255.255.0
|     Broadcast Address: 192.168.50.255
|     Domain Name: aichi.example
|     Domain Name Server: 192.168.50.1
|_    Router: 192.168.50.1
Nmap done: 0 IP addresses (0 hosts up) scanned in 10.09 seconds
WARNING: No targets were specified, so 0 hosts scanned.
```

</details>

同一セグメントで ICMP に応答するホストを列挙します。`scripts/dhcp-start.sh` が
用意する `veth-host` を指定すると、名前空間側のホストが応答します。

```bash
nmap -e veth-host --script broadcast-ping
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-31 06:24 +0000
Pre-scan script results:
| broadcast-ping: 
|   IP: 192.168.50.1  MAC: b2:ee:e2:0e:b2:d0
|_  Use --script-args=newtargets to add the results as targets
WARNING: No targets were specified, so 0 hosts scanned.
Nmap done: 0 IP addresses (0 hosts up) scanned in 3.09 seconds
```

</details>

PROFINET 機器を DCP のマルチキャストで探索します。

```bash
nmap --script multicast-profinet-discovery
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:50 +0000
Pre-scan script results:
| multicast-profinet-discovery: 
|   02:fc:00:00:00:01: 
|     Interface: eth0
|     IP: 
|       ip_addr: 192.0.2.2
|       ip_info: IP set
|       subnetmask: 255.255.255.0
|       gateway: 192.0.2.1
|     Device: 
|       vendorId: 0x002a
|       deviceId: 0x0105
|       vendorValue: Aichi Company AIC-PLC-01
|       deviceRole: 0x02 (IO-Controller)
|_      nameOfStation: aic-plc-01
Nmap done: 0 IP addresses (0 hosts up) scanned in 2.14 seconds
WARNING: No targets were specified, so 0 hosts scanned.
```

</details>

## Custom NSE
OPC UA サーバのエンドポイントと認証方式を取得します。

```bash
nmap -p 4840 --script opcua.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-31 12:50 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000073s latency).

PORT     STATE SERVICE
4840/tcp open  opcua
| opcua: 
|   Server time: 2028-11-15 00:00:00Z
|   Clock skew: +806d11h
|   Application URI: urn:freeopcua:python:server
|   Endpoint URLs: 
|     opc.tcp://127.0.0.1:4840/freeopcua/server/
|   Security: 
|_    None (None), authentication: Anonymous, Certificate, UserName

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

Grafana のバージョンとデータベースの状態を取得します。

```bash
nmap -p 3000 --script grafana.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000048s latency).

PORT     STATE SERVICE
3000/tcp open  grafana
| grafana: 
|   Version: 13.2.0
|   Build commit: f681b1359f6a
|   Database: ok
|_  Anonymous access: disabled

Nmap done: 1 IP address (1 host up) scanned in 0.10 seconds
```

</details>

認証情報を渡すと、API から組織、アカウント、データソース、統計を取得します。

```bash
nmap -p 3000 --script grafana.nse --script-args "grafana.username=admin,grafana.password=admin" 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-31 06:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000044s latency).

PORT     STATE SERVICE
3000/tcp open  grafana
| grafana: 
|   Version: 13.2.0
|   Build commit: f681b1359f6a
|   Database: ok
|   Anonymous access: disabled
|   Credentials: accepted
|   Organisation: Main Org.
|   Users: admin (Admin, admin@localhost)
|   Data sources: plant-influx (influxdb, http://127.0.0.1:8086)
|_  Statistics: 1 users, 0 dashboards, 1 datasources

Nmap done: 1 IP address (1 host up) scanned in 0.12 seconds
```

</details>

InfluxDB のバージョンと、認証なしで参照できるデータベースを取得します。

```bash
nmap -p 8086 --script influxdb.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:50 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000036s latency).

PORT     STATE SERVICE
8086/tcp open  influxdb
| influxdb: 
|   Version: 1.6.7~rc0
|   Build: OSS
|   Authentication: not required
|_  Databases: _internal, plant

Nmap done: 1 IP address (1 host up) scanned in 0.09 seconds
```

</details>

CoDeSys V2 ランタイムの OS と製品種別を取得します。

```bash
nmap -p 2455 --script codesys-v2-discover.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:50 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000050s latency).

PORT     STATE SERVICE
2455/tcp open  CoDeSyS
| codesys-v2-discover: 
|   OS Name: Linux 3.16.0
|_  Product Type: AIC-PLC-01

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

## HTML レポートの出力

`-oX` で XML を出力し、nmap 同梱のスタイルシートで HTML に変換します。

```bash
nmap -p 80,502,1880,1883,4840 \
  --script opcua.nse,http-date \
  -oX scan.xml 127.0.0.1
xsltproc -o scan.html /usr/local/share/nmap/nmap.xsl scan.xml
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-31 12:50 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000025s latency).

PORT     STATE SERVICE
80/tcp   open  http
|_http-date: Wed, 15 Nov 2028 00:00:00 GMT; +2y75d11h09m45s from local time.
502/tcp  open  mbap
1880/tcp open  vsat-control
1883/tcp open  mqtt
4840/tcp open  opcua
| opcua: 
|   Server time: 2028-11-15 00:00:00Z
|   Clock skew: +806d11h
|   Application URI: urn:freeopcua:python:server
|   Endpoint URLs: 
|     opc.tcp://127.0.0.1:4840/freeopcua/server/
|   Security: 
|_    None (None), authentication: Anonymous, Certificate, UserName

Nmap done: 1 IP address (1 host up) scanned in 0.11 seconds
```

</details>
