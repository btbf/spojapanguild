# **5.プール運営で使用するアドレスを作成する**

!!! failure "注意"
    プール登録後、以下の手順をやり直しすると変更手続きが面倒になるのでご注意ください。



## **1.プロトコルパラメータの取得**

=== "ブロックプロデューサーノード" 
    ```bash
    cd $NODE_HOME
    cardano-cli conway query protocol-parameters \
        $NODE_NETWORK \
        --out-file params.json
    ```


!!! hint "運用上のセキュリティに関する重要なアドバイス"
    キーの生成はエアギャップオフラインマシンで生成する必要があり、インターネット接続が無くても生成可能です。  
    paymentキーは支払い用アドレスに使用され、stakeキーはプール委任アドレス用の管理に使用されます。


## **2.支払いアドレスキーの作成**

=== "エアギャップオフラインマシン"

```bash
cd $NODE_HOME
cardano-cli conway address key-gen \
    --verification-key-file payment.vkey \
    --signing-key-file payment.skey
```
## **3. ステークアドレスキーの作成**

=== "エアギャップオフラインマシン"

```bash
cardano-cli conway stake-address key-gen \
    --verification-key-file stake.vkey \
    --signing-key-file stake.skey
```

## **4.ステークアドレスの作成**

=== "エアギャップオフラインマシン"

```bash
cardano-cli conway stake-address build \
    --stake-verification-key-file stake.vkey \
    --out-file stake.addr \
    $NODE_NETWORK
```

## **5.支払い用アドレスの作成**
=== "エアギャップオフラインマシン"

```bash
cardano-cli conway address build \
    --payment-verification-key-file payment.vkey \
    --stake-verification-key-file stake.vkey \
    --out-file payment.addr \
    $NODE_NETWORK
```

上書き・削除されないようパーミッションを変更する。

=== "エアギャップオフラインマシン"

```bash
chmod 400 payment.vkey
chmod 400 payment.skey
chmod 400 stake.vkey
chmod 400 stake.skey
chmod 400 stake.addr
chmod 400 payment.addr
```

| ファイル      | 用途                          |
| ----------- | ------------------------------------ |
| `payment.vkey`       | paymentアドレス公開鍵  |
| `payment.skey`       | paymentアドレス秘密鍵 |
| `payment.addr`    | paymentアドレスファイル |
| `stake.vkey`       | ステークアドレス公開鍵  |
| `stake.skey`       | ステークアドレス秘密鍵 |
| `stake.addr`    | ステークアドレスファイル |

!!! danger "注意"
    これらのファイルは紛失しないようにご注意ください。特に.vkey/.skeyを無くした場合、プール報酬や誓約金を引き出せなくなります。複数の外部デバイスにバックアップを取ってください。


<!--{% tab title="Mnemonic Method" %}
{% hint style="info" %}
このプロセスを提案してくれた [ilap](https://gist.github.com/ilap/3fd57e39520c90f084d25b0ef2b96894)のクレジット表記です。
{% endhint %}

{% hint style="success" %}
**この方法によるメリット**: 委任をサポートするウォレット（ダイダロス、ヨロイなど）からプール報酬を確認することが可能になります。
{% endhint %}

15ワードまたは24ワード長のシェリー互換ニーモニックを、オフラインマシンのダイダロスまたはヨロイを使用して作成します。

ブロックプロデューサーノードに `cardano-wallet`をダウンロードします。

```bash
###
### On ブロックプロデューサーノード,
###
cd $NODE_HOME
wget https://hydra.iohk.io/build/3662127/download/1/cardano-wallet-shelley-2020.7.28-linux64.tar.gz
```

正規ウォレットであることを確認するために、SHA256チェックを実行します。

```bash
echo "f75e5b2b4cc5f373d6b1c1235818bcab696d86232cb2c5905b2d91b4805bae84 *cardano-wallet-shelley-2020.7.28-linux64.tar.gz" | shasum -a 256 --check
```

チェックが成功した例：

> cardano-wallet-shelley-2020.7.28-linux64.tar.gz: OK

{% hint style="danger" %}
SHA256チェックで **OK**が出た場合のみ続行してください。
{% endhint %}

USBキーまたはその他のリムーバブルメディアを介して、カルダノウォレットをエアギャップオフラインマシンに転送します。

ウォレットファイルを抽出してクリーンアップします。

```bash
###
### On エアギャップオフラインマシン,
###
tar -xvf cardano-wallet-shelley-2020.7.28-linux64.tar.gz
rm cardano-wallet-shelley-2020.7.28-linux64.tar.gz
```

スクリプトファイルを作成します。`extractPoolStakingKeys.sh`

```bash
###
### On エアギャップオフラインマシン,
###
cat > extractPoolStakingKeys.sh << HERE
#!/bin/bash 

CADDR=\${CADDR:=\$( which cardano-address )}
[[ -z "\$CADDR" ]] && ( echo "cardano-address cannot be found, exiting..." >&2 ; exit 127 )

CCLI=\${CCLI:=\$( which cardano-cli )}
[[ -z "\$CCLI" ]] && ( echo "cardano-cli cannot be found, exiting..." >&2 ; exit 127 )

OUT_DIR="\$1"
[[ -e "\$OUT_DIR"  ]] && {
           echo "The \"\$OUT_DIR\" is already exist delete and run again." >&2 
           exit 127
} || mkdir -p "\$OUT_DIR" && pushd "\$OUT_DIR" >/dev/null

shift
MNEMONIC="\$*"

# Generate the master key from mnemonics and derive the stake account keys 
# as extended private and public keys (xpub, xprv)
echo "\$MNEMONIC" |\
"\$CADDR" key from-recovery-phrase Shelley > root.prv

cat root.prv |\
"\$CADDR" key child 1852H/1815H/0H/2/0 > stake.xprv

cat root.prv |\
"\$CADDR" key child 1852H/1815H/0H/0/0 > payment.xprv

TESTNET=0
MAINNET=1
NETWORK=\$MAINNET

cat payment.xprv |\
"\$CADDR" key public | tee payment.xpub |\
"\$CADDR" address payment --network-tag \$NETWORK |\
"\$CADDR" address delegation \$(cat stake.xprv | "\$CADDR" key public | tee stake.xpub) |\
tee base.addr_candidate |\
"\$CADDR" address inspect
echo "Generated from 1852H/1815H/0H/{0,2}/0"
cat base.addr_candidate
echo

# XPrv/XPub conversion to normal private and public key, keep in mind the 
# keypars are not a valind Ed25519 signing keypairs.
TESTNET_MAGIC="--testnet-magic 42"
MAINNET_MAGIC="$NODE_NETWORK"
MAGIC="\$MAINNET_MAGIC"

SESKEY=\$( cat stake.xprv | bech32 | cut -b -128 )\$( cat stake.xpub | bech32)
PESKEY=\$( cat payment.xprv | bech32 | cut -b -128 )\$( cat payment.xpub | bech32)

cat << EOF > stake.skey
{
    "type": "StakeExtendedSigningKeyShelley_ed25519_bip32",
    "description": "",
    "cborHex": "5880\$SESKEY"
}
EOF

cat << EOF > payment.skey
{
    "type": "PaymentExtendedSigningKeyShelley_ed25519_bip32",
    "description": "Payment Signing Key",
    "cborHex": "5880\$PESKEY"
}
EOF

"\$CCLI" shelley key verification-key --signing-key-file stake.skey --verification-key-file stake.evkey
"\$CCLI" shelley key verification-key --signing-key-file payment.skey --verification-key-file payment.evkey

"\$CCLI" shelley key non-extended-key --extended-verification-key-file payment.evkey --verification-key-file payment.vkey
"\$CCLI" shelley key non-extended-key --extended-verification-key-file stake.evkey --verification-key-file stake.vkey


"\$CCLI" shelley stake-address build --stake-verification-key-file stake.vkey \$MAGIC > stake.addr
"\$CCLI" shelley address build --payment-verification-key-file payment.vkey \$MAGIC > payment.addr
"\$CCLI" shelley address build \
    --payment-verification-key-file payment.vkey \
    --stake-verification-key-file stake.vkey \
    \$MAGIC > base.addr

echo "Important the base.addr and the base.addr_candidate must be the same"
diff base.addr base.addr_candidate
popd >/dev/null
HERE
```

バイナリーファイルを使用するには、アクセス権を追加してパスをエクスポートします。

```bash
###
### On エアギャップオフラインマシン,
###
chmod +x extractPoolStakingKeys.sh
export PATH="$(pwd)/cardano-wallet-shelley-2020.7.28:$PATH"
```

キーを抽出し、ニーモニックフレーズで更新します。

```bash
###
### On エアギャップオフラインマシン,
###
./extractPoolStakingKeys.sh extractedPoolKeys/ <15|24-word length mnemonic>
```

{% hint style="danger" %}
**重要**: **base.addr** と **base.addr\_candidate** は同じでなければなりません。
{% endhint %}

新しいステークキーは次のフォルダーにあります。 `extractedPoolKeys/`

`paymentとstake`で使用するペアキーを `$NODE_HOME`に移動します。

```bash
###
### On エアギャップオフラインマシン,
###
cd extractedPoolKeys/
cp stake.vkey stake.skey stake.addr payment.vkey payment.skey base.addr $NODE_HOME
cd $NODE_HOME
#Rename to base.addr file to payment.addr
mv base.addr payment.addr
```

{% hint style="info" %}
**payment.addr**はあなたのプール誓約金を保持しているアドレスになります。
{% endhint %}

ニーモニックフレーズを保護するには、履歴とファイルを削除します。

```bash
###
### On エアギャップオフラインマシン,
###
history -c && history -w
rm -rf $NODE_HOME/cardano-wallet-shelley-2020.7.28
```

すべてのターミナルウィンドウを閉じ、履歴のない新しいウィンドウを開きます。

{% hint style="success" %}
いかがでしょうか？ウォレットでプール報酬を確認することが可能になりました。
{% endhint %}
{% endtab %} -->


## **6.支払い用アドレスに入金する**

次のステップは、あなたの支払いアドレスに送金する手順です。

!!! important "ファイル転送"
    エアギャップマシンの**payment.addr**と**stake.addr** をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|payment.addr / stake.addr| B[BP];
    ```

=== "メインネット"

    !!! info "以下のウォレットから送金が可能です"
        * ダイダロス / ヨロイウォレット / nami / ccvault.io

    支払いアドレスを表示させ、このアドレスに送金します。

    ```bash
    echo "$(cat $NODE_HOME/payment.addr)"
    ```
    !!! Question "何ADA入金したらいい？"
        初回はテストで少額から入金してください  
          
        payment.addrは以下の役割があるため必要分入金してください  
        ●プール登録料の支払い(500ADA)  
        ●ステークアドレス登録料の支払い(2ADA)  
        ●トランザクション手数料の支払い(数ADA)  
        ●誓約金の預け先(誓約として設定したい額)  

=== "テストネット"
    !!! info "テストネット用tADAの請求"
        [テストネット用口座](https://docs.cardano.org/cardano-testnet/tools/faucet/)にあなたの支払い用アドレスをリクエストします。  
        テストネット用口座は24時間ごとに10000tADAを提供します。

    次のコードを実行し。支払いアドレスを表示させます。

    ```bash
    echo "$(cat $NODE_HOME/payment.addr)"
    ```

    このアドレスを上記ページのリクエスト欄に貼り付けます。


支払い用アドレスに送金後、残高を確認してください。

!!! hint ""
    ノードをブロックチェーンと完全に同期させる必要があります。完全に同期されていない場合は、残高が表示されません。


=== "ブロックプロデューサーノード"

    ```bash
    cardano-cli conway query utxo \
        --address $(cat payment.addr) \
        $NODE_NETWORK
    ```

    次のように表示されたら入金完了です。

    ```text
                            TxHash                                 TxIx        Lovelace
    ----------------------------------------------------------------------------------------
    100322a39d02c2ead....                                              0        1000000000
    ```