# カルダノ財団SPO投票マニュアル

!!! note "概要"
    * 投票トランザクション [fae7bda85acb99c513aeab5f86986047b6f6cbd33a8e11f11c5005513a054dc8](https://jp.cexplorer.io/tx/fae7bda85acb99c513aeab5f86986047b6f6cbd33a8e11f11c5005513a054dc8/metadata#data)
    * 投票期限：413エポック終了まで
    * CIP-0094ダッシュボード  
    Adastat.net [[Mainnet]](https://adastat.net/polls) / Cardanoscan.io [[Mainnet]](https://cardanoscan.io/spo-polls/)
    * トランザクション手数料のみで投票できます
    * CIP-0094に対応したcardano-cli(v8.0.0-untested または v8.0.0)が必要です
    * 投票は初回１回のみが有効です。

## 1.SJG TOOLで投票する

!!! Question "SJG TOOL投票仕様"
    * 投票データに簡易メッセージを添付可能！  
    [ADASTAT](https://adastat.net/polls/96861fe7da8d45ba5db95071ed3889ed1412929f33610636c072a4b5ab550211)に実装された投票データ簡易メッセージを表示できます。
    * インストール済みのCLIがCIP-0094非対応の場合は、`cardano-cli v8.0.0-untested`を別途自動インストールします。これは投票のみに使用し、通常のオペレーションには使用しません。
    * エアギャップに`cardano-cli v8.0.0-untested`をインストールする必要はありません。
    * 投票内容の自動翻訳はAPI自動翻訳のため、正しい日本語になっていない場合があります。 

1-1. SJG TOOLを起動し、v5.3へアップグレードしてください。

1-2. `[5] SPO投票ツール` を選択してください

1-3. 投票トランザクションハッシュを入力してください 

```
fae7bda85acb99c513aeab5f86986047b6f6cbd33a8e11f11c5005513a054dc8
```

1-4. 画面の指示に従って進めてください。(中断することも可能です)

1-5. 投票確認
CIP-0094ダッシュボードで自身の投票を確認してみましょう！  
    Adastat.net [[Mainnet]](https://adastat.net/polls) / Cardanoscan.io [[Mainnet]](https://cardanoscan.io/spo-polls/)

以上です。

## 2.CLIコマンドで投票する
!!! Warning "CLIコマンド投票仕様"
    * 投票データ簡易メッセージ添付には対応していません。添付したい場合は各自でメタデータファイルを編集するかSJGTOOLを利用してください。

2-1.CLIバージョンチェック
```
cardano-cli version
```
> v8.0.0はCIP-0094に対応しています。

CLIパスを設定する
```
cli_path=$(which cardano-cli)
```

作業ディレクトリを作成する
```
mkdir $HOME/git/spo-poll && cd $HOME/git/spo-poll
```

!!! Danger "CLI v1.35.7以下の場合"
    CIP-0094に対応したCLIが必要のため、以下を実行し`v8.0.0-untested`をダウンロードしてください。 これは投票のみに使用し、通常のオペレーションには使用しません。

    v8.0.0-untestedをダウンロードする
    ```
    wget -q https://github.com/btbf/spojapanguild/raw/d7cd9792ab4cb532b74a8cd1bf30de3c1c03b8a6/scripts/spo-poll/cardano-cli.gz
    gzip -d cardano-cli.gz
    chmod 755 $HOME/git/spo-poll/cardano-cli
    ```
    バージョン確認
    ```
    $HOME/git/spo-poll/cardano-cli version
    ```
    > cardano-cli 8.0.0 - linux-x86_64 - ghc-8.10
    > git rev 0000000000000000000000000000000000000000

    CLIパスを上書きする
    ```
    cli_path=$HOME/git/spo-poll/cardano-cli
    ```

    * エアギャップに`cardano-cli v8.0.0-untested`をインストールする必要はありません。


投票トランザクションハッシュを設定する
```
txHash="fae7bda85acb99c513aeab5f86986047b6f6cbd33a8e11f11c5005513a054dc8"
```

投票Cborデータ(json)をダウンロードする
```
wget https://raw.githubusercontent.com/cardano-foundation/CIP-0094-polls/main/networks/${NODE_CONFIG}/${txHash}/poll.json -O $HOME/git/spo-poll/poll_${txHash}-CBOR.json
```

投票ファイル作成コマンドを実行する

```
${cli_path} governance answer-poll --poll-file $HOME/git/spo-poll/poll_${txHash}-CBOR.json > $HOME/git/spo-poll/poll_${txHash}-poll-answer.json
```

投票トランザクション送信準備

=== "ブロックプロデューサーノード"
    ウォレット残高確認
    ```
    cd $NODE_HOME
    cardano-cli conway query utxo \
        --address $(cat payment.addr) \
        $NODE_NETWORK > fullUtxo.out

    tail -n +3 fullUtxo.out | sort -k3 -nr | sed -e '/lovelace + [0-9]/d' > balance.out

    cat balance.out
    ```

    UTXO計算
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

    投票用トランザクションファイルを作成する
    ```
    cd $NODE_HOME
    cardano-cli conway transaction build \
        $NODE_NETWORK \
        ${tx_in} \
        --change-address $(cat payment.addr) \
        --metadata-json-file $HOME/git/spo-poll/poll_${txHash}-poll-answer.json \
        --json-metadata-detailed-schema \
        --required-signer-hash $(cat pool.id) \
        --out-file $NODE_HOME/poll-answer.tx
    ```

!!! important "ファイル転送"
    BPの`poll-answer.tx` をエアギャップマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|poll-answer.tx| B[エアギャップ];
    ```

エアギャップで署名ファイルを作成します。

=== "エアギャップオフラインマシン"
    ```
    cd $NODE_HOME
    chmod u+rwx $HOME/cold-keys
    cardano-cli conway transaction sign \
        --tx-body-file poll-answer.tx \
        --signing-key-file $HOME/cold-keys/node.skey \
        --signing-key-file payment.skey \
        $NODE_NETWORK \
        --out-file poll-answer-tx.signed
    chmod a-rwx $HOME/cold-keys
    ```

!!! important "ファイル転送"
    エアギャップの`poll-answer-tx.signed` をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|poll-answer-tx.signed| B[BP];
    ```

BPでトランザクションを送信します
=== "ブロックプロデューサーノード"
    ```
    submit_txHash=$(cardano-cli conway transaction txid --tx-file $NODE_HOME/poll-answer.tx)
    cardano-cli conway transaction submit --tx-file $NODE_HOME/poll-answer-tx.signed $NODE_NETWORK
    ```

数分後にトランザクションメタデータを確認する
```
curl -sX POST "https://api.koios.rest/api/v0/tx_metadata" -H "accept: application/json" -H "content-type: application/json"  -d "{\"_tx_hashes\":[\"${submit_txHash}\"]}" | jq .
```

### 投票確認
CIP-0094ダッシュボードで自身の投票を確認してみましょう！  
Adastat.net [[Mainnet]](https://adastat.net/polls) / Cardanoscan.io [[Mainnet]](https://cardanoscan.io/spo-polls/)

以上です。