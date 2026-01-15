# **リレーノード増設**

増設するリレーサーバーでは、まず1〜3を実施し、その後4以降の手順へ進んでください。    

???+ note "増設するリレーサーバーで実施"

    ## **1. Ubuntu初期設定**
    [https://docs.spojapanguild.net/setup/ubuntu-setup/#ubuntu](../setup/ubuntu-setup.md/#ubuntu)

    ## **2. ノードセットアップ**
    [https://docs.spojapanguild.net/setup/node-setup](../setup/node-setup.md)

    ## **3. トポロジーファイル設定**
    [https://docs.spojapanguild.net/setup/relay-bp-setup/#2](../setup/relay-bp-setup.md/#2)


## **4. BPとリレー1のトポロジー変更**
=== "ブロックプロデューサー"

    実行前に `+` をクリックして注釈を確認してください。  

    ``` yaml
    cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF
    {
      "bootstrapPeers": null,
      "localRoots": [
        {
          "accessPoints": [
            {
              "address": "リレー1のIP",#(1)!
              "port": 6000 #(2)!
            },
            {
              "address": "リレー2のIP",#(3)!
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

    1. リレー1のIPアドレスまたはDNSアドレスに置き換えてください。
    2. リレー1のポートに置き換えてください。
    3. リレー2のIPアドレスまたはDNSアドレスに置き換えてください。
    4. リレー2のポートに置き換えてください。
    5. 固定接続ピアの数を指定してください。
    6. `"publicRoots":`を空にしてください。
    7. `-1`を指定することで台帳から接続先を取得しないBPモードになります。
    8. ここでは`advertise`を`false`にしてください。

=== "リレーノード1"

    実行前に `+` をクリックして注釈を確認してください。  

    ``` yaml
    cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF
    {
      "bootstrapPeers": [
        {
          "address": "backbone.cardano.iog.io",
          "port": 3001
        },
        {
          "address": "backbone.mainnet.cardanofoundation.org",
          "port": 3001
        },
        {
          "address": "backbone.mainnet.emurgornd.com",
          "port": 3001
        }
      ],
      "localRoots": [
        {
          "accessPoints": [
            {
              "address": "BPのIP",#(1)!
              "port": 00000 #(2)!
            }
          ],
          "advertise": false,#(5)!
          "trustable": true,
          "valency": 1
        },
        {
          "accessPoints": [
            {
              "address": "リレー2のIP",#(3)!
              "port": 6000 #(4)!
            }
          ],
          "advertise": true,
          "trustable": true,
          "valency": 1
        }
      ],
      "publicRoots": [
        {
          "accessPoints": [],
          "advertise": false
        }
      ],
      "useLedgerAfterSlot": 157852837
    }
    EOF
    ```
    { .annotate }

    1. BPのIPアドレスまたはDNSアドレスに置き換えてください。
    2. BPのポートに置き換えてください。
    3. リレー2のIPアドレスまたはDNSアドレスに置き換えてください。
    4. リレー2のポートに置き換えてください。
    5. `accessPoints`にBPを指定する時は必ず`advertise`を`false`にしてください。

ノードを再起動します。
```bash
sudo systemctl reload-or-restart cardano-node
```

## **5. 運用証明書(pool.cert)の更新**

[運用証明書(pool.cert)の更新](../operation/cert-update.md)を実行し、増設したリレーをチェーンに登録します。

## **6. Grafanaのセットアップ**

=== "増設したリレーサーバーで実施"

      「1.インストール」を実施してください。  
      > 「BPまたはリレー2以降」タブと「リレーノード/BP」タブを増設したリレーサーバーで実施します。  
      [https://docs.spojapanguild.net/setup/monitoring-setup/#1](../setup/monitoring-setup.md#1)
    
      
=== "Grafana導入済みのリレーサーバーで実施"

      「2.設定ファイルの作成」を実施してください。  
      > Grafanaがインストールされているサーバーで実施します。  
      [https://docs.spojapanguild.net/setup/monitoring-setup/#2](../setup/monitoring-setup.md#2)

---