
# **Midnightバリデーターを起動する**

## **起動パラメータファイル作成**
```bash { py title="全てコピーして実行してください" }
cat > $HOME/midnight/.env << EOF

#ネットワーク
CFG_PRESET=${MIDNIGHT_NETWORK}

#PostgreSQL認証ファイル
PGPASSFILE=$NODE_HOME/.pgpass

#Midnightキーディレクトリ
BASE_PATH='$HOME/midnight/data'

#パートナーチェーン固有パラメータファイル
ADDRESSES_JSON=$HOME/midnight/${MIDNIGHT_NETWORK}-addresses.json

#Midnight起動ポート番号
MIDNIGHT_PORT=30333

#cardano-db-syncデータ取得 PostgreSQL接続URI
DB_SYNC_POSTGRES_CONNECTION_STRING="postgresql:///cexplorer?host=/var/run/postgresql"

#Midnight-nodeシークレットキー
NODE_KEY="$(cat $HOME/midnight/data/chains/partner_chains_template/network/secret_ed25519)"

#カルダノセキュリティパラメータ
CARDANO_SECURITY_PARAMETER=432

#P2P接続先
BOOTNODES="/dns/boot-node-01.${MIDNIGHT_NETWORK}.midnight.network/tcp/30333/ws/p2p/12D3KooWMjUq13USCvQR9Y6yFzYNYgTQBLNAcmc8psAuPx2UUdnB \\
           /dns/boot-node-02.${MIDNIGHT_NETWORK}.midnight.network/tcp/30333/ws/p2p/12D3KooWR1cHBUWPCqk3uqhwZqUFekfWj8T7ozK6S18DUT745v4d \\
           /dns/boot-node-03.${MIDNIGHT_NETWORK}.midnight.network/tcp/30333/ws/p2p/12D3KooWQxxUgq7ndPfAaCFNbAxtcKYxrAzTxDfRGNktF75SxdX5"

#追加オプション
APPEND_ARGS="--validator --allow-private-ip --pool-limit 10 --trie-cache-size 0 --prometheus-external --rpc-methods=auto --rpc-port 9944 --public-addr /ip4/$(curl -4 -s ifconfig.me)/tcp/30333 --keystore-path=$HOME/midnight/data/chains/partner_chains_template/keystore/"

#ネットワークスペックファイルパス
CHAIN=$HOME/midnight/${MIDNIGHT_NETWORK}-chain-spec.json
EOF
```

## **Midnight-node起動設定**

systemdサービスファイル作成
``` bash { py title="全てコピーして実行してください" }
cat > $HOME/midnight/midnight-node.service << EOF 
[Unit]
Description     = Midnight node service
Wants           = network-online.target
After           = network-online.target 

[Service]
Type=simple
User=${USER}
WorkingDirectory=${HOME}/midnight
EnvironmentFile=${HOME}/midnight/.env

ExecStart="${HOME}/midnight/midnight-node"

KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=300
LimitNOFILE=32768
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=midnight-node

[Install]
WantedBy=multi-user.target
EOF
```

```bash
sudo cp $HOME/midnight/midnight-node.service /etc/systemd/system/midnight-node.service
```
```bash
sudo chmod 644 /etc/systemd/system/midnight-node.service
```

サービス有効化
``` bash { py title="1行づつ実行してください" }
sudo systemctl daemon-reload
sudo systemctl enable midnight-node
sudo systemctl start midnight-node
```

Midnightノード動作確認
```bash
sudo systemctl status midnight-node
```
```{ .yaml .no-copy py title="戻り値　Active: active"} 
● cardano-db-sync.service - Cardano DB Sync
     Loaded: loaded (/etc/systemd/system/cardano-db-sync.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2025-12-30 07:18:14 UTC; 4h 42min ago
   Main PID: 212117 (startDbSync.sh)
      Tasks: 18 (limit: 18679)
     Memory: 3.0G
        CPU: 3h 3min 55.713s
```

ログ確認
```bash
sudo journalctl -u midnight-node -f
```

``` { .yaml .no-copy py title="ログ状況"}
2025-12-31 05:56:14 Midnight Node    
2025-12-31 05:56:14 ✌️  version 0.12.0-29935d2f    
2025-12-31 05:56:14 ❤️  by Substrate DevHub <https://github.com/substrate-developer-hub>, 2017-2025    
2025-12-31 05:56:14 📋 Chain specification: testnet-02-1    
2025-12-31 05:56:14 🏷  Node name: madly-drug-7531    
2025-12-31 05:56:14 👤 Role: AUTHORITY    
2025-12-31 05:56:14 💾 Database: ParityDb at /home/cardano/midnight/data/chains/testnet-02/paritydb/full    
2025-12-31 05:56:14 Creating idx_tx_out_address index. This may take a while.  
```
> ↑この処理は少し時間がかかりますので動き出すまでしばらくお待ち下さい。  


## **Midnight-monitorインストール**

!!! hint "Midnight-monitor"
      - 各コンポーネント起動ステータス
      - LiveViewノードモニタリング
      - ブロック生成記録
      - Midnightログ表示

![](../images/midnight-node/midnight-monitor.jpg)

LiveView & Block-Monitorダウンロード
```bash
cd $HOME/midnight
wget -O ./LiveView.sh  https://raw.githubusercontent.com/btbf/Midnight-Live-View/refs/heads/main/LiveView.sh
wget -O ./simple_block_monitor.sh  https://raw.githubusercontent.com/btbf/Midnight-Live-View/refs/heads/main/simple_block_monitor.sh
chmod +x LiveView.sh simple_block_monitor.sh
```

依存関係インストール
```bash
sudo apt install ruby-rubygems
```
```bash
sudo gem install tmuxinator
```

環境変数追加
```bash
echo export EDITOR='nano' >> $HOME/.bashrc
echo alias mux=tmuxinator >> $HOME/.bashrc
source $HOME/.bashrc
```

bash保管ファイルDL
```bash
sudo wget https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.bash -O /etc/bash_completion.d/tmuxinator.bash
```

tmuxパネル設定ファイルDL
```bash { py title="全てコピーして実行してください" }
cat > $HOME/.config/tmuxinator/midnight-monitor.yml << EOF 
---
name: midnight-monitor
project_root: "$HOME/midnight"
windows:
- bash:
    layout: 1b3a,210x51,0,0[210x7,0,0,0,210x30,0,8{88x30,0,8,9,121x30,89,8,13},210x12,0,39,12]
    panes:
    - cd $HOME/midnight; ./midnight-status.sh
    - cd $HOME/midnight; ./LiveView.sh
    - cd $HOME/midnight; ./simple_block_monitor.sh run
    - TZ=UTC journalctl -u midnight-node -f --output=cat --since "$(date -u '+%Y-%m-%d %H:%M:%S')"
EOF
```

モニターパネルを起動(アタッチ)
```bash
mux midnight-monitor
```
> tmux拡張プログラムのため、++ctrl++ + ++b++ (離して) ++d++ でデタッチ可能です

再読み込みする場合
```bash
mux stop midnight-monitor
mux midnight-monitor
```

---