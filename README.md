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
| `setup.sh` | nmap / pymodbus / Node-RED の導入 |
| `start.sh` | Modbusサーバと Node-RED の起動 |
| `test.sh` | 起動とスキャンの実行 |
