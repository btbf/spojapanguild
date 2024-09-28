---
status: new
---
# BPサーバーの引越し手順（旧VPS会社→新VPS会社）


!!! tip "前提注意事項"
    * 本まとめは現VPS会社→新VPS会社へと `BPのみ` を移行するまとめです。
    * 実際に行う際には手順をよく読みながら進めてください。
    * ブロック生成予定まで余裕がある時に実施してください。
    * 旧BPは[3-3.旧BPシャットダウン](./bp-move.md#3-3bp)まで、**起動状態** にしておいてください。

## **1.新BPセットアップ**

!!! info "留意事項"
    1. サーバ独自機能に留意する
        * さくらのパケットフィルタや、AWSのFW設定などのサーバー独自の機能に気を付けてください。
    2. 新BPのファイヤーウォール設定は、旧BPと同じ設定にしてください。
    3. 旧BPのユーザー名（例：ubuntu）と新BPのユーザー名は変更しないでください。
        * もし変更する場合は、以下のファイル内のパス名を手動で変更してください。
        * `startBlockProducingNode.sh` DIRECTORY=/home/ユーザー名/cnode

### **1-1.Ubuntu初期設定**

新サーバーで[Ubuntu初期設定](../setup/1-ubuntu-setup.md)を実施します。  


### **1-2.ノードセットアップ**

1. [依存関係インストール](../setup/2-node-setup.md#2) 〜
[gLiveViewのインストール](../setup/2-node-setup.md#2-7-gliveview)まで実施します。
2. [リレーとBPを接続する](../setup/3-relay-bp-setup.md)の「BPの場合」を実施します。


## **2.既存リレー作業**
リレートポロジー情報変更 
 
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
    > gLiveviewでリレーが最新ブロックと同期することをご確認ください

=== "ダイナミックP2Pの場合"

    ```
    nano $NODE_HOME/${NODE_CONFIG}-topology.json
    ```
    > 旧BPのIPとポートを新BPのIPとポートに変更する

    トポロジーファイルの再読み込み
    ```
    cnreload
    ```
    > ダイナミックP2P有効時、トポロジーファイル変更による再起動は不要です。


## **3.旧BP移行処理**

### **3-1.旧BPノード停止**

=== "旧BP"

    ```
    sudo systemctl stop cardano-node
    ```
    ```
    sudo systemctl disable cardano-node
    ```  

### **3-2.旧BPファイル移動**

??? tio "**参考）移行ファイル一覧**"

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


=== "旧BP"

    Zstandardインストール
    ```
    sudo apt install zstd
    ```

    上記の移行ファイルを一つのファイルに圧縮する
    ```
    cd $NODE_HOME
    tar --exclude "guild-db/cncli/cncli.db" -acvf bp-move.zst guild-db/ vrf.skey vrf.vkey kes.skey kes.vkey node.cert payment.addr stake.addr poolMetaData.json poolMetaDataHash.txt startBlockProducingNode.sh pool.id-bech32 pool.id
    ```

旧BPのcnodeにある`bp-move.zst`を新BPのcnodeディレクトリにコピーする
``` mermaid
graph LR
    A[旧BP] -->|bp-move.zst| B[新BP];
``` 

## **4.新BP再設定**

### **4-1.移行ファイル復元**

=== "新BP"

    ノード停止
    ```
    sudo systemctl stop cardano-node
    ```

    ファイル確認
    ```
    ls $NODE_HOME/bp-move.zst
    ```
    > ファイルパスが表示されることを確認する。  
    > 例）`/home/cardano/cnode/bp-move.zst`
    
    ファイル展開
    ```
    cd $NODE_HOME
    tar -xvf bp-move.zst
    ```
    > 戻り値に移行ファイル一覧のファイル名が表示されることを確認する

    圧縮ファイルを削除する
    ```
    rm bp-move.zst
    ```

### **4-2. パーミッション変更**
=== "新BP"
    ```
    cd $NODE_HOME
    chmod 400 vrf.skey
    chmod 400 vrf.vkey
    chmod +x startBlockProducingNode.sh
    ```

    ノードを起動します。
    ```
    sudo systemctl start cardano-node
    ```
    ノードログ確認
    ```
    journalctl --unit=cardano-node --follow
    ```

### **4-3. 新BP接続確認**
gLiveViewで新BPが最新ブロックと同期後、リレーと疎通(I/O)ができているかを確認します。

=== "新BP"
    gLiveView確認
    ```
    cd $NODE_HOME/scripts
    ./gLiveView.sh
    ```
    > PeerリストにリレーのIPがあることを確認してください。

### **4-4. params.json再作成**

=== "新BP"
```
cd $NODE_HOME
cardano-cli conway query protocol-parameters \
    --mainnet \
    --out-file params.json
```

### **4-5. ブロックログ設定**

- [ステークプールブロックログ導入手順](../setup/10-blocklog-setup.md)

!!! danger "注意"
    「10-6. 過去のブロック生成実績取得」は実施しないでください。


### **4-6. SJGツール導入**

- [SPO JAPAN GUILD TOOL](../operation/tool.md)


### **4-7. ブロック生成状態チェック**

SJGツールを起動し、「[2] ブロック生成状態チェック」ですべての項目がOKになることを確認する

### **4-8. ブロック生成ステータス通知設定**
(SPO Block Notify)

=== "旧BPで導入済みの場合"

    1. 新BPで[11-1. 依存プログラムをインストールする](../setup/11-blocknotify-setup.md#11-1)のみを実施する
    2. 旧BPで設定ファイルを確認する
    
    ```
    cat $NODE_HOME/scripts/block-notify/.env
    ```
    または
    ```
    cat $NODE_HOME/guild-db/blocklog/.env
    ```
    または
    ```
    cat $NODE_HOME/scripts/block-notify/config.ini
    ```

    3. 新BPで[11-3. 通知プログラムの設定](../setup/11-blocknotify-setup.md#11-3)を実施する
    （config.iniの設定値は旧BPで表示された設定ファイルの内容を参考にする）


=== "旧BPで未導入の場合"
    
    [SPO Block Notify設定](../setup/11-blocknotify-setup.md)から導入してください。


## **5. Prometheus設定**

### **5-1.新BP`node exporter`インストール**

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

### **5-2.Grafanaサーバー`prometheus.yml`の修正**

=== "Grafanaサーバー(リレー1)"

    `prometheus.yml`に記載されてる旧BPのIPを新BPのIPへ変更してください
    ```
    sudo nano /etc/prometheus/prometheus.yml
    ```

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
## **6.最終作業**

### **6-1.旧BPシャットダウン**

=== "旧BP"
    ```
    sudo shutdown -h now
    ```

### **6-2.Tracemempool無効化**

Txの増加が確認できたらTracemempoolを無効にします。

=== "新BP"
    ```
    sed -i $NODE_HOME/${NODE_CONFIG}-config.json \
        -e "s/TraceMempool\": true/TraceMempool\": false/g"
    ```

ノード再起動
```
sudo systemctl reload-or-restart cardano-node
```

### **6-3.Mithril-Signer再セットアップ**
旧サーバーでMithril-Signer-Nodeを実行していた場合は、新サーバーでも再セットアップしてください。不明点がある場合はBTBF SPO LAB.でご質問ください。

