# handson4nmap

nmap の NSE スクリプトを試すためのハンズオン環境です。
Codespaces を開くと Modbus/TCP サーバ (502) と Node-RED (1880) が自動起動します。

## nmap コマンド

Modbus のスレーブIDとデバイス情報を列挙します。

```bash
nmap -p 502 --script modbus-discover 127.0.0.1
```

Node-RED の診断エンドポイントからバージョン情報を取得します。

```bash
nmap -p 1880 --script node-red.nse 127.0.0.1
```

OPC UA サーバのエンドポイントと認証方式を取得します。

```bash
nmap -p 4840 --script opcua.nse 127.0.0.1
```

OpenVPN サーバのセッション情報を取得します。

```bash
nmap -p 1194 --script openvpn.nse 127.0.0.1
nmap -sU -p 1194 --script openvpn.nse 127.0.0.1
```

PROFINET 機器を DCP のマルチキャストで探索します。root 権限が必要です。

```bash
nmap --script multicast-profinet-discovery
```

このスクリプトはコンテナイメージの nmap には同梱されていないため、`scripts/install.sh` が
`scripts/nmap-build.sh` 経由で最新の nmap をソースから導入します。

MQTT ブローカの情報を取得します。

```bash
nmap -p 1883 --script mqtt.nse 127.0.0.1
```

認証を要求するブローカでは結果が変わります。

```bash
nmap -p 1884 --script mqtt.nse 127.0.0.1
```

ブローカが保持しているトピックと最新のペイロードを購読して表示します。
テスト用のパブリッシャが retain 付きで3つのトピックを配信しています。

```bash
nmap -p 1883 --script mqtt-subscribe 127.0.0.1
```

CoDeSys V2 ランタイムの OS と製品種別を取得します。

```bash
nmap -p 2455 --script ./external/codesys-v2-discover.nse 127.0.0.1
```

HTTP の Date ヘッダから時刻ずれを検出します。テスト用サーバは 4分51秒 進めた時刻を返します。

```bash
nmap -p 8000 --script http-date 127.0.0.1
```

DHCP サーバの提供内容を確認します。テスト用サーバは veth の先の
ネットワーク名前空間で動いています。

```bash
nmap -sU -p 67 --script dhcp-discover 192.168.50.1
nmap --script broadcast-dhcp-discover -e veth-host
```

Siemens S7 PLC の装置情報を取得します。

```bash
nmap -p 102 --script s7-info 127.0.0.1
```

https://raw.githubusercontent.com/nmap/nmap/master/scripts/

## HTML レポートの出力

`-oX` で XML を出力し、nmap 同梱のスタイルシートで HTML に変換します。

```bash
nmap -p 502,1880,1883,4840,8000 \
  --script modbus-discover,./node-red.nse,./mqtt.nse,./opcua.nse,http-date \
  -oX scan.xml 127.0.0.1
xsltproc -o scan.html /usr/share/nmap/nmap.xsl scan.xml
```

`xsltproc` は `scripts/install.sh` が導入します。
`scan.html` をブラウザで開くと、ポートごとにスクリプトの出力がまとまった形で確認できます。

## ファイル

| ファイル | 内容 |
| --- | --- |
| `mock_servers/modbus_server.py` | pymodbus によるModbus/TCPサーバ |
| `mock_servers/opcua_server.py` | opcua によるOPC UAサーバ |
| `mock_servers/codesys_server.py` | CoDeSys V2 の識別要求に応答するサーバ |
| `mock_servers/mqtt_publisher.py` | MQTT に retain 付きでトピックを配信する |
| `mock_servers/s7_server.py` | s7-info に応答する S7comm サーバ |
| `mock_servers/http_clockskew_server.py` | 時刻をずらした Date を返す HTTP サーバ |
| `mock_servers/profinet-server.py` | PROFINET DCP に応答するサーバ(raw socket 実装) |
| `mock_servers/profinet-server2.py` | 同上を scapy で実装したもの |
| `scripts/mosquitto-auth.conf` | 認証必須の MQTT ブローカの設定 |
| `scripts/dnsmasq.conf` | テスト用 DHCP サーバの設定 |
| `scripts/dhcp-start.sh` | veth と名前空間を用意して dnsmasq を起動する |
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
| `tests/codesys.sh` | codesys-v2-discover の出力を検証する |
| `tests/report.sh` | HTML レポートを生成して内容を検証する |
| `tests/test.sh` | 起動とスキャン結果の検証 |

