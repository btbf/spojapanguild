---
status: new
---
# リレーサーバーの引越し手順（旧VPS会社→新VPS会社）


!!! tip "前提注意事項"
    * 本まとめは現VPS会社→新VPS会社へと `リレーのみ` を移行するまとめです。
    * 実際に行う際には手順をよく読みながら進めてください。
    * ブロック生成予定まで余裕がある時に実施してください。
    * <font color=red>リレー1台かつトポロジーアップデータにIPアドレスで登録している場合は、旧リレーと新リレーを一定期間併用運用する必要があります。</font>

## **1.新リレーセットアップ**
!!! info "はじめにお読みください"
    1. サーバ独自機能に留意する
        * さくらのパケットフィルタや、AWSのFW設定などのサーバー独自の機能に気を付けてください。
    2. 新リレーのファイヤーウォールを事前に開放設定(SSH、ノードポート、Grafanaなど)してください。
    3. 旧リレーのユーザー名（例：ubuntu）と新リレーのユーザー名は変更しないでください。
        * もし変更する場合は、以下のファイル内のパス名を手動で変更してください。
        * `startRelayNode1.sh` DIRECTORY=/home/ユーザー名/cnode
        * `topologyUpdater.sh` CNODE_HOME=/home/ユーザー名/cnode
        * `relay-topology_pull.sh` curl -4 -s -o /home/ユーザー名/cnode/****


### **1-1.Ubuntu初期設定**

新サーバーで[Ubuntu初期設定](../setup/1-ubuntu-setup.md#0-3)を実施します。  


### **1-2.ノードセットアップ**

[依存関係インストール](../setup/2-node-setup.md#2-1-cabalghc) 〜
[gLiveViewのインストール](../setup/2-node-setup.md#2-7-gliveview)まで実施します。
  
## **2.旧リレー移行処理**

**旧リレーファイル移動**

以下のファイルを旧リレーのcnodeディレクトリから新リレーのcnodeディレクトリにコピーします。

``` mermaid
graph LR
    A[旧リレー] -->|ファイル/フォルダ| B[新リレー];
``` 

| ファイル名 | 用途 |
:----|:----
| mainnet-topology.json | トポロジーファイル |
| startRelayNode1.sh | ノード起動スクリプト |
| topologyUpdater.sh | トポロジーアップデータスクリプト |
| relay-topology_pull.sh | トポロジー生成スクリプト |
| rsyncd.conf | RSYNC設定ファイル(設定中の場合) |
| rsync_ed25519.pub | RSYNC鍵ファイル(設定中の場合) |


## **3.新リレー再設定**

!!! tip "旧リレーをダイナミックP2Pで運用していた場合"
    新リレーの`mainnet-config.json`のP2P設定を`true`にする
    === "新リレー"
    ```
    sed -i -e 's!"EnableP2P": false!"EnableP2P": true!' $NODE_HOME/mainnet-config.json
    ```

### **3-1.パーミッション変更**
=== "新リレー"
    ```
    cd $NODE_HOME
    chmod +x startRelayNode1.sh
    chmod +x topologyUpdater.sh
    chmod +x relay-topology_pull.sh
    ```

    ノードを再起動します。
    ```
    sudo systemctl reload-or-restart cardano-node
    ```
    ノードログ確認
    ```
    journalctl --unit=cardano-node --follow
    ```

!!! tip "DNS運用の場合"

    * リレーDNSのAレコードを新リレーサーバーのIPアドレスへ変更する

### **3-2. トポロジーアップデータ設定**
 
=== "新リレー"
```
nano $NODE_HOME/topologyUpdater.sh
```
> 旧リレーのIPとポートを新リレーのIPとポートに変更する  

* CNODE_PORT=xxxx　　
* CNODE_HOSTNAME="xxx.xxx.xxx.xxx"　　

!!! tip "DNS運用の場合"
    * <font color="red">(DNS運用の場合は変更不要)</font>

トポロジーアップデータ実行
```
cd $NODE_HOME
./topologyUpdater.sh
```
`topologyUpdater.sh`が正常に実行された場合、以下の形式が表示されます。
> { "resultcode": "201", "datetime":"2020-07-28 01:23:45", "clientIp": "xxx.xxx.xxx.xx", "iptype": 4, "msg": "nice to meet you" }

### **3-3.Cron登録**
1.[Cronジョブ設定](../setup/8.topology-setup.md#cron)を実行する  

2.Cronジョブ設定から4時間後に[フェッチリスト登録確認](../setup/8.topology-setup.md#_2)を実行する  

3.トポロジーファイル再作成

=== "手動P2Pの場合"
    relay-topology_pull.shを実行し、トポロジーファイルを再作成する。
    ```
    cd $NODE_HOME
    ./relay-topology_pull.sh
    ```

    ノード再起動
    ```
    sudo systemctl reload-or-restart cardano-node
    ```
=== "ダイナミックP2Pの場合"
    何もせず、`relay-topology_pull.sh`も実行しないでください。


!!! tip "旧リレー併用目安"
    リレー1台かつトポロジーアップデータにIPアドレスで登録している場合は、新リレーのIncomingの数が安定して10以上に増えるまで旧リレーと新リレーを併用してください。

## **4.BP設定修正**

### **4-1.ファイアウォール設定変更**

!!! tip "AWSなどufwを使用しない場合"
    VPSの管理画面からファイアウォールの設定を変更してください。

=== "BP"
    ```
    PORT=`grep "PORT=" $NODE_HOME/startBlockProducingNode.sh`
    b_PORT=${PORT#"PORT="}
    echo "BPポートは${b_PORT}です"
    ```

    <新リレーIP> の <>を除いて新リレーIPを入力してください。
    ```
    sudo ufw allow from <新リレーIP> to any port ${b_PORT}
    sudo ufw reload
    ```

### **4-2.トポロジーファイル修正**
=== "BP"
    ```
    nano $NODE_HOME/mainnet-topology.json
    ```

    * 旧リレーIPとポートを新リレーのIPとポートに変更する  
    * DNS運用の場合は変更不要

    BPノードを再起動する
    ```
    sudo systemctl reload-or-restart cardano-node
    ```

チェーンが同期したら新リレーとBPの双方向の疎通(I/O)ができているかを確認します。

=== "BP"
    gLiveView確認
    ```
    cd $NODE_HOME/scripts
    ./gLiveView.sh
    ```
    > InとOutに新リレーのIPがあることを確認してください。


## **5.Grafana/Prometheus設定**

=== "新リレーでGrafanaも運用する場合"
    [監視ツールセットアップ](../setup/9-monitoring-tools-setup.md)のリレーノード1タブと[9-3.Grafanaダッシュボード設定](../setup/9-monitoring-tools-setup.md#9-3grafana)を実行する。

    !!! tip "Grafana追加設定"
        Grafanaは追加設定がありますので必要に応じて実施してください。

        * [アラート設定](./grafana-alert.md)
        * [セキュリティ強化設定](./grafana-security.md)


=== "新リレーでGrafanaを運用しない場合"

    - 新リレーにて`prometheus node exporter`をインストールします。

    === "新リレー"
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

    * DNSベースで接続している人は、DNSの変更が反映されたら自動的に切り替わるので以下作業は不要です。

    === "Grafanaサーバー(リレー1など)"
        ```
        sudo nano /etc/prometheus/prometheus.yml
        ```
        > * 旧リレーのIPを新リレーのIPへ変更してください

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

        Grafanaに新リレーのメトリクス(Slotなど)が表示されているか確認する。


## **6.プール情報更新**
[プール情報の更新](../operation/cert-update.md)を用いて、チェーン登録中のリレーIPを変更する。  
(DNS運用の場合は不要です)

---
## **7.補足**

### **Tracemempool無効化**

新リレーに十分なInが確認できた場合の処理

=== "新リレー"
    Txの増加が確認できたらTracemempoolを無効にします。
    ```
    sed -i $NODE_HOME/${NODE_CONFIG}-config.json \
        -e "s/TraceMempool\": true/TraceMempool\": false/g"
    ```

    ノード再起動
    ```
    sudo systemctl reload-or-restart cardano-node
    ```


旧リレーストップ
=== "旧リレー"
    ```
    sudo systemctl stop cardano-node
    ```
    サービス解除
    ```
    sudo systemctl disable cardano-node
    ```

BPファイアウォールから旧リレーIP削除
=== "BP"
    ```
    sudo ufw status numbered
    ```
    ```
    sudo ufw delete <削除したい番号>
    ```

!!! tip "ufwを使わないケース"
    AWSやVSPによっては管理画面でセキュリティ設定(ファイアウォール)を行っている場合がありますので、その場合はVPS管理画面から設定を変更してください。


### **Mithril-Signer再セットアップ**
旧サーバーでMithril-Signer-Relayを実行していた場合は、新サーバーでも再セットアップしてください。不明点がある場合はBTBF SPO LAB.でご質問ください。

---
 
