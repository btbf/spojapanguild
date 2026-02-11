# **最終チェック**

## **1. Txの確認**

!!! danger "重要な確認事項"
    ブロックを生成するには、「Total Tx」が増加していることを確認する必要があります。プール登録から約12時間後から他のリレーからの接続(Incoming)が増えてきたことを確認し、Txが増加していることを確認してください。万一、増加していない場合にはファイアウォールやトポロジーファイルの内容を再確認して下さい。

=== "リレーノード/BP"
```bash
cd $NODE_HOME/scripts
./gLiveView.sh
```

!!! info ""
    プール登録から約12時間~24時間後に「Total Tx」が増加しているか確認する

![](../../images/glive-tx.png)


## **2. Tracemempool無効**

!!! danger "重要な最終調整"
    ノード稼働時の、CPU/メモリ消費を抑えるためノード設定を調整します。
    この調整はプール運営のパフォーマンスを左右しますので推奨設定となります。

    * トランザクション流入ログをトレース(記録)することで、CPU/メモリ消費を増加させる原因となることがわかっているため、この機能を無効にします。  
    * <font color=red>この設定を行うと、上記で確認した「Total TX」「Pending Tx」は増加しなくなりますが、上記で増加が確認できていれば問題ございません</font>


=== "リレー/BP"
    ```bash
    sed -i $NODE_HOME/${NODE_CONFIG}-config.json \
        -e "s/TraceMempool\": true/TraceMempool\": false/g"
    ```

**ノードを再起動する**
```
sudo systemctl reload-or-restart cardano-node
```

ノードログにエラーが出ていないか確認する
```
journalctl --unit=cardano-node --follow
```


## **3. ブロック生成可能状態チェック**

**SPO JAPAN GUILD TOOLを導入する**

導入手順は**プール構築マニュアル内の[SJGツール導入設定](../operation/sjg-tool-setup.md)**をご参照ください

**TOOLを実行する**

```
gtool
```
>[2] ブロック生成状態チェック を選択する


!!! success "！重要！"
    [プール運用マニュアル](../operation/index.md)を必ず確認し、プール運営について学習してください。

---