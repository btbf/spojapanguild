# カルダノ財団SPO投票マニュアル

!!! warning "概要"
    * 現在はPreProdテストネットで投票ツールの動作確認が行われております。
    * PreProdテストネットにプール登録が必要です。
    * 投票専用のcardano-cli v8.0.0が必要です。
    * BPでセットアップします。

## 投票用CLIインストール
投票用cardano-cli v8.0.0のインストールスクリプトを実行する  
スクリプト内の指示に従って下さい。
=== "BP"
    ```
    mkdir "${HOME}/git/spo-poll";cd "${HOME}/git/spo-poll"
    curl -sS -o build_CCLI8.sh https://raw.githubusercontent.com/btbf/CIP-0094-polls/main/scripts/build_CCLI8.sh
    chmod 755 build_CCLI8.sh
    ./build_CCLI8.sh
    ```

ビルドされた gitハッシュは以下の通りです
``` { .yaml .no-copy }
cardano-cli 8.0.0 - linux-x86_64 - ghc-8.10
git rev 0000000000000000000000000000000000000000
```
> 既存のCLIとは別ディレクトにインストールされます。
> ${HOME}/.local/bin/CIP-0094/cardano-cli

## 投票用ツール起動
``` { .yaml .no-copy }
Using /home/user/.local/bin/CIP-0094/cardano-cli version 8.0.0 ...
   _____ ____  ____                    ____
  / ___// __ \/ __ \      ____  ____  / / /
  \__ \/ /_/ / / / /_____/ __ \/ __ \/ / / 
 ___/ / ____/ /_/ /_____/ /_/ / /_/ / / /  
/____/_/    \____/     / .___/\____/_/_/   
                      /_/                  

1) PreProd
2) Mainnet
3) Quit
Which network should we look at?
```
> 1を入力してEnter

``` { .yaml .no-copy }
1) PreProd Demo Poll (epoch 86 - 1 May 2023)
2) Other
3) Quit
Which poll TX should we look at? 
```
> 1を入力してEnter

``` { .yaml .no-copy }
How satisfied are you with the current rewards and incentives scheme?
[0] dissatisfied (不満)
[1] no opinion (未回答)
[2] satisfied (満足)

Please indicate an answer (by index):
```
> 回答の番号を入力してEnterを押すと、自動的にTxファイルを作成します。

## トランザクション送信
tx.rawをエアギャップのcnodeフォルダにコピーする
!!! important "ファイル転送"
    BPの`tx.raw` をエアギャップマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|tx.raw| B[エアギャップ];
    ```


エアギャップで署名する
=== "エアギャップ"
    ```
    cd $NODE_HOME
    chmod u+rwx $HOME/cold-keys
    cardano-cli transaction sign \
        --tx-body-file tx.raw \
        --signing-key-file payment.skey \
        --signing-key-file $HOME/cold-keys/node.skey \
        $NODE_NETWORK \
        --out-file tx.signed
    chmod a-rwx $HOME/cold-keys
    ```

tx.signedをBPのcnodeフォルダにコピーする
!!! important "ファイル転送"
    エアギャップの`tx.signed` をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|tx.signed| B[BP];
    ```

Txを送信する
=== "BP"
    ```
    cardano-cli transaction submit \
        --tx-file tx.signed \
        $NODE_NETWORK
    ```

Txを確認する
=== "BP"
    ```
    txId=`cardano-cli transaction txid --tx-body-file tx.raw`
    echo "https://preprod.cardanoscan.io/transaction/${txId}"
    ```


投票結果を確認する
[https://adastat.net/polls/62c6be72bdf0b5b16e37e4f55cf87e46bd1281ee358b25b8006358bf25e71798](https://adastat.net/polls/62c6be72bdf0b5b16e37e4f55cf87e46bd1281ee358b25b8006358bf25e71798)