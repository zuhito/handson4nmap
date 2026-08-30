# handson4nmap

nmap の NSE スクリプトを試すためのハンズオン環境です。
Codespaces を開くと Modbus/TCP サーバ (502) と Node-RED (1880) が自動起動します。

## nmap コマンド

Modbus のスレーブIDとデバイス情報を列挙します。

```bash
nmap -p 502 --script modbus-discover 127.0.0.1
```

sid を最後まで列挙する場合は次のようにします。

```bash
nmap -p 502 --script modbus-discover --script-args='modbus-discover.aggressive=true' 127.0.0.1
```

Node-RED の診断エンドポイントからバージョン情報を取得します。

```bash
nmap -p 1880 --script ./node-red.nse 127.0.0.1
```

httpAdminRoot を変更している場合は root を指定します。

```bash
nmap -p 1880 --script ./node-red.nse --script-args='node-red.root=/admin' 127.0.0.1
```

OPC UA サーバのエンドポイントと認証方式を取得します。

```bash
nmap -p 4840 --script ./opcua.nse 127.0.0.1
```

OpenVPN サーバのセッション情報を取得します。

```bash
nmap -p 1194 --script ./openvpn.nse <host>
nmap -sU -p 1194 --script ./openvpn.nse <host>
```

PROFINET 機器を DCP のマルチキャストで探索します。root 権限が必要です。

```bash
nmap --script ./external/multicast-profinet-discovery.nse
```

このスクリプトは nmap 本体に同梱されていないため、`scripts/install.sh` が `scripts/profinet-nse.sh` 経由で
上流から取得し、古い nmap 向けの互換パッチを当てて `external/` に配置します。

まとめて実行します。

```bash
bash scripts/test.sh
```

## ファイル

| ファイル | 内容 |
| --- | --- |
| `mock_servers/modbus_server.py` | pymodbus によるModbus/TCPサーバ |
| `mock_servers/opcua_server.py` | opcua によるOPC UAサーバ |
| `mock_servers/profinet-server.py` | PROFINET DCP に応答するサーバ |
| `scripts/openvpn-udp.conf` / `scripts/openvpn-tcp.conf` | テスト用 OpenVPN サーバの設定 |
| `scripts/profinet-nse.sh` | 上流の multicast-profinet-discovery を取得する |
| `node-red.nse` | Node-RED の /diagnostics を参照するNSEスクリプト |
| `opcua.nse` | OPC UA の GetEndpoints を実行するNSEスクリプト |
| `openvpn.nse` | OpenVPN の制御チャネルを叩くNSEスクリプト |
| `scripts/install.sh` | nmap / pymodbus / Node-RED の導入 |
| `scripts/start.sh` | 各サーバの起動 |
| `scripts/test.sh` | 起動とスキャン結果の検証 |

## テスト

`test.sh` はサーバを起動し、nmap の出力に期待する文字列が含まれるかを検証します。
ポートが60秒以内に開かない場合や、スキャン結果が期待と異なる場合は異常終了します。

GitHub Actions は Codespaces と同じ `universal:2-linux` イメージを、
Codespaces と同じ root ユーザで実行します。
実行条件を揃えることで、片方だけで動くという状態を防ぎます。
