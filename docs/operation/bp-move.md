# BPサーバーの引越し手順（旧VPS会社→新VPS会社）


!!! tip "前提注意事項"
    * 本まとめは現VPS会社→新VPS会社へと `BPのみ` を移行するまとめです。
    * 実際に行う際には、 `自己責任` でお願いします。
    * ブロック生成予定まで余裕がある時に実施してください。
    * 旧BPは「2-5. ~旧BPのノードを停止する。」まで、稼働させたまま にしておいてください。


## **1.Ubuntu初期設定**

1-1. 新サーバーで[Ubuntu初期設定](../../setup/1-ubuntu-setup/#0-3)を実施します。  

!!! info "留意事項"
    1. サーバ独自機能に留意する
        * さくらのパケットフィルタや、AWSのUFW設定などのサーバー独自の機能に気を付けてください。
    2. 新BPのファイヤーウォール設定は、旧BPと同じ設定にしてください。
    3. 旧BPのユーザー名（例：ubuntu）と新BPのユーザー名は変更しないでください。
        * もし変更する場合は、下記2-5にて旧BPから新BPにコピーするファイル `startBlockProducingNode.sh` 内の変数DIRECTORYのパス名を手動で変更してください。
        * DIRECTORY=/home/<new_user_name>/cnode

## **2.インストール**

2-1. [依存関係インストール](../../setup/2-node-setup/#2-1-cabalghc) 〜
[gLiveViewのインストール](../../setup/2-node-setup/#2-7-gliveview)まで実施します。

- サーバスペックによって、ノードが完全同期する日数は変動しますが、大体１～３日程度かかります。
  複数リレー運用かつディスク空き容量に余裕がある場合は、[RSYNC+SSH](../../operation/node-update/#3rsyncssh)手順を試してみるといいでしょう。  

2-2. 旧BPのcnodeディレクトリにある`mainnet-topology.json`を新BPのcnodeディレクトリにコピーし、新BPのノードを再起動します。


=== "新BP"
    ノード再起動
    ```
    sudo systemctl reload-or-restart cardano-node
    ```
    ノードログ確認
    ```
    journalctl --unit=cardano-node --follow
    ```

2-3. リレーのトポロジー情報を変更します。 
 
* `xxx`を新BPと旧BPのIPとポート情報に書き換えてください。

=== "手動P2Pの場合"
    * 任意の接続先がある場合は"|" で区切って「IPアドレス:ポート番号:Valency の形式」で追加してください。

    ```
    cat > $NODE_HOME/relay-topology_pull.sh << EOF
    #!/bin/bash
    NEW_BLOCKPRODUCING_IP=xxx.xxx.xxx
    NEW_BLOCKPRODUCING_PORT=xxxx
    OLD_BLOCKPRODUCING_IP=xxx.xxx.xxx
    OLD_BLOCKPRODUCING_PORT=xxxx
    PEERS=18
    curl -4 -s -o $NODE_HOME/${NODE_CONFIG}-topology.json "https://api.clio.one/htopology/v1/fetch/?max=\${PEERS}&customPeers=\${NEW_BLOCKPRODUCING_IP}:\${NEW_BLOCKPRODUCING_PORT}:1|\${OLD_BLOCKPRODUCING_IP}:\${OLD_BLOCKPRODUCING_PORT}:1|relays-new.cardano-mainnet.iohk.io:3001:2"
    EOF
    ```

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
    ``` yaml
    cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF
    {
    "localRoots": [
        { "accessPoints": [
            {
            "address": "xx.xxx.xx.xxx", #(1)!
            "port": yyyy #(2)!
            },
            {
            "address": "bb.bbb.bb.bbb", #(3)!
            "port": aaaa #(4)!
            }
            ],
            "advertise": false,
            "valency": 2
        }
    ],
    "publicRoots": [
        { "accessPoints": [
            {
            "address": "backbone.cardano-mainnet.iohk.io",
            "port": 3001
            },
            {
            "address": "backbone.cardano.iog.io",
            "port": 3001
            },
            {
            "address": "backbone.mainnet.emurgornd.com",
            "port": 3001
            }
        ],
        "advertise": false
        }
    ],
    "useLedgerAfterSlot": 110332824
    }
    EOF
    ```

    1.  新BPのIPアドレスに置き換えてください
    2.  新BPのポートに置き換えてください
    3.  旧BPまたは他リレーのIPアドレスに置き換えてください
    4.  旧BPまたは他リレーのポートに置き換えてください

    トポロジーファイルの再読み込み
    ```
    kill -SIGHUP $(pidof cardano-node)
    ```
    > ダイナミックP2P有効時、トポロジーファイル変更による再起動は不要です。


2-4. gLiveViewで新BPとリレーの双方向の疎通(I/O)ができているかを確認します。

=== "新BP"
    gLiveView確認
    ```
    cd $NODE_HOME/scripts
    ./gLiveView.sh
    ```
    > InとOutにリレーのIPがあることを確認してください。

2-5. BPキー移行のため旧BPノードを停止します。

=== "旧BP"

    ```
    sudo systemctl stop cardano-node
    ```
    ```
    sudo systemctl disable cardano-node
    ```
    > 旧BPのノードが絶対に起動しないようにVPS管理コンソールからサーバーを停止しておいてください。

- ここで**旧BPとリレーとの接続が切れます。**

以下のファイルを旧BPのcnodeディレクトリから新BPのcnodeディレクトリにコピーします。

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
| pool.id-bech32 | stakepoolid、bech32形式 |
| pool.id | stakepoolid、hex形式 |
| guild-db | ブロックログ関連フォルダ |

!!! hint "guild-dbフォルダについて"
    * 旧BPからguild-dbフォルダを移動しないと、過去の「Ideal」、「Luck」が全て消えます(この2つは再取得できません)ので、[FileZillaをセットアップ](../../operation/sftp/)して、必ず移動してください。
    * その他の必要ファイルがあれば移動しておいてください。

2-6. VRFキーのパーミッションを変更します。
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

2-8. `gLiveView.sh`を起動して「Txが増加しているか」、「上段表示がRelayではなくCoreに変わっているか」を確認します。

gLiveView確認
```
cd $NODE_HOME/scripts
./gLiveView.sh
```

2-9. `params.json`を再作成します。

=== "新BP"
```
cd $NODE_HOME
cardano-cli query protocol-parameters \
    --mainnet \
    --out-file params.json
```

2-10. ブロックログの導入前に、cncli.dbを削除します。

=== "新BP"
    ```
    rm $NODE_HOME/guild-db/cncli/cncli.db
    ```

2-11. ブロックログの設定をします。

- [ステークプールブロックログ導入手順](../../setup/10-blocklog-setup/)


2-12. ブロックが生成できる状態にあるかどうか、`SPO JAPAN GUILD TOOL`でチェックします。

- [SPO JAPAN GUILD TOOL](../../operation/tool/#spo-japan-guild-tool)

## 3.新BPブロック生成確認後
3-1. ブロック生成を確認したら、旧BPのバックアップ(スナップショット)を取得し、インスタンスは不要なので削除します。

??? hint "何らかの事情で、旧BPを再稼働したい場合(IP接続のとき）"
    === "新BP"
        - 新BPのノードを停止し、新BPのノードが自動起動しないように設定します。また、新BPが絶対に起動しないように、コンソールで停止しておきます。
        ```
        sudo systemctl stop cardano-node
        ```
        ```
        sudo systemctl disable cardano-node
        ```

    === "旧BP"
        - 旧BPをコンソールで起動し、自動起動する設定をし、旧BPのノードを起動します。
        ```
        sudo systemctl enable cardano-node
        ```
        ```
        sudo systemctl start cardano-node
        ```

3-2.リレートポロジーファイルの変更  
`xxx`を新BPのIPとポート情報に書き換えてください。  
=== "手動P2Pの場合"
    ```
    cat > $NODE_HOME/relay-topology_pull.sh << EOF
    #!/bin/bash
    BLOCKPRODUCING_IP=xxx.xxx.xxx
    BLOCKPRODUCING_PORT=xxxx
    PEERS=18
    curl -4 -s -o $NODE_HOME/${NODE_CONFIG}-topology.json "https://api.clio.one/htopology/v1/fetch/?max=\${PEERS}&customPeers=\${BLOCKPRODUCING_IP}:\${BLOCKPRODUCING_PORT}:1|relays-new.cardano-mainnet.iohk.io:3001:2"
    EOF
    ```

    ```
    cd $NODE_HOME
    ./relay-topology_pull.sh
    ```
    ```
    sudo systemctl reload-or-restart cardano-node
    ```
    ノードログ確認
    ```
    journalctl --unit=cardano-node --follow
    ```
    gLiveView確認
    ```
    cd $NODE_HOME/scripts
    ./gLiveView.sh
    ```
=== "ダイナミックP2Pの場合"
    ``` yaml
    cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF
    {
    "localRoots": [
        { "accessPoints": [
            {
            "address": "xx.xxx.xx.xxx", #(1)!
            "port": yyyy #(2)!
            }
            ],
            "advertise": false,
            "valency": 2
        }
    ],
    "publicRoots": [
        { "accessPoints": [
            {
            "address": "backbone.cardano-mainnet.iohk.io",
            "port": 3001
            },
            {
            "address": "backbone.cardano.iog.io",
            "port": 3001
            },
            {
            "address": "backbone.mainnet.emurgornd.com",
            "port": 3001
            }
        ],
        "advertise": false
        }
    ],
    "useLedgerAfterSlot": 110332824
    }
    EOF
    ```

    1.  新BPのIPアドレスに置き換えてください
    2.  新BPのポートに置き換えてください

    トポロジーファイルの再読み込み
    ```
    kill -SIGHUP $(pidof cardano-node)
    ```
    > ダイナミックP2P有効時、トポロジーファイル変更による再起動は不要です。

2-15. Prometheus、Grafanaの設定

- 新BPにて`prometheus node exporter`をインストールします。

=== "新BP"
    ```
    sudo apt install -y prometheus-node-exporter
    ```

    サービスを有効にして、自動的に開始されるように設定します。
    ```
    sudo systemctl enable prometheus-node-exporter.service
    ```

`prometheus.yml`の修正  

* 旧BPのIPを新BPのIPへ変更してください
* DNSベースで接続している人は、DNSの変更が反映されたら自動的に切り替わるのでこの作業は不要です。

=== "Grafanaサーバー(リレー1)"
    ```
    sudo nano /etc/prometheus/prometheus.yml
    ```
    > 定義ファイルを書き換え、保存して閉じます。

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

`Grafanaパネルの修正`

Grafanaダッシュボードのメトリクスを旧BPのIPから新BPのIPに書き換えてください。

---
## 補足
- Txの増加が確認できたらTracemempoolを無効にします。

=== "新BP"
```
sed -i $NODE_HOME/${NODE_CONFIG}-config.json \
    -e "s/TraceMempool\": true/TraceMempool\": false/g"
```

- ブロック生成ステータス通知セットアップ

旧BPで[ブロック生成ステータス通知](../../setup/11-blocknotify-setup/#_1)を設定されていた方は設定し直しておくとよいでしょう。

---
## 執筆・編集

元ネタ執筆/校正：[AICHI/TOKAI Stake Pool](https://adapools.org/pool/970e9a7ae4677b152c27a0eba3db996b372de094d24fc2974768f3da)
見やすく編集/改良：[WYAM-StakePool](https://adapools.org/pool/940d6893606290dc6b7705a8aa56a857793a8ae0a3906d4e2afd2119)

また、作成に当たっては以下の方々のご助言もいただきました！
- BTBFさん
- sakakibaraさん
- でーちゃん
- Daikonさん
- conconさん

こちらの手順で不備がありましたら今後のコミュニティのためにAichiまたはWYAMにDMなどで教えていただけると幸いです。（不備が無かったら、「無かったです！」と一報いただけると、自分の投稿に自信が持てますので、無くても教えていただけると幸いです）