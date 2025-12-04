# **KESの更新**

以降は、すべて手動で行うKES更新手順です。  
ドキュメントとして記載しておきますが、<font color=red>**実運用では、半自動更新が可能な[SJG TOOL](../operation/sjg-tool-setup.md/#spo-japan-guild-tool)の利用を推奨します。**</font>

!!! summary "概要"
    **KESとは**
     **`Key Evolving Signature`**の略です。  

    キーを悪意のある攻撃者（クラッカー）からステークプールを保護するために作成されます。  
    90日ごとに再生成する必要があり、有効期限が切れる前に更新すれば期限内ならいつ更新しても問題ありません。  

!!! danger "注意"

    * **KESの有効期限が切れるとブロック生成が出来なくなります。**  
    必ず期限が切れる前に、以下の手順で更新してください。  

    * Cardanoノード1.35.x以降、KESカウンター番号の取扱い規則（レギュレーション）が変更されています。  
        * オンチェーンに記録されている自プールのKESカウンター値 +`1` で更新する必要があります。  
        * オンチェーンにまだ自プールが生成したブロックがない場合は、毎回 `0` で更新します。  

!!! tip "KES更新の流れ"  

    1. **BP**：KES更新タイミングを確認  
    2. **BP**：新しいKESファイルを生成  
    3. **BP**：KESファイル(`kes.skey`/`kes.vkey`)をエアギャップのcnodeディレクトリへコピー  
    4. **BP** & **エアギャップ**：`kes.vkey`ファイルハッシュを比較  
    5. **BP**：オンチェーンカウンター番号を算出  
    6. **エアギャップ**：`node.counter`を生成  
    7. **BP**：現在の`KesPeriod`を算出  
    8. **エアギャップ**：`node.cert`を生成 ([項目7](../operation/kes-update.md/#7-bpkesperiod)で算出した`KesPeriod`を使うこと)   
    9. **エアギャップ**：`node.cert`をBPのcnodeディレクトリへコピー  
    10. **BP** & **エアギャップ**：`node.cert`ファイルハッシュを比較  
    11. **BP**：ノードを再起動  


## **1. KES更新タイミングの確認**
=== "ブロックプロデューサー"
    ```bash
    slotNumInt=`curl -s http://localhost:12798/metrics | grep cardano_node_metrics_slotNum_int | awk '{ print $2 }'`
    echo "scale=6; ${slotNumInt} / 129600" | bc | awk '{printf "%.5f\n", $0}'
    ```
    > 戻り値の小数点以下が`.99800`前後になっている場合、`startKesPeriod`の切り替わりが間近です。  
    切り替わり後（`.00000`付近）になってから作業を開始してください。


## **2. KESファイルのバックアップ、新規作成**
既存ファイルのバックアップ
=== "ブロックプロデューサー"
    ```bash
    cp $NODE_HOME/kes.vkey $NODE_HOME/kes-bk.vkey
    cp $NODE_HOME/kes.skey $NODE_HOME/kes-bk.skey
    cp $NODE_HOME/node.cert $NODE_HOME/node-bk.cert
    ```

KESファイルの新規作成
    ```bash
    cardano-cli conway node key-gen-KES \
      --verification-key-file $NODE_HOME/kes.vkey \
      --signing-key-file $NODE_HOME/kes.skey
    ```


## **3. KESファイルをエアギャップにコピー**
BPで生成したKESファイル(**`kes.skey`**/**`kes.vkey`**)をエアギャップのcnodeディレクトリへコピー    

!!! important "ファイル転送"
    BPで生成した**`kes.skey`**/**`kes.vkey`**をエアギャップのcnodeディレクトリにコピーします。
    ```mermaid
    graph LR
        A[BP] -->|**kes.skey** / **kes.vkey**| B[エアギャップ];
    ``` 


## **4. ハッシュ値の確認**
BPとエアギャップで`kes.vkey`ファイルハッシュを比較します。  

=== "ブロックプロデューサー"
    ```bash
    cd $NODE_HOME
    sha256sum kes.vkey
    ```

=== "エアギャップ"
    ```bash
    cd $NODE_HOME
    sha256sum kes.vkey
    ```

!!! notice "確認"
    BPとエアギャップの両方で表示された戻り値を比較し、ハッシュ値が一致していれば問題ありません。  


## **5. オンチェーンカウンター取得**
=== "ブロックプロデューサー"
    ```bash
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
    > 上記のコマンドをそのままコピーしてターミナルに入力してください。 


## **6. カウンターファイル生成**
=== "エアギャップ"
    ```bash
    cd $NODE_HOME
    read -p "BPで算出した更新カウンター番号を入力してください: " cnt_No
    ```
    > 上記のコマンドをそのままコピーしてターミナルに入力してください。  
    > コマンド実行後に、数字入力モードになりますので[項目5](../operation/kes-update.md/#5)で確認した更新カウンター番号を入力します。

    ```bash
    chmod u+rwx $HOME/cold-keys
    cardano-cli conway node new-counter \
      --cold-verification-key-file $HOME/cold-keys/node.vkey \
      --counter-value $cnt_No \
      --operational-certificate-issue-counter-file $HOME/cold-keys/node.counter
    ```

    カウンター番号が正しく生成されているか確認します。
    ```bash
    cardano-cli conway text-view decode-cbor \
      --in-file  $HOME/cold-keys/node.counter \
      | grep int | head -1 | cut -d"(" -f2 | cut -d")" -f1
    ```
    > 上記コマンドの戻り値が、あなたが入力した更新カウンター番号と一致していることを確認してください。


## **7. BPで現在の`KesPeriod`を算出**
=== "ブロックプロデューサー"
    ```bash
    cd $NODE_HOME
    slotNo=$(cardano-cli conway query tip $NODE_NETWORK | jq -r '.slot')
    slotsPerKESPeriod=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r '.slotsPerKESPeriod')
    kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
    startKesPeriod=${kesPeriod}
    echo "startKesPeriod: ${startKesPeriod}"
    ```


## **8. `node.cert`ファイルの生成**  
次のコマンドで、新しい`node.cert`ファイルを作成します。

=== "エアギャップ"
    ```bash
    cd $NODE_HOME
    read -p "BPで算出した startKesPeriod を入力してください: " kes
    ```
    > 上記のコマンドをそのままコピーしてターミナルに入力してください。  
    > コマンド実行後に、数字入力モードになりますので[項目7](../operation/kes-update.md/#7-bpkesperiod)で算出した`startKesPeriod`の数字を入力します。  
    > 必ずBPで算出した値と一致していることを確認してから入力してください。

```bash
echo "入力した startKesPeriod は: $kes"
```
> 戻り値に入力した数字が表示されているかを確認します。

```bash
chmod u+rwx $HOME/cold-keys
cardano-cli conway node issue-op-cert \
  --kes-verification-key-file $NODE_HOME/kes.vkey \
  --cold-signing-key-file $HOME/cold-keys/node.skey \
  --operational-certificate-issue-counter $HOME/cold-keys/node.counter \
  --kes-period $kes \
  --out-file $NODE_HOME/node.cert
chmod a-rwx $HOME/cold-keys
```

!!! tip "ヒント"
    コールドキーのアクセス権限を適切に設定することで、セキュリティを向上させるとともに、誤削除や誤編集からキーを保護できます。

    ロックするには：

    ```bash
    chmod a-rwx $HOME/cold-keys
    ```

    ロックを解除するには：

    ```bash
    chmod u+rwx $HOME/cold-keys
    ```


## **9. `node.cert`ファイルをBPへコピー**
エアギャップで生成した**`node.cert`**をBPのcnodeディレクトリへコピー

!!! important "ファイル転送"
    エアギャップで生成した**`node.cert`**をBPのcnodeディレクトリにコピーします。
    ```mermaid
    graph LR
        A[エアギャップ] -->|**node.cert**| B[BP];
    ``` 


## **10. ハッシュ値確認**
BPとエアギャップで`node.cert`のハッシュ値が一致していることを確認します。

=== "ブロックプロデューサー"
    ```bash
    cd $NODE_HOME
    sha256sum node.cert
    ```

=== "エアギャップ"
    ```bash
    cd $NODE_HOME
    sha256sum node.cert
    ```

!!! note "確認"
    BPとエアギャップで表示された戻り値を比較し、ハッシュ値が一致していれば問題ありません。  


## **11. ノード再起動**
この手順を完了するため、ブロックプロデューサーを再起動してください。

=== "ブロックプロデューサー"
    ```bash
    sudo systemctl reload-or-restart cardano-node
    ```

    `gLiveview`でノード同期を確認します。
    ```bash
    glive
    ```

    ??? danger "10分以上経ってもノードが同期を再開しない場合はこちら"  
        KES更新に失敗している可能性があります。  
        以下の手順でバックアップファイルから復元してください。  
        
        1. ノードを停止
        ```bash
        sudo systemctl stop cardano-node
        ```
        
        2. バックアップファイルを復元
        ```bash
        mv $NODE_HOME/kes-bk.vkey $NODE_HOME/kes.vkey
        mv $NODE_HOME/kes-bk.skey $NODE_HOME/kes.skey
        mv $NODE_HOME/node-bk.cert $NODE_HOME/node.cert
        ```
        
        3. ノードを起動
        ```bash
        sudo systemctl start cardano-node
        ```
        
        4. ノード同期状況を確認
        ```bash
        glive
        ```


## **12. チェックプログラム実行**
確認のため、**[SJG TOOL](../operation/sjg-tool-setup.md/#spo-japan-guild-tool)**を実行します。

```bash
gtool
```
> `[2] ブロック生成状態チェック`を選択します。


## **13. バックアップファイル削除**
ブロック生成状態のチェックがすべて正常（OK）であることを確認したら、不要となったバックアップファイルを削除してください。

```bash
rm $NODE_HOME/kes-bk.vkey
rm $NODE_HOME/kes-bk.skey
rm $NODE_HOME/node-bk.cert
```

---