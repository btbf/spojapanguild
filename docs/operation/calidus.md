# **Calidus Pool Key設定**

!!! info "概要"
    - ステークプールの所有権を証明するための署名技術
    - 既存のCIP-22や少額送金による、プール秘密鍵やvrf秘密鍵を頻繁に使用することなく所有権を証明できます。
    - Cardano対応のライトウォレットにも復元可能でWebベースプラットフォームでも利用可能
    - 今後Calidus Pool Keyに対応した多様なサービスがリリース予定


## **1.cardano-signerインストール**

### **ブロックプロデューサー**

**ダウンロード**
=== "ブロックプロデューサーノード"  
    ```
    signer_release="$(curl -s https://api.github.com/repos/gitmachtl/cardano-signer/releases/latest | jq -r '.tag_name' | sed -e "s/^.\{1\}//")"
    cd $HOME/git
    wget -q https://github.com/gitmachtl/cardano-signer/releases/download/v${signer_release}/cardano-signer-${signer_release}_linux-x64.tar.gz
    ```
    ```
    tar -xzvf cardano-signer-${signer_release}_linux-x64.tar.gz
    rm cardano-signer-${signer_release}_linux-x64.tar.gz
    ```

**インストール** 
=== "ブロックプロデューサーノード"
    ```
    sudo cp cardano-signer /usr/local/bin/cardano-signer
    ```

**バージョン確認**
=== "ブロックプロデューサーノード"
    ```
    cardano-signer --version
    ```

### **エアギャップ**

!!! important "ファイル転送"
    BPの`$HOME/git`にある`cardano-signer`をエアギャップマシンの`$HOME/git`にコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|cardano-signer| B[エアギャップ];
    ```

**システムフォルダへコピーする**
=== "エアギャップマシン"  
    ```
    cd $HOME/git
    chmod 755 cardano-signer
    sudo cp cardano-signer /usr/local/bin/cardano-signer
    ```

**バージョン確認** 
=== "エアギャップマシン" 
    ```
    cardano-signer --version
    ```

## **2.Calidusキー作成**

!!! danger "Calidusキーとjsonファイルの取り扱いについて"
    - 通常のウォレットと同じ性質のペアキーとなります。
    - `Calidus-MnemonicsKey.json`にはライトウォレットに復元するための`Mnemonics`(復元シードフレーズ)が含まれています。
    - 万が一このキーを紛失した場合でも差し替え可能ですが、もしADAを保持している場合は出金が出来なくなりますのでご注意ください。
    - 複数のデバイスにバックアップすることをオススメします。
    - <font color=red>一つのcalidusペアキーで複数のプールを登録できます</font>

??? "一つのペアキーで複数プールを登録する場合はこちら"
    1. 1プール目のエアギャップ領域で`myCalidusKey`ペアキー発行する。
    2. 2プール目のエアギャップ領域($HODE_HOME)に`calidus`ディレクトリを作成する
    ```
    mkdir -p $NODE_HOME/calidus
    ```
    3. 作成したディレクトリに`myCalidusKey`**ペアキーのみ**をコピーする
    4. 「3.メタデータ作成」から実行する

**`myCalidusKey`ペアキー発行**

=== "エアギャップマシン"
    ```
    mkdir -p $NODE_HOME/calidus
    cd $NODE_HOME/calidus
    cardano-signer keygen --path payment \
        --out-skey myCalidusKey.skey \
        --out-vkey myCalidusKey.vkey \
        --json-extended \
        --out-file Calidus-MnemonicsKey.json
    ```

## **3.メタデータ作成**

**プール秘密鍵で署名したメタデータ作成します**  
=== "エアギャップマシン"
    ```
    chmod u+rwx $HOME/cold-keys
    cardano-signer sign --cip88 \
        --calidus-public-key $NODE_HOME/calidus/myCalidusKey.vkey \
        --secret-key $HOME/cold-keys/node.skey \
        --json \
        --out-file $NODE_HOME/calidus/myCalidusRegistrationMetadata.json
    chmod a-rwx $HOME/cold-keys
    ```


## **5.オンチェーン登録**

最新のスロット番号を取得します

=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    currentSlot=$(cardano-cli conway query tip $NODE_NETWORK | jq -r '.slot')
    echo Current Slot: $currentSlot
    ```

!!! info ""
    自身プールウォレットアドレス宛に10ADAとメタデータを含んだTxを送信します。

=== "ブロックプロデューサーノード"
    ```bash
    amountToSend=10000000
    echo "送金額: $amountToSend Lovelace"
    ```

送金先のアドレスを設定します。

=== "ブロックプロデューサーノード"
    ```bash
    destinationAddress=$(echo $(cat $NODE_HOME/payment.addr))
    echo 送金先: $destinationAddress
    ```

payment.addrの残高を算出します。

=== "ブロックプロデューサーノード"
    ```bash
    cardano-cli conway query utxo \
        --address $(cat payment.addr) \
        $NODE_NETWORK > fullUtxo.out
    ```
    ```
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
    
    ウォレット残高情報ファイル作成
    ```bash
    cat > $NODE_HOME/wallet_balance.sh << EOF 
    #!/bin/bash
    total_balance=$total_balance
    tx_in="$tx_in"
    tempBalanceAmont=$tempBalanceAmont
    destinationAddress=$destinationAddress
    amountToSend=$amountToSend
    currentSlot=$currentSlot
    EOF
    ```

    !!! important "ファイル転送"
        BPの`$NODE_HOME`にある`wallet_balance.sh`と`params.json`をエアギャップマシンのcnodeディレクトリにコピーします。
        ``` mermaid
        graph LR
            A[BP] -->|wallet_balance.sh / params.json| B[エアギャップ];
        ```

エアギャップでウォレット残高を読み込む

=== "エアギャップ"
    ```
    source $NODE_HOME/wallet_balance.sh
    ```

トランザクションファイルを作成
=== "エアギャップ"
    ```bash
    cd $NODE_HOME
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${tempBalanceAmont} \
        --tx-out ${destinationAddress}+${amountToSend} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --metadata-json-file $NODE_HOME/calidus/myCalidusRegistrationMetadata.json \
        --fee 200000 \
        --out-file tx.tmp
    ```

最低手数料を出力します

=== "エアギャップ"
    ```bash
    fee=$(cardano-cli conway transaction calculate-min-fee \
        --tx-body-file tx.tmp \
        --witness-count 1 \
        --protocol-params-file params.json | awk '{ print $1 }')
    echo fee: $fee
    ```

手数料計算

=== "エアギャップ"
    ```bash
    txOut=$((${total_balance}-${fee}-${amountToSend}))
    echo Change Output: ${txOut}
    ```

トランザクションファイルを構築します

=== "エアギャップ"
    ```bash
    cardano-cli conway transaction build-raw \
        ${tx_in} \
        --tx-out $(cat payment.addr)+${txOut} \
        --tx-out ${destinationAddress}+${amountToSend} \
        --invalid-hereafter $(( ${currentSlot} + 10000)) \
        --metadata-json-file $NODE_HOME/calidus/myCalidusRegistrationMetadata.json \
        --fee ${fee} \
        --out-file tx.raw
    ```

トランザクションに署名します

=== "エアギャップ"
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

署名されたトランザクションを送信します

=== "ブロックプロデューサーノード"
    ウォレット残高情報ファイルを削除する
    ```
    rm $NODE_HOME/wallet_balance.sh
    ```
    トランザクションIDを確認する
    ```
    tx_id=$(cardano-cli conway transaction txid --tx-body-file $NODE_HOME/tx.signed)
    echo TxID:$tx_id
    ```

    トランザクションを送信する
    ```bash
    cardano-cli conway transaction submit \
        --tx-file tx.signed \
        $NODE_NETWORK
    ```

> Transacsion Successfully submittedと表示されれば成功

## **6.オンチェーン確認**
```
curl -s "https://api.koios.rest/api/beta/pool_calidus_keys?pool_id_bech32=eq.$(cat $NODE_HOME/pool.id-bech32)" | jq .
```
> 戻り値に、`"pool_status": "registered"`の項目があれば登録成功
