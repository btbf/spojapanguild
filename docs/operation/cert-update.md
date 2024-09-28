# **プール情報(pool.cert)の更新**

!!! summary "概要"
    * 誓約、固定手数料、変動手数料、リレー情報、メタデータを変更する場合に実施します。
    * メタデータURLのみ変更になる場合でも「メタデータ更新を含む場合」を実施しメタデータファイルを再作成してください。

!!! info "注意"
    誓約・固定手数料・変動手数料の反映は提出エポック＋3エポック後からになります。  
    例）  
    320エポックに変更申請  
    321エポックで有効化  
    322エポックで待機  
    323エポックで反映  


=== "メタデータ更新を含む場合"
    === "ブロックプロデューサーノード"
        変数にプールメタデータ値を設定し実行してください
        > 文字列は`''`で囲ってください  
        > extendedを設定していない場合は `''`のままで大丈夫です
        ```
        name=''
        description=''
        ticker=''
        homepage=''
        extended=''
        ```

        メタデータファイルを作成する

        ``` title="このボックスはすべてコピーして実行してください"
        cat > $NODE_HOME/poolMetaData.json << EOF
        {
            "name": "$name",
            "description": "$description",
            "ticker": "$ticker",
            "homepage": "$homepage",
            "extended": "$extended",
            "nonce":"$(date +%s)"
        }
        EOF
        ```

    !!! Success "poolMetaData.jsonを各ホストサーバーへアップロードする"
        poolMetaData.jsonをローカルマシンにダウンロードし、Githubまたはご自身のサーバーの所定の位置にアップロードしてください


    **ハッシュ値確認**

    === "ブロックプロデューサーノード"
        ```text
        cd $NODE_HOME
        cardano-cli conway stake-pool metadata-hash --pool-metadata-file poolMetaData.json > poolMetaDataHash.txt
        ```

        オンラインファイルハッシュ値確認
        > `https:****.**.**`をメタデータファイルのURLに置き換えてから実行してください

        ```
        cd $NODE_HOME
        wget -O onlineMetaData.json https:****.**.**
        ```

        オンラインメタデータハッシュ値
        ```
        cardano-cli conway stake-pool metadata-hash --pool-metadata-file onlineMetaData.json > onlineMetaDataHash.txt
        ```

        ハッシュ値
        ```
        printf "\n　サーバー:$(cat poolMetaDataHash.txt)\nオンライン:$(cat onlineMetaDataHash.txt)\n\n"
        ```
        >ハッシュ値が一致する必要があります。異なる場合はホストサーバーへ正しくアップロードされているかご確認ください。
        
        ハッシュ値が一致したら、確認用ファイルを削除する。
        ```
        rm onlineMetaDataHash.txt
        rm onlineMetaData.json
        ```


    
    !!! important "ファイル転送"
        BPの``poolMetaDataHash.txt`` をエアギャップマシンのcnodeディレクトリにコピーします。
        ``` mermaid
        graph LR
            A[BP] -->|poolMetaDataHash.txt| B[エアギャップ];
        ```

    BPとエアギャップハッシュ値確認
    === "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    echo $(cat poolMetaDataHash.txt)
    ```

    === "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    echo $(cat poolMetaDataHash.txt)
    ```
    > ハッシュ値が異なっている場合は、BPのpoolMetaDataHash.txtがエアギャップに正しくコピーされていません。

=== "誓約、手数料、リレー情報のみ更新の場合"


**登録証明書トランザクションを作成する**

複数のリレーノードを設定する場合は [複数のリレーノードを構成する記述方法](../setup/7-register-stakepool.md#poolcert) を参考にパラメーターを指定して下さい。  

!!! notice "注意"
    以下は参考コードです。ご自身のプール設定値に変更してください  
    例）  
    
    * 固定費・・・170ADA
    * Margin・・・5%
    * 誓約・・・1000ADA

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    ```

    ```bash
    chmod u+rwx $HOME/cold-keys
    cardano-cli conway stake-pool registration-certificate \
        --cold-verification-key-file $HOME/cold-keys/node.vkey \
        --vrf-verification-key-file vrf.vkey \
        --pool-pledge 1000000000 \
        --pool-cost 170000000 \
        --pool-margin 0.05 \
        --pool-reward-account-verification-key-file stake.vkey \
        --pool-owner-stake-verification-key-file stake.vkey \
        $NODE_NETWORK \
        --pool-relay-ipv4 ***.***.***.*** \
        --pool-relay-port 6000 \
        --metadata-url https://xxx.xxx.xxx/poolMetaData.json \
        --metadata-hash $(cat poolMetaDataHash.txt) \
        --out-file pool.cert
    ```

!!! notice "ヒント"
    上記のコードを自プール用の設定に修正したら、次回も使用できるようテキストファイルとして保存しておいてください。

ステークプールに誓約します。

=== "エアギャップオフラインマシン"
    ```bash
    cardano-cli conway stake-address delegation-certificate \
        --stake-verification-key-file stake.vkey \
        --cold-verification-key-file $HOME/cold-keys/node.vkey \
        --out-file deleg.cert
    ```


!!! important "ファイル転送"
    エアギャップの`pool.cert`と`deleg.cert`をブロックプロデューサーのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|pool.cert / deleg.cert| B[BP];
    ```

最新のスロット番号を取得します

=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    currentSlot=$(cardano-cli conway query tip $NODE_NETWORK | jq -r '.slot')
    echo Current Slot: $currentSlot
    ```

payment.addrの残高を出力します。

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway query utxo \
        --address $(cat payment.addr) \
        $NODE_NETWORK > fullUtxo.out

    tail -n +3 fullUtxo.out | sort -k3 -nr | sed -e '/lovelace + [0-9]/d' > balance.out

    cat balance.out
    ```

UTXOを算出します
=== "ブロックプロデューサーノード"
    ```bash
    tx_in=""
    total_balance=0
    while read -r utxo; do
        in_addr=$(awk '{ print $1 }' <<< "${utxo}")
        idx=$(awk '{ print $2 }' <<< "${utxo}")
        utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
        total_balance=$((${total_balance}+${utxo_balance}))
        echo TxHash: ${in_addr}#${idx}
        echo ADA: ${utxo_balance}
        tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
    done < balance.out
    txcnt=$(cat balance.out | wc -l)
    echo Total ADA balance: ${total_balance}
    echo Number of UTXOs: ${txcnt}
    ```

build-rawトランザクションコマンドを実行します。


=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${total_balance} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee 200000 \
        --certificate-file pool.cert \
        --certificate-file deleg.cert \
        --out-file tx.tmp
    ```

最低手数料を計算します。

=== "ブロックプロデューサーノード"
    ```bash
    fee=$(cardano-cli conway transaction calculate-min-fee \
        --tx-body-file tx.tmp \
        --witness-count 3 \
        --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee
    ```

計算結果を出力します。

=== "ブロックプロデューサーノード"
    ```bash
    txOut=$((${total_balance}-${fee}))
    echo txOut: ${txOut}
    ```

トランザクションファイルを構築します。

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${txOut} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee ${fee} \
        --certificate-file pool.cert \
        --certificate-file deleg.cert \
        --out-file tx.raw
    ```


!!! important "ファイル転送"
    BPの`tx.raw` をエアギャップマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|tx.raw| B[エアギャップ];
    ```

トランザクションに署名します。

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    cardano-cli conway transaction sign \
        --tx-body-file tx.raw \
        --signing-key-file payment.skey \
        --signing-key-file $HOME/cold-keys/node.skey \
        --signing-key-file stake.skey \
        $NODE_NETWORK \
        --out-file tx.signed
    chmod a-rwx $HOME/cold-keys
    ```

!!! important "ファイル転送"
    エアギャップの`tx.signed` をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|tx.signed| B[BP];
    ```

トランザクションを送信します。

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway transaction submit \
        --tx-file tx.signed \
        $NODE_NETWORK
    ```
    > Transacsion Successfully submittedと表示されれば成功