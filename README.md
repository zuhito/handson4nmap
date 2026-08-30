# handson4nmap

nmap の NSE スクリプトを試すためのハンズオン環境です。
Codespaces を開くと Modbus/TCP サーバ (502) と Node-RED (1880) が自動起動します。

各コマンドの下にある「ターミナルで実行」をクリックすると、VS Code のターミナルに
コマンドが入力されて実行されます。VS Code の Markdown プレビューで開いた場合のみ動作し、
GitHub 上では通常のリンクとして表示されます。信頼していないワークスペースでは
確認ダイアログが出ることがあります。

## 外部ホストへの実行

`scanme.nmap.org` は nmap プロジェクトがスキャンを許可している検証用ホストです。

```bash
nmap scanme.nmap.org
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20scanme.nmap.org%5Cn%22%7D)

ページのタイトルを取得します。

```bash
nmap -p 80 --script http-title scanme.nmap.org
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%2080%20--script%20http-title%20scanme.nmap.org%5Cn%22%7D)

Date ヘッダから時刻ずれを確認します。

```bash
nmap -p 80 --script http-date scanme.nmap.org
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%2080%20--script%20http-date%20scanme.nmap.org%5Cn%22%7D)

## nmap コマンド

DHCP サーバの提供内容を確認します。

```bash
nmap --script broadcast-dhcp-discover
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20--script%20broadcast-dhcp-discover%5Cn%22%7D)

NTP サーバの時刻を取得します。BusyBox の ntpd が応答します。

```bash
nmap -sU -p 123 --script ntp-info 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-sU%20-p%20123%20--script%20ntp-info%20127.0.0.1%5Cn%22%7D)

SNMP エージェントのシステム情報を取得し、コミュニティ名を総当たりします。

```bash
nmap -sU -p 161 --script snmp-info 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-sU%20-p%20161%20--script%20snmp-info%20127.0.0.1%5Cn%22%7D)

Modbus のスレーブIDとデバイス情報を列挙します。

```bash
nmap -p 502 --script modbus-discover 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%20502%20--script%20modbus-discover%20127.0.0.1%5Cn%22%7D)

HTTP の Date ヘッダから時刻ずれを検出します。テスト用サーバは 4分51秒 進めた時刻を返します。

```bash
nmap -p 8000 --script http-date 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%208000%20--script%20http-date%20127.0.0.1%5Cn%22%7D)

PROFINET 機器を DCP のマルチキャストで探索します。

```bash
nmap --script multicast-profinet-discovery
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20--script%20multicast-profinet-discovery%5Cn%22%7D)

Siemens S7 PLC の装置情報を取得します。

```bash
nmap -p 102 --script s7-info 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%20102%20--script%20s7-info%20127.0.0.1%5Cn%22%7D)

```bash
nmap -p 1883 --script mqtt-subscribe 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%201883%20--script%20mqtt-subscribe%20127.0.0.1%5Cn%22%7D)

## Custom NSE

MQTT ブローカの情報を取得します。

```bash
nmap -p 1883 --script mqtt.nse 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%201883%20--script%20mqtt.nse%20127.0.0.1%5Cn%22%7D)

認証を要求するブローカでは結果が変わります。

```bash
nmap -p 1884 --script mqtt.nse 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%201884%20--script%20mqtt.nse%20127.0.0.1%5Cn%22%7D)

Node-RED の診断エンドポイントからバージョン情報を取得します。

```bash
nmap -p 1880 --script node-red.nse 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%201880%20--script%20node-red.nse%20127.0.0.1%5Cn%22%7D)

OPC UA サーバのエンドポイントと認証方式を取得します。

```bash
nmap -p 4840 --script opcua.nse 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%204840%20--script%20opcua.nse%20127.0.0.1%5Cn%22%7D)

OpenVPN サーバのセッション情報を取得します。

```bash
nmap -p 1194 --script openvpn.nse 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%201194%20--script%20openvpn.nse%20127.0.0.1%5Cn%22%7D)

```bash
nmap -sU -p 1194 --script openvpn.nse 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-sU%20-p%201194%20--script%20openvpn.nse%20127.0.0.1%5Cn%22%7D)

CoDeSys V2 ランタイムの OS と製品種別を取得します。

```bash
nmap -p 2455 --script ./external/codesys-v2-discover.nse 127.0.0.1
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%202455%20--script%20.%2Fexternal%2Fcodesys-v2-discover.nse%20127.0.0.1%5Cn%22%7D)

## HTML レポートの出力

`-oX` で XML を出力し、nmap 同梱のスタイルシートで HTML に変換します。

```bash
nmap -p 502,1880,1883,4840,8000 \
  --script modbus-discover,./node-red.nse,./mqtt.nse,./opcua.nse,http-date \
  -oX scan.xml 127.0.0.1
xsltproc -o scan.html /usr/local/share/nmap/nmap.xsl scan.xml
```

[ターミナルで実行](command:workbench.action.terminal.sendSequence?%7B%22text%22%3A%20%22nmap%20-p%20502%2C1880%2C1883%2C4840%2C8000%20%5C%5C%5Cn%20%20--script%20modbus-discover%2C.%2Fnode-red.nse%2C.%2Fmqtt.nse%2C.%2Fopcua.nse%2Chttp-date%20%5C%5C%5Cn%20%20-oX%20scan.xml%20127.0.0.1%5Cnxsltproc%20-o%20scan.html%20%2Fusr%2Flocal%2Fshare%2Fnmap%2Fnmap.xsl%20scan.xml%5Cn%22%7D)

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

