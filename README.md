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

両方をまとめて実行します。

```bash
bash test.sh
```

## ファイル

| ファイル | 内容 |
| --- | --- |
| `modbus_server.py` | pymodbus によるModbus/TCPサーバ |
| `node-red.nse` | Node-RED の /diagnostics を参照するNSEスクリプト |
| `install.sh` | nmap / pymodbus / Node-RED の導入 |
| `start.sh` | Modbusサーバと Node-RED の起動 |
| `test.sh` | 起動とスキャン結果の検証 |

## テスト

`test.sh` はサーバを起動し、nmap の出力に期待する文字列が含まれるかを検証します。
ポートが60秒以内に開かない場合や、スキャン結果が期待と異なる場合は異常終了します。

GitHub Actions は Codespaces と同じ `universal:2-linux` イメージを、
Codespaces と同じ root ユーザで実行します。
実行条件を揃えることで、片方だけで動くという状態を防ぎます。
