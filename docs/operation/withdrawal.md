# **資金引き出し**

## **1 stake.addrからの引き出し**

!!! summary "概要"
    * 報酬は `stake.addr` アドレスに蓄積されていきます。  
    * **1回のトランザクションで引き出せる金額は残高全額のみです。**  
    (分割して引き出すことはできません)  
    * **トランザクション手数料はpayment.addrから引き落とされます。**

    **1-1 payment.addrへ送金する方法**は[こちら](#1-1-paymentaddr)

    **1-2 任意のアドレスへ送金する方法は**[こちら](#1-2)

!!! info "注意"
    入力ミスなどで送金が失敗しても責任は負えません。自己責任のもと実施下さい。  
    **payment.skey**と**stake.skey**は必ずオフライン環境で保管してください。  



### **1-1 payment.addrへ送金する方法**


現在のスロットを算出します

=== "ブロックプロデューサノード"
    ```bash
    currentSlot=$(cardano-cli conway query tip $NODE_NETWORK | jq -r '.slot')
    echo Current Slot: $currentSlot
    ```


ステークアドレスの残高を算出します

=== "ブロックプロデューサノード"
    ```bash
    cd $NODE_HOME
    rewardBalance=$(cardano-cli conway query stake-address-info \
        $NODE_NETWORK \
        --address $(cat stake.addr) | jq -r ".[0].rewardAccountBalance")
    echo rewardBalance: $rewardBalance
    ```


**1 ADA** = **1,000,000 lovelace.**と覚えましょう  

報酬の移動先となるpayment.addrを設定します。payment.addrには取引手数料を支払うための残高が必要です。


=== "ブロックプロデューサノード"
    ```bash
    destinationAddress=$(cat payment.addr)
    echo destinationAddress: $destinationAddress
    ```

payment.addrの残高を算出します

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway query utxo \
        --address $(cat payment.addr) \
        $NODE_NETWORK > fullUtxo.out

    tail -n +3 fullUtxo.out | sort -k3 -nr | sed -e '/lovelace + [0-9]/d' > balance.out

    cat balance.out
    ```

UTXOを算出します

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

    withdrawalString="$(cat stake.addr)+${rewardBalance}"
    tempRewardAmount=$(( ${total_balance}+${rewardBalance} ))
    ```


build-raw transactionコマンドを実行します。

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${tempRewardAmount} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee 200000 \
        --withdrawal ${withdrawalString} \
        --out-file tx.tmp
    ```



現在の最低料金を計算します。


=== "ブロックプロデューサノード"
    ```bash
    fee=$(cardano-cli conway transaction calculate-min-fee \
        --tx-body-file tx.tmp \
        --witness-count 2 \
        --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee
    ```


変更出力を計算します。

=== "ブロックプロデューサノード"
    ```bash
    txOut=$((${total_balance}-${fee}+${rewardBalance}))
    echo Change Output: ${txOut}
    ```

トランザクションをビルドします。

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${txOut} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee ${fee} \
        --withdrawal ${withdrawalString} \
        --out-file tx.raw
    ```

!!! important "ファイル転送"
    BPの`tx.raw` をエアギャップマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|tx.raw| B[エアギャップ];
    ```

支払いとステークの秘密鍵の両方を使用してトランザクションに署名します。


=== "エアギャップオフラインマシン"
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
    エアギャップの`tx.signed` をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|tx.signed| B[BP];
    ```

署名されたトランザクションを送信します。


=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway transaction submit \
        --tx-file tx.signed \
        $NODE_NETWORK
    ```

資金が到着したか確認します。


=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway query utxo \
        --address ${destinationAddress} \
        $NODE_NETWORK
    ```
> Transacsion Successfully submittedと表示されれば成功


更新されたラブレースの残高と報酬を表示します。

```text
                           TxHash                                 TxIx        Lovelace
----------------------------------------------------------------------------------------
100322a39d02c2ead....  
```


### **1-2 任意のアドレスへ送金する方法**

現在のスロットNoを算出します。

=== "ブロックプロデューサノード"
    ```bash
    currentSlot=$(cardano-cli conway query tip $NODE_NETWORK | jq -r '.slot')
    echo Current Slot: $currentSlot
    ```

入金先アドレスを指定します。


=== "ブロックプロデューサノード"
    ```bash
    destinationAddress=入金先アドレスを指定する
    echo destinationAddress: $destinationAddress
    ```



報酬アドレス残高を算出します


=== "ブロックプロデューサノード"
    ```bash
    cd $NODE_HOME
    rewardBalance=$(cardano-cli conway query stake-address-info \
        $NODE_NETWORK \
        --address $(cat stake.addr) | jq -r ".[0].rewardAccountBalance")
    echo rewardBalance: $rewardBalance
    ```

payment.addr の残高を算出


=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway query utxo \
        --address $(cat payment.addr) \
        $NODE_NETWORK > fullUtxo.out

    tail -n +3 fullUtxo.out | sort -k3 -nr | sed -e '/lovelace + [0-9]/d' > balance.out

    cat balance.out
    ```

UTXOを算出します

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

    withdrawalString="$(cat stake.addr)+${rewardBalance}"
    echo ${withdrawalString}
    ```


build-raw transactionコマンドを実行します。

=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${total_balance} \
        --tx-out ${destinationAddress}+${rewardBalance} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee 200000 \
        --withdrawal ${withdrawalString} \
        --out-file tx.tmp
    ```



現在の最低料金を計算します。


=== "ブロックプロデューサノード"
    ```bash
    fee=$(cardano-cli conway transaction calculate-min-fee \
        --tx-body-file tx.tmp \
        --witness-count 2 \
        --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee
    ```



変更出力を計算します。


=== "ブロックプロデューサノード"
    ```bash
    txOut=$((${total_balance}-${fee}))
    echo Change Output: ${txOut}
    ```



トランザクションをビルドします。


=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${txOut} \
        --tx-out ${destinationAddress}+${rewardBalance} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee ${fee} \
        --withdrawal ${withdrawalString} \
        --out-file tx.raw
    ```


!!! important "ファイル転送"
    BPの`tx.raw` をエアギャップマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|tx.raw| B[エアギャップ];
    ```


支払いとステークの秘密鍵の両方を使用してトランザクションに署名します。

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    cardano-cli conway transaction sign \
        --tx-body-file tx.raw \
        --signing-key-file payment.skey \
        --signing-key-file stake.skey \
        $NODE_NETWORK \
        --out-file tx.signed
    ```


**tx.signed** を **ブロックプロデューサノード**のcnodeディレクトリにコピーします。

!!! important "ファイル転送"
    エアギャップの`tx.signed` をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|tx.signed| B[BP];
    ```

署名されたトランザクションを送信します。


=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway transaction submit \
        --tx-file tx.signed \
        $NODE_NETWORK
    ```

> Transacsion Successfully submittedと表示されれば成功


資金が到着したか確認します。


=== "ブロックプロデューサノード"
    ```bash
    cardano-cli conway query utxo \
        --address ${destinationAddress} \
        $NODE_NETWORK
    ```



更新されたラブレースの残高と報酬を表示します。

```text
                           TxHash                                 TxIx        Lovelace
----------------------------------------------------------------------------------------
100322a39d02c2ead....  
```



## **2 Payment.addrからの引き出し**
!!! summary "概要"
    payment.addrから任意のアドレスへ送信する例です

!!! info "注意"
    * 入力ミスなどで送金が失敗しても責任は負えません。自己責任のもと実施下さい。  
    * **宣言した誓約(Pledge)分まで引き出してしまうと、プール報酬がゼロになりますのでご注意ください**
    * **payment.skey**と**stake.skey**は必ずオフライン環境で保管してください。  


最新のスロット番号を取得します


=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    currentSlot=$(cardano-cli conway query tip $NODE_NETWORK | jq -r '.slot')
    echo Current Slot: $currentSlot
    ```



lovelace形式で送信する金額を設定します。**1 ADA** = **1,000,000 lovelace** で覚えます。


=== "ブロックプロデューサーノード"
    ```bash
    amountToSend=10000000
    echo amountToSend: $amountToSend
    ```

送金先のアドレスを設定します。

=== "ブロックプロデューサーノード"
    ```bash
    destinationAddress=送金先アドレス
    echo destinationAddress: $destinationAddress
    ```


payment.addrの残高を算出します。

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

    tempBalanceAmont=$(( ${total_balance}-${amountToSend} ))
    ```

build-rawトランザクションコマンドを実行します。

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${tempBalanceAmont} \
        --tx-out ${destinationAddress}+${amountToSend} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee 200000 \
        --out-file tx.tmp
    ```

最低手数料を出力します

=== "ブロックプロデューサーノード"
    ```bash
    fee=$(cardano-cli conway transaction calculate-min-fee \
        --tx-body-file tx.tmp \
        --witness-count 1 \
        --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee
    ```



計算結果を出力します。


=== "ブロックプロデューサーノード"
    ```bash
    txOut=$((${total_balance}-${fee}-${amountToSend}))
    echo Change Output: ${txOut}
    ```



トランザクションファイルを構築します。


=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${txOut} \
        --tx-out ${destinationAddress}+${amountToSend} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --fee ${fee} \
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

署名されたトランザクションを送信します。


=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway transaction submit \
        --tx-file tx.signed \
        $NODE_NETWORK
    ```

> Transacsion Successfully submittedと表示されれば成功

入金されているか確認します。


=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway query utxo \
        --address ${destinationAddress} \
        $NODE_NETWORK \
    ```



先程指定した金額と一致していれば問題ないです。

```text
                           TxHash                                 TxIx        Lovelace
----------------------------------------------------------------------------------------
100322a39d02c2ead....                                              0        10000000
```