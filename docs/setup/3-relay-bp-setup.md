# **3. リレーとBPを接続する**

!!! caution "前提条件"
    以下の項目を実施する前にリレー/BPノードが起動しているか確認してください。
    ```
    cardano-cli query tip --mainnet | grep syncProgress
    ```

    戻り値確認
    `"syncProgress": "100.00"`  
    > 戻り値が99以下の場合は100(最新ブロックまで同期)になるまで待ちましょう。

!!! abstract "BPとリレーの役割"

    * **ブロックプロデューサーノード(BP)**  
    ブロック生成用の専用ノードです。ブロック生成に必要なキーと証明書 \(node.cert, kes.skey vrf.skey\)を用いて起動し自身のリレーノードのみに接続します。  
  
    * **リレーノード(リレー)**  
    自身のBPと他のリレーノードとの繋がりを持ち最新スロットを取得しブロック伝播の役割を果たします。  

![](../images/producer-relay-diagram.png)

## 3-1. 接続タイプ(トポロジー)
| 接続タイプ | ピア取得元 | 適用推奨ノード | Topologyファイル |
| :---------- | :---------- | :---------- | :---------- |
| D-P2P(非ブートストラップピア) | 台帳自動取得 | リレー/BP | [Non bootstrap peers](https://book.world.dev.cardano.org/environments/mainnet/topology-non-bootstrap-peers.json) | 
| D-P2P(ブートストラップピア) | 台帳自動取得 | リレー(一部) | [bootstrap peers](https://book.world.dev.cardano.org/environments/mainnet/topology.json) | 
| 非P2P | 手動(TopologyUpdater) | サブリレー | [Legacy non-p2p](https://book.world.dev.cardano.org/environments/mainnet/topology-legacy.json) | 

!!! hint "Topology設定について"
    * ノードv8.9.0以降全てのノードでD-P2P(非ブートストラップピア)有効を推奨します。
    * D-P2P(ブートストラップピア)は一部リレーのみで有効にし、数週間かけて段階的に有効にしてください。
    * 非P2Pは大規模プールのサブリレーで適用可能です。
    * 以下の手順は、D-P2P(非ブートストラップピア) で構成します。

!!! hint "**topology.json** とは？"

    * P2P(ピアツーピア)接続における接続先ノードを記述するファイルです。
    * リレーノードでは、パブリックノード \(IOHKや他のリレーノード\) 及び、自身のブロックプロデューサーノード情報を記述します。
    * ブロックプロデューサーノードでは、自身のリレーノード情報のみ記述します。
    * **「xxx.xxx.xxx.xxx」はパブリックIP(静的)アドレス**に置き換えて下さい
    * ポート番号を変更している場合は修正してください

!!! attention "ファイアウォール設定について"
    ご利用のVPSによっては管理画面からFWを設定する場合があります（例AWS系など）  
    その場合は以下の設定を行わず、VPSマイページ管理画面などから個別に設定してください。

## 3-2. 各ノード設定変更

新トポロジーファイル項目解説

| 項目     | 説明                          |
| ----------- | ------------------------------------ |
| `localRoots`       | 常に固定したい接続先を記入 |
| `accessPoints`       |  接続先グループ |
| `advertise`    | PeerSharing実装後に使用するフラグ(今は`false`) |
| `valency`    | 接続数(接続先グループ内に記載した数と一致させる必要があります) |
| `publicRoots`    | ブートストラップ用バックアップ接続先 |
| `useLedgerAfterSlot`    | 初期同期の際に台帳Peer検索を有効にするスロット番号 |

**以下、各ノードごとのタブをクリックして実施してください**

??? danger "リレーノードの場合"
    リレーファイアウォール設定を変更

    リレーノードで使用する `6000` 番ポートのインバウンド通信を許可する。任意の番号で設定している場合はその番号を許可する。

    ```bash
    sudo ufw allow 6000/tcp
    ```
    ```bash
    sudo ufw reload
    ```

    リレーTopologyファイル変更

    自身のリレーノードから接続を固定するノードを指定します。  
    「xxx.xxx.xxx.xxx」はBPのパブリックIP(静的)アドレスと[2-4で設定した](../setup/2-node-setup.md#2-4)BPポート番号に置き換えて下さい。

    実行前に `+`をクリックして注釈を確認してください。  

    ``` yaml
    cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF
    {
    "localRoots": [
        { 
          "accessPoints": [
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
      { 
        "accessPoints": [
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
    { .annotate }

    1.  BP1のIPアドレスに置き換えてください
    2.  BP1のポートに置き換えてください
    3.  BP2または他リレーのIPアドレスに置き換えてください
    4.  BP2または他リレーのポートに置き換えてください

??? danger "BPの場合"

    ファイアウォール設定を変更

    !!! tip "BPのセキュリティ"
        BPサーバーにはプール運営の秘密鍵を保管するため、ファイアウォールでリレーサーバーからの通信のみに限定する必要があります。

    BPノードに設定したポート番号を確認する
    ```bash
    PORT=`grep "PORT=" $NODE_HOME/startBlockProducingNode.sh`
    b_PORT=${PORT#"PORT="}
    echo "BPポートは${b_PORT}です"
    ```

    BPノードで使用するポート(上記で表示された番号)の通信を許可する。  
      
    `<>`を除いてIPのみ入力してください。

    ```bash title="Ubuntu22.04の場合は１行づつ実行してください"
    sudo ufw allow from <リレーノード1のIP> to any port ${b_PORT}
    sudo ufw allow from <リレーノード2のIP> to any port ${b_PORT}
    sudo ufw reload
    ```
   
    BP-Topologyファイル変更  

    実行前に `+`をクリックして注釈を確認してください。  

    ``` yaml
    cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF
    {
    "localRoots": [
        { 
          "accessPoints": [
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
          "valency": 2 #(5)!
        }
    ],
    "publicRoots": [],
    "useLedgerAfterSlot": -1 #(6)!
    }
    EOF
    ```
    { .annotate }

    1.  リレー1のIPアドレスまたはDNSアドレスに置き換えてください
    2.  リレー1のポートに置き換えてください
    3.  リレー2または他リレーのIPアドレスに置き換えてください
    4.  リレー2または他リレーのポートに置き換えてください
    5.  固定接続ピアの数を指定してください
    6.  `-1`を指定することで台帳から接続先を取得しないBPモードになります

**mainnet-topology.json構文チェック**
```
cat $NODE_HOME/mainnet-topology.json | jq .
```
=== "正常"
    mainnet-topology.jsonの中身がそのまま表示されます

=== "parse error"
    json記法に誤りがあるため以下のエラーが表示されます。mainnet-topology.jsonを開いて`{}` `[]` `,`が正しい位置にあるかご確認ください。
    ```{ .yaml .no-copy }
    parse error: Expected another key-value pair at line x, column x
    ```


トポロジーファイルを再読み込みする
```
cnreload
```
> ダイナミックP2Pを有効にしている場合、トポロジーファイル変更によるノード再起動は不要になりました。
