# **KESの更新**

!!! summary "概要"
    (KES=Key Evolving Signature)の略  
    キーを悪用するハッカーからステークプールを保護するために作成され、90日ごとに再生成する必要があります。有効期限が切れる前に更新してください。期限内ならいつ更新しても問題ありません



!!! info "注意"
    KESの有効期限が切れると、ブロック生成が出来なくなりますので期限が切れる前に以下の手順で更新してください


■KES更新の流れ  
1.BP：現在のKesPeriodを算出する  
2.BP：新しいKESファイルを生成する  
3.BP：KESファイル(kes.skey/kes.vkey)をエアギャップのcnodeディレクトリへコピーする  
4.BPとエアギャップで`kes.vkey`ファイルハッシュを比較する  
5.エアギャップ：node.certを生成する (1で算出したKesPeriodを使うこと)  
6.エアギャップ：node.certファイルをBPのcnodeディレクトリへコピーする  
7.BPとエアギャップで`node.cert`ファイルハッシュを比較する  
8.BP：ノードを再起動する  
9.BP：KESチェックプログラムを実行する  


## **0.サーバー時間の確認**
```
date '+%Y/%m/%d %R'
```
> 23:30以降が表示されていて、日付をまたぎそうな場合はサーバー時間の日付が変わってから作業をお願いします  
> 作業中に日付をまたぐと、最後のチェックプログラムでエラーになります。  

## **1.現在のKesPeriodを算出**
=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    slotNo=$(cardano-cli query tip --mainnet | jq -r '.slot')
    slotsPerKESPeriod=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r '.slotsPerKESPeriod')
    kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
    startKesPeriod=${kesPeriod}
    echo startKesPeriod: ${startKesPeriod}
    ```


## **2.新しいKESファイルを生成**
=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    cardano-cli node key-gen-KES \
        --verification-key-file kes.vkey \
        --signing-key-file kes.skey
    ```

**KESファイル(kes.skey/kes.vkey)をエアギャップのcnodeディレクトリへコピーする**

!!! important "ファイル転送"
    BPにある`kes.skey/kes.vkey`をエアギャップオフラインマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|kes.skey<br>kes.vkey| B[エアギャップ];
    ``` 

BPとエアギャップで`kes.vkey`ファイルハッシュを比較する

=== "ブロックプロデューサーノード"
```bash
cd $NODE_HOME
sha256sum kes.vkey
```

=== "エアギャップオフラインマシン"
```bash
cd $NODE_HOME
sha256sum kes.vkey
```

!!! notice "確認"
    BPとエアギャップで表示された戻り値を比較して、ハッシュ値が一致していればOK  


## **3.node.cert生成**
  
次のコマンドで、新しい `node.cert`ファイルを作成します。

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    read -p "BPで算出したstartKesPeriodを入力してください:" kes
    ```
    > ↑このままコマンドに入力してください  
    > コマンド実行後に、数字入力モードになりますので  
    > そこで1で算出した`startKesPeriod`の数字を入力します
```
echo "入力した数字は$kesです"
```
> 入力した数字が戻り値に表示されているかご確認ください
```
chmod u+rwx $HOME/cold-keys
cardano-cli node issue-op-cert \
    --kes-verification-key-file kes.vkey \
    --cold-signing-key-file $HOME/cold-keys/node.skey \
    --operational-certificate-issue-counter $HOME/cold-keys/node.counter \
    --kes-period $kes \
    --out-file node.cert
chmod a-rwx $HOME/cold-keys
```

!!! info "ヒント"
    コールドキーへのアクセス権限を変更しセキュリティを向上させることができます。これによって誤削除、誤った編集などから保護できます。

    ロックするには

    ```bash
    chmod a-rwx $HOME/cold-keys
    ```

    ロックを解除するには

    ```bash
    chmod u+rwx $HOME/cold-keys
    ```
    {% endhint %}


!!! important "ファイル転送"
    エアギャップにある`node.cert`をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|node.cert| B[BP];
    ``` 

**BPとエアギャップで`node.cert`ファイルハッシュを比較する**

=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    sha256sum node.cert
    ```


=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    sha256sum node.cert
    ```

!!! note "ノード"
    BPとエアギャップで表示された戻り値を比較して、ハッシュ値が一致していればOK  

## **4.ノード再起動**
この手順を完了するには、ブロックプロデューサーノードを停止して再起動します。

=== "ブロックプロデューサーノード"
    ```
    sudo systemctl reload-or-restart cardano-node
    ```


## **5.KESチェックプログラム実行**

2022/02/06 最新バージョン4.1

!!! danger "注意"
    *** ノードが同期したことを確認してから以下を実行してください ***

=== "ブロックプロデューサーノード"
    ```
    cd $NODE_HOME
    wget https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/kes_chk.sh -O kes_chk.sh
    chmod 755 kes_chk.sh
    ```
    ```
    ./kes_chk.sh
    ```
    > 最初に`pool`から始まるPoolIDを入力してください。[adapools.org](https://adapools.org/)  
    > 表示された内容をご確認ください。  
    > 最後に"KESは正常に更新されました"と表示されれば完了です  
