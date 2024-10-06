---
status: new
---
# リレーサーバーの引越し手順（旧VPS会社→新VPS会社）


!!! tip "前提注意事項"
    * 本まとめは現VPS会社→新VPS会社へと `リレーのみ` を移行するまとめです。
    * 実際に行う際には手順をよく読みながら進めてください。
    * ブロック生成予定まで余裕がある時に実施してください。
    * 移行後はダイナミックP2Pで運用します

## **1.新リレーセットアップ**
!!! info "はじめにお読みください"
    1. サーバ独自機能に留意する
        * さくらのパケットフィルタや、AWSのFW設定などのサーバー独自の機能に気を付けてください。
    2. 新リレーのファイヤーウォールを事前に開放設定(SSH、ノードポート、Grafanaなど)してください。


### **1-1.Ubuntu初期設定**

新サーバーで[Ubuntu初期設定](../setup/1-ubuntu-setup.md)を実施します。  


### **1-2.ノードセットアップ**

1. [依存関係インストール](../setup/2-node-setup.md#2) 〜
[gLiveViewのインストール](../setup/2-node-setup.md#2-7-gliveview)まで実施します。
2. [リレーとBPを接続する](../setup/3-relay-bp-setup.md#3-2)の「リレーノードの場合」を実施します。


## **2.BP設定修正**

### **2-1.ファイアウォール設定変更**

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

### **2-2.トポロジーファイル修正**
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


## **3.Grafana/Prometheus設定**

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

        FW設定でPrometheusメトリクスポートをリレー1のIP限定で開放する
        ```bash title="Ubuntu22.04の場合は１行づつ実行してください"
        sudo ufw allow from <リレーノード1のIP> to any port 12798
        sudo ufw allow from <リレーノード1のIP> to any port 9100
        sudo ufw reload
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


## **4.プール情報更新**
[プール情報の更新](../operation/cert-update.md)を用いて、チェーン登録中のリレーIPを変更する。  
(DNS運用の場合は不要です)

---
## **5.補足**

### **Tracemempool無効化**

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

### **旧リレーRSYNC設定済の場合**
1. `rsyncd.conf` `rsync_ed25519.pub`を旧リレーのcnodeから新リレーのcnodeへ移動してください。
2. 転送元サーバーの`~/.ssh/config`の旧リレーIPを新リレーIPに変更してください。

### **Mithril-Signer再セットアップ**
旧サーバーでMithril-Signer-Relayを実行していた場合は、新サーバーでも再セットアップしてください。不明点がある場合はBTBF SPO LAB.でご質問ください。

---
 
