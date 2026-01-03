
# **SPO Midnightバリデーター登録**

## **midnight-nodeインストール**

midnight-nodeダウンロード
``` bash
mkdir -p $HOME/midnight
cd $HOME/midnight
wget -q --show-progress https://spojapanguild.net/node_config/midnight/testnet-02/midnight-node0.12.0.gz
```

midnight-node解凍
``` bash
gunzip -c midnight-node0.12.0.gz > midnight-node && rm midnight-node0.12.0.gz
```

```  bash
chmod +x midnight-node
```

バージョン確認
``` bash
./midnight-node --version
```
> midnight-node 0.12.0



設定ファイルダウンロード
``` bash
cd $HOME/midnight
wget -q --show-progress https://spojapanguild.net/node_config/midnight/testnet-02/pc-chain-config.json
wget -q --show-progress https://spojapanguild.net/node_config/midnight/testnet-02/chain-spec.json
wget -q --show-progress https://spojapanguild.net/node_config/midnight/testnet-02/addresses.json
```


## **パートナーチェーンキー生成**
``` bash
CFG_PRESET=testnet-02 ./midnight-node wizards generate-keys
```
キー保存パス指定でそのまま ++enter++ 
``` { .yaml .no-copy py title="ウィザート表示"} 
This 🧙 wizard will generate the following keys and save them to your node's keystore:
→  an ECDSA Cross-chain key
→  an ED25519 Grandpa key
→  an SR25519 Aura key
It will also generate a network key for your node if needed.

? node base path (./data) ←ここでEnter
```

`$HOME/midnight`配下に`./data`が作成されます
``` { .yaml .no-copy py title="キーファイル構成"} 
data/
└── chains
    └── undeployed
        ├── keystore
        │   ├── 6175728281... # sidechain key
        │   ├── 63726367cd... # aura key
        │   └── 677a322ca6... # grandpa key
        └── network
            └── secret_ed25519 # network (node) key
```

キーフォルダ名変更
``` bash
mv ./data/chains/undeployed/ ./data/chains/partner_chains_template
```

## **バリデーター登録**

### **ステークプールキーコピー**

!!! hint "ステークプールキーコピー"
    Previewテストネットにある以下のファイルを当サーバーの`$HOME/midnight`にコピーする

    - `~/cold-keys/node.skey`
    - `~/cnode/payment.skey`
    - `~/cnode/payment.vkey`

`node.skey`をリネームする
``` bash
cd $HOME/midnight
mv node.skey cold.skey
```

### **エンタープライズアドレス作成**
``` bash
cd $HOME/midnight
cardano-cli conway address build \
    --payment-verification-key-file payment.vkey \
    --out-file midnight-payment.addr \
    $NODE_NETWORK
```

以下のエンタープライズアドレスにtADAを送金する [tADA Faucet](https://docs.cardano.org/cardano-testnets/tools/faucet)

``` bash
echo $(cat midnight-payment.addr)
```
![](../images/midnight-node/register1-5.jpg)

入金を確認する
``` bash
cardano-cli conway query utxo \
    --address $(cat midnight-payment.addr) \
    $NODE_NETWORK \
    --output-text
```

``` { .yaml .no-copy py title="戻り値"} 
                           TxHash                                 TxIx        Amount
--------------------------------------------------------------------------------------
731a0f97f31aacdd10b7345065bf05a79194a72184c4a3a7d922913da4554714     0        10000000000 lovelace + TxOutDatumNone
```

### **登録ウィザート1**
``` bash
cd $HOME/midnight
CFG_PRESET=testnet-02 ./midnight-node wizards register1
```
Ogmios protocolで `https` を選択後 ++enter++
``` {.yaml .no-copy}
  http
> https
```
![](../images/midnight-node/register1-1.jpg)


Ogmios hostnameに以下のエンドポイントを入力後 ++enter++
```
ogmios.testnet-02.midnight.network
```
![](../images/midnight-node/register1-2.jpg)

Ogmios port に `443` を入力後 ++enter++
```
443
```
![](../images/midnight-node/register1-3.jpg)

`payment.vkey` 指定でそのまま ++enter++ 
![](../images/midnight-node/register1-4.jpg)


UTxO選択でそのまま ++enter++ 
![](../images/midnight-node/register1-6.jpg)

戻り値(register2コマンド)をすべて ++copy++ 
![](../images/midnight-node/register1-7.jpg)



### **登録ウィザード2**

そのまま 貼り付け して ++enter++
![](../images/midnight-node/register1-8.jpg)

`cold.skey` 指定でそのまま ++enter++ 
![](../images/midnight-node/register2-1.jpg)

戻り値(register3コマンド)をすべて ++copy++ 
![](../images/midnight-node/register2-2.jpg)


### **登録ウィザート3**

そのまま 貼り付け して ++enter++
![](../images/midnight-node/register2-3.jpg)

`payment.skey` 指定でそのまま ++enter++ 
![](../images/midnight-node/register3-1.jpg)

Ogmios protocolで `https` を選択後 ++enter++
``` {.yaml .no-copy}
  http
> https
```
![](../images/midnight-node/register1-1.jpg)


Ogmios hostnameに以下のエンドポイントを入力後 ++enter++
```
ogmios.testnet-02.midnight.network
```
![](../images/midnight-node/register1-2.jpg)

Ogmios port に `443` を入力後 ++enter++
```
443
```
![](../images/midnight-node/register1-3.jpg)

`Show registration status?(Y/n)`が表示されたら `n` を入力して ++enter++ 
![](../images/midnight-node/register3-2.jpg)



## **オンチェーン登録確認**

エポック確認
``` bash { py title="ボックス内のコピーボタンでコピーして実行してください" }
NEXT_EPOCH=$(curl -s -L -X POST -H "Content-Type: application/json" -d '{
  "jsonrpc": "2.0",
  "method": "sidechain_getStatus",
  "params": [],
  "id": 1
}' https://rpc.testnet-02.midnight.network \
| jq '.result.mainchain.epoch + 2')
echo $NEXT_EPOCH
```

登録確認
``` bash { py title="ボックス内のコピーボタンでコピーして実行してください" }
SIDECHAIN_KEY=$(jq -r '.sidechain_pub_key' ${HOME}/midnight/partner-chains-public-keys.json)

curl -s -L -X POST -H "Content-Type: application/json" -d "{
  \"jsonrpc\": \"2.0\",
  \"method\": \"sidechain_getAriadneParameters\",
  \"params\": [$NEXT_EPOCH],
  \"id\": 1
}" https://rpc.testnet-02.midnight.network \
| jq --arg key "$SIDECHAIN_KEY" '
  .result.candidateRegistrations
  | to_entries[]
  | . as $e
  | $e.value[]
  | select(.sidechainPubKey == $key)
  | {
      mainchainPubKey: $e.key,
      sidechainPubKey,
      auraPubKey,
      grandpaPubKey,
      stakeDelegation,
      isValid
    }
'
```

登録完了！
``` { .yaml .no-copy py title="戻り値"} 
{
    ~  チェーンキー表示省略  ~
  "isValid": true
}
```

