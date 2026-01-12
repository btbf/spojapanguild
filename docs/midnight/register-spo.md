
# **Midnight-node用サーバ構築**

本ドキュメントは、Midnightバリデーターサーバで行うMidnight-node用サーバ構築とSPOバリデータ登録の手順です。  

## **事前準備**

??? tip "ローカル環境での事前準備"

    SSH接続でログインする場合は、事前にローカル環境でSSH認証キーを作成してください。

    === "Windowsの場合"
        **1. 管理者モードでターミナルを起動します。**  

        `Win + X` を押下し、ターミナル（管理者）を選択し、SSHクライアントの有無を確認します。  
        ```powershell
        Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
        ```
        > `State : Installed`であれば問題ありません。

        ??? tip "`State : NotPresent`の場合"

            以下のコマンドで追加してください。
            ```powershell
            Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
            ```
        
        **2. SSH鍵生成**  
        ```powershell
        mkdir ~/.ssh -Force
        ssh-keygen -t ed25519 -N "" -C "ssh_connect" -f ~/.ssh/ssh_ed25519
        ```
        
        **3. 公開鍵ファイル名の変更**
        ```powershell
        cd ~/.ssh
        mv ssh_ed25519.pub authorized_keys
        ```


    === "Macの場合"
        **1. ターミナルを起動します。**  

        `⌘ + Space（Command + Space）`を押下し、「`terminal`」と入力し、Enterを押下します。

        **2. SSH鍵生成**
        ```bash
        mkdir -p ~/.ssh
        ssh-keygen -t ed25519 -N "" -C "ssh_connect" -f ~/.ssh/ssh_ed25519
        ```

        **3. 公開鍵ファイル名の変更**
        ```bash
        cd ~/.ssh
        mv ssh_ed25519.pub authorized_keys
        ```

    !!! danger "注意"
        以下の鍵は絶対に紛失しないでください。  
        紛失するとサーバーへ接続できなくなります。  

        `ssh_ed25519` （秘密鍵）  
        `authorized_keys` （公開鍵）

!!! info "サーバーでの事前準備"
    日常運用では`root`アカウントを使用せず、sudo権限を付与した一般ユーザーで操作します。

    新しいユーザーを作成します。  
    > 任意のアルファベット文字を入力してください。  
    > この例では`cardano` ユーザーとして以降進めます。

    ```bash
    adduser cardano
    ```

    ``` { .yaml .no-copy }
    New password:           # パスワードを設定
    Retype new password:    # 確認のため再入力

    Enter the new value, or press ENTER for the default
            Full Name []:   # フルネーム等の情報を設定（不要であればブランクでも問題ありません）
            Room Number []:
            Work Phone []:
            Home Phone []:
            Other []:
    Is the information correct? [Y/n] : y
    ```

    `cardano`にsudo権限を付与します。
    ```bash
    usermod -aG sudo cardano
    ```

    rootからログアウトします。
    ```bash
    exit
    ```

    !!! tip "ヒント"
        ターミナルソフトのユーザー名とパスワードを上記で作成したユーザー名とパスワードに書き換えて再接続します。

## **1. SPOKIT導入設定**

### **1-1. 初期設定**

!!! tip "パスワード入力について"
    管理者権限パスワードを求められた場合は、ユーザー作成時に設定したパスワードを入力してください。

`SPOKIT`を導入しUbuntuセキュリティ設定のみを行います。
```bash
wget -qO- https://spokit.spojapanguild.net/install.sh | bash
```


セットアップノードタイプ（リレー）を選択して ++enter++
![](../images/spokit/2.jpg)

接続ネットワーク (Preview-Testnet) を選択して ++enter++
![](../images/spokit/3-preview.jpg)

作業ディレクトリパス指定　そのまま ++enter++
![](../images/spokit/4.jpg)

セットアップ内容に問題なければ ++enter++
![](../images/spokit/5.jpg)

環境設定読み込み  
赤枠に表示されているコマンドをコピーして実行  
![](../images/spokit/6.jpg)


### **1-2. Ubuntuセキュリティ設定**

!!! Question "Ubuntuセキュリティ設定モードについて"
    このモードでは、Cardanoノード実行に推奨されるUbuntuセキュリティ設定が含まれています。  
    ４～９については選択制となっておりますので、環境に応じて設定してください。

``` bash { py title="実行コマンド" }
spokit ubuntu
```

Ubuntuセキュリティ設定ウィザート  
１～４は自動インストール・有効化されます。


はい を選択して ++enter++  
![](../images/spokit/7.jpg)

chronyインストール・設定
> システム時刻を正確かつ安定して同期するための時刻同期デーモンです。

はい を選択して ++enter++  
![](../images/spokit/8.jpg)

SSH設定  
> リモートサーバを安全に操作・管理するための通信プロトコル

SSH鍵認証用のauthorized_keysファイルをローカルからサーバーに転送する写真を追加し、差し替え予定

はい を選択して ++enter++  
![](../images/spokit/9-1.jpg)

> rootログイン可否設定

![](../images/spokit/9-2.jpg)

SSHポート設定
> セキュリティを高めるためにはポート番号を変更してください

![](../images/spokit/9-3.jpg)

> ランダムな番号を割り当てるかカスタムで任意の番号を指定してください

![](../images/spokit/9-4.jpg)

> Ubuntu内部ファイアウォールを使用する場合は、はい を選択して ++enter++ 

![](../images/spokit/10.jpg)

> <font color="red">↓ここの注意事項をよく読んでください</font>

![](../images/spokit/10-1.jpg)


不要なディレクトリを削除する
```
rm -rf $HOME/cnode
```

## **2. midnight-nodeインストール**

### **2-1. 環境変数設定**

!!! tip "設定"

    === "Preview(テストネット)"

        ```bash
        grep -q '^export MIDNIGHT_NETWORK=' "$HOME/.bashrc" || printf '\nexport MIDNIGHT_NETWORK=testnet-02\n' >> "$HOME/.bashrc"
        source "$HOME/.bashrc"
        ```

### **2-2. midnight-nodeダウンロード**

=== "Preview(テストネット)"

``` bash
mkdir -p $HOME/midnight
cd $HOME/midnight
wget -q --show-progress https://spojapanguild.net/node_config/midnight/${MIDNIGHT_NETWORK}/midnight-node0.12.0.gz
```

midnight-node解凍
``` bash
gunzip -c midnight-node0.12.0.gz > midnight-node && rm midnight-node0.12.0.gz
```

``` bash
chmod +x midnight-node
sudo cp midnight-node /usr/local/bin/midnight-node
```

バージョン確認
``` bash
midnight-node --version
```
> midnight-node 0.12.0


設定ファイルダウンロード
``` bash
cd $HOME/midnight
wget -q --show-progress https://spojapanguild.net/node_config/midnight/${MIDNIGHT_NETWORK}/pc-chain-config.json -O ${MIDNIGHT_NETWORK}-pc-chain-config.json
wget -q --show-progress https://spojapanguild.net/node_config/midnight/${MIDNIGHT_NETWORK}/chain-spec.json -O ${MIDNIGHT_NETWORK}-chain-spec.json
wget -q --show-progress https://spojapanguild.net/node_config/midnight/${MIDNIGHT_NETWORK}/addresses.json -O ${MIDNIGHT_NETWORK}-addresses.json
```

!!! important "ファイル転送"

    以下のファイルをエアギャップの`$HOME/midnight`ディレクトリにコピーします。
    ```mermaid
    graph LR
        A[Preview テストネット] -->|**midnight-node**| B[エアギャップ];
    ``` 

=== "エアギャップ"

    ```bash
    grep -q '^export MIDNIGHT_NETWORK=' "$HOME/.bashrc" || printf '\nexport MIDNIGHT_NETWORK=testnet-02\n' >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
    ```

    ```bash
    mkdir -p $HOME/midnight
    ```
    ```bash
    cd $HOME/midnight
    chmod +x midnight-node
    sudo cp midnight-node /usr/local/bin/midnight-node
    ```
    ```bash
    midnight-node --version
    ```
    > midnight-node 0.12.0


## **3.パートナーチェーンキー生成**

=== "エアギャップ"

``` bash
cd $HOME/midnight
CFG_PRESET=${MIDNIGHT_NETWORK} midnight-node wizards generate-keys
```
キー保存パス指定でそのまま ++enter++ 
``` bash { .yaml .no-copy py title="ウィザード表示"} 
This 🧙 wizard will generate the following keys and save them to your node's keystore:
→  an ECDSA Cross-chain key
→  an ED25519 Grandpa key
→  an SR25519 Aura key
It will also generate a network key for your node if needed.

? node base path (./data) ←ここでEnter
```

`$HOME/midnight`配下に`./data`が作成されます
``` bash { .yaml .no-copy py title="キーファイル構成"} 
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

## **4. バリデーター登録**

=== "エアギャップ"

### **4-1. エンタープライズアドレス作成**
``` bash
cd $NODE_HOME
cardano-cli conway address build \
    $NODE_NETWORK \
    --payment-verification-key-file payment.vkey \
    --out-file $HOME/midnight/midnight-payment.addr
```

!!! important "ファイル転送"

    エアギャップから以下をサーバーの`$HOME/midnight`にコピーします。

    - `data`
    - `midnight-payment.addr`
    - `partner-chains-public-keys.json`
    > $HOME/midnight/
    
    - `payment.skey`
    > $NODE_HOME


=== "Preview(テストネット)"

[tADA Faucet](https://docs.cardano.org/cardano-testnets/tools/faucet){target="_blank" rel="noopener"}から`tADA`を以下のエンタープライズアドレスに送金します。  

``` bash
cd $HOME/midnight
echo $(cat midnight-payment.addr)
```
![](../images/midnight-node/register1-5.jpg)

入金を確認します。
``` bash
cardano-cli conway query utxo \
    --address $(cat $HOME/midnight/midnight-payment.addr) \
    $NODE_NETWORK \
    --output-text
```

``` { .yaml .no-copy py title="戻り値"} 
                           TxHash                                 TxIx        Amount
--------------------------------------------------------------------------------------
731a0f97f31aacdd10b7345065bf05a79194a72184c4a3a7d922913da4554714     0        10000000000 lovelace + TxOutDatumNone
```

`$HOME/cold-keys`ディレクトリのロック解除
``` bash
chmod u+rwx $HOME/cold-keys
```

!!! tip "ヒント"
    3つの登録ウィザードが表示されますのでそれぞれ入力します。

### **4-2. 登録ウィザード1**
``` bash
cd $HOME/midnight
CFG_PRESET=${MIDNIGHT_NETWORK} midnight-node wizards register1
```

Ogmios protocolでは、 `https` を選択して ++enter++
``` {.yaml .no-copy}
  http
> https
```
![](../images/midnight-node/register1-1.jpg)

Ogmios hostnameでは、以下のエンドポイントを入力して ++enter++
```bash
ogmios.${MIDNIGHT_NETWORK}.midnight.network
```
![](../images/midnight-node/register1-2.jpg)

Ogmios portでは、 `443` を入力して ++enter++
```bash
443
```
![](../images/midnight-node/register1-3.jpg)

`payment.vkey`のPATHを入力して ++enter++ 
```bash
$NODE_HOME/payment.vkey
```
![](../images/midnight-node/register1-4.jpg)

UTxOの選択ではそのまま ++enter++ 
![](../images/midnight-node/register1-6.jpg)

戻り値(register2コマンド)をすべて ++copy++ します。
![](../images/midnight-node/register1-7.jpg)


### **4-3. 登録ウィザード2**

コピーしたコマンドを貼り付けて ++enter++
![](../images/midnight-node/register1-8.jpg)

`node.skey`のPATHを入力して ++enter++ 
```bash
$HOME/cold-keys/node.skey
```
![](../images/midnight-node/register2-1.jpg)

戻り値(register3コマンド)をすべて ++copy++ します。
![](../images/midnight-node/register2-2.jpg)


### **4-4. 登録ウィザード3**

コピーしたコマンドを貼り付けて ++enter++
![](../images/midnight-node/register2-3.jpg)

`payment.skey`のPATHを入力して ++enter++ 
```bash
$NODE_HOME/payment.skey
```
![](../images/midnight-node/register3-1.jpg)

Ogmios protocolでは `https` を選択して ++enter++
``` {.yaml .no-copy}
  http
> https
```
![](../images/midnight-node/register1-1.jpg)

Ogmios hostnameでは以下のエンドポイントを入力して ++enter++
```bash
ogmios.${MIDNIGHT_NETWORK}.midnight.network
```
![](../images/midnight-node/register1-2.jpg)

Ogmios portでは `443` を入力して ++enter++
```bash
443
```
![](../images/midnight-node/register1-3.jpg)

`Show registration status?(Y/n)`が表示されたら `n` を入力後 ++enter++ 
![](../images/midnight-node/register3-2.jpg)

`$HOME/cold-keys`ディレクトリのロック
``` bash
chmod a-rwx $HOME/cold-keys
```


## **5. オンチェーン登録確認**

=== "Preview(テストネット)"

エポック確認
``` bash { py title="全てコピーして実行してください" }
NEXT_EPOCH=$(curl -s -L -X POST -H "Content-Type: application/json" -d '{
  "jsonrpc": "2.0",
  "method": "sidechain_getStatus",
  "params": [],
  "id": 1
}' https://rpc.${MIDNIGHT_NETWORK}.midnight.network \
| jq '.result.mainchain.epoch + 2')
echo $NEXT_EPOCH
```

登録確認
``` bash { py title="全てコピーして実行してください" }
SIDECHAIN_KEY=$(jq -r '.sidechain_pub_key' ${HOME}/midnight/partner-chains-public-keys.json)

curl -s -L -X POST -H "Content-Type: application/json" -d "{
  \"jsonrpc\": \"2.0\",
  \"method\": \"sidechain_getAriadneParameters\",
  \"params\": [$NEXT_EPOCH],
  \"id\": 1
}" https://rpc.${MIDNIGHT_NETWORK}.midnight.network \
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

!!! note "isvaild:falseと表示されている場合の確認事項"

    登録完了直後に`isVaild:false`と表示されている場合は以下のことを確認してください。

    - カルダノステークプールの有効ステーク(Active Stake)  
      **SPOKITの場合**：`spokit` > 「プール情報管理」> 「ブロック生成状態チェック」> 有効ステーク値  
      **Cardanoscanの場合**:　自身のPoolIDを検索し、Active Stakeの値確認
    
    - ActiveStake反映タイミング (n + 2エポック)  
      **反映待機期間**：Previewテストネット約2日、メインネット約10日後に反映します。