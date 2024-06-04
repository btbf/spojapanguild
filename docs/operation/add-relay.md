# リレーノード増設マニュアル

## 1.Ubuntu初期設定
[https://docs.spojapanguild.net/setup/1-ubuntu-setup/](https://docs.spojapanguild.net/setup/1-ubuntu-setup/)

## 2.ノードインストール
[https://docs.spojapanguild.net/setup/2-node-setup/](https://docs.spojapanguild.net/setup/2-node-setup/)

## 3.リレーサーバートポロジー設定
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

    BPトポロジーファイル変更(ダイナミックP2P)  

    実行前に `+`をクリックして注釈を確認してください。  

    ``` yaml
    cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF
    {
    "bootstrapPeers": null,
    "localRoots": [
        {
          "accessPoints": [
            {
            "address": "リレー１のIP",#(1)!
            "port": 6000 #(2)!
            },
            {
            "address": "リレー２のIP",#(3)!
            "port": 6000 #(4)!
            }
          ],
          "advertise": false,#(8)!
          "trustable": true,
          "valency": 2 #(5)!
        }
    ],
    "publicRoots": [],#(6)!
    "useLedgerAfterSlot": -1 #(7)!
    }
    EOF
    ```
    { .annotate }

    1.  リレー１のIPアドレスまたはDNSアドレスに置き換えてください
    2.  リレー１のポートに置き換えてください
    3.  リレー２のIPアドレスまたはDNSアドレスに置き換えてください
    4.  リレー２のポートに置き換えてください
    5.  固定接続ピアの数を指定してください
    6.  "publicRoots":を空にしてください
    7.  `-1`を指定することで台帳から接続先を取得しないBPモードになります
    8. ここでは`advertise`を`false`にしてください


ノードを再起動する
```
cnrestart
```

## 5.プール情報更新

[プール情報の更新](../operation/cert-update.md)を実行し、増設したリレーをチェーンに登録します。

## 6.Grafanaセットアップ

=== "増設リレーで実施"
    9-1.インストール  
    「BPまたはリレー2以降」タブと「リレーノード/BP」タブを増設リレーで実施  
    [https://docs.spojapanguild.net/setup/9-monitoring-tools-setup/#9-1](../setup/9-monitoring-tools-setup.md)


=== "Grafana導入済みのリレーで実施"
      9-2.設定ファイルの作成
      Grafanaがインストールされているサーバーで実施 #9-2
    [https://docs.spojapanguild.net/setup/9-monitoring-tools-setup/#2](../setup/9-monitoring-tools-setup.md)


