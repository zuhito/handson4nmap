# handson4nmap

A hands-on environment for trying out nmap commands.
The mock servers start automatically when the Codespace opens.

## Ports and services

| Port | Protocol | Service |
| --- | --- | --- |
| 22 | tcp | SSH |
| 25 | tcp | SMTP |
| 53 | udp | DNS |
| 67 | udp | DHCP |
| 80 | tcp | HTTP |
| 102 | tcp | S7 |
| 110 | tcp | POP3 |
| 123 | udp | NTP |
| 143 | tcp | IMAP |
| 161 | udp | SNMP |
| 502 | tcp | Modbus TCP |
| 1194 | udp | OpenVPN |
| 1883 | tcp | MQTT |
| 3306 | tcp | MySQL |
| 4840 | tcp | OPC UA |
| 5900 | tcp | VNC |
| none | ethernet | PROFINET DCP |

## TCP Scan

Connection to the SSH server on port 22

```bash
nmap -p 22 127.0.0.1
```

<details>
<summary>Result</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000051s latency).

PORT   STATE SERVICE
22/tcp open  ssh

Nmap done: 1 IP address (1 host up) scanned in 0.04 seconds
```

</details>

Connection to the HTTP server on port 80

```bash
nmap -p 80 127.0.0.1
```

<details>
<summary>Result</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000046s latency).

PORT   STATE SERVICE
80/tcp open  http

Nmap done: 1 IP address (1 host up) scanned in 0.04 seconds
```

</details>

Page title of the HTTP server
```bash
nmap -p 80 --script http-title 127.0.0.1
```

<details>
<summary>Result</summary>

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

Response headers returned by the HTTP server
```bash
nmap -p 80 --script http-headers 127.0.0.1
```

<details>
<summary>Result</summary>

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

Messages subscribed from the MQTT broker

```bash
nmap -p 1883 --script mqtt-subscribe 127.0.0.1
```

<details>
<summary>Result</summary>

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

Maintenance messages with the `nagoya` topic (logging in required)

```bash
nmap -p 1883 --script mqtt-subscribe --script-args "mqtt-subscribe.username=username,mqtt-subscribe.password=password" 127.0.0.1
```

<details>
<summary>Result</summary>

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

Messages with selected topics

```bash
nmap -p 1883 --script mqtt-subscribe --script-args 'mqtt-subscribe.topic=aichi/line1/#' 127.0.0.1
```

<details>
<summary>Result</summary>

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

Configuration of the MySQL server

```bash
nmap -p 3306 --script mysql-info 127.0.0.1
```

<details>
<summary>Result</summary>

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

Information of the SMTP server

```bash
nmap -p 25 --script smtp-commands 127.0.0.1
```

<details>
<summary>Result</summary>

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

Information of the POP3 server

```bash
nmap -p 110 --script pop3-capabilities 127.0.0.1
```

<details>
<summary>Result</summary>

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

Information of the IMAP server

```bash
nmap -p 143 --script imap-capabilities 127.0.0.1
```

<details>
<summary>Result</summary>

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

Information of the VNC server

```bash
nmap -p 5900 --script vnc-info 127.0.0.1
```

<details>
<summary>Result</summary>

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

Device information of a PLC that speaks S7 protocol

```bash
nmap -p 102 --script s7-info 127.0.0.1
```

<details>
<summary>Result</summary>

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

Device information of a Modbus server

```bash
nmap -p 502 --script modbus-discover 127.0.0.1
```

<details>
<summary>Result</summary>

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

## Clock Skew
Server time from the HTTP Date header (the test server always reports 2028-11-15)

```bash
nmap -p 80 --script http-date 127.0.0.1
```

<details>
<summary>Result</summary>

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

Clock skew of the HTTP server (`clock-skew` is a host script that aggregates the
timestamps collected by scripts such as `http-date`)

```bash
nmap -p 80 --script http-date,clock-skew 127.0.0.1
```

<details>
<summary>Result</summary>

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

## UDP Scan (-sU option)

Connection to the OpenVPN server over UDP
```bash
nmap -sU -p 1194 127.0.0.1
```

<details>
<summary>Result</summary>

```
Starting Nmap 7.99SVN ( https://nmap.org ) at 2026-08-31 02:49 +0000
Nmap scan report for localhost (127.0.0.1)
Host is up (0.00020s latency).

PORT     STATE SERVICE
1194/udp open  openvpn

Nmap done: 1 IP address (1 host up) scanned in 0.17 seconds
```

</details>

Time reported by the NTP server (the test server always returns 2028-11-15)

```bash
nmap -sU -p 123 --script ntp-info 127.0.0.1
```

<details>
<summary>Result</summary>

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

System information from SNMP

```bash
nmap -sU -p 161 --script snmp-info 127.0.0.1
```

<details>
<summary>Result</summary>

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

## Broadcast / Multicast
Configuration offered by the DHCP server

```bash
nmap --script broadcast-dhcp-discover
```

<details>
<summary>Result</summary>

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

DHCP request sent with a specific MAC address
```bash
nmap --script broadcast-dhcp-discover --script-args "broadcast-dhcp-discover.mac=00:11:22:33:44:55"
```

<details>
<summary>Result</summary>

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

Discovery of PROFINET devices

```bash
nmap --script multicast-profinet-discovery
```

<details>
<summary>Result</summary>

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
Endpoints and authentication methods of the OPC UA server

```bash
nmap -p 4840 --script opcua.nse 127.0.0.1
```

<details>
<summary>Result</summary>

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

## HTML report

HTM report generated by XSLT

```bash
nmap -p 80  --script http-date,clock-skew -oX scan.xml 127.0.0.1
xsltproc -o scan.html /usr/local/share/nmap/nmap.xsl scan.xml
```

HTML report that collects every result

```bash
nmap -sS -sU -p T:22,25,80,102,110,143,502,1883,3306,5990,U:123,161,1194 --script http-title,http-headers,http-date,mqtt-subscribe,mysql-info,smtp-commands,pop3-capabilities,imap-capabilities,vnc-info,s7-info,modbus-discover,clock-skew,ntp-info,snmp-info,broadcast-dhcp-discover,multicast-profinet-discovery -oX scan.xml 127.0.0.1
xsltproc -o scan.html /usr/local/share/nmap/nmap.xsl scan.xml
```
