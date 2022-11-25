# **3. リレーとBPを接続する**

!!! caution "前提条件"
    リレーサーバー及びBPサーバーでノードが最新ブロックに同期してから以下を実施してください

!!! abstract "BPとリレーの役割"

    * **ブロックプロデューサーノード(BP)**  
    ブロック生成に必要なキーと証明書 \(node.cert, kes.skey vrf.skey\)を用いて起動します。自身のリレーノードのみに接続します。  
  
    * **リレーノード(リレー)**  
    自身のBPと他のリレーノードとの繋がりを持ち最新スロットを取得しブロック伝播の役割を果たします。  

![](../images/producer-relay-diagram.png)



## 3-1. リレーサーバーの設定変更

### 3-1-1. ファイアウォール設定を変更

リレーノードで使用する `6000` 番ポートの通信を許可する。任意の番号で設定している場合はその番号を許可する。
```bash
sudo ufw allow 6000/tcp
sudo ufw reload
```

### 3-1-2. Topologyファイル変更


!!! hint "**topology.json** とは？"

    * P2P(ピアツーピア)接続における接続先ノードを記述するファイルです。
    
    * リレーノードでは、パブリックノード \(IOHKや他のリレーノード\) 及び、自身のブロックプロデューサーノード情報を記述します。

    * ブロックプロデューサーノードでは、自身のリレーノード情報のみ記述します。

    * **「xxx.xxx.xxx.xxx」はパブリックIP(静的)アドレス**に置き換えて下さい

    * ポート番号を変更している場合は修正してください


=== "リレーノード"
自身のリレーノードから接続するノードを指定します。  
「xxx.xxx.xxx.xxx」はBPのパブリックIP(静的)アドレスと[2-4で設定した](../setup/2-node-setup.md#2-4)BPポート番号に置き換えて下さい。

```bash
cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF 
 {
    "Producers": [
      {
        "addr": "relays-new.cardano-mainnet.iohk.io",
        "port": 3001,
        "valency": 2
      },
      {
        "addr": "xxx.xxx.xxx.xxx",
        "port": xxxxx,
        "valency": 1
      }
    ]
  }
EOF
```


リレーノードを再起動する
```
sudo systemctl reload-or-restart cardano-node
```

## 3-2. BPサーバーの設定変更

### 3-2-1. ファイアウォール設定を変更

!!! tip "BPのセキュリティ"
    BPサーバーにはプール運営の秘密鍵を保管するため、ファイアウォールでリレーサーバーからの通信のみに限定する必要があります。

BPノードに設定したポート番号を確認する
```bash
PORT=`grep "PORT=" $NODE_HOME/startBlockProducingNode.sh`
b_PORT=${PORT#"PORT="}
echo "BPポートは${b_PORT}です"
```

BPノードで使用する `xxxx` 番ポート(上記で表示された番号)の通信を許可する。  
  
`<リレーノード1のIP>` の `<>`を除いてIPのみ入力してください。`xxxx`は上記で表示されたBPポート番号に置き換えてコマンドを実行してください。

=== "BP(リレー1台の場合)"
    ```bash
    sudo ufw allow from <リレーノード1のIP> to any port xxxxx
    sudo ufw reload
    ```

=== "BP(リレー2台の場合)"
    ```bash
    sudo ufw allow from <リレーノード1のIP> to any port xxxxx
    sudo ufw allow from <リレーノード2のIP> to any port xxxxx
    sudo ufw reload
    ```

### 3-2-2. Topologyファイル変更

!!! hint "ヒント"
    自身のBPノードから接続するリレーノードのIPとポート番号を指定します。
    あらかじめ、**「xxx.xxx.xxx.xxx」はご自身のリレーサーバーパブリックIP(静的)アドレスとポート番号**　に置き換えてからコマンドを実行して下さい。リレー台数分記載します。

=== "BP(リレー1台の場合)"

    ```bash
    cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF 
    {
        "Producers": [
          {
            "addr": "xxx.xxx.xxx.xxx",
            "port": 6000,
            "valency": 1
          }
        ]
      }
    EOF
    ```

=== "BP(リレー2台の場合)"
    ```bash
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

BPノードを再起動する
```
sudo systemctl reload-or-restart cardano-node
```
