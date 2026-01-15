# **BPポート変更**

BPノードポートを6000番で運用されてる方向けの変更マニュアルです。

!!! note "BPノードポート番号を変更する理由"
    CNTOOLでは参考として6000ポートが割り当てられており、こちらに合わせる形で当マニュアルも6000を採用しておりましたが、6000ポートは「x window system」に割り当てられてるポートで、使わなければ使っても大丈夫となっています。ただし、BPポート=6000という認識が広まっていくと、セキュリティ上好ましくなく各プールで独自ポートを採用したほうが良いため。

## **1. 変更点**
1. ダイナミックポート(49513～65535までの番号)を使います。
2. $NODE_HOME/`startBlockProducingNode.sh`のPORT=6000を変更するポート番号へと書き換えます。
3. $NODE_HOME/scripts/`env`のCNODE_PORT=6000を変更するポート番号へと書き換えます。

## **2. BPにて実施**
新しいBPノードポート番号を決める為、xxxxxを(49513～65535)の範囲内で決めて入力します。

```bash
PORT=xxxxx
```

スクリプトのポートを新しいポートに書き換える(このままコピーして実行)
```bash
sed -i $NODE_HOME/startBlockProducingNode.sh \
    -e '1,73s!PORT=6000!PORT='${PORT}'!'
sed -i $NODE_HOME/scripts/env \
    -e '1,73s!CNODE_PORT=6000!CNODE_PORT='${PORT}'!'
```

## **3. BPサーバーufw設定変更**

!!! tip "ufwを使わないケース"
    AWSやVSPによっては管理画面でセキュリティ設定(ファイアウォール)を行う場合がありますので、その場合は、管理画面から設定を変更してください。


新しいポート番号取得
```bash
PORT=`grep "PORT=" $NODE_HOME/startBlockProducingNode.sh`
b_PORT=${PORT#"PORT="}
echo "BPポートは${b_PORT}です"
```
ファイアウォール旧BPポート許可を削除

> 山かっこ<>は不要です
```bash 
sudo ufw status numbered
```
```
sudo ufw delete <削除したい番号>
```

新しいBPポート番号の許可を設定（リレーが２台ある想定） 
```bash title="Ubuntu22.04の場合は１行づつ実行してください"
sudo ufw allow from <リレー１> to any port ${b_PORT}
sudo ufw allow from <リレー２> to any port ${b_PORT}
sudo ufw reload
```

ノード再起動
```bash
sudo systemctl reload-or-restart cardano-node
```

## **4. 変更確認**
- BPポートがきちんと変更されたかを確認します。

```bash
ps aux | grep cardano-node
```
> 戻り値の --port を確認します。

- BPノードを再起動後、各サービスが正常稼働していることも併せて確認しておきます。

```bash
tmux a -t cncli
tmux a -t leaderlog
tmux a -t logmonitor
tmux a -t validate
tmux a -t blockcheck
```
>blockcheckサービスを導入している場合のコマンドも併せて記載してます。


<details>
<summary>補足</summary>

<div>

サービス再起動コマンド
```bash
sudo systemctl reload-or-restart cnode-cncli-sync.service
```
ブロックチェック再起動コマンド
```bash
sudo systemctl reload-or-restart cnode-blockcheck.service
```

デタッチ方法
``` { .yaml .no-copy }
Ctrl + b → d
```

</div>

</details>

## **5. リレーにて実施**
疎通確認
> 0.0.0.0をBPIPに書き換えて、
> xxxxxをBPノードポート番号を入力し実行。
    ```bash
    nc -vz 0.0.0.0 xxxxx
    ```

> port [tcp/*] succeeded! であればOKです。

トポロジーファイル生成用スクリプト書き換え

> トポロジー共有のため別ファイルを自身で作成している場合は、そちらでも忘れずにポート番号を変更しておいてください。  
> xxxxxは、BPノードポート番号を入力します。

```bash
PORT=xxxxx
```
```bash
sed -i $NODE_HOME/relay-topology_pull.sh \
    -e '1,10s!BLOCKPRODUCING_PORT=6000!BLOCKPRODUCING_PORT='${PORT}'!'
```

トポロジーファイルを再作成します。
```bash
cd $NODE_HOME
./relay-topology_pull.sh
```

ノード再起動します。
```bash
sudo systemctl reload-or-restart cardano-node
```

BPポートを確認します。
```bash
cat $NODE_HOME/mainnet-topology.json
```

## **6. 最終確認**

BPのGliveViewを起動し、[p] Peer Analysisを表示。  
リレーノードのIPが`i`と`o`両方で表示されていることを確認する。

---