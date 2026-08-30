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

このスクリプトは nmap 本体に同梱されていないため、`scripts/install.sh` が `scripts/profinet-nse.sh` 経由で
上流から取得し、古い nmap 向けの互換パッチを当てて `external/` に配置します。

MQTT ブローカの情報を取得します。

```bash
nmap -p 1883 --script mqtt.nse 127.0.0.1
```

## ファイル

| ファイル | 内容 |
| --- | --- |
| `mock_servers/modbus_server.py` | pymodbus によるModbus/TCPサーバ |
| `mock_servers/opcua_server.py` | opcua によるOPC UAサーバ |
| `mock_servers/profinet-server.py` | PROFINET DCP に応答するサーバ(raw socket 実装) |
| `mock_servers/profinet-server2.py` | 同上を scapy で実装したもの |
| `scripts/mosquitto.conf` | テスト用 MQTT ブローカの設定 |
| `scripts/openvpn-udp.conf` / `scripts/openvpn-tcp.conf` | テスト用 OpenVPN サーバの設定 |
| `scripts/profinet-check.sh` | PROFINET の両実装を順に検証する |
| `scripts/profinet-nse.sh` | 上流の multicast-profinet-discovery を取得する |
| `node-red.nse` | Node-RED の /diagnostics を参照するNSEスクリプト |
| `opcua.nse` | OPC UA の GetEndpoints を実行するNSEスクリプト |
| `openvpn.nse` | OpenVPN の制御チャネルを叩くNSEスクリプト |
| `scripts/install.sh` | nmap / pymodbus / Node-RED の導入 |
| `scripts/start.sh` | 各サーバの起動 |
| `scripts/test.sh` | 起動とスキャン結果の検証 |

