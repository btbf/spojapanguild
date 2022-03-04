# **ノードアップデートマニュアル**

!!! note "対応バージョン" 
    2022年3月1日時点でこのガイドは v.1.34.0に対応しています


!!! info "概要"
    * 以下、バージョンアップ作業を行う場合、ブロック生成スケジュールがないタイミングで実施してください。
    * 以下手順実施後、ブロック生成確認済みです。
    * 今回のアップデートに期限はありませんが、なるべく早めの実施をお願いします


### **主な変更点と新機能**
* Cabalアップデート v3.6.2.0
* CLIリーダーシップのスケジュールコマンド追加
* ステークプール運用証明書の有効性チェックコマンド追加
* トランザクションビルドコマンドでのCDDL形式CBORエンコーディングのサポート
* その他開発者用コマンドも多数追加

## **1.ノードアップデート**

### **1-1. システムアップデート**

```bash
sudo apt update -y
```
```bash
sudo apt upgrade -y
```
ノードをストップする
```bash
sudo systemctl stop cardano-node
```
サーバーを再起動する
```bash
sudo reboot
```

SSHで再接続する

### **1-2. cabal/GHCアップデート**


**ccabalバージョンアップ**
```
ghcup upgrade
ghcup install cabal 3.6.2.0
ghcup set cabal 3.6.2.0
```

cabalバージョン確認
```
which cabal
cabal --version
```
> 以下の戻り値ならOK  
> /home/user/.ghcup/bin/cabal  
cabal-install version 3.6.2.0
compiled using version 3.6.2.0 of the Cabal library  



GHCバージョン確認
```bash
ghc --version
```
> GHCのバージョンは「8.10.7」であることを確認してください。

!!! danger "確認"
    **GHC 8.10.4だった場合**
    ```bash
    ghcup upgrade
    ghcup install ghc 8.10.7
    ghcup set ghc 8.10.7
    ```
    ```bash
    ghc --version
    ```
    > GHCのバージョンは「8.10.7」であればOK



### **1-3.ソースコードダウンロード**

```bash
cd $HOME/git
rm -rf cardano-node-old/
git clone https://github.com/input-output-hk/cardano-node.git cardano-node2
cd cardano-node2/
```

### **1-4.ソースコードからビルド**

```bash
cabal clean
cabal update
```


<!--#git fetch --all --recurse-submodules --tags
#git checkout $(curl -s https://api.github.com/repos/input-output-hk/cardano-node/releases/latest | jq -r .tag_name)
-->
```
git fetch --all --recurse-submodules
git checkout release/1.34
cabal configure -O0 -w ghc-8.10.7
```

```bash
echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
```
```bash
cabal build cardano-node cardano-cli
```
> 'hackage.haskell.org'! Falling back to older state (2021-12-06T23:34:30Z).
Resolving dependencies...
と表示され止まったように見えますが、動くまでお待ちください

> ビルド完了までに数十分ほどかかります。  

**バージョン確認**

```bash
$(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-cli") version  
$(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-node") version  
```
以下の戻り値を確認する  
>cardano-cli 1.34.0 - linux-x86_64 - ghc-8.10
git rev 36a3c0ff8ce3db3104f5db97672fa2fd32311fef   

>cardano-node 1.34.0 - linux-x86_64 - ghc-8.10
git rev 36a3c0ff8ce3db3104f5db97672fa2fd32311fef  


**ノードをストップする** 
```
sudo systemctl stop cardano-node
```

**バイナリーファイルをシステムフォルダーへコピーする**

```bash
sudo cp $(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
```

```bash
sudo cp $(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node
```

**システムに反映されたノードバージョンを確認する**

```bash
cardano-cli version
cardano-node version
```

以下の戻り値を確認する  
>cardano-cli 1.34.0 - linux-x86_64 - ghc-8.10
git rev 36a3c0ff8ce3db3104f5db97672fa2fd32311fef   

>cardano-node 1.34.0 - linux-x86_64 - ghc-8.10
git rev 36a3c0ff8ce3db3104f5db97672fa2fd32311fef  


### **1-5.ノード起動**

```bash
sudo systemctl start cardano-node
```

!!! info "ヒント"
    DBの同期が完了するまで数十分かかります

**ノード状況を確認する**

```
cd $NODE_HOME/scripts
./gLiveView.sh
```



### **1-6.作業フォルダリネーム**
前バージョンで使用していたバイナリフォルダをリネームし、バックアップとして保持します。最新バージョンを構築したフォルダをcardano-nodeとして使用します。

```bash
cd $HOME/git
mv cardano-node/ cardano-node-old/
mv cardano-node2/ cardano-node/
```


<!--

以下のコードを実行して、ユニットファイルを作成します。

{% tabs %}
{% tab title="リレーノード" %}
```bash
cat > $NODE_HOME/cardano-node.service << EOF 
# The Cardano node service (part of systemd)
# file: /etc/systemd/system/cardano-node.service 

[Unit]
Description     = Cardano node service
Wants           = network-online.target
After           = network-online.target 

[Service]
User            = ${USER}
Type            = simple
WorkingDirectory= ${NODE_HOME}
ExecStart       = /bin/bash -c '${NODE_HOME}/startRelayNode1.sh'
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=300
LimitNOFILE=32768
Restart=always
RestartSec=5
SyslogIdentifier=cardano-node

[Install]
WantedBy	= multi-user.target
EOF
```
{% endtab %}

{% tab title="ブロックプロデューサーノード" %}
```bash
cat > $NODE_HOME/cardano-node.service << EOF 
# The Cardano node service (part of systemd)
# file: /etc/systemd/system/cardano-node.service 

[Unit]
Description     = Cardano node service
Wants           = network-online.target
After           = network-online.target 

[Service]
User            = ${USER}
Type            = simple
WorkingDirectory= ${NODE_HOME}
ExecStart       = /bin/bash -c '${NODE_HOME}/startBlockProducingNode.sh'
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=300
LimitNOFILE=32768
Restart=always
RestartSec=5
SyslogIdentifier=cardano-node

[Install]
WantedBy	= multi-user.target
EOF
```
{% endtab %}
{% endtabs %}


## 1-9.Serviceファイルをシステムフォルダにコピーする
```
sudo cp $NODE_HOME/cardano-node.service /etc/systemd/system/cardano-node.service
```

## 1-10.systemctlデーモンを再起動する
```
sudo systemctl daemon-reload
```
-->

## 2. エアギャップマシンアップデート

 **エアギャップマシン用にバイナリファイルをコピーする**

更新手順１を終えたBPかリレーサーバーで以下を実行する
```bash
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-cli") ~/cardano-cli
```

```bash
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-node") ~/cardano-node
```

１．R-loginの転送機能を開き、ユーザーフォルダ直下にある「cardano-cli」と「cardano-node」をローカルパソコンにダウンロードします(エアギャップUbuntuとの共有フォルダ)

!!! hint "ヒント"
    R-loginの転送機能が遅いので、大容量ファイルをダウン・アップロードする場合は、SFTP接続可能なソフトを使用すると効率的です。（FileZilaなど）


２．エアギャップマシンの $HOME/git/cardano-node2 ディレクトリ(無ければ作成)に「cardano-cli」と「cardano-node」をコピーする

**エアギャップマシンのシステムフォルダへコピーする**

エアギャップマシンで以下を実行する
```bash
sudo cp $(find $HOME/git/cardano-node2 -type f -name "cardano-cli") /usr/local/bin/cardano-cli
```

```bash
sudo cp $(find $HOME/git/cardano-node2 -type f -name "cardano-node") /usr/local/bin/cardano-node
```

**システムに反映されたノードバージョンを確認する**

```bash
cardano-cli version
cardano-node version
```

以下の戻り値を確認する  
>cardano-cli 1.33.0 - linux-x86_64 - ghc-8.10
git rev 814df2c146f5d56f8c35a681fe75e85b905aed5d

>cardano-node 1.33.0 - linux-x86_64 - ghc-8.10
git rev 814df2c146f5d56f8c35a681fe75e85b905aed5d  



## **3.CNCLIバージョンアップ**

!!! info "ヒント"
    BPのみで実施します

**サービスを止める**
```
sudo systemctl stop cnode-cncli-sync.service
```

**CNCLIをアップデートする**
!!! info "ヒント"
既にCNCLI4.0.4導入済みの場合は飛ばしてください


```bash
rustup update
cd $HOME/git/cncli
git fetch --all --prune
git checkout $(curl -s https://api.github.com/repos/AndrewWestberg/cncli/releases/latest | jq -r .tag_name)
cargo install --path . --force
cncli --version
```

**ノードを再起動する**
```
sudo systemctl reload-or-restart cardano-node
```

**サービス起動を確認する**

```bash
tmux ls
```

!!! info "ヒント"
    ノードを再起動してから、約20秒後に5プログラムがバックグラウンドで起動中であればOKです
    * cncli
    * leaderlog
    * validate
    * logmonitor
    * blockcheck(ブロック生成ステータス通知を導入している場合)



```
tmux a -t cncli
```
>「100.00% synced」になるまで待ちます。
100%になったら、Ctrl+bを押した後に d を押し元の画面に戻ります
(バックグラウンド実行に切り替え)


ノードバージョンアップは以上です。



## **4.新メトリクスについて**

v1.31.0からブロックチェーンの状態をより可視化したメトリクスが追加されています。
Grafanaに新規パネルを追加することで確認することができます。

現時点では、このメトリクスをもってプールの性能が図れるわけではないですが、現状を把握する指標としてお使いいただけます。

```
■ブロックの伝搬について
1秒、3秒、5秒以内にブロックをダウンロードできたおおよその推定値
95%のブロックを3秒以内にダウンロードしていれば、よく稼働しているノード指標となります。
95%のブロックを5秒以内にダウンロードすることは、ウロボロスPraosのセキュリティ上の最低ラインとなります。
※ノードを再起動すると初期化されますので適正値になるまで時間がかかります。
cardano_node_metrics_blockfetchclient_blockdelay_cdfOne (1秒以内に伝播)
cardano_node_metrics_blockfetchclient_blockdelay_cdfThree (3秒以内に伝播)
cardano_node_metrics_blockfetchclient_blockdelay_cdfFive (5秒以内に伝播)
Panel Stat 
#Grafana Field Unit (Percent(0.0-1.0))

■ブロック受信までの時間
ブロックがミントされるべきだったときから、ローカルのリレーがブロックを受信するまでの遅延を推定した時間
この指標には、コンセンサス/元帳がそのブロックを採用するまでの時間は含まれていません（採用されない可能性もあります）。
cardano_node_metrics_blockfetchclient_blockdelay_s
#Grafana
Panel Stat 
Field Unit (none)


■ブロックサイズの確認
あるスロットのブロックを最初にダウンロードしたときのブロックサイズです。
cardano_node_metrics_blockfetchclient_blocksize
#Grafana
Panel Graph
Field Unit (Bytes(IEC))

■5秒以上後に到着したブロックの追跡
ミントされたはずのブロックが5秒以上後に到着したブロックを追跡します。
cardano_node_metrics_blockfetchclient_lateblocks
#Grafana
Panel Stat 
Field Unit (none)


■リレーノードの有用性判定
人気のないノードには0に近い値が与えられます。そして、非常に有用なノードには1以上の値が与えられます。
値が0の場合、誰もあなたのリレーからブロックを取得していないことを意味します。
1の値は、新しいブロックが作成されるたびに、誰かがそれを取得していることを意味します。
2以上の値は、ミントされたブロックごとに、2つのノードがあなたからそのブロックをフェッチしていることを意味します。
cardano.node.metrics.served.block.latest.count
#計算式
rate(cardano_node_metrics_served_block_latest_count_int[1h])/rate(cardano_node_metrics_blockNum_int[1h])
#Grafana
Panel Graph
Field Unit (none)

■チェーン上のフォーク数をカウント
ノードがスタートしてからのフォーク数。ブロック伝播遅延の影響で2秒前後のスロット間のスケジュールで発生
cardano_node_metrics_forks_int
#Grafana
Panel Graph
Field Unit (none)
```

<!--
# 5 ブロックログアップデート暫定調整

## BPの対応
GliveView、ブロックログのCNTOOL系モジュールの仕様変更に伴うアップデート作業です。

```
cd $NODE_HOME/scripts
wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env -O env
```
```
sed -i $NODE_HOME/scripts/env \
    -e '1,73s!#CCLI="${HOME}/.cabal/bin/cardano-cli"!CCLI="/usr/local/bin/cardano-cli"!' \
    -e '1,73s!#CNODE_HOME="/opt/cardano/cnode"!CNODE_HOME='${NODE_HOME}'!' \
    -e '1,73s!#CNODE_PORT=6000!CNODE_PORT=6000!' \
    -e '1,73s!#CONFIG="${CNODE_HOME}/files/config.json"!CONFIG="${CNODE_HOME}/mainnet-config.json"!' \
    -e '1,73s!#SOCKET="${CNODE_HOME}/sockets/node0.socket"!SOCKET="${CNODE_HOME}/db/socket"!' \
    -e '1,73s!#SOCKET="#LOG_DIR="${CNODE_HOME}/logs"!LOG_DIR="${CNODE_HOME}/logs"!' \
    -e '1,73s!#UPDATE_CHECK="Y"!UPDATE_CHECK="N"!' \
    -e '1,73s!#BLOCKLOG_DIR="${CNODE_HOME}/guild-db/blocklog"!BLOCKLOG_DIR="${CNODE_HOME}/guild-db/blocklog"!' \
    -e '1,73s!#BLOCKLOG_TZ="UTC"!BLOCKLOG_TZ="Asia/Tokyo"!'
```
>BPのポート番号を変更している場合は6000を変更してください。

```
./gLiveView.sh
```
> Script update(s) detected, do you want to download the latest version? (yes/no): ***_no_***


> A new version of Guild LiveView is available  
> Installed Version : v1.22.4  
> Available Version : v1.24.0  
> Do you want to upgrade to the latest version of Guild LiveView? (yes/no):***_yes_***  

>Enter

```
./gLiveView.sh
```
> Script update(s) detected, do you want to download the latest version? (yes/no):***_no_***  
> このメッセージはしばらく手続けるため、煩わしい場合はenvファイルにある`UPDATE_CHECK="N"`へ変更する    

```
wget https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/blocks.sh -O blocks.sh
```

```
./blocks.sh
```
> The static content from env file does not match with guild-operators repository, do you want to download the updated file? (yes/no):***_no_*** 

## リレーの対応
```
cd $NODE_HOME/scripts
wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env -O env
```
```
sed -i $NODE_HOME/scripts/env \
    -e '1,73s!#CNODE_HOME="/opt/cardano/cnode"!CNODE_HOME=${NODE_HOME}!' \
    -e '1,73s!#CNODE_PORT=6000!CNODE_PORT=6000!' \
    -e '1,73s!#CONFIG="${CNODE_HOME}/files/config.json"!CONFIG="${CNODE_HOME}/mainnet-config.json"!' \
    -e '1,73s!#SOCKET="${CNODE_HOME}/sockets/node0.socket"!SOCKET="${CNODE_HOME}/db/socket"!'
```
>リレーのポート番号を変更している場合は6000を変更してください。

```
./gLiveView.sh
```

> Script update(s) detected, do you want to download the latest version? (yes/no):***_no_*** 

> A new version of Guild LiveView is available  
> Installed Version : v1.22.4  
> Available Version : v1.24.0  
> Do you want to upgrade to the latest version of Guild LiveView? (yes/no):***_yes_***  

>Enter

```
./gLiveView.sh
```
> Script update(s) detected, do you want to download the latest version? (yes/no):***_yes_***  

>Enter

次回以降...
```
./gLiveView.sh
```
> Script update(s) detected, do you want to download the latest version? (yes/no):***_no_***  

> このメッセージはしばらく手続けるため、煩わしい場合はenvファイルにある`UPDATE_CHECK="N"`へ変更する  


以上、暫定的な対応となります。  

-->

<!--
## **99 前バージョンへロールバックする場合**
最新バージョンに問題がある場合は、以前のバージョンへ戻す場合のみ実行してください。

!!! danger "確認"
バイナリを更新する前にノードを停止します。

```bash
sudo systemctl stop cardano-node
```


古いリポジトリを復元します。

```bash
cd $HOME/git
mv cardano-node/ cardano-node-rolled-back/
mv cardano-node-old/ cardano-node/
```

バイナリーファイルを `/usr/local/bin`にコピーします。

```bash
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node
```

バイナリーが希望するバージョンであることを確認します。

```bash
/usr/local/bin/cardano-cli version
/usr/local/bin/cardano-node version
```

```bash
sudo systemctl start cardano-node
```

!!! success "確認"
    再起動して同期が開始しているか確認して下さい。

--> 

