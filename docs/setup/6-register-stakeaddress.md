# **6.ステークアドレスの登録**



## **1.ステーク証明書を作成する**

=== "エアギャップオフラインマシン"

    ```bash
    cd $NODE_HOME
    cardano-cli conway stake-address registration-certificate \
        --stake-verification-key-file stake.vkey \
        --out-file stake.cert
    ```
!!! important "ファイル転送"
    エアギャップマシンの**stake.cert** をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|stake.cert| B[BP];
    ```

## **2.ステークアドレスを登録する**
!!! hint ""
    ステークアドレスの登録には2000000 lovelace \(2ADA\)が必要です。

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

    tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

    cat balance.out
    ```

UTXOを算出します
=== "ブロックプロデューサーノード"

    ```sh
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

keyDepositの値を出力します。
=== "ブロックプロデューサーノード"

    ```bash
    keyDeposit=$(cat $NODE_HOME/params.json | jq -r '.stakeAddressDeposit')
    echo keyDeposit: $keyDeposit
    ```

トランザクション仮ファイルを作成します
=== "ブロックプロデューサーノード"

    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+$(( ${total_balance} - ${keyDeposit} )) \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee 200000 \
        --out-file tx.tmp \
        --certificate stake.cert
    ```

現在の最低手数料を計算します。
=== "ブロックプロデューサーノード"

    ```bash
    fee=$(cardano-cli conway transaction calculate-min-fee \
        --tx-body-file tx.tmp \
        --witness-count 2 \
        --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee
    ```


計算結果を出力します。
=== "ブロックプロデューサーノード"

    ```bash
    txOut=$((${total_balance}-${keyDeposit}-${fee}))
    echo Change Output: ${txOut}
    ```


ステークアドレスを登録するトランザクションファイルを作成します。
=== "ブロックプロデューサーノード"

    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${txOut} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee ${fee} \
        --certificate-file stake.cert \
        --out-file tx.raw
    ```

!!! important "ファイル転送"
    BPの**tx.raw**をエアギャップマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|tx.raw| B[エアギャップ];
    ```

paymentとstakeの秘密鍵でトランザクションファイルに署名します。

=== "エアギャップマシン"

    ```bash
    cd $NODE_HOME
    cardano-cli conway transaction sign \
        --tx-body-file tx.raw \
        --signing-key-file payment.skey \
        --signing-key-file stake.skey \
        $NODE_NETWORK \
        --out-file tx.signed
    ```

!!! important "ファイル転送"
    エアギャップマシンの**tx.signed**をBPのcnodeディレクトリにコピーします。

    ``` mermaid
    graph LR
        A[エアギャップ] -->|tx.signed| B[BP];
    ```

署名されたトランザクションを送信します。

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway transaction submit \
        --tx-file tx.signed \
        $NODE_NETWORK
    ```
    > Transacsion Successfully submittedと表示されれば成功
