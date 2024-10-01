!!! info "概要"
    - この投票手順はガバナンスアクションのSPO投票のみに使用できます。
    - SJG Toolに実装しているコマンドとは異なりますが実行結果は同じです。
    - 投票にはトランザクション手数料が必要です。
    - トランザクション手数料はpayment.addrから引き落とされます。プール誓約を下回らないようご注意ください。

    ガバナンスアクション確認サイト  
    [https://cardanoscan.io/govActions](https://cardanoscan.io/govActions)  
    [https://gov.tools/governance_actions](https://gov.tools/governance_actions)


=== "BP/エアギャップ"
    初めて作業する場合はガバナンス作業用ディレクトリを作成する
    ```
    mkdir -p $NODE_HOME/governance
    ```


## 1.投票ファイル作成

!!! tip "投票例"  
    ガバナンスアクショントランザクションID:`59fd353253eb177e2104e8f23ea4c63e3d32ef95c7865d03e90d3884424dc1db`に対して
    `No`で投票する場合

エアギャップで投票ファイルを作成する
=== "エアギャップ"

    1. `gov_id`変数に投票するガバナンスアクションのトランザクションIDを指定する(Bech32IDは指定できない) 
    2. 投票フラグは次の3つのいずれかを指定 `--yes` `--no` `--abstain`  
    

    ```
    gov_id="59fd353253eb177e2104e8f23ea4c63e3d32ef95c7865d03e90d3884424dc1db"
    ```

    ```
    chmod u+rwx $HOME/cold-keys
    cd $NODE_HOME
    cardano-cli conway governance vote create \
    --no \
    --governance-action-tx-id $gov_id \
    --governance-action-index "0" \
    --cold-verification-key-file $HOME/cold-keys/node.vkey \
    --out-file $NODE_HOME/governance/vote.file
    ```

!!! important "ファイル転送"
    エアギャップの**vote.file**をBPの~/cnode/governance/ディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|vote.file| B[BP];
    ```

**ハッシュ値確認**
エアギャップとBPで`vote.file`ファイルハッシュを比較する  
<font color="red">必ずハッシュ値が一致していることを確認してください</font>

=== "エアギャップ"
```bash
sha256sum $NODE_HOME/governance/vote.file
```

=== "BP"
```bash
sha256sum $NODE_HOME/governance/vote.file
```


## 2.トランザクションファイル作成
=== "BP"

    payment.addrの残高を取得する
    ```
    cd $NODE_HOME
    cardano-cli query utxo \
        --address $(cat payment.addr) \
        $NODE_NETWORK > fullUtxo.out

    tail -n +3 fullUtxo.out | sort -k3 -nr | sed -e '/lovelace + [0-9]/d' > balance.out

    cat balance.out
    ```

    未使用UTXOを取得する
    ```
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

    ```
    cd $NODE_HOME
    cardano-cli conway transaction build \
    $NODE_NETWORK \
    ${tx_in} \
    --change-address $(cat $NODE_HOME/payment.addr) \
    --vote-file $NODE_HOME/governance/vote.file \
    --witness-override 2 \
    --out-file $NODE_HOME/governance/vote-tx.raw
    ```

!!! important "ファイル転送"
    BPの**vote-tx.raw**をエアギャップマシンの~/cnode/governance/ディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|vote-tx.raw| B[エアギャップ];
    ```

**ハッシュ値確認**
BPとエアギャップで`vote-tx.raw`ファイルハッシュを比較する  
<font color="red">必ずハッシュ値が一致していることを確認してください</font>

=== "BP"
```bash
sha256sum $NODE_HOME/governance/vote-tx.raw
```

=== "エアギャップ"
```bash
sha256sum $NODE_HOME/governance/vote-tx.raw
```

## 3.署名ファイル作成
=== "エアギャップ"
    ```
    cardano-cli conway transaction sign \
    --tx-body-file $NODE_HOME/governance/vote-tx.raw \
    --signing-key-file $HOME/cold-keys/node.skey \
    --signing-key-file $NODE_HOME/payment.skey \
    --out-file $NODE_HOME/governance/vote-tx.signed

    chmod a-rwx $HOME/cold-keys
    ```

!!! important "ファイル転送"
    エアギャップの**vote-tx.signed**をBPの~/cnode/governance/ディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|vote-tx.signed| B[BP];
    ```

**ハッシュ値確認**
エアギャップとBPで`vote-tx.signed`ファイルハッシュを比較する  
<font color="red">必ずハッシュ値が一致していることを確認してください</font>

=== "エアギャップ"
```bash
sha256sum $NODE_HOME/governance/vote-tx.signed
```

=== "BP"
```bash
sha256sum $NODE_HOME/governance/vote-tx.signed
```

## 4.投票トランザクション送信
=== "BP"
    ```
    cd $NODE_HOME
    cardano-cli conway transaction submit \
    --tx-file $NODE_HOME/governance/vote-tx.signed \
    $NODE_NETWORK
    ```