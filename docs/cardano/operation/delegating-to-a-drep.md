# **委任代表者（DRep）への委任**

Cardanoエコシステムでは、委任代表者（DRep）が、ADA保有者に代わってガバナンスアクションへの投票を行います。

投票権をDRepに委任するには、投票委任証明書を作成し、ブロックチェーンに送信します。

!!! info "投票権の委任先"
    - Registered DReps（登録されたDRep）  
      登録されたDRepに投票権を委任します。
    - Always Abstain（常に棄権）  
      すべてのガバナンスアクションに対して棄権します。
    - Always No Confidence（常に不信任）  
      すべてのガバナンスアクションに対して不信任を表明します。

投票権を委任するには、ステーク鍵を使用して投票委任証明書（`vote-deleg.cert`）を作成します。

=== "エアギャップ"

    **governanceディレクトリの作成**

    ```bash
    mkdir -p $NODE_HOME/governance
    ```

    **変数`drep_id`に代入**  
    投票権を委任したい DRep ID を代入します。  
    > Explorerに表示される HEX（例: `22...`）をコピーして代入してください。

    ```bash
    drep_id=
    ```

    委任するDRepを検索：  
    [adastat.net](https://adastat.net/dreps){target="_blank" rel="noopener"}

    **`drep.id`ファイルの作成**

    ```bash
    cat > $NODE_HOME/governance/drep.id << EOF
    ${drep_id}
    EOF
    ```

    **`vote-deleg.cert`ファイルの作成**

    ```bash
    cd $NODE_HOME
    cardano-cli latest stake-address vote-delegation-certificate \
      --stake-verification-key-file stake.vkey \
      --drep-key-hash $(sed 's/^..//' $NODE_HOME/governance/drep.id) \
      --out-file $NODE_HOME/governance/vote-deleg.cert
    ```

    ??? info "棄権または不信任を表明したい場合"

        ガバナンスプロセスを棄権するには、次のように入力します。

        ```bash
        cd $NODE_HOME
        cardano-cli latest stake-address vote-delegation-certificate \
          --stake-verification-key-file stake.vkey \
          --always-abstain \
          --out-file $NODE_HOME/governance/vote-deleg.cert
        ```

        常に不信任を表明するには、次のように入力します。

        ```bash
        cd $NODE_HOME
        cardano-cli latest stake-address vote-delegation-certificate \
          --stake-verification-key-file stake.vkey \
          --always-no-confidence \
          --out-file $NODE_HOME/governance/vote-deleg.cert
        ```

!!! tip
    BPで事前に governance ディレクトリを作成しておきます。

    ```bash
    mkdir -p $NODE_HOME/governance
    ```

!!! info "ファイル転送"
    エアギャップの `$NODE_HOME/governance/vote-deleg.cert` を、BP の `$NODE_HOME/governance` ディレクトリにコピーします。

=== "BP"

    **手数料支払い用UTxOの選択**
    > トランザクション手数料は`payment.addr`から引き落とされますので誓約（Pledge）を下回らないようご注意ください。

    ```bash
    tx_in=$(
      cardano-cli latest query utxo \
        --address "$(cat $NODE_HOME/payment.addr)" \
        ${NODE_NETWORK} \
        --output-json \
      | jq -r '
        to_entries
        | map(
            select((.value.referenceScript // null) == null)
            | select((.value.datum // null) == null)
            | select((.value.inlineDatum // null) == null)
            | select((.value.inlineDatumRaw // null) == null)
            | select((.value.datumhash // null) == null)
          )
        | sort_by(.value.value.lovelace) | reverse
        | if length > 0 then .[0].key else empty end
      '
    )

    if [ -z "${tx_in}" ]; then
      echo "WARNING: 使用可能なUTxOが見つかりません。"
      echo "payment.addr のUTxOを確認してください。"
    else
      echo "tx_in: ${tx_in}"
    fi
    ```

    **投票委任証明書を含むトランザクションのビルド**

    ```bash
    cardano-cli latest transaction build \
      ${NODE_NETWORK} \
      --tx-in "${tx_in}" \
      --change-address "$(cat $NODE_HOME/payment.addr)" \
      --certificate-file $NODE_HOME/governance/vote-deleg.cert \
      --witness-override 2 \
      --out-file $NODE_HOME/governance/tx.raw
    ```

!!! info "ファイル転送"
    BP の `$NODE_HOME/governance/tx.raw` を、エアギャップの `$NODE_HOME/governance` ディレクトリにコピーします。

**トランザクションに署名**

=== "エアギャップ"

    ```bash
    cd $NODE_HOME
    cardano-cli latest transaction sign \
      --tx-body-file $NODE_HOME/governance/tx.raw \
      --signing-key-file payment.skey \
      --signing-key-file stake.skey \
      ${NODE_NETWORK} \
      --out-file $NODE_HOME/governance/tx.signed
    ```

!!! info "ファイル転送"
    エアギャップの `$NODE_HOME/governance/tx.signed` を、BP の `$NODE_HOME/governance` ディレクトリにコピーします。

**署名されたトランザクションの送信**

=== "BP"

    ```bash
    cardano-cli latest transaction submit \
        --tx-file $NODE_HOME/governance/tx.signed \
        ${NODE_NETWORK}
    ```

    > Transaction successfully submitted. Transaction hash is:  
    > {"txhash":"****************************************************************"}