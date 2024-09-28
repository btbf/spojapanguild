# **4.BP用キーファイル作成**

!!! info "事前確認"
    以下の項目を実施する前にBPノードが起動しているか確認してください。
    ```
    cardano-cli conway query tip --mainnet | grep syncProgress
    ```
    
    戻り値確認
    `"syncProgress": "100.00"` 戻り値が99以下の場合は100(最新ブロックまで同期)になるまで待ちましょう。

!!! important "BP起動に必要なファイルとは？"
    ブロックプロデューサーノードでは３つのキーを生成する必要があります。

    * ステークプールの運用証明書 \(node.cert\)
    * ステークプールのセキュリティキー \(kes.skey\)
    * ステークプールのVRFキー \(vrf.skey\)

## **1.KESキーの作成**


!!! quote "KESキーについて"
    \(KES=Key Evolving Signature\)の略  
    キーを悪用するハッカーからステークプールを保護するために作成され、90日ごとに再生成する必要があります。詳細は運用マニュアルを参照してください

=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    cardano-cli conway node key-gen-KES \
        --verification-key-file kes.vkey \
        --signing-key-file kes.skey
    ```

## **2.コールドキーの作成** 
!!! danger "注意"
     **コールドキーはエアギャップオフラインマシンで生成し保管する必要があります**  
    このファイルはプール運営で重要なコールドキーです。エアギャップマシンで作成しオンライン環境に保管しないようご注意下さい。  
    {==外部に流出するとプールが乗っ取られる可能性がありますので管理には十分注意してください==}
    また複数のUSBに保管し、絶対に上書き・削除しないようご注意下さい。コールドキーは次のパスに格納されます `$HOME/cold-keys`

=== "エアギャップオフラインマシン"

    ```text
    mkdir $HOME/cold-keys
    ```

    コールドキーのペアキーとカウンターファイルを作成します。

    ```bash
    cd $HOME/cold-keys
    cardano-cli conway node key-gen \
        --cold-verification-key-file node.vkey \
        --cold-signing-key-file node.skey \
        --operational-certificate-issue-counter node.counter
    ```
    アクセス権を読み取り専用に更新します。
    ```
    chmod 400 node.vkey
    chmod 400 node.skey
    ```

!!! warning "重要"
    すべてのキーを別の安全なストレージデバイス(USB)などにバックアップしましょう！複数のバックアップを作成することをおすすめします。

## **3.プール運用証明書の作成**


!!! warning "事前確認"
    ブロックチェーンと完全に同期している必要があります。 同期が途中の場合、正しいslotsPerKESPeriodを取得できません。 あなたのBPノードが完全に同期されたことを確認するには、[カルダノエクスプローラー](https://explorer.cardano.org/ja.html)で自身の同期済みエポックとスロットが一致しているかをご確認ください。

=== "ブロックプロデューサーノード"

    ジェネシスファイルからslotsPerKESPeriodを出力します。
    ```bash
    cd $NODE_HOME
    slotsPerKESPeriod=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r '.slotsPerKESPeriod')
    echo slotsPerKESPeriod: ${slotsPerKESPeriod}
    ```
    同期済みslotNoを算出します。
    ```bash
    slotNo=$(cardano-cli conway query tip $NODE_NETWORK | jq -r '.slot')
    echo slotNo: ${slotNo}
    ```

    startKesPeriodを算出します。

    ```bash
    kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
    echo kesPeriod: ${kesPeriod}
    startKesPeriod=${kesPeriod}
    echo startKesPeriod: ${startKesPeriod}
    ```


!!! important "ファイル転送"
    BPの`kes.skey`と`kes.vkey` をエアギャップマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|kes.skey / kes.vkey| B[エアギャップ];
    ```


BPとエアギャップで`kes.vkey`ファイルハッシュを比較する

=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    sha256sum kes.vkey
    ```

!!! hint ""
    BPとエアギャップで表示された戻り値を比較して、ハッシュ値が一致していればOK  

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    sha256sum kes.vkey
    ```



!!! info "確認"
    ステークプールオペレータは、プールを実行する権限があることを確認するための運用証明書を発行する必要があります。証明書には、オペレータの署名が含まれプールに関する情報（アドレス、キーなど）が含まれます。




=== "エアギャップオフラインマシン"

    ```bash
    cd $NODE_HOME
    read -p "BPで算出したstartKesPeriodを入力してください:" kes
    ```
    > ↑このままコマンドに入力してください  
    > コマンド実行後に、数字入力モードになりますので  
    > そこでBPで算出した`startKesPeriod`の数字を入力します

    入力した数字が戻り値に表示されているか確認し証明書を作成する
    ```
    echo "入力した数字は$kesです"
    ```

    ```
    cardano-cli conway node issue-op-cert \
        --kes-verification-key-file kes.vkey \
        --cold-signing-key-file $HOME/cold-keys/node.skey \
        --operational-certificate-issue-counter $HOME/cold-keys/node.counter \
        --kes-period $kes \
        --out-file node.cert
    ```

!!! important "ファイル転送"
    エアギャップマシンの**node.cert** をBPのcnodeディレクトリにコピーします。

    ``` mermaid
    graph LR
        A[エアギャップ] -->|node.cert| B[BP];
    ```


** BPとエアギャップで`node.cert`ファイルハッシュを比較する **

=== "ブロックプロデューサーノード"

    ```bash
    cd $NODE_HOME
    sha256sum node.cert
    ```

!!! hint ""
    BPとエアギャップで表示された戻り値を比較して、ハッシュ値が一致していればOK  

=== "エアギャップオフラインマシン"

    ```bash
    cd $NODE_HOME
    sha256sum node.cert
    ```



## **4.VRFキーの作成**

=== "ブロックプロデューサーノード"

    ```bash
    cd $NODE_HOME
    cardano-cli conway node key-gen-VRF \
        --verification-key-file vrf.vkey \
        --signing-key-file vrf.skey
    ```
    
    vrfキーのアクセス権を読み取り専用に更新します。
    ```
    chmod 400 vrf.skey
    chmod 400 vrf.vkey
    ```
    !!! failure "注意"
        vrfキーを誤って削除しないように注意してください。

## **5.BPノードとして再起動**


BPノードを一旦停止する  

=== "ブロックプロデューサーノード"
    ```bash
    sudo systemctl stop cardano-node
    ```

    ノードポート番号を確認する
    ```
    PORT=`grep "PORT=" $NODE_HOME/startBlockProducingNode.sh`
    b_PORT=${PORT#"PORT="}
    echo "BPポートは${b_PORT}です"
    ```
    > ↑そのまま実行し、BPのポート番号が表示されることを確認する

    起動スクリプトにKES、VRF、運用証明書のパスを追記し更新します。

    ```bash title="このボックスはすべてコピーして実行してください"
    cat > $NODE_HOME/startBlockProducingNode.sh << EOF 
    #!/bin/bash
    DIRECTORY=$NODE_HOME
    PORT=${b_PORT}
    HOSTADDR=0.0.0.0
    TOPOLOGY=\${DIRECTORY}/${NODE_CONFIG}-topology.json
    DB_PATH=\${DIRECTORY}/db
    SOCKET_PATH=\${DIRECTORY}/db/socket
    CONFIG=\${DIRECTORY}/${NODE_CONFIG}-config.json
    SNAPSHOT=43200
    KES=\${DIRECTORY}/kes.skey
    VRF=\${DIRECTORY}/vrf.skey
    CERT=\${DIRECTORY}/node.cert
    /usr/local/bin/cardano-node +RTS -N --disable-delayed-os-memory-return -I0.1 -Iw300 -A32m -n4m -F1.5 -H2500M -T -S -RTS run --topology \${TOPOLOGY} --database-path \${DB_PATH} --socket-path \${SOCKET_PATH} --host-addr \${HOSTADDR} --port \${PORT} --config \${CONFIG} --shelley-kes-key \${KES} --shelley-vrf-key \${VRF} --shelley-operational-certificate \${CERT} --snapshot-interval \${SNAPSHOT}
    EOF
    ```

    BPを起動します。

    ```bash
    sudo systemctl start cardano-node
    ```

    BPとして起動しているか確認する

    ```bash
    cd $NODE_HOME/scripts
    ./gLiveView.sh
    ```

    チェーン同期後にCoreの表示があればOK

!!! danger "**注意事項**"
    ブロックプロデューサーノードを実行するためには、以下の３つのファイルが必要です。このファイルが揃っていない場合や起動時に指定されていない場合はブロックが生成できません。

    * kes.skey
    * vrf.skey
    * node.cert

    


