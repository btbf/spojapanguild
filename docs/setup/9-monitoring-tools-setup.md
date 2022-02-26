# **9.監視ツールセットアップ**

プロメテウスはターゲットに指定したメトリックHTTPエンドポイントをスクレイピングし、情報を収集する監視ツールです。[オフィシャルドキュメントはこちら](https://prometheus.io/docs/introduction/overview/) グラファナは収集されたデータを視覚的に表示させるダッシュボードツールです。

### **1.インストール**

!!! abstract "概要"
    「prometheus」および「prometheus node exporter」をインストールします。 この手順では、リレーノード1でprometheusとGrafana本体を稼働させ、リレーノード1およびブロックプロデューサーノードの情報を取得する手順です。

prometheusインストール

=== "リレーノード1"
    ```text
    sudo apt install -y prometheus prometheus-node-exporter
    ```

=== "ブロックプロデューサーノード"

    ```bash
    sudo apt install -y prometheus-node-exporter
    ```

grafanaインストール

=== "リレーノード1"
    ```bash
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    ```
    ```bash
    echo "deb https://packages.grafana.com/oss/deb stable main" > grafana.list
    sudo mv grafana.list /etc/apt/sources.list.d/grafana.list
    ```
    ```bash
    sudo apt update && sudo apt install -y grafana
    ```

サービスを有効にして、自動的に開始されるように設定します。

=== "リレーノード1"

    ```bash
    sudo systemctl enable grafana-server.service
    sudo systemctl enable prometheus.service
    sudo systemctl enable prometheus-node-exporter.service
    ```

=== "ブロックプロデューサーノード"

    ```bash
    sudo systemctl enable prometheus-node-exporter.service
    ```

## **2.定義ファイルの作成**

!!! warning "注意"
    targets:の「xxx.xxx.xxx」は、BPのパブリックIP(静的)アドレスに置き換えて下さい

=== "リレーノード1"

    ```bash
    cat > prometheus.yml << EOF
    global:
    scrape_interval:     15s 

    # Attach these labels to any time series or alerts when communicating with
    # external systems (federation, remote storage, Alertmanager).
    external_labels:
        monitor: 'codelab-monitor'

    # A scrape configuration containing exactly one endpoint to scrape:
    # Here it's Prometheus itself.
    scrape_configs:
    # The job name is added as a label job=<job_name> to any timeseries scraped from this config.
    - job_name: 'prometheus'

        static_configs:
        - targets: ['localhost:9100']
            labels:
            alias: 'relaynode1'
            type:  'system'
        - targets: ['xxx.xxx.xxx:9100']
            labels:
            alias: 'block-producing-node'
            type:  'system'
        - targets: ['xxx.xxx.xxx:12798']
            labels:
            alias: 'block-producing-node'
            type:  'cardano-node'
        - targets: ['localhost:12798']
            labels:
            alias: 'relaynode1'
            type:  'cardano-node'
    EOF
    ```

prometheus.ymlを移動します
=== "リレーノード1"
    ```bash
    sudo mv prometheus.yml /etc/prometheus/prometheus.yml
    ```

サービスを起動します。

=== "リレーノード1"

    ```bash
    sudo systemctl restart grafana-server.service
    sudo systemctl restart prometheus.service
    sudo systemctl restart prometheus-node-exporter.service
    ```

サービスが正しく実行されていることを確認します。

=== "リレーノード1"

    ```bash
    sudo systemctl --no-pager status grafana-server.service prometheus.service prometheus-node-exporter.service
    ```


## **3.ノード設定ファイルの更新**
=== "リレーノード1/BP"

    ```bash
    cd $NODE_HOME
    sed -i ${NODE_CONFIG}-config.json -e "s/127.0.0.1/0.0.0.0/g"
    ```



!!! info "ファイアウォールの設定を確認してください"
    ファイアウォールを設定している場合は、ブロックプロデューサーノードにて9100番と12798番ポートをリレーノード1のパブリックIP(静的)指定で開放して下さい。  
    リレーノード1では、Grafana用に3000番ポートを開放してください。


ノードを再起動し設定ファイルを有効化します。


=== "リレーノード1/BP"

    ```bash
    sudo systemctl reload-or-restart cardano-node
    ```


## **4.Grafanaダッシュボードの設定**

1. ローカルブラウザから http://&lt;リレーノードIPアドレス&gt;:3000 を開きます。 事前に3000番ポートを開いておく必要があります。
2. ログイン名・PWは次のとおりです。 **admin** / **admin**
3. パスワードを変更します。
4. 左メニューの歯車アイコンから データソースを追加します。
5. 「Add data source」をクリックし、「Prometheus」を選択します。
6. 名前は **Prometheus**としてください。
7. **URL** を [http://localhost:9090](http://localhost:9090)に設定します。
8. **Save & Test**をクリックします。
9. こちらの[JSONファイル](https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/grafana-monitor-cardano-nodes-by-kaze.json)を開き、内容を全選択してコピーします。
10. 左メニューから**Create +** iconを選択 &gt; **Import**をクリックします。
11. 9でコピーした内容を「Import via panel json」に貼り付けます
12. **Load**ボタンをクリックし、次の画面で***Import**ボタンをクリックします。


![Grafana system health dashboard](https://gblobscdn.gitbook.com/assets%2F-M5KYnWuA6dS_nKYsmfV%2F-MJFWbLTL5oVQ3taFexL%2F-MJFX9deFAhN4ks6OQCL%2Fdashboard-kaze.jpg?alt=media&token=f28e434a-fcbf-40d7-8844-4ff8a36a0005)



!!! success "🎊おめでとうございます🎊"
これで基本的な監視設定は完了です。必要に応じてノード異常時の通知設定を行ってください
{% endhint %}