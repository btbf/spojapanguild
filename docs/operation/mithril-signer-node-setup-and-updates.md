# **Mithril Signerノードの設定、更新**

このマニュアルは、Stake Pool Operator（SPO）がCardano メインネット上で `Mithril Signer` を安全に運用するための設定および更新手順をまとめたものです。  

!!! info "インストールバージョン"
    | Node | Mithril-signer | squid |
    | :---------- | :---------- | :---------- |
    | 10.5.3 | 0.2.276 | 7.3 |

## **1. Mithril Signerの設定**

### **1-1. BPにMithril Signerのインストール**

!!! info "補足"
    **`Mithril Signer`**は、ブロック生成ノード（BP）が保持する`KES鍵`を用いて署名を行うため、BP上で稼働させる必要があります。

ビルド済みバイナリファイルダウンロード

=== "ブロックプロデューサー"

システムのアップデート
```bash
sudo apt update -y && sudo apt upgrade -y
```

作業ディレクトリの作成
```bash
mkdir -p $HOME/mithril
```

ビルド済みバイナリのダウンロード
```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/input-output-hk/mithril/refs/heads/main/mithril-install.sh | sh -s -- -c mithril-signer -d 2543.1-hotfix -p $HOME/git/mithril
```

`bin`ディレクトリへコピー
```bash
sudo cp $HOME/git/mithril/mithril-signer /usr/local/bin/mithril-signer
```

バージョン確認
```bash
mithril-signer -V
```
> mithril-signer 0.2.276+5d5571e

#### **ENV変数の設定**

=== "ブロックプロデューサー"

パラメータ値算出
```bash
era_params=$(jq -nc --arg address $(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/era.addr) --arg verification_key $(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/era.vkey) '{"address": $address, "verification_key": $verification_key}')
```

BPから接続するリレーIPを指定
```bash
relay_ip=xx.xxx.xx.xx
```

envファイル作成
```bash
cat > $HOME/mithril/mithril-signer.env << EOF
KES_SECRET_KEY_PATH=$NODE_HOME/kes.skey
OPERATIONAL_CERTIFICATE_PATH=$NODE_HOME/node.cert
NETWORK=mainnet
AGGREGATOR_ENDPOINT=https://aggregator.release-mainnet.api.mithril.network/aggregator
RUN_INTERVAL=60000
DB_DIRECTORY=$NODE_HOME/db
CARDANO_NODE_SOCKET_PATH=$NODE_HOME/db/socket
CARDANO_CLI_PATH=/usr/local/bin/cardano-cli
DATA_STORES_DIRECTORY=$HOME/mithril/stores
STORE_RETENTION_LIMIT=5
ERA_READER_ADAPTER_TYPE=cardano-chain
ERA_READER_ADAPTER_PARAMS=$era_params
RELAY_ENDPOINT=http://${relay_ip}:3132
ENABLE_METRICS_SERVER=true
METRICS_SERVER_IP=0.0.0.0
METRICS_SERVER_PORT=61234
EOF
```

#### **サービスファイル作成**

=== "ブロックプロデューサー"

```bash
cat > $HOME/mithril/mithril-signer.service << EOF
[Unit]
Description=Mithril Signer service
BindsTo=cardano-node.service
After=cardano-node.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=60
User=${USER}
EnvironmentFile=$HOME/mithril/mithril-signer.env
ExecStart=/usr/local/bin/mithril-signer -vvv

[Install]
WantedBy=cardano-node.service
EOF
```

```bash
sudo cp $HOME/mithril/mithril-signer.service /etc/systemd/system/mithril-signer.service
```

```bash
sudo chmod 644 /etc/systemd/system/mithril-signer.service
```

```bash
sudo systemctl daemon-reload
```

```bash
sudo systemctl enable mithril-signer
```

### **1-2. Mithrilリレーノードのセットアップ**

!!! info "説明"
    Mithril Signer はアグリゲーターとの通信を行いますが、**セキュリティおよびネットワーク分離の観点から、BP から直接インターネット通信を行わず、Relay ノード上で Squid をフォワードプロキシとして動作させ、中継通信を行います。**


=== "リレーノード"

システムのアップデート
```bash
sudo apt update -y && sudo apt upgrade -y
```

`squid`のインストール
```bash
cd $HOME
wget https://github.com/squid-cache/squid/releases/download/SQUID_7_3/squid-7.3.tar.gz
```

```bash
tar xzf squid-7.3.tar.gz
cd squid-7.3
```

`squid`のビルド
```bash
./configure \
    --prefix=/opt/squid \
    --localstatedir=/opt/squid/var \
    --libexecdir=/opt/squid/lib/squid \
    --datadir=/opt/squid/share/squid \
    --sysconfdir=/etc/squid \
    --with-default-user=squid \
    --with-logdir=/opt/squid/var/log/squid \
    --with-pidfile=/opt/squid/var/run/squid.pid
```

```bash
make
```

インストールコマンドの実行
```bash
sudo make install
```

`squid`のバージョン確認
```bash
/opt/squid/sbin/squid -v
```

戻り値
``` { .yaml .no-copy }
Squid Cache: Version 7.3
Service Name: squid
configure options:  '--prefix=/opt/squid' '--localstatedir=/opt/squid/var' '--libexecdir=/opt/squid/lib/squid' '--datadir=/opt/squid/share/squid' '--sysconfdir=/etc/squid' '--with-default-user=squid' '--with-logdir=/opt/squid/var/log/squid' '--with-pidfile=/opt/squid/var/run/squid.pid' 'PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:'
```

インストールファイルの削除
```bash
cd $HOME
rm squid-7.3.tar.gz
rm -rf squid-7.3
```

`squid`のアカウント作成
```bash
sudo adduser --system --no-create-home --group squid
```

アクセス権限の付与
```bash
sudo chown squid -R /opt/squid/var/
```
```bash
sudo chgrp squid -R /opt/squid/var/
```

#### **`squid`のサービスファイル作成**

=== "リレーノード"

Mithril用の`squid`設定ファイルの作成
```bash
cat > $HOME/squid.service << EOF
[Unit]
Description=Squid service
BindsTo=cardano-node.service
After=cardano-node.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=60
User=squid
Group=squid
ExecStart=/opt/squid/sbin/squid -f /etc/squid/squid.conf
PIDFile=/opt/squid/var/run/squid.pid

[Install]
WantedBy=cardano-node.service
EOF
```

サービスファイルの設定
```bash
sudo cp $HOME/squid.service /etc/systemd/system/squid.service
```
```bash
sudo systemctl daemon-reload
```
```bash
sudo systemctl enable squid
```

リレーから接続するBPIPを指定
```bash
bp_ip=xx.xxx.xx.xx
```

`squid`の設定ファイル作成
```bash
cat > $HOME/squid.conf << EOF
# Listening port (port 3132 is recommended)
http_port 3132

# ACL for internal IP of your block producer node
acl block_producer_internal_ip src $bp_ip

# ACL for aggregator endpoint
acl aggregator_domain dstdomain .mithril.network

# ACL for SSL port only
acl SSL_port port 443

# Allowed traffic
http_access allow block_producer_internal_ip aggregator_domain SSL_port

# Do not disclose block producer internal IP
forwarded_for delete

# Turn off via header
via off
 
# Deny request for original source of a request
follow_x_forwarded_for deny all
 
# Anonymize request headers
request_header_access Authorization allow all
request_header_access Proxy-Authorization allow all
request_header_access Cache-Control allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Connection allow all
request_header_access All deny all

# Disable cache
cache deny all

# Deny everything else
http_access deny all
EOF
```
```bash
sudo mv $HOME/squid.conf /etc/squid/squid.conf
```

ファイアウォール設定
```bash
sudo ufw allow from $bp_ip to any port 3132 proto tcp
```
ファイアウォールの再起動
```bash
sudo ufw reload
```
`squid`の起動
```bash
sudo systemctl start squid
```
`squid`の起動確認
```bash
sudo systemctl status squid --no-pager
```
> Activeが `active (running)` になっていること

=== "ブロックプロデューサー"

`mithril-signer`の起動
```bash
sudo systemctl start mithril-signer
```
ログの確認
```bash
journalctl -u mithril-signer -f --output=cat
```

以上で、署名者登録が完了しました。  
スナップショットに署名するのは2エポック後からとなります。

### **1-3. Mithril-Signerの動作確認**
インストール後にアグリゲーターに正常に登録されているかを確認します。

=== "ブロックプロデューサー"

```bash
cd $HOME/mithril
wget https://mithril.network/doc/scripts/verify_signer_registration.sh
```
```bash
chmod +x verify_signer_registration.sh
```
```bash
PARTY_ID=$(cat $NODE_HOME/pool.id-bech32) AGGREGATOR_ENDPOINT=https://aggregator.release-mainnet.api.mithril.network/aggregator $HOME/mithril/verify_signer_registration.sh
```

!!! tip "登録確認"
    正常の場合
    ``` { .yaml .no-copy }
    >> Congrats, your signer node is registered!
    ```
    未登録の場合
    ``` { .yaml .no-copy }
    >> Oops, your signer node is not registered. Party ID not found among the signers registered at epoch ***.
    ```

### **1-4. 便利なエイリアス設定**

=== "ブロックプロデューサー"

!!! tip "エイリアス設定"
    ブロックプロデューサー（BP）上で、短いコマンドで`Mithril Signer`のログをリアルタイム確認できるようにします。
    ```bash
    echo alias mithril='"journalctl -u mithril-signer -f --output=cat"' >> $HOME/.bashrc
    source $HOME/.bashrc
    ```

    設定後は、以下のコマンドを実行するだけで、`Mithril Signer`の起動状態（ログ）をリアルタイムで確認できます。
    ``` { .yaml .no-copy }
    mithril ・・・ログ表示
    ```

### **1-5. Grafanaダッシュボード設定**

=== "ブロックプロデューサー"

`xxx.xxx.xxx.xx`をGrafana導入サーバーのIPに置き換えて実行
```bash
sudo ufw allow from xxx.xxx.xxx.xx to any port 61234
```
```bash
sudo ufw reload
```

=== "Grafana導入サーバー"

`Prometheus`設定ファイルの編集
```bash
sudo nano /etc/prometheus/prometheus.yml
```

以下の`xxx.xxx.xxx.xxx`を`Mithril-signer`が稼働しているBPのIPに置き換えて`prometheus.yml`ファイルの最後の行に追加
```bash
      - targets: ['xxx.xxx.xxx.xxx:61234']
        labels:
          alias: 'BP-signer'
          type:  'Mithril-signer'
```

`prometheus.yml`の構文チェック
```bash
sudo promtool check config /etc/prometheus/prometheus.yml
```
!!! tip "戻り値確認"
    構文エラーなしの場合
    ```{ .yaml .no-copy }
    Checking /etc/prometheus/prometheus.yml
    SUCCESS: 0 rule files found
    ```

    構文エラーの場合(一例)
    ```{ .yaml .no-copy }
    Checking /etc/prometheus/prometheus.yml
    FAILED: parsing YAML file /etc/prometheus/prometheus.yml: yaml: line XX: did not find expected '-' indicator
    ```
    `/etc/prometheus/prometheus.yml`ファイルを開いて余分なスペースや記号の有無などを確認してください。

`Prometheus`サービスの再起動
```
sudo systemctl restart prometheus.service
```

=== "ブロックプロデューサー"

Mithril-signer用のダッシュボードファイルをダウンロード
```bash
curl -s -o $NODE_HOME/Mithril-Signer-on-SJG-Grafana-dashboard.json https://raw.githubusercontent.com/akyo3/Extends-SJG-Knowledge/refs/heads/main/Mithril-Signer-on-SJG-Grafana-dashboard.json
```

ファイル内容の置換
```bash
sed -i $NODE_HOME/Mithril-Signer-on-SJG-Grafana-dashboard.json \
    -e "s/bech32_id_of_your_pool/$(cat $NODE_HOME/pool.id-bech32)/g"
```

!!! info "ファイル転送"
    BPのcnodeディレクトリに取得した`Mithril-Signer-on-SJG-Grafana-dashboard.json`をローカルのホストマシンにダウンロードします。
    ```mermaid
    graph LR
        A[BP] -->|**Mithril-Signer-on-SJG-Grafana-dashboard.json**| B[ローカルのホストマシン];
    ``` 

Grafanaの左メニューから「`Dashboards`」を開き、「`New`」→「`Import`」→「`Upload dashboard JSON file`」を選択し、ダウンロードした `Mithril-Signer-on-SJG-Grafana-dashboard.json` を指定します。  

データソースの割り当て画面では、  

- `Prometheus` には `Prometheus`  
- `yesoreyeram-infinity-datasource` には `yesoreyeram-infinity-datasource`  

をそれぞれ選択してください。

設定内容を確認後、「`Import`」を選択するとダッシュボードが読み込まれます。


## **2. Mithril Signerの更新**

### **2-1. BPのMithril Signer更新**

=== "ブロックプロデューサー"

システムのアップデート
```bash
sudo apt update -y && sudo apt upgrade -y
```

`mithril-signer`の停止
```bash
sudo systemctl stop mithril-signer
```

既存ファイルの削除
```bash
rm -rf $HOME/git/mithril/*
```

ビルド済みバイナリファイルのダウンロード
```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/input-output-hk/mithril/refs/heads/main/mithril-install.sh | sh -s -- -c mithril-signer -d 2543.1-hotfix -p $HOME/git/mithril
```

`bin`ディレクトリへコピー
```bash
sudo cp $HOME/git/mithril/mithril-signer /usr/local/bin/mithril-signer
```

バージョン確認
```bash
mithril-signer -V
```
> mithril-signer 0.2.276+5d5571e

`mithril-signer`の起動
```bash
sudo systemctl start mithril-signer
```

起動から約3分後に`Signer`の登録を確認 
```bash
curl -s localhost:61234/metrics | grep ^mithril_signer_signer_registration_success
```

!!! info "Signer登録成功の戻り値"
    ```{ .yaml .no-copy }
    mithril_signer_signer_registration_success_last_epoch  (現在のエポック）
    mithril_signer_signer_registration_success_since_startup 1
    ```

    !!! tip "上記の戻り値が確認できない場合は5分後にログを確認"
        ```bash
        journalctl -u mithril-signer -f --output=cat
        ```

### **2-2. リレーノードのMithril Signer更新**

=== "リレーノード"

**`Squid`のアップデート**

バージョン確認
```bash
/opt/squid/sbin/squid -v | grep Version
```

!!! tip "ヒント"
    `Squid Cache: Version 7.3` の戻り値がある場合、以降実施不要です。

`squid`の停止
```bash
sudo systemctl stop squid
```
```bash
sudo systemctl disable squid
```

システムアップデート
```bash
sudo apt update -y && sudo apt upgrade -y
```

`squid7.3`のインストール
```bash
cd $HOME
wget https://github.com/squid-cache/squid/releases/download/SQUID_7_3/squid-7.3.tar.gz
```

```bash
tar xzf squid-7.3.tar.gz
cd squid-7.3
```

`squid`のビルド
```bash
./configure \
    --prefix=/opt/squid \
    --localstatedir=/opt/squid/var \
    --libexecdir=/opt/squid/lib/squid \
    --datadir=/opt/squid/share/squid \
    --sysconfdir=/etc/squid \
    --with-default-user=squid \
    --with-logdir=/opt/squid/var/log/squid \
    --with-pidfile=/opt/squid/var/run/squid.pid
```

```bash
make
```

```bash
sudo make install
```

`squid`のバージョン確認
```bash
/opt/squid/sbin/squid -v | grep Version
```

戻り値
``` { .yaml .no-copy }
Squid Cache: Version 7.3
```

`squid`のサービス有効化
```bash
sudo systemctl enable squid
```

`squid`サービスの起動
```bash
sudo systemctl start squid
```

インストールファイルの削除
```bash
cd $HOME
rm squid-7.3.tar.gz
rm -rf squid-7.3
```