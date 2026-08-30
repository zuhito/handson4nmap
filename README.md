# handson4nmap

nmap の NSE スクリプトを試すためのハンズオン環境です。
Codespaces を開くと Modbus/TCP サーバ (502) と Node-RED (1880) が自動起動します。

## Test server

`scanme.nmap.org` は nmap プロジェクトがスキャンを許可している検証用ホストです。

```bash
nmap scanme.nmap.org
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20scanme.nmap.org%5Cn%22%7D)

```bash
nmap -p 22 scanme.nmap.org
```

```bash
nmap -p 80 scanme.nmap.org
```

ページのタイトルを取得します。

```bash
nmap -p 80 --script http-title scanme.nmap.org
```

Date ヘッダから時刻ずれを確認します。

```bash
nmap -p 80 --script http-date scanme.nmap.org
```

## nmap コマンド

DHCP サーバの提供内容を確認します。

```bash
nmap --script broadcast-dhcp-discover
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:50 +0000
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
Nmap done: 0 IP addresses (0 hosts up) scanned in 10.08 seconds
WARNING: No targets were specified, so 0 hosts scanned.
```

</details>

NTP サーバの時刻を取得します。BusyBox の ntpd が応答します。

```bash
nmap -sU -p 123 --script ntp-info 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000068s latency).

PORT    STATE SERVICE
123/udp open  ntp
| ntp-info: 
|_  receive time stamp: 2026-08-30T07:51:05

Nmap done: 1 IP address (1 host up) scanned in 10.13 seconds
```

</details>

SNMP エージェントのシステム情報を取得し、コミュニティ名を総当たりします。

```bash
nmap -sU -p 161 --script snmp-info 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.00020s latency).

PORT    STATE SERVICE
161/udp open  snmp
| snmp-info: 
|   enterprise: net-snmp
|   engineIDFormat: unknown
|   engineIDData: 0e78d13fead9936a00000000
|   snmpEngineBoots: 1
|_  snmpEngineTime: 29m56s

Nmap done: 1 IP address (1 host up) scanned in 0.21 seconds
```

</details>

Modbus のスレーブIDとデバイス情報を列挙します。

```bash
nmap -p 502 --script modbus-discover 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000039s latency).

PORT    STATE SERVICE
502/tcp open  modbus
| modbus-discover: 
|   sid 0x1: 
|     Slave ID data: Aichi Company-AIC-PLC-01-1.0.0\xFF
|_    Device identification: Aichi Company AIC-PLC-01 1.0.0

Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
```

</details>

HTTP の Date ヘッダから時刻ずれを検出します。テスト用サーバは 4分51秒 進めた時刻を返します。

```bash
nmap -p 8000 --script http-date 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000032s latency).

PORT     STATE SERVICE
8000/tcp open  http-alt
|_http-date: Sun, 30 Aug 2026 07:56:01 GMT; +4m51s from local time.

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

`clock-skew` はホストスクリプトで、`http-date` などが取得した時刻をまとめて
そのホストの時計のずれとして表示します。

```bash
nmap -p 8000 --script http-date,clock-skew 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000037s latency).

PORT     STATE SERVICE
8000/tcp open  http-alt
|_http-date: Sun, 30 Aug 2026 07:56:01 GMT; +4m51s from local time.

Host script results:
|_clock-skew: 4m50s

Nmap done: 1 IP address (1 host up) scanned in 0.09 seconds
```

</details>

OPC UA サーバが返す時刻も `clock-skew` に集計されます。
ずれが 0 秒の場合は `-vv` を付けないと表示されません。

```bash
nmap -vv -p 4840 --script ./opcua.nse,clock-skew 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
NSE: Loaded 2 scripts for scanning.
NSE: Script Pre-scanning.
NSE: Starting runlevel 1 (of 2) scan.
Initiating NSE at 07:51
Completed NSE at 07:51, 0.00s elapsed
NSE: Starting runlevel 2 (of 2) scan.
Initiating NSE at 07:51
Completed NSE at 07:51, 0.00s elapsed
Initiating Parallel DNS resolution of 1 host. at 07:51
Completed Parallel DNS resolution of 1 host. at 07:51, 0.00s elapsed
Initiating SYN Stealth Scan at 07:51
Scanning localhost (127.0.0.1) [1 port]
Discovered open port 4840/tcp on 127.0.0.1
Completed SYN Stealth Scan at 07:51, 0.00s elapsed (1 total ports)
NSE: Script scanning 127.0.0.1.
NSE: Starting runlevel 1 (of 2) scan.
Initiating NSE at 07:51
Completed NSE at 07:51, 0.00s elapsed
NSE: Starting runlevel 2 (of 2) scan.
Initiating NSE at 07:51
Completed NSE at 07:51, 0.00s elapsed
Nmap scan report for localhost (127.0.0.1)
Host is up, received localhost-response (0.000036s latency).
Scanned at 2026-08-30 07:51:10 UTC for 0s

PORT     STATE SERVICE REASON
4840/tcp open  opcua   syn-ack ttl 64
| opcua: 
|   Server time: 2026-08-30 07:51:10Z
|   Clock skew: +0s
|   Application URI: urn:freeopcua:python:server
|   Endpoint URL: opc.tcp://127.0.0.1:4840/freeopcua/server/
|   Security: None (http://opcfoundation.org/UA/SecurityPolicy#None)
|_  Authentication: Anonymous, Certificate, UserName

Host script results:
|_clock-skew: 0s

NSE: Script Post-scanning.
NSE: Starting runlevel 1 (of 2) scan.
Initiating NSE at 07:51
Completed NSE at 07:51, 0.00s elapsed
NSE: Starting runlevel 2 (of 2) scan.
Initiating NSE at 07:51
Completed NSE at 07:51, 0.00s elapsed
Read data files from: /usr/local/bin/../share/nmap
Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
           Raw packets sent: 1 (44B) | Rcvd: 2 (88B)
```

</details>

PROFINET 機器を DCP のマルチキャストで探索します。

```bash
nmap --script multicast-profinet-discovery
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
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
Nmap done: 0 IP addresses (0 hosts up) scanned in 2.13 seconds
WARNING: No targets were specified, so 0 hosts scanned.
```

</details>

Siemens S7 PLC の装置情報を取得します。

```bash
nmap -p 102 --script s7-info 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000051s latency).

PORT    STATE SERVICE
102/tcp open  iso-tsap
| s7-info: 
|   Module: 6ES7 315-2AG10-0AB0
|   Basic Hardware: 6ES7 315-2AG10-0AB0
|   Version: 2.6.9
|   System Name: SIMATIC 300(Aichi)
|   Module Type: CPU 315-2 DP
|   Serial Number: S C-AIC421302009
|   Plant Identification: Aichi Company Plant 1
|_  Copyright: Original Siemens Equipment
Service Info: Device: specialized

Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
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
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 09:42 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.00043s latency).

PORT     STATE SERVICE
1883/tcp open  mqtt
| mqtt-subscribe: 
|   Topics and their most recent payloads: 
|     aichi/line1/status: running
|     aichi/line1/current: 12.7
|     aichi/line2/pressure: 0.0
|     aichi/line1/pressure: 101.3
|_    aichi/line2/status: stopped

Nmap done: 1 IP address (1 host up) scanned in 7.54 seconds
```

</details>

`mqtt-subscribe.topic` を指定すると購読するトピックを絞れます。
`aichi/line1/#` を指定した場合、停止中の line2 は出力されません。

```bash
nmap -p 1883 --script mqtt-subscribe --script-args 'mqtt-subscribe.topic=aichi/line1/#' 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%201883%20--script%20mqtt-subscribe%20--script-args%20%27mqtt-subscribe.topic%3Daichi%2Fline1%2F%23%27%20127.0.0.1%5Cn%22%7D)

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 09:42 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000048s latency).

PORT     STATE SERVICE
1883/tcp open  mqtt
| mqtt-subscribe: 
|   Topics and their most recent payloads: 
|     aichi/line1/current: 12.7
|     aichi/line1/status: running
|_    aichi/line1/pressure: 101.3

Nmap done: 1 IP address (1 host up) scanned in 7.12 seconds
```

</details>

## Custom NSE

MQTT ブローカの情報を取得します。

```bash
nmap -p 1883 --script mqtt.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000037s latency).

PORT     STATE SERVICE
1883/tcp open  mqtt
| mqtt: 
|   Protocol: MQTT 5.0
|   Connection: Success (0x00)
|   Anonymous access: allowed
|   Session present: no
|   Topic alias maximum: 10
|_  Receive maximum: 20

Nmap done: 1 IP address (1 host up) scanned in 0.06 seconds
```

</details>

認証を要求する MQTT 3.1.1 のブローカでは結果が変わります。
こちらは MQTT 5.0 の接続を拒否するため、スクリプトが 3.1.1 で再接続します。

```bash
nmap -p 1884 --script mqtt.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 08:23 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000039s latency).

PORT     STATE SERVICE
1884/tcp open  mqtt
| mqtt: 
|   Protocol: MQTT 3.1.1
|   Connection: Not authorized (0x05)
|   Anonymous access: denied
|_  Session present: no

Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
```

</details>

Node-RED の診断エンドポイントからバージョン情報を取得します。

```bash
nmap -p 1880 --script node-red.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000027s latency).

PORT     STATE SERVICE
1880/tcp open  node-red
| node-red: 
|   Node-RED: 5.0.4
|   Node.js: v22.22.2 (linux/x64)
|_  OS: Linux 6.18.44-fc-v22 (x64)

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```

</details>

OPC UA サーバのエンドポイントと認証方式を取得します。

```bash
nmap -p 4840 --script opcua.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000026s latency).

PORT     STATE SERVICE
4840/tcp open  opcua
| opcua: 
|   Server time: 2026-08-30 07:51:23Z
|   Clock skew: +0s
|   Application URI: urn:freeopcua:python:server
|   Endpoint URL: opc.tcp://127.0.0.1:4840/freeopcua/server/
|   Security: None (http://opcfoundation.org/UA/SecurityPolicy#None)
|_  Authentication: Anonymous, Certificate, UserName

Nmap done: 1 IP address (1 host up) scanned in 0.06 seconds
```

</details>

OpenVPN サーバのセッション情報を取得します。

```bash
nmap -p 1195 --script openvpn.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000024s latency).

PORT     STATE SERVICE
1195/tcp open  openvpn
| openvpn: 
|   Packet: P_CONTROL_HARD_RESET_SERVER_V2 (opcode 8)
|   Server session ID: 26165f827f1c8163
|   Key ID: 0
|_  Client session acknowledged: yes

Nmap done: 1 IP address (1 host up) scanned in 0.06 seconds
```

</details>

```bash
nmap -sU -p 1194 --script openvpn.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000089s latency).

PORT     STATE SERVICE
1194/udp open  openvpn
| openvpn: 
|   Packet: P_CONTROL_HARD_RESET_SERVER_V2 (opcode 8)
|   Server session ID: 690520bfc305701a
|   Key ID: 0
|_  Client session acknowledged: yes

Nmap done: 1 IP address (1 host up) scanned in 0.13 seconds
```

</details>

CoDeSys V2 ランタイムの OS と製品種別を取得します。

```bash
nmap -p 2455 --script ./external/codesys-v2-discover.nse 127.0.0.1
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000031s latency).

PORT     STATE SERVICE
2455/tcp open  CoDeSyS
| codesys-v2-discover: 
|   OS Name: Linux 3.16.0
|_  Product Type: AIC-PLC-01

Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
```

</details>

## HTML レポートの出力

`-oX` で XML を出力し、nmap 同梱のスタイルシートで HTML に変換します。

```bash
nmap -p 502,1880,1883,4840,8000 \
  --script modbus-discover,./node-red.nse,./mqtt.nse,./opcua.nse,http-date \
  -oX scan.xml 127.0.0.1
xsltproc -o scan.html /usr/local/share/nmap/nmap.xsl scan.xml
```

<details>
<summary>実行例</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-30 07:51 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000015s latency).

PORT     STATE SERVICE
502/tcp  open  modbus
| modbus-discover: 
|   sid 0x1: 
|     Slave ID data: Aichi Company-AIC-PLC-01-1.0.0\xFF
|_    Device identification: Aichi Company AIC-PLC-01 1.0.0
1880/tcp open  node-red
| node-red: 
|   Node-RED: 5.0.4
|   Node.js: v22.22.2 (linux/x64)
|_  OS: Linux 6.18.44-fc-v22 (x64)
1883/tcp open  mqtt
| mqtt: 
|   Protocol: MQTT 5.0
|   Connection: Success (0x00)
|   Anonymous access: allowed
|   Session present: no
|   Topic alias maximum: 10
|_  Receive maximum: 20
4840/tcp open  opcua
| opcua: 
|   Server time: 2026-08-30 07:51:23Z
|   Clock skew: +0s
|   Application URI: urn:freeopcua:python:server
|   Endpoint URL: opc.tcp://127.0.0.1:4840/freeopcua/server/
|   Security: None (http://opcfoundation.org/UA/SecurityPolicy#None)
|_  Authentication: Anonymous, Certificate, UserName
8000/tcp open  http-alt
|_http-date: Sun, 30 Aug 2026 07:56:14 GMT; +4m51s from local time.

Nmap done: 1 IP address (1 host up) scanned in 0.09 seconds
```

</details>

## ファイル

| ファイル | 内容 |
| --- | --- |
| `mock_servers/modbus_server.py` | pymodbus によるModbus/TCPサーバ |
| `mock_servers/opcua_server.py` | opcua によるOPC UAサーバ |
| `scripts/snmpd.conf` | テスト用 SNMP エージェントの設定 |
| `mock_servers/codesys_server.py` | CoDeSys V2 の識別要求に応答するサーバ |
| `mock_servers/s7_server.py` | s7-info に応答する S7comm サーバ |
| `mock_servers/http_clockskew_server.py` | 時刻をずらした Date を返す HTTP サーバ |
| `mock_servers/profinet-server.py` | PROFINET DCP に応答するサーバ(scapy 実装) |
| `scripts/mosquitto-auth.conf` | 認証必須の MQTT ブローカの設定 |
| `scripts/dnsmasq.conf` | テスト用 DHCP サーバの設定 |
| `scripts/dhcp-start.sh` | veth と名前空間を用意して dnsmasq を起動する |
| `scripts/snmpd.conf` | テスト用 SNMP エージェントの設定 |
| `scripts/mosquitto.conf` | テスト用 MQTT ブローカの設定 |
| `scripts/openvpn-udp.conf` / `scripts/openvpn-tcp.conf` | テスト用 OpenVPN サーバの設定 |
| `scripts/profinet-check.sh` | PROFINET の両実装を順に検証する |
| `scripts/nmap-build.sh` | 最新の nmap をソースから導入する |
| `scripts/pnet-build.sh` | p-net (v0.2.0) を取得してビルドする |
| `scripts/pnet-start.sh` | p-net のサンプルアプリを起動する |
| `node-red.nse` | Node-RED の /diagnostics を参照するNSEスクリプト |
| `opcua.nse` | OPC UA の GetEndpoints を実行するNSEスクリプト |
| `openvpn.nse` | OpenVPN の制御チャネルを叩くNSEスクリプト |
| `scripts/install.sh` | nmap / pymodbus / Node-RED の導入 |
| `scripts/start.sh` | 各サーバの起動 |
| `tests/mqtt-subscribe.sh` | mqtt-subscribe の出力を検証する |
| `tests/snmp.sh` | snmp-info と snmp-brute の出力を検証する |
| `tests/codesys.sh` | codesys-v2-discover の出力を検証する |
| `tests/snmp.sh` | snmp-info と snmp-brute の出力を検証する |
| `tests/ntp.sh` | ntp-info の出力を検証する |
| `tests/report.sh` | HTML レポートを生成して内容を検証する |
| `tests/test.sh` | 起動とスキャン結果の検証 |

