# BPサーバーの引越し手順（旧VPS会社→新VPS会社）


!!! tip "前提注意事項"
    * 本まとめは現VPS会社→新VPS会社へと `BPのみ` を移行するまとめです。
    * 実際に行う際には手順をよく読みながら進めてください。
    * ブロック生成予定まで余裕がある時に実施してください。
    * 旧BPは[2-4. 旧BPノード停止](./#2-4-bp)まで、**起動状態** にしておいてください。


## **1.Ubuntu初期設定**

1-1. 新サーバーで[Ubuntu初期設定](../../setup/1-ubuntu-setup/#0-3)を実施します。  

!!! info "留意事項"
    1. サーバ独自機能に留意する
        * さくらのパケットフィルタや、AWSのFW設定などのサーバー独自の機能に気を付けてください。
    2. 新BPのファイヤーウォール設定は、旧BPと同じ設定にしてください。
    3. 旧BPのユーザー名（例：ubuntu）と新BPのユーザー名は変更しないでください。
        * もし変更する場合は、以下のファイル内のパス名を手動で変更してください。
        * `startBlockProducingNode.sh` DIRECTORY=/home/ユーザー名/cnode

## **2.セットアップ**

### 2-1.インストール 
[依存関係インストール](../../setup/2-node-setup/#2-1-cabalghc) 〜
[gLiveViewのインストール](../../setup/2-node-setup/#2-7-gliveview)まで実施します。


### 2-2. 旧BPトポロジー引継ぎ
旧BPのcnodeディレクトリにある`mainnet-topology.json`を新BPのcnodeディレクトリにコピーし、新BPのノードを再起動します。
``` mermaid
graph LR
    A[旧BP] -->|mainnet-topology.json| B[新BP];
``` 

=== "新BP"
    ノード再起動
    ```
    sudo systemctl reload-or-restart cardano-node
    ```
    ノードログ確認
    ```
    journalctl --unit=cardano-node --follow
    ```

### 2-3. リレートポロジー情報変更 
 
=== "手動P2Pの場合"
    !!! tip ""
        === "リレーノード"
        ```
        nano $NODE_HOME/relay-topology_pull.sh
        ```
        旧BPのIPとポートを新BPのIPとポートに変更する

        * BLOCKPRODUCING_IP=xxx.xxx.xxx
        * BLOCKPRODUCING_PORT=xxxx

    relay-topology_pull.shを実行し、リレーノードを再起動します。  

    ```
    cd $NODE_HOME
    ./relay-topology_pull.sh
    ```
    ノード再起動
    ```
    sudo systemctl reload-or-restart cardano-node
    ```
    > リレーが最新ブロックと同期するまでお待ち下さい

=== "ダイナミックP2Pの場合"

    ```
    nano $NODE_HOME/${NODE_CONFIG}-topology.json
    ```
    > 旧BPのIPとポートを新BPのIPとポートに変更する

    トポロジーファイルの再読み込み
    ```
    kill -SIGHUP $(pidof cardano-node)
    ```
    > ダイナミックP2P有効時、トポロジーファイル変更による再起動は不要です。

!!! danger "旧BPのIP記載について"
    このマニュアルの流れで旧BPは停止状態になりますが、万が一起動状態になりBP2重起動によるブロック伝播を防ぐため旧BPのIPはリレートポロジーに記載しないものとします。

### 2-4. 旧BPノード停止

=== "旧BP"

    ```
    sudo systemctl stop cardano-node
    ```
    ```
    sudo systemctl disable cardano-node
    ```
    > ここで`旧BP`とリレーとの接続が切れます。  
    > 旧BPのノードが絶対に起動しないようにVPS管理コンソールからサーバーを停止しておいてください。



### 2-5. 新BP接続確認
gLiveViewで新BPとリレーの双方向の疎通(I/O)ができているかを確認します。

=== "新BP"
    gLiveView確認
    ```
    cd $NODE_HOME/scripts
    ./gLiveView.sh
    ```
    > InとOutにリレーのIPがあることを確認してください。


### 2-6. 旧BPファイル移動

**参考）移行ファイル一覧**

| ファイル名 | 用途 |
:----|:----
| vrf.skey | ブロック生成に必須 |
| vrf.vkey | ブロック生成に必須 |
| kes.skey | ブロック生成に必須 |
| kes.vkey | KES公開鍵 |
| node.cert | ブロック生成に必須 |
| payment.addr | 残高確認で必要 |
| stake.addr | 残高確認で必要 |
| poolMetaData.json | pool.cert作成時に必要 |
| poolMetaDataHash.txt | pool.cert作成時に必要 |
| startBlockProducingNode.sh | ノード起動スクリプト |
| pool.id-bech32 | stakepoolid(bech32形式) |
| pool.id | stakepoolid(hex形式) |
| guild-db | ブロックログ関連フォルダ(cncli.db以外) |

上記の移行ファイルを一つのファイルに圧縮する
=== "旧BP"
    ```
    cd $NODE_HOME
    tar --exclude "guild-db/cncli/cncli.db" -acvf bp-move.zst guild-db/ vrf.skey vrf.vkey kes.skey kes.vkey node.cert payment.addr stake.addr poolMetaData.json poolMetaDataHash.txt startBlockProducingNode.sh pool.id-bech32 pool.id
    ```

旧BPのcnodeにある`bp-move.zst`を新BPのcnodeディレクトリにコピーする
``` mermaid
graph LR
    A[旧BP] -->|bp-move.zst| B[新BP];
``` 

=== "新BP"
    ```
    ls $NODE_HOME/bp-move.zst
    ```
    > ファイルパスが表示されることを確認する。  
    > 例）`/home/cardano/cnode/move/bp-move.zst`
    
    ファイルを展開する
    ```
    cd $NODE_HOME
    tar -xvf bp-move.zst
    ```
    > 戻り値に移行ファイル一覧のファイル名が表示されることを確認する

### 2-7. パーミッション変更
=== "新BP"
    ```
    cd $NODE_HOME
    chmod 400 vrf.skey
    chmod 400 vrf.vkey
    chmod +x startBlockProducingNode.sh
    ```

    2-7. ノードを再起動します。
    ```
    sudo systemctl reload-or-restart cardano-node
    ```
    ノードログ確認
    ```
    journalctl --unit=cardano-node --follow
    ```

### 2-8. params.json再作成

=== "新BP"
```
cd $NODE_HOME
cardano-cli query protocol-parameters \
    --mainnet \
    --out-file params.json
```

### 2-9. ブロックログ設定

- [ステークプールブロックログ導入手順](../../setup/10-blocklog-setup/)

!!! danger "注意"
    「10-6. 過去のブロック生成実績取得」は実施しないでください。


### 2-10. SJGツール導入

- [SPO JAPAN GUILD TOOL](../../operation/tool/#spo-japan-guild-tool)


### 2-11. ブロック生成状態チェック

SJGツールを起動し、「[2] ブロック生成状態チェック」ですべての項目がOKになることを確認する

### 2-12. ブロック生成ステータス通知設定

=== "旧BPで導入済みの場合"
    依存環境インストール
    === "新BP"
    ```
    sudo apt install -y python3-watchdog python3-tz python3-dateutil python3-requests build-essential libssl-dev libffi-dev python3-dev python3-pip
    ```
    ```
    pip install discordwebhook python-dotenv slackweb
    ```
    パーミッション変更
    ```
    chmod +x $NODE_HOME/guild-db/blocklog/block_check.py
    ```
    サービスファイル作成
    ```
    cat > $NODE_HOME/service/cnode-blockcheck.service << EOF 
    # file: /etc/systemd/system/cnode-blockcheck.service

    [Unit]
    Description=Cardano Node - CNCLI blockcheck
    BindsTo=cnode-cncli-sync.service
    After=cnode-cncli-sync.service

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    Restart=on-failure
    RestartSec=20
    User=$(whoami)
    WorkingDirectory=$NODE_HOME
    ExecStart=/usr/bin/tmux new -d -s blockcheck
    ExecStartPost=/usr/bin/tmux send-keys -t blockcheck 'cd $NODE_HOME/guild-db/blocklog' Enter
    ExecStartPost=/usr/bin/tmux send-keys -t blockcheck python3 Space block_check.py Enter
    ExecStop=/usr/bin/tmux kill-session -t blockcheck
    KillSignal=SIGINT
    RestartKillSignal=SIGINT
    SuccessExitStatus=143
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=cnode-blockcheck
    TimeoutStopSec=5

    [Install]
    WantedBy=cnode-cncli-sync.service
    EOF
    ```
    ```
    sudo cp $NODE_HOME/service/cnode-blockcheck.service /etc/systemd/system/cnode-blockcheck.service
    sudo chmod 644 /etc/systemd/system/cnode-blockcheck.service
    ```
    ```
    sudo systemctl daemon-reload
    sudo systemctl enable cnode-blockcheck.service
    ```

=== "旧BPで未導入の場合"
    
    [ブロック生成ステータス通知セットアップ](../setup/11-blocknotify-setup.md)から導入してください。


### 2-13. Prometheus設定

- 新BPにて`prometheus node exporter`をインストールします。

=== "新BP"
    ```
    sudo apt install -y prometheus-node-exporter
    ```

    サービスを有効にして、自動的に開始されるように設定します。
    ```
    sudo systemctl enable prometheus-node-exporter.service
    ```
    
    ノード再起動
    ```
    sudo systemctl reload-or-restart cardano-node
    ```

`prometheus.yml`の修正  

=== "Grafanaサーバー(リレー1)"
    ```
    sudo nano /etc/prometheus/prometheus.yml
    ```
    > * 旧BPのIPを新BPのIPへ変更してください

    サービス再起動
    ```
    sudo systemctl restart grafana-server.service
    sudo systemctl restart prometheus.service
    sudo systemctl restart prometheus-node-exporter.service
    ```

    サービスが正しく実行されていることを確認します。
    ```
    sudo systemctl --no-pager status grafana-server.service prometheus.service prometheus-node-exporter.service
    ```

    GrafanaにBPのメトリクス(KESなど)が表示されているか確認する。

---
### 補足
- Txの増加が確認できたらTracemempoolを無効にします。

=== "新BP"
```
sed -i $NODE_HOME/${NODE_CONFIG}-config.json \
    -e "s/TraceMempool\": true/TraceMempool\": false/g"
```

ノード再起動
```
sudo systemctl reload-or-restart cardano-node
```

