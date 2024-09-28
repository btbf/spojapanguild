# **KESの更新**

!!! summary "概要"
    (KES=Key Evolving Signature)の略  
    キーを悪用するハッカーからステークプールを保護するために作成され、90日ごとに再生成する必要があります。有効期限が切れる前に更新してください。期限内ならいつ更新しても問題ありません。  

    以下の手順は、全て手作業で更新する方法です。

    <font color=red>KES更新は、半自動更新が可能な[SJG TOOL](./tool.md)を推奨します。</font>


!!! info "注意"

    * KESの有効期限が切れると、ブロック生成が出来なくなりますので期限が切れる前に以下の手順で更新してください。
    * 1.35.xからカウンター番号更新のレギュレーションが変更になりました。  
      --必ず自プールのオンチェーンカウンター番号+1 で更新する必要があります。  
      --オンチェーンにまだ自プールが生成したブロックがない場合は毎回0で更新します。  



■KES更新の流れ  
0.BP：KES更新タイミングを確認する  
1.BP：新しいKESファイルを生成する  
2.BP：KESファイル(kes.skey/kes.vkey)をエアギャップのcnodeディレクトリへコピーする  
3.BPとエアギャップで`kes.vkey`ファイルハッシュを比較する  
4.BP:オンチェーンカウンター番号を算出する。  
5.エアギャップ: node.counterを生成する  
6.BP：現在のKesPeriodを算出する
7.エアギャップ：node.certを生成する (1で算出したKesPeriodを使うこと)   
8.エアギャップ：node.certファイルをBPのcnodeディレクトリへコピーする  
9.BPとエアギャップで`node.cert`ファイルハッシュを比較する  
10.BP：ノードを再起動する    


## **0.KES更新タイミングチェック**
=== "ブロックプロデューサーノード"
    ```
    slotNumInt=`curl -s http://localhost:12798/metrics | grep cardano_node_metrics_slotNum_int | awk '{ print $2 }'`
    echo "scale=6; ${slotNumInt} / 129600" | bc | awk '{printf "%.5f\n", $0}'
    ```
    > 戻り値の小数点以下が`.99800`付近の場合、`startKesPeriod`の切り替わりが近いため、切り替わってから以下の作業を進めてください。


## **1.KESファイル作成**
既存ファイルバックアップ
=== "ブロックプロデューサーノード"
    ```bash
    cp $NODE_HOME/kes.vkey $NODE_HOME/kes-bk.vkey
    cp $NODE_HOME/kes.skey $NODE_HOME/kes-bk.skey
    cp $NODE_HOME/node.cert $NODE_HOME/node-bk.cert
    ```

    KESファイル新規作成
    ```bash
    cardano-cli conway node key-gen-KES \
        --verification-key-file $NODE_HOME/kes.vkey \
        --signing-key-file $NODE_HOME/kes.skey
    ```

## **2.KESファイルをAGにコピー**
**KESファイル(kes.skey/kes.vkey)をエアギャップのcnodeディレクトリへコピーする**

!!! important "ファイル転送"
    BPにある`kes.skey/kes.vkey`をエアギャップオフラインマシンのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[BP] -->|kes.skey / kes.vkey| B[エアギャップ];
    ``` 

## **3.ハッシュ値確認**
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


## **4.オンチェーンカウンター取得**
=== "ブロックプロデューサーノード"
    ```
    kesperiodinfo=$(cardano-cli conway query kes-period-info $NODE_NETWORK --op-cert-file $NODE_HOME/node.cert --out-file kesperiod.json)
    lastBlockCnt=`cat kesperiod.json | jq -r '.qKesNodeStateOperationalCertificateNumber'`

    if expr "$lastBlockCnt" : "[0-9]*$" >&/dev/null; then
    echo '----------------------------------------------'
    echo オンチェーンカウンター番号は: $lastBlockCnt です。
    echo 更新カウンター番号は $(($lastBlockCnt+1)) です。
    echo '---------------------------------------------'
    else
    echo '----------------------------'
    echo まだブロックを生成していません。
    echo 更新カウンター番号は: "0" です。
    echo '----------------------------'
    fi
    rm kesperiod.json
    ```
    > ↑このままコピーしてコマンドに入力してください 


## **5.カウンターファイル生成**

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    read -p "BPで算出した更新カウンター番号を入力してください:" cnt_No
    ```
    > ↑このままコピーしてコマンドに入力してください  
    > コマンド実行後に、数字入力モードになりますので  
    > 項目5で確認した、更新カウンター番号を入力します

    ```
    chmod u+rwx $HOME/cold-keys
    cardano-cli conway node new-counter \
      --cold-verification-key-file $HOME/cold-keys/node.vkey \
      --counter-value $cnt_No \
      --operational-certificate-issue-counter-file $HOME/cold-keys/node.counter
    ```

    カウンター番号が正しく生成されているか確認する
    ```
    cardano-cli conway text-view decode-cbor \
     --in-file  $HOME/cold-keys/node.counter \
      | grep int | head -1 | cut -d"(" -f2 | cut -d")" -f1
    ```
    > 上記コマンド実行の戻り値が「入力した更新カウンター番号」であることを確認してください


## **6.BPで現在のKesPeriod算出**
=== "ブロックプロデューサーノード"
    ```bash
    cd $NODE_HOME
    slotNo=$(cardano-cli conway query tip $NODE_NETWORK | jq -r '.slot')
    slotsPerKESPeriod=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r '.slotsPerKESPeriod')
    kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
    startKesPeriod=${kesPeriod}
    echo startKesPeriod: ${startKesPeriod}
    ```

## **7.node.cert生成**
  
次のコマンドで、新しい `node.cert`ファイルを作成します。

=== "エアギャップオフラインマシン"
    ```bash
    cd $NODE_HOME
    read -p "BPで算出したstartKesPeriodを入力してください:" kes
    ```
    > ↑このままコピーしてコマンドに入力してください  
    > コマンド実行後に、数字入力モードになりますので  
    > そこで1で算出した`startKesPeriod`の数字を入力します
```
echo "入力した数字は$kesです"
```
> 入力した数字が戻り値に表示されているかご確認ください

```
chmod u+rwx $HOME/cold-keys
cardano-cli conway node issue-op-cert \
    --kes-verification-key-file $NODE_HOME/kes.vkey \
    --cold-signing-key-file $HOME/cold-keys/node.skey \
    --operational-certificate-issue-counter $HOME/cold-keys/node.counter \
    --kes-period $kes \
    --out-file $NODE_HOME/node.cert
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

## **8.node.certをBPへコピー**

**エアギャップ：node.certファイルをBPのcnodeディレクトリへコピーする**

!!! important "ファイル転送"
    エアギャップにある`node.cert`をBPのcnodeディレクトリにコピーします。
    ``` mermaid
    graph LR
        A[エアギャップ] -->|node.cert| B[BP];
    ``` 

## **9.ハッシュ値確認**
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

## **10.ノード再起動**
この手順を完了するには、ブロックプロデューサーノードを停止して再起動します。

=== "ブロックプロデューサーノード"
    ```
    sudo systemctl reload-or-restart cardano-node
    ```

    gLiveviewでノード同期を確認する
    ```
    glive
    ```

    ??? danger "10分以上経過しても同期しない場合はこちら"
        KES更新に失敗している可能性があるため、バックアップファイルから復元してください。
        ノード停止
        ```
        sudo systemctl stop cardano-node
        ```
        ファイル復元
        ```
        mv $NODE_HOME/kes-bk.vkey $NODE_HOME/kes.vkey
        mv $NODE_HOME/kes-bk.skey $NODE_HOME/kes.skey
        mv $NODE_HOME/node-bk.cert $NODE_HOME/node.cert
        ```
        ノード起動
        ```
        sudo systemctl start cardano-node
        ```
        同期状況確認
        ```
        glive
        ```

## **11.チェックプログラム実行**

**SPO JAPAN GUILD TOOLを実行する**

```
gtool
```
>[2] ブロック生成状態チェック を選択する

SPO JAPAN GUILD TOOLの導入は[こちら](./tool.md)をご参照ください

## **12.バックアップファイル削除**
上記でブロック生成状態の確認がすべてOKだった場合、KESバックアップファイルを削除してください

```
rm $NODE_HOME/kes-bk.vkey
rm $NODE_HOME/kes-bk.skey
rm $NODE_HOME/node-bk.cert
```