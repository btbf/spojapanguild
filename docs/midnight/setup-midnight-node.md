
# **Midnightバリデーターを起動する**

本ドキュメントは、Midnightバリデーターサーバで行うMidnight-node起動の手順です。  

## **PostgreSQL 接続設定**
###　Midnightバリデーターサーバで実行
=== "Midnightバリデーターサーバ"
    ``` bash
    FW_ALLOW_HOST="$(curl -s https://api.ipify.org)"
    echo "FW_ALLOW_HOST=${FW_ALLOW_HOST}"
    ```
    > 上記のコマンド実行した戻り値を<font color=red>インデクサーサーバー↓</font>で実行してください。

### インデクサーサーバーで実行

=== "インデクサーサーバー"
    ``` {.yaml .no-copy}
    FW_ALLOW_HOST=***.**.**.**
    # 上記Midnight-nodeサーバで表示されたコマンドを実行する
    ```
    
    postgreSQLポート許可
    ```bash
    sudo ufw allow from ${FW_ALLOW_HOST} to any port 5432
    ```
    > 戻り： Rule added

    ``` bash
    sudo ufw reload
    ```
    > 戻り：Firewall reloaded

    postgreSQLログイン許可設定
    ``` bash
    echo "hostssl cexplorer $(whoami) ${FW_ALLOW_HOST}/32 scram-sha-256" | \
    sudo tee -a /etc/postgresql/17/main/pg_hba.conf > /dev/null
    ```
    ```{ .yaml .no-copy py title="戻り値"} 
    hostssl cexplorer <Midnight-nodeユーザーID> <Midnight-nodeサーバIP>/32 scram-sha-256
    ```

    postgresql再起動
    ```bash
    sudo systemctl restart postgresql
    ```

    !!! important "ファイル転送"
        インデクサーサーバーの`$HOME`直下にある`.pgpass`をMidnight-nodeサーバの`$HOME/midnight`ディレクトリにコピーします。
        ``` mermaid
        graph LR
            A[インデクサーサーバー] -->|.pgpass| B[Midnight-nodeサーバ];
        ```
        .pgpassファイルは必ず`$HOME`(ユーザーディレクトリ直下)に配置してください

## PostgreSQL接続チェック

=== "Midnightバリデーターサーバ"
    `.pgpass`ファイルパーミッション変更
    ```
    chmod 600 $HOME/.pgpass
    ```

    接続テスト
    ```
    PGPASS_LINE=$(cat $HOME/.pgpass)
    DBSYNC_HOST=$(echo "$PGPASS_LINE" | cut -d: -f1)
    DBSYNC_USER=$(echo "$PGPASS_LINE" | cut -d: -f4)
    psql "postgresql://${DBSYNC_USER}@${DBSYNC_HOST}:5432/cexplorer?sslmode=require"
    ```
    ``` { .yaml .no-copy py title="戻り値"} 
    psql (17.7 (Ubuntu 17.7-3.pgdg22.04+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off, ALPN: postgresql)
    # ↑この文言があればSSL/TSL通信が確立しています！
    Type "help" for help.

    cexplorer=# \q ← で終了できます
    ```

## **起動パラメータファイル作成**
=== "Midnightバリデーターサーバ"

    postgreSQL接続情報取得
    ```
    PGPASS_LINE=$(cat $HOME/.pgpass)
    DBSYNC_HOST=$(echo "$PGPASS_LINE" | cut -d: -f1)
    DBSYNC_USER=$(echo "$PGPASS_LINE" | cut -d: -f4)
    ```

    ```bash { py title="全てコピーして実行してください" }
    cat > $HOME/midnight/.env << EOF

    #ネットワーク
    CFG_PRESET=${MIDNIGHT_NETWORK}

    #Midnightキーディレクトリ
    BASE_PATH='$HOME/midnight/data'

    #パートナーチェーン固有パラメータファイル
    ADDRESSES_JSON=$HOME/midnight/${MIDNIGHT_NETWORK}-addresses.json

    #Midnight起動ポート番号
    MIDNIGHT_PORT=30333

    #cardano-db-syncデータ取得 PostgreSQL接続URI
    DB_SYNC_POSTGRES_CONNECTION_STRING="postgresql://${DBSYNC_USER}@${DBSYNC_HOST}:5432/cexplorer?sslmode=require"

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
● midnight-node.service - Midnight node service
     Loaded: loaded (/etc/systemd/system/midnight-node.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2025-12-30 07:18:14 UTC; 4h 42min ago
   Main PID: 212117 (midnight-node)
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


## **Midnight-Monitorインストール**

!!! hint "Midnight-monitor"
      - LiveViewノードモニタリング
      - Midnight-Blocklog スケジュール監視モード

![](../images/midnight-node/midnight-monitor.jpg)

LiveViewダウンロード
```bash
cd $HOME/midnight
wget -O ./LiveView.sh  https://raw.githubusercontent.com/btbf/Midnight-Live-View/refs/heads/main/LiveView.sh
chmod +x LiveView.sh
```

Midnight-blocklogインストール
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustup toolchain install stable
rustup default stable
rustc -V
cargo -V
```

```
sudo apt-get update
sudo apt-get install -y build-essential pkg-config libssl-dev
```

```
cd $HOME
release="$(curl -s https://api.github.com/repos/btbf/Midnight-blocklog/releases/latest | jq -r '.tag_name')"
```

```
git clone https://github.com/btbf/Midnight-blocklog.git
cd Midnight-blocklog
git checkout ${release}
cargo install --path . --bin mblog --locked --force
```

```
mblog --version
```
> 0.3.2



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
mkdir -p $HOME/.config/tmuxinator
cat > $HOME/.config/tmuxinator/midnight-monitor.yml << EOF 
---
name: midnight-monitor
project_root: "$HOME/midnight"
windows:
- bash:
    layout: even-horizontal
    panes:
    - cd $HOME/midnight; ./LiveView.sh
    - mblog block --keystore-path $HOME/midnight/data/chains/partner_chains_template/keystore --tz Asia/Tokyo --db $HOME/midnight/mblog.db --watch
EOF
```

モニターパネルを起動(アタッチ)
```bash
mux midnight-monitor
```

モニターパネルバックグラウンド移動(デタッチ)
> ++ctrl++ + ++b++ (離して) ++d++ 

再読み込みする場合
```bash
mux stop midnight-monitor
mux midnight-monitor
```

### **Midnight-blocklog使用方法**

スケジュール追跡モードは上記のMidnight-monitorで起動されていますが、他の使い方をご紹介します。

スケジュールJSON出力
```
# 現在 epoch のスケジュールを JSON 出力
mblog block --keystore-path $HOME/midnight/data/chains/partner_chains_template/keystore --tz UTC --output-json --current

# 次 epoch のスケジュールを JSON 出力
mblog block --keystore-path $HOME/midnight/data/chains/partner_chains_template/keystore --tz UTC --output-json --next
```

ブロック生成実績表示
```
# 最新の epoch（デフォルト）
mblog log --db $HOME/midnight/mblog.db

# epoch 指定
mblog log --db $HOEM/midnight/mblog.db --epoch 245525
```