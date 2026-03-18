# **プール廃止処理**

!!! important "プール廃止の流れ"
    
    ``` mermaid
    graph LR
        A[1-リタイア処理] -->|500ADA返還| B(2-登録料返還確認);
        C[3-stake.addrから全額引出処理] -->|全額| D(3-payment.addr着金確認);
        E[4-stake.addr解除処理] -->|2ADA返還| F(4-payment.addr確認);
        G[5-payment.addr全額引出処理] -->|全額| H(5-任意のアドレス確認);
        click A "./#1"
        click B "./#_3"
        click C "../withdrawal/#2-1-paymentaddr"
        click E "./#2"
        click G "./#3paymentaddr"
    ```

## **1. リタイア処理**

**現在のエポックの計算**

=== "ブロックプロデューサノード"
    ```bash
    startTimeGenesis=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r .systemStart)
    startTimeSec=$(date --date=${startTimeGenesis} +%s)
    currentTimeSec=$(date -u +%s)
    epochLength=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r .epochLength)
    epoch=$(( (${currentTimeSec}-${startTimeSec}) / ${epochLength} ))
    echo current epoch: ${epoch}
    ```


**引退エポックの算出**
> プールが最も早く引退できるエポックと最も遅い引退エポックを見つけます。

=== "ブロックプロデューサノード"
    ```bash
    poolRetireMaxEpoch=$(cat $NODE_HOME/params.json | jq -r '.poolRetireMaxEpoch')
    echo poolRetireMaxEpoch: ${poolRetireMaxEpoch}

    minRetirementEpoch=$(( ${epoch} + 1 ))
    maxRetirementEpoch=$(( ${epoch} + ${poolRetireMaxEpoch} ))

    echo リタイア可能最短エポック: ${minRetirementEpoch}
    echo リタイア可能最長エポック: ${maxRetirementEpoch}
    ```


!!! info "リタイアのタイミングについて"
    **例**: エポック320でeMax18の場合,

    * 最も早いポックは 321 \( 現在のエポック  + 1\)
    * 最も遅いエポックは 338 \( eMax + 現在のエポック\)

    * プールはリタイア指定エポック開始時にリタイア処理されます。  
    * もし心変わりがある場合は、エポック指定エポック開始前に[運用証明書(pool.cert)の更新](../operation/cert-update.md)を送信することでリタイア手続きを無効にできます。
    * プール登録料500ADAはリタイア処理エポック開始時にstake.addrに入金されます。  


**登録解除証明書 `pool.dereg`の作成**  

以下のコマンド内の `--epoch ***` にリタイアしたいエポックを記入します。

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    chmod u+rwx $HOME/cold-keys
    cardano-cli latest stake-pool deregistration-certificate \
      --cold-verification-key-file $HOME/cold-keys/node.vkey \
      --epoch *** \
      --out-file pool.dereg
    ```


!!! important "ファイル転送"
    エアギャップの`pool.dereg`をBPのcnodeディレクトリにコピー
    
    ``` mermaid
    graph LR
        A[エアギャップ] -->|pool.dereg| B[BP];
    ```


**payment.addrの残高参照**

=== "ブロックプロデューサノード"
    ```bash
    cd $NODE_HOME
    cardano-cli latest query utxo \
      --address $(cat payment.addr) \
      $NODE_NETWORK \
      --output-text \
      --out-file fullUtxo.out

    tail -n +3 fullUtxo.out | sort -k3 -nr | sed -e '/lovelace + [0-9]/d' > balance.out

    cat balance.out
    ```

**UTXOを算出**

=== "ブロックプロデューサノード"
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

**現在のスロットを算出**

=== "ブロックプロデューサノード"
    ```bash
    currentSlot=$(cardano-cli latest query tip $NODE_NETWORK | jq -r '.slot')
    echo Current Slot: $currentSlot
    ```

**トランザクションのビルド**

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli latest transaction build-raw \
      ${tx_in} \
      --tx-out $(cat payment.addr)+${total_balance} \
      --invalid-hereafter $(( ${currentSlot} + 10000)) \
      --fee 200000 \
      --certificate-file pool.dereg \
      --out-file tx.tmp
    ```

**最低料金の計算**

=== "ブロックプロデューサノード"
    ```bash
    fee=$(cardano-cli latest transaction calculate-min-fee \
      --tx-body-file tx.tmp \
      --witness-count 2 \
      --output-text \
      --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee
    ```

**変更出力の計算**

=== "ブロックプロデューサノード"
    ```bash
    txOut=$((${total_balance}-${fee}))
    echo txOut: ${txOut}
    ```

**トランザクションのビルド**

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli latest transaction build-raw \
      ${tx_in} \
      --tx-out $(cat payment.addr)+${txOut} \
      --invalid-hereafter $(( ${currentSlot} + 10000)) \
      --fee ${fee} \
      --certificate-file pool.dereg \
      --out-file tx.raw
    ```


!!! important "ファイル転送"
    BPの`tx.raw`をエアギャップオフラインマシンのcnodeディレクトリにコピー
    
    ``` mermaid
    graph LR
        A[BP] -->|tx.raw| B[エアギャップ];
    ```

**トランザクションに署名**

=== "エアギャップオフラインマシン"
    ```bash
    cardano-cli latest transaction sign \
      --tx-body-file tx.raw \
      --signing-key-file payment.skey \
      --signing-key-file $HOME/cold-keys/node.skey \
      $NODE_NETWORK \
      --out-file tx.signed
    ```

**コールドキーのロック**

```bash
chmod a-rwx $HOME/cold-keys
```



!!! important "ファイル転送"
    
    エアギャップの`tx.signed` を ブロックプロデューサノードのcnodeディレクトリにコピーします。
    
    ``` mermaid
    graph LR
        A[エアギャップ] -->|tx.signed| B[BP];
    ```


**トランザクションの送信**

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli latest transaction submit \
      --tx-file tx.signed \
      $NODE_NETWORK
    ```

### **1-1. リタイア確認**

* KOIOS APIを使用してリタイア処理ステータスを確認できます。

=== "ブロックプロデューサノード"
    ```bash
    cd $NODE_HOME
    curl -s -X POST -H "content-type: application/json" -d @- "https://api.koios.rest/api/v1/pool_info" << EOS | jq '.[0].pool_status,.[0].retiring_epoch'
    {"_pool_bech32_ids":["$(cat 'pool.id-bech32')"]}
    EOS
    ```

    ``` { .yaml .no-copy }
    #戻り値サンプル
    "retired" # "retiring"でリタイア処理待ち "retired"でリタイア済み 
    309 #リタイアエポック
    ```

## **2. 登録料返還確認**

!!! warning "注意"
    以降の処理は、プールのリタイア処理が完了してから実施してください

!!! important "ファイル転送"
    
    エアギャップの`stake.addr` を BPのcnodeディレクトリにコピーします。
    
    ``` mermaid
    graph LR
        A[エアギャップ] -->|stake.addr| B[BP];
    ```

=== "ブロックプロデューサノード"
    ```bash
    cd $NODE_HOME
    cardano-cli latest query stake-address-info \
      --address $(cat stake.addr) \
      $NODE_NETWORK
    ```

**戻り値確認**

> rewardAccountBalance: の値を確認

## **3. stake.addrから引き出し**

[stake.addrからpayment.addrへ送金する方法](../operation/withdrawal.md/#1-1-paymentaddr)  


## **4. ステークキーの解除**

!!! fail "注意"
    * この手順ではstake.addrの登録を解除し、2ADAの返還手続きを行います。
    * プール登録料(500ADA)が返還される前に以下の処理を行ってしまうと、500ADAを受け取ることが出来ません。  
    * 以下の手続きは、プール登録料の500ADAを受け取ってから実施してください。


**ステークキー登録解除証明書作成**

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    cardano-cli latest stake-address deregistration-certificate \
      --stake-verification-key-file stake.vkey \
      --key-reg-deposit-amt 2000000 \
      --out-file stake-dereg.cert
    ```


!!! important "ファイル転送"
    
    エアギャップの`stake-dereg.cert` を ブロックプロデューサノードのcnodeディレクトリにコピーします。
    
    ``` mermaid
    graph LR
        A[エアギャップ] -->|stake-dereg.cert| B[BP];
    ```


**ステークキー登録料算出**

=== "ブロックプロデューサノード"
    ```bash
    keyDeposit=$(cat $NODE_HOME/params.json | jq -r '.stakeAddressDeposit')
    echo keyDeposit: $keyDeposit
    ```

**最新スロット算出**

=== "ブロックプロデューサノード"
    ```bash
    cd $NODE_HOME
    currentSlot=$(cardano-cli latest query tip $NODE_NETWORK | jq -r '.slot')
    echo Current Slot: $currentSlot
    ```

**payment.addr残高を参照**

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli latest query utxo \
      --address $(cat payment.addr) \
      $NODE_NETWORK \
      --output-text \
      --out-file fullUtxo.out

    tail -n +3 fullUtxo.out | sort -k3 -nr | sed -e '/lovelace + [0-9]/d' > balance.out

    cat balance.out
    ```

**UTXOを算出**

=== "ブロックプロデューサノード"
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

**仮トランザクションファイルを作成**

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli latest transaction build-raw \
      ${tx_in} \
      --tx-out $(cat payment.addr)+$(( ${total_balance} + ${keyDeposit} )) \
      --invalid-hereafter $(( ${currentSlot} + 10000)) \
      --fee 200000 \
      --certificate stake-dereg.cert \
      --out-file tx.tmp
    ```

**最低料金の計算**

=== "ブロックプロデューサノード"
    ```bash
    fee=$(cardano-cli latest transaction calculate-min-fee \
      --tx-body-file tx.tmp \
      --witness-count 2 \
      --output-text \
      --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee
    ```

**変更出力の計算**

=== "ブロックプロデューサノード"
    ```bash
    txOut=$((total_balance+keyDeposit-fee))
    echo Change Output: ${txOut}
    ```

**トランザクションのビルド**

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli latest transaction build-raw \
      ${tx_in} \
      --tx-out $(cat payment.addr)+${txOut} \
      --invalid-hereafter $(( ${currentSlot} + 10000)) \
      --fee ${fee} \
      --certificate-file stake-dereg.cert \
      --out-file tx.raw
    ```

!!! important "ファイル転送"
    BPの`tx.raw` をエアギャップマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|tx.raw| B[エアギャップ];
    ```


**トランザクションに署名**

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    cardano-cli latest transaction sign \
      --tx-body-file tx.raw \
      --signing-key-file payment.skey \
      --signing-key-file stake.skey \
      $NODE_NETWORK \
      --out-file tx.signed
    ```


!!! important "ファイル転送"
    エアギャップの`tx.signed` をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|tx.signed| B[BP];
    ```
=== "ブロックプロデューサノード"
    ```bash
    cardano-cli latest transaction submit \
      --tx-file tx.signed \
      $NODE_NETWORK
    ```

## **5. 全額引き出し（payment.addr）**

まずは、最新のスロット番号を取得し **invalid-hereafter** パラメータを正しく設定します。


=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    currentSlot=$(cardano-cli latest query tip $NODE_NETWORK | jq -r '.slot')
    echo Current Slot: $currentSlot
    ```

**送金先のアドレスの設定**

=== "ブロックプロデューサーノード"
    ```bash
    destinationAddress=送金先アドレス
    echo destinationAddress: $destinationAddress
    ```

**payment.addrの残高の参照**

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli latest query utxo \
      --address $(cat payment.addr) \
      $NODE_NETWORK \
      --output-text \
      --out-file fullUtxo.out

    tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

    cat balance.out
    ```

**UTXOを算出**

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


**トランザクションのビルド**

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli latest transaction build-raw \
      ${tx_in} \
      --tx-out ${destinationAddress}+${total_balance} \
      --invalid-hereafter $(( ${currentSlot} + 10000)) \
      --fee 200000 \
      --out-file tx.tmp
    ```


**最低手数料の出力**

=== "ブロックプロデューサーノード"
    ```bash
    fee=$(cardano-cli latest transaction calculate-min-fee \
      --tx-body-file tx.tmp \
      --witness-count 1 \
      --output-text \
      --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee
    ```


**計算結果の出力**

=== "ブロックプロデューサーノード"
    ```bash
    txOut=$((${total_balance}-${fee}))
    echo Change Output: ${txOut}
    ```

**送金金額を確認**

=== "ブロックプロデューサーノード"
    ```bash
    amountToSend=$((${txOut}))
    echo amountToSend: $amountToSend
    ```

**トランザクションのビルド**

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli latest transaction build-raw \
      ${tx_in} \
      --tx-out ${destinationAddress}+${amountToSend} \
      --invalid-hereafter $(( ${currentSlot} + 10000)) \
      --fee ${fee} \
      --out-file tx.raw
    ```


!!! important "ファイル転送"
    
    BPの`tx.raw` をエアギャップオフラインマシンのcnodeディレクトリにコピーします。
    
    ``` mermaid
    graph LR
        A[BP] -->|tx.raw| B[エアギャップ];
    ```

**トランザクションに署名**

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    cardano-cli latest transaction sign \
      --tx-body-file tx.raw \
      --signing-key-file payment.skey \
      $NODE_NETWORK \
      --out-file tx.signed
    ```

**tx.signed** をブロックプロデューサーノードのcnodeディレクトリにコピーします。

!!! important "ファイル転送"
    
    エアギャップの`tx.signed` をBPのcnodeディレクトリにコピーします。
    
    ``` mermaid
    graph LR
        A[エアギャップ] -->|tx.signed| B[BP];
    ```

**署名済みトランザクションの送信**

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli latest transaction submit \
      --tx-file tx.signed \
      $NODE_NETWORK
    ```


全額出金されているかを確認します。

=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    cardano-cli latest query utxo \
      --address $(cat payment.addr) \
      $NODE_NETWORK \
      --output-text
    ```

トランザクションが消えていれば問題ありません。

```text
                           TxHash                                 TxIx        Lovelace
----------------------------------------------------------------------------------------
```

---