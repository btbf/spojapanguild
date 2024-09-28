# **2-4.手動トポロジー設定**

!!! danger "注意"
    現在のリレーノードトポロジー形成は[ダイナミックP2P](../setup/3-relay-bp-setup.md)へ移行しています。
    この設定は今後廃止されます。

## 事前準備

**ノードをストップする** 
```
sudo systemctl stop cardano-node
```

**手動P2P用のトポロジーファイルをダウンロード**
```
cd $NODE_HOME
wget --no-use-server-timestamps -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/topology-legacy.json -O ${NODE_CONFIG}-topology.json
```

**ダイナミックP2Pを無効にする**
```
sed -i ${NODE_CONFIG}-config.json \
    -e 's!"EnableP2P": true!"EnableP2P": false!'
```

## TopologyUpdaterの設定

| ファイル      | 用途                          |
| :---------- | :----------------------------------- |
| `topologyUpdater.sh`       | トポロジーフェッチリスト登録スクリプト  |
| `relay-topology_pull.sh`       | トポロジーファイル生成スクリプト |

ノード情報をトポロジーフェッチリストに登録するスクリプト「`topologyUpdater.sh`」を作成します。

!!! hint "topologyUpdater.shについて"
    リレーノード情報(IPアドレスとポート番号、オン/オフライン状態)をトポロジーフェッチリストへ1時間に1回送信することで、世界中のリレーノードに自プールのリレー情報が登録される仕組みです

  
### スクリプトファイルの作成 
  
!!! warning "注意"
    以下は、リレーノードのパブリックIPとノードポートに合わせる  

    * CNODE_HOSTNAMEの「xxx.xxx.xxx.xx」はリレーのパブリックIP(静的)アドレスまたはDNS名に置き換えて下さい
    * リレーノードポート番号を6000から変更している場合は修正してください
    * ※26行目の"CHANGE ME"は変更しないでください
    
=== "リレーノード"
    ```bash title="このボックスはすべてコピーして実行してください"
    cat > $NODE_HOME/topologyUpdater.sh << EOF
    #!/bin/bash
    # shellcheck disable=SC2086,SC2034
    
    USERNAME=$(whoami)
    CNODE_PORT=6000
    CNODE_HOSTNAME="xxx.xxx.xxx.xx"
    CNODE_BIN="/usr/local/bin"
    CNODE_HOME=$NODE_HOME
    CNODE_LOG_DIR="\${CNODE_HOME}/logs"
    GENESIS_JSON="\${CNODE_HOME}/${NODE_CONFIG}-shelley-genesis.json"
    NETWORKID=\$(jq -r .networkId \$GENESIS_JSON)
    CNODE_VALENCY=1   # optional for multi-IP hostnames
    NWMAGIC=\$(jq -r .networkMagic < \$GENESIS_JSON)
    [[ "\${NETWORKID}" = "Mainnet" ]] && HASH_IDENTIFIER="--mainnet" || HASH_IDENTIFIER="--testnet-magic \${NWMAGIC}"
    [[ "\${NWMAGIC}" = "764824073" ]] && NETWORK_IDENTIFIER="--mainnet" || NETWORK_IDENTIFIER="--testnet-magic \${NWMAGIC}"
    
    export PATH="\${CNODE_BIN}:\${PATH}"
    export CARDANO_NODE_SOCKET_PATH="\${CNODE_HOME}/db/socket"
    
    blockNo=\$(/usr/local/bin/cardano-cli conway query tip \${NETWORK_IDENTIFIER} | jq -r .block )
    
    # Note:
    # if you run your node in IPv4/IPv6 dual stack network configuration and want announced the
    # IPv4 address only please add the -4 parameter to the curl command below  (curl -4 -s ...)
    if [ "\${CNODE_HOSTNAME}" != "CHANGE ME" ]; then
    T_HOSTNAME="&hostname=\${CNODE_HOSTNAME}"
    else
    T_HOSTNAME=''
    fi

    if [ ! -d \${CNODE_LOG_DIR} ]; then
    mkdir -p \${CNODE_LOG_DIR};
    fi
    
    curl -4 -s "https://api.clio.one/htopology/v1/?port=\${CNODE_PORT}&blockNo=\${blockNo}&valency=\${CNODE_VALENCY}&magic=\${NWMAGIC}\${T_HOSTNAME}" | tee -a \$CNODE_LOG_DIR/topologyUpdater_lastresult.json
    EOF
    ```

権限を追加し、「topologyUpdater.sh」を実行します。

=== "リレーノード"
    ```bash
    cd $NODE_HOME
    chmod +x topologyUpdater.sh
    ./topologyUpdater.sh
    ```

`topologyUpdater.sh`が正常に実行された場合、以下の形式が表示されます。

> `{ "resultcode": "201", "datetime":"2020-07-28 01:23:45", "clientIp": "1.2.3.4", "iptype": 4, "msg": "nice to meet you" }`

!!! fail "注意"
    ※`topologyUpdater.sh`は1時間以内に2回以上実行しないで下さい。最悪の場合ブラックリストに追加されることがあります。スクリプトが実行されるたびに、**`$NODE_HOME/logs`**にログが作成されます。 


### Cronジョブの設定

crontabジョブを追加し、「topologyUpdater.sh」を1時間に1回自動実行されるように設定します。
    

!!! danger "注意"
    * 以下のコードは複数回実行しないで下さい。複数回実行した場合、同じ時間に複数自動実行されるスケジュールが登録されてしまうので、ブラックリストに入ります。
    * 以下のコードは毎時5分に実行されるように指定しています。
    　

=== "リレーノード"
    ```bash title="このボックスはすべてコピーして実行してください"
    cat > $NODE_HOME/crontab-fragment.txt << EOF
    5 * * * * ${NODE_HOME}/topologyUpdater.sh
    EOF
    crontab -l | cat - crontab-fragment.txt >crontab.txt && crontab crontab.txt
    rm crontab-fragment.txt
    ```

    > no crontab for ~~
    というメッセージが表示されることがありますが、Cron初回設定時に表示されるメッセージとなりますので、問題ありません。

    ```
    crontab -l
    ```
    以下が返り値として表示されればOK。
    > "5 * * * * /home/***/cnode/topologyUpdater.sh"


    !!! success "フェッチリストへの登録について"
        4時間の間で4回スクリプトが実行された後に、ノードがオンライン状態で有ることが認められた場合にノードIPがトポロジーフェッチリストに登録されます。上記設定から4時間後に次の項目を実施してください。



### フェッチリスト登録確認
=== "リレーノード"

    ```bash
    cd $NODE_HOME/logs
    cat topologyUpdater_lastresult.json
    ```

以下の内容が表示されていれば登録成功  
最後の一行が最新のresultcodeになり、400番台・500番台の場合は、サーバ設定に問題があります。
```
{ "resultcode": "201", "datetime":"2021-01-10 18:30:06", "clientIp": "000.000.000.000", "iptype": 4, "msg": "nice to meet you" }
{ "resultcode": "203", "datetime":"2021-01-10 19:30:03", "clientIp": "000.000.000.000", "iptype": 4, "msg": "welcome to the topology" }
{ "resultcode": "204", "datetime":"2021-01-10 20:30:04", "clientIp": "000.000.000.000", "iptype": 4, "msg": "glad you're staying with us" }
```


### トポロジーファイルを生成する

!!! hint "前提条件"
    リレーノードIPがトポロジーフェッチリストに登録されたことを確認後、以下のセクションを実行して下さい。

??? hint "トポロジーの形成方法▼"
    トポロジーファイルを更新する`relay-topology_pull.sh`スクリプトを作成します。 
    このスクリプトを作成・実行することで、世界中のリレーノード情報の中から自分のリレーノードに対して近距離・中距離・遠距離に分散したリレーノードを抽出し半自動でトポロジーを形成できます。 
  
??? hint  "個別に追加したい場合▼"
    ※お知り合いのノードや自ノードが複数ある場合は、IOHKノード情報の後に "|" で区切って`IPアドレス`:`ポート番号`:`Valency` の形式で追加できます。  
    ```
    |relays-new.cardano-mainnet.iohk.io:3001:2|relay1-eu.xstakepool.com:3001:1|00.000.000.00:3001:1
    ```

!!! warning "注意"
    以下は、BPのパブリックIPとノードポートに書き換えてからコマンドを実行する  
    BLOCKPRODUCING_IPの「xxx.xxx.xxx」はBPのパブリックIP(静的)アドレスに置き換えて下さい
    BLOCKPRODUCING_PORTは任意で設定した番号に置き換えてください。

=== "リレーノード"
    ```bash title="このボックスはすべてコピーして実行してください"
    cat > $NODE_HOME/relay-topology_pull.sh << EOF
    #!/bin/bash
    BLOCKPRODUCING_IP=xxx.xxx.xxx
    BLOCKPRODUCING_PORT=xxxxx
    PEERS=18
    cp $NODE_HOME/${NODE_CONFIG}-topology.json $NODE_HOME/${NODE_CONFIG}-topology-bk.json
    curl -4 -s -o $NODE_HOME/${NODE_CONFIG}-topology.json "https://api.clio.one/htopology/v1/fetch/?max=\${PEERS}&customPeers=\${BLOCKPRODUCING_IP}:\${BLOCKPRODUCING_PORT}:1|relays-new.cardano-mainnet.iohk.io:3001:2"
    EOF
    ```

shファイルに権限を追加し、relay-topology_pull.shを実行する

=== "リレーノード"
    ```bash
    cd $NODE_HOME
    chmod +x relay-topology_pull.sh
    ./relay-topology_pull.sh
    ```

!!! hint ""
    relay-topology_pull.shを実行すると新しいトポロジーファイル\(mainnet-topology.json\)を生成します。

!!! warning ""
    トポロジーファイルを更新した場合は、リレーノードを再起動することを忘れないで下さい。

=== "リレーノード"
    ```bash
    sudo systemctl start cardano-node
    ```


### **トポロジーファイル更新方法**

!!! note "概要"
    トポロジーファイルに記載されてるリレーノードは常に最新状態を保つことが望ましいため、1エポックに1回は書き換えることを推奨します。

=== "リレーノード"
  ```bash
  cd $NODE_HOME
  ./relay-topology_pull.sh
  ```

!!! hint "ヒント"
    relay-topology_pull.shを実行すると新しいトポロジーファイル\(mainnet-topology.json\)を生成します。
    新しいトポロジーファイルはノード再起動後に有効になります。

=== "リレーノード"
  ```bash
  sudo systemctl reload-or-restart cardano-node
  ```