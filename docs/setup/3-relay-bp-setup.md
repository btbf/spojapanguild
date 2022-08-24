# **3. リレーとBPを接続する**

!!! caution "前提条件"
    リレーサーバー及びBPサーバーでノードが最新ブロックに同期してから以下を実施してください

!!! abstract "BPとリレーの役割"

    * **ブロックプロデューサーノード(BP)**  
    ブロック生成に必要なキーと証明書 \(node.cert, kes.skey vrf.skey\)を用いて起動します。自身のリレーノードのみに接続します。  
  
    * **リレーノード(リレー)**  
    自身のBPと他のリレーノードとの繋がりを持ち最新スロットを取得しブロック伝播の役割を果たします。  

![](../images/producer-relay-diagram.png)



## **3-1. Topologyファイルの修正**

!!! hint "**topology.json** とは？"

    * P2P(ピアツーピア)接続における接続先ノードを記述するファイルです。
    
    * リレーノードでは、パブリックノード \(IOHKや他のリレーノード\) 及び、自身のブロックプロデューサーノード情報を記述します。

    * ブロックプロデューサーノードでは、自身のリレーノード情報のみ記述します。

    * **「xxx.xxx.xxx.xxx」はパブリックIP(静的)アドレス**に置き換えて下さい

    * ポート番号を変更している場合は修正してください


=== "リレーノード"
**「xxx.xxx.xxx.xxx」はBPのパブリックIP(静的)アドレスとポート番号**に置き換えて下さい

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

自身のブロックプロデューサーノード上で以下のコマンドを実行します。 

=== "ブロックプロデューサーノード"
**「xxx.xxx.xxx.xxx」はリレーのパブリックIP(静的)アドレス**に置き換えて下さい
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

BPノードを再起動する
```
sudo systemctl reload-or-restart cardano-node
```
