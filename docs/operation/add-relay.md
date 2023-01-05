# リレーノード増設マニュアル

## 1.Ubuntu初期設定
[https://docs.spojapanguild.net/setup/1-ubuntu-setup/](https://docs.spojapanguild.net/setup/1-ubuntu-setup/)

## 2.ノードインストール
[https://docs.spojapanguild.net/setup/2-node-setup/](https://docs.spojapanguild.net/setup/2-node-setup/)

## 3.リレーサーバーの設定変更
[https://docs.spojapanguild.net/setup/3-relay-bp-setup/#3-1](https://docs.spojapanguild.net/setup/3-relay-bp-setup/#3-1)


## 4.BPのFWと設定ファイル変更
=== "ブロックプロデューサー"
    ```
    PORT=`grep "PORT=" $NODE_HOME/startBlockProducingNode.sh`
    b_PORT=${PORT#"PORT="}
    echo "BPポートは${b_PORT}です"
    ```

    `<増設リレーノードのIP>` の `<>`を除いてIPのみ入力してください。
    ```
    sudo ufw allow from <増設リレーノードのIP> to any port ${b_PORT}
    sudo ufw reload
    ```

    !!! hint "ヒント"
        自身のBPノードから接続するリレーノードのIPとポート番号を指定します。
        あらかじめ、**「xxx.xxx.xxx.xxx」はご自身のリレーサーバーパブリックIP(静的)アドレスとポート番号**　に置き換えてからコマンドを実行して下さい。リレー台数分記載します。
        
    ```
    cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF 
    {
        "Producers": [
        {
            "addr": "aa.xxx.xxx.xxx",
            "port": 6000,
            "valency": 1
        },
        {
            "addr": "bb.xxx.xxx.xxx",
            "port": 6000,
            "valency": 1
        }
        ]
    }
    EOF
    ```
    ```
    sudo systemctl reload-or-restart cardano-node
    ```

## 5.P2Pトポロジー設定
=== "増設リレー"
    [https://docs.spojapanguild.net/setup/8.topology-setup/](https://docs.spojapanguild.net/setup/8.topology-setup/)



## 6.監視ツールセットアップ

=== "増設リレー"
    9-1.インストール  
    「BPまたはリレー2以降」タブと「全サーバー」タブを増設リレーで実施  
    [https://docs.spojapanguild.net/setup/9-monitoring-tools-setup/#1](https://docs.spojapanguild.net/setup/9-monitoring-tools-setup/#1)

    9-3.ノード設定ファイルの更新  
    [https://docs.spojapanguild.net/setup/9-monitoring-tools-setup/#3](https://docs.spojapanguild.net/setup/9-monitoring-tools-setup/#3)


9-2.設定ファイルの作成
グラファナがインストールされているサーバーで  「リレーノード1(リレー2台の場合)」タブを実施 
=== "リレーノード1"
    [https://docs.spojapanguild.net/setup/9-monitoring-tools-setup/#2](https://docs.spojapanguild.net/setup/9-monitoring-tools-setup/#2)


