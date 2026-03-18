# **ブロックログ設定**

!!! info "ブロックログについて"
    このツールはウロボロスにおける自プールのブロック生成スケジュールを事前に取得するツールです。  
    <font color=red>ブロック生成スケジュールはセキュリティ上パブリックには公開されません。</font>

## **1. インストール要件**

!!! abstract "設定サーバー"
    * BPノード限定

!!! abstract "稼働要件"

    * ４つのサービス(プログラム)をsystemdにて常駐させます。
    * ブロックチェーン同期用DBを新しく設置します(sqlite3)
    * 日本語マニュアルのフォルダ構成に合わせて作成されています。
    * vrf.skey と vrf.vkeyが必要です。

!!! abstract "プログラム構成図"
    ``` mermaid
        flowchart TB
            a1[cardano-node] --> a2[logファイル]
            a3 --> a5[leaderlog.service]
            a3 --> a6[validate.service]
            a1[cardano-node] --> a3[cncli.service]
            a2 --> a4[logmonitor.service]
            a3[cncli.service]
            a4[logmonitor.service]
            a5[leaderlog.service]
            a6[validate.service]
            subgraph Guild-DB
                a7[cncli.db]
                a8[blocklog.db]
            end
            subgraph ステータス通知
                a9[blocknotify] --> 各アプリ
            end
            Guild-DB --> blocks.sh
            a8[blocklog.db] --> a9[blocknotify]
            a3[cncli.service] --> a7[cncli.db]
            a5[leaderlog.service] --> a8[blocklog.db]
            a6[validate.service] --> a8[blocklog.db]
            
    ```

## **2. CNCLIインストール**

!!! info "CNCLIについて"
    [AndrewWestberg](https://twitter.com/amw7){target="_blank" rel="noopener"}さんによって開発された[CNCLI](https://github.com/cardano-community/cncli){target="_blank" rel="noopener"}はプールのブロック生成スケジュールを算出し、Shelley期におけるSPOに革命をもたらしました。

  
**RUST環境の準備**
```bash
mkdir $HOME/.cargo && mkdir $HOME/.cargo/bin
chown -R $USER $HOME/.cargo
touch $HOME/.profile
chown $USER $HOME/.profile
```

**rustupのインストール**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
> 1) Proceed with standard installation (default - just press enter)が表示されたらEnter

```bash
source $HOME/.cargo/env
rustup install stable
rustup default stable
rustup update
rustup component add clippy rustfmt
```

**CNCLIのダウンロード・インストール**
```bash
cd $HOME
cncli_release="$(curl -s https://api.github.com/repos/cardano-community/cncli/releases/latest | jq -r '.tag_name' | sed -e "s/^.\{1\}//")"
```
```bash
curl -sLJ https://github.com/cardano-community/cncli/releases/download/v${cncli_release}/cncli-${cncli_release}-ubuntu22-x86_64-unknown-linux-gnu.tar.gz -o $HOME/cncli-${cncli_release}-x86_64-unknown-linux-gnu.tar.gz
```
```bash
tar xzvf $HOME/cncli-${cncli_release}-x86_64-unknown-linux-gnu.tar.gz -C $HOME/.cargo/bin/
```
```bash
rm $HOME/cncli-${cncli_release}-x86_64-unknown-linux-gnu.tar.gz
```

**CNCLIのバージョン確認**
```bash
cncli --version
```
> cncli v6.7.0

## **3. sqlite3のインストール**
```bash
sudo apt install sqlite3
```
```bash
sqlite3 --version
```
> 3.31.1以上のバージョンがインストールされていれば問題ありません。


## **4. 依存ファイルのダウンロード**

```bash
cd $NODE_HOME/scripts
wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/cncli.sh -O ./cncli.sh
wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/cntools.library -O ./cntools.library
wget https://raw.githubusercontent.com/btbf/spojapanguild/master/scripts/blocks.sh -O ./blocks.sh 
wget https://raw.githubusercontent.com/btbf/spojapanguild/master/scripts/logMonitor.sh -q -O ./logMonitor.sh
```

**パーミッション変更**
```bash
chmod 755 cncli.sh
chmod 755 logMonitor.sh
chmod 755 blocks.sh
```

**設定ファイルの修正**
```bash
PORT=`grep "PORT=" $NODE_HOME/startBlockProducingNode.sh`
b_PORT=${PORT#"PORT="}
echo "BPポートは${b_PORT}です"
```
```bash
sed -i $NODE_HOME/scripts/env \
  -e '1,73s!#CNODEBIN="${HOME}/.local/bin/cardano-node"!CNODEBIN="/usr/local/bin/cardano-node"!' \
  -e '1,73s!#CCLI="${HOME}/.local/bin/cardano-cli"!CCLI="/usr/local/bin/cardano-cli"!' \
  -e '1,73s!#CNCLI="${HOME}/.local/bin/cncli"!CNCLI="${HOME}/.cargo/bin/cncli"!' \
  -e '1,73s!#CNODE_HOME="/opt/cardano/cnode"!CNODE_HOME="'${NODE_HOME}'"!' \
  -e '1,73s!#CNODE_PORT=6000!CNODE_PORT='${b_PORT}'!' \
  -e '1,73s!#UPDATE_CHECK="Y"!UPDATE_CHECK="N"!' \
  -e '1,73s!#CONFIG="${CNODE_HOME}/files/config.json"!CONFIG="${CNODE_HOME}/'${NODE_CONFIG}'-config.json"!' \
  -e '1,73s!#SOCKET="${CNODE_HOME}/sockets/node.socket"!SOCKET="${CNODE_HOME}/db/socket"!' \
  -e '1,73s!#PROM_HOST=127.0.0.1!PROM_HOST=127.0.0.1!' \
  -e '1,73s!#PROM_PORT=12798!PROM_PORT=12798!' \
  -e '1,73s!#BLOCKLOG_TZ="UTC"!BLOCKLOG_TZ="Asia/Tokyo"!' \
  -e '1,73s!#POOL_NAME=""!POOL_DIR=${CNODE_HOME}!' \
  -e '1,116s!#WALLET_PAY_ADDR_FILENAME="payment.addr"!WALLET_PAY_ADDR_FILENAME="payment.addr"!' \
  -e '1,116s!#WALLET_STAKE_ADDR_FILENAME="reward.addr"!WALLET_STAKE_ADDR_FILENAME="stake.addr"!' \
  -e '1,116s!#POOL_HOTKEY_VK_FILENAME="hot.vkey"!POOL_HOTKEY_VK_FILENAME="kes.vkey"!' \
  -e '1,116s!#POOL_HOTKEY_SK_FILENAME="hot.skey"!POOL_HOTKEY_SK_FILENAME="kes.skey"!' \
  -e '1,116s!#POOL_COLDKEY_VK_FILENAME="cold.vkey"!POOL_COLDKEY_VK_FILENAME="node.vkey"!' \
  -e '1,116s!#POOL_COLDKEY_SK_FILENAME="cold.skey"!POOL_COLDKEY_SK_FILENAME="node.skey"!' \
  -e '1,116s!#POOL_OPCERT_COUNTER_FILENAME="cold.counter"!POOL_OPCERT_COUNTER_FILENAME="node.counter"!' \
  -e '1,116s!#POOL_OPCERT_FILENAME="op.cert"!POOL_OPCERT_FILENAME="node.cert"!' \
  -e '1,116s!#POOL_VRF_SK_FILENAME="vrf.skey"!POOL_VRF_SK_FILENAME="vrf.skey"!'
```

**cncli.shファイルの修正**

**プールIDの確認**
```bash
pool_hex=`cat $NODE_HOME/pool.id`
pool_bech32=`cat $NODE_HOME/pool.id-bech32`
printf "\nプールID(hex)は \e[32m${pool_hex}\e[m です\n\n"
printf "\nプールID(bech32)は \e[32m${pool_bech32}\e[m です\n\n"
```

<strong><font color=red>ご自身のプールID `2種類`が表示されていることを確認してください</font></strong>  
プールIDが表示されていない場合は、[こちらの手順](../setup/stake-pool-register.md/#4)を実行してください。  

**cncli.shファイルの修正**
```bash
sed -i $NODE_HOME/scripts/cncli.sh \
-e '1,30s!#POOL_ID=""!POOL_ID="'${pool_hex}'"!' \
-e '1,30s!#POOL_ID_BECH32=""!POOL_ID_BECH32="'${pool_bech32}'"!' \
-e '1,30s!#POOL_VRF_SKEY=""!POOL_VRF_SKEY="${CNODE_HOME}/vrf.skey"!' \
-e '1,30s!#POOL_VRF_VKEY=""!POOL_VRF_VKEY="${CNODE_HOME}/vrf.vkey"!'
```

## **5. サービスファイル作成・登録**
```bash
mkdir -p $NODE_HOME/service
cd $NODE_HOME/service
```

=== "cncli"
    ```bash title="このボックスはすべてコピーして実行してください"
    cat > $NODE_HOME/service/cnode-cncli-sync.service << EOF 
    # file: /etc/systemd/system/cnode-cncli-sync.service

    [Unit]
    Description=Cardano Node - CNCLI sync
    BindsTo=cardano-node.service
    After=cardano-node.service

    [Service]
    Type=simple
    Restart=on-failure
    RestartSec=20
    User=$(whoami)
    WorkingDirectory=${NODE_HOME}/scripts
    ExecStart=/bin/bash -l -c "exec ${NODE_HOME}/scripts/cncli.sh sync"
    ExecStop=/bin/bash -l -c "exec kill -2 \$(ps -ef | grep [c]ncli.sync.*.${NODE_HOME}/ | tr -s ' ' | cut -d ' ' -f2) &>/dev/null"
    KillSignal=SIGINT
    SuccessExitStatus=143
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=cnode-cncli-sync
    TimeoutStopSec=5
    KillMode=mixed

    [Install]
    WantedBy=cardano-node.service
    EOF
    ```

=== "validate"
    ```bash title="このボックスはすべてコピーして実行してください"
    cat > $NODE_HOME/service/cnode-cncli-validate.service << EOF 
    # file: /etc/systemd/system/cnode-cncli-validate.service

    [Unit]
    Description=Cardano Node - CNCLI validate
    BindsTo=cnode-cncli-sync.service
    After=cnode-cncli-sync.service

    [Service]
    Type=simple
    Restart=on-failure
    RestartSec=20
    User=$(whoami)
    WorkingDirectory=${NODE_HOME}/scripts
    ExecStartPre=/bin/sleep 5
    ExecStart=/bin/bash -l -c "exec ${NODE_HOME}/scripts/cncli.sh validate"
    SuccessExitStatus=143
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=cnode-cncli-validate
    TimeoutStopSec=5
    KillMode=mixed

    [Install]
    WantedBy=cnode-cncli-sync.service
    EOF
    ```

=== "leaderlog"
    ```bash title="このボックスはすべてコピーして実行してください"
    cat > $NODE_HOME/service/cnode-cncli-leaderlog.service << EOF
    # file: /etc/systemd/system/cnode-cncli-leaderlog.service

    [Unit]
    Description=Cardano Node - CNCLI Leaderlog
    BindsTo=cnode-cncli-sync.service
    After=cnode-cncli-sync.service

    [Service]
    Type=simple
    Restart=on-failure
    RestartSec=20
    User=$(whoami)
    WorkingDirectory=${NODE_HOME}
    ExecStart=/bin/bash -l -c "exec ${NODE_HOME}/scripts/cncli.sh leaderlog"
    SuccessExitStatus=143
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=cnode-cncli-leaderlog
    TimeoutStopSec=5
    KillMode=mixed

    [Install]
    WantedBy=cnode-cncli-sync.service
    EOF
    ```

=== "logmonitor"
    ```bash title="このボックスはすべてコピーして実行してください"
    cat > $NODE_HOME/service/cnode-logmonitor.service << EOF 
    # file: /etc/systemd/system/cnode-logmonitor.service

    [Unit]
    Description=Cardano Node - CNCLI logmonitor
    BindsTo=cardano-node.service
    After=cardano-node.service

    [Service]
    Type=simple
    Restart=on-failure
    RestartSec=1
    User=$(whoami)
    WorkingDirectory=${NODE_HOME}
    ExecStart=/bin/bash -l -c "exec ${NODE_HOME}/scripts/logMonitor.sh"
    ExecStop=/bin/bash -l -c "exec kill -2 \$(ps -ef | grep -m1 ${NODE_HOME}/scripts/logMonitor.sh | tr -s ' ' | cut -d ' ' -f2) &>/dev/null"
    KillSignal=SIGINT
    SuccessExitStatus=143
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=cnode-logmonitor
    TimeoutStopSec=5
    KillMode=mixed

    [Install]
    WantedBy=cardano-node.service
    EOF
    ```


**サービスファイルをシステムフォルダにコピーし、権限を付与**
```bash
sudo cp $NODE_HOME/service/cnode-cncli-sync.service $NODE_HOME/service/cnode-cncli-validate.service $NODE_HOME/service/cnode-cncli-leaderlog.service $NODE_HOME/service/cnode-logmonitor.service /etc/systemd/system/
```
```bash
sudo chmod 644 /etc/systemd/system/cnode-cncli-sync.service /etc/systemd/system/cnode-cncli-validate.service /etc/systemd/system/cnode-cncli-leaderlog.service /etc/systemd/system/cnode-logmonitor.service
```

**サービスファイルの有効化**

```bash
sudo systemctl daemon-reload
```
```bash
sudo systemctl enable --now cnode-cncli-sync.service cnode-cncli-validate.service cnode-cncli-leaderlog.service cnode-logmonitor.service
```

**便利なエイリアス設定**
!!! hint "エイリアス設定"
    スクリプトへのパスを通し、エイリアスで起動出来るようにする。
    ```bash
    echo alias cnclilog='"journalctl --no-hostname -u cnode-cncli-sync -f"' >> $HOME/.bashrc
    echo alias validate='"journalctl --no-hostname -u cnode-cncli-validate -f"' >> $HOME/.bashrc
    echo alias leaderlog='"journalctl --no-hostname -u cnode-cncli-leaderlog -f"' >> $HOME/.bashrc
    echo alias logmonitor='"journalctl --no-hostname -u cnode-logmonitor -f"' >> $HOME/.bashrc
    ```

    環境変数再読み込み
    ```bash
    source $HOME/.bashrc
    ```

    以下のコマンドを入力して実行すると、サービスファイルログが閲覧できます。  
    単語を入力するだけで、起動状態(ログ)を確認できます。  
    `cnclilog`　`validate`　`leaderlog`　`logmonitor`

## **6. ブロックチェーンとDBを同期**

cncliログ確認
```bash
cnclilog
```

!!! info "確認"
    * cncli同期確認「100.00% synced」になるまで待ちます。  
    100%になったら、Ctrl+cで閉じます。

他サービスの起動確認

=== "validate"

    !!! info ""
        こちらのサービスは生成したブロックがブロックチェーン上に記録されているか照合します。

        ```bash
        validate
        ```

        以下の表示なら正常です。
        > ~ CNCLI Block Validation started ~
        
        Ctrl+cで閉じます

=== "leaderlog"

    !!! info ""

        こちらのサービスはスロットリーダーを自動的に算出します。 
        次エポックの1.5日前から次エポックのスケジュールを算出することができます。

        ```bash
        leaderlog
        ```

        以下の表示なら正常です。  
        > ~ CNCLI Leaderlog started ~

        Ctrl+cで閉じます

=== "logmonitor"

    !!! info ""
        こちらのサービスはプールのノードログからブロック生成結果を抽出します。

        ```bash
        logmonitor
        ```

        以下の表示なら正常です。  

        > ~~ LOG MONITOR STARTED ~~  
        > monitoring logs/node.json for traces

        Ctrl+cで閉じます




## **7. ブロックログを表示する**

このツールでは上記で設定してきたプログラムを組み合わせ、割り当てられたスロットリーダーに対してのブロック生成結果をデータベースに格納し、確認することができます。

```bash
cd $NODE_HOME/scripts
./blocks.sh
```

!!! hint "便利な設定"
    スクリプトへのパスを通し、任意の単語で起動出来るようにする。
    ```bash
    echo alias blocks="'cd $NODE_HOME/scripts; ./blocks.sh'" >> $HOME/.bashrc
    source $HOME/.bashrc
    ```

    ターミナル上で`blocks`と入力し実行するだけで起動できます。  
     


![](../../images/blocks1.JPG)

（ｓ）実績概要---エポック毎のブロック生成実績参照  
（ｅ）エポック詳細---個別エポックのブロック生成スケジュールおよび生成実績参照

![](../../images/blocklog.JPG)

ブロックステータス

| 項目     | 意味                          |
| ----------- | ------------------------------------ |
| **Leader**       | ブロック生成割り当て数  |
| **Ideal**       | アクティブステーク（シグマ）に基づいて割り当てられたブロック数の期待値/理想値 |
| **Luck**    | 期待値における実際に割り当てられたスロットリーダー数のパーセンテージ |
| **Adopted**    | ブロック生成フラグ |
| **Confirmed**    | 生成したブロックのうち確実にオンチェーンであることが検証されたブロック (ブロック生成成功) |
| **Missed**    | スロットでスケジュールされているが、 cncli DB には記録されておらず他のプールがこのスロットのためにブロックを作った可能性 |
| **Ghosted**    | ブロックは作成されましたが「Orphans(孤立ブロック)」となっております。 スロットバトル・ハイトバトルで敗北したか、ブロック伝播の問題で有効なブロックになっていません |
| **Stolen**    | 別のプールに有効なブロックが登録されているため、スロットバトルで敗北した可能性 |
| **Invalid**    | プールはブロックの作成に失敗しました。base64でエンコードされたエラーメッセージがlogmonitorに表示されます |
 
Invalidのエラー内容は次のコードでデコードできます 
```
echo (base64コードを入れる) | base64 -d | jq -r
```

メニュー項目が文字化けする場合は、システム文字コードが「UTF-8」であることを確認してください。  
```bash
echo $LANG
```


## **8. ブロック生成スケジュールと通知**

[SPO BlockNotify設定](../setup/blocknotify-setup.md)を導入することでブロックログDBに保存されるブロック生成ステータスを`LINE`/`Slack`/`Discord`/`Telegram`に通知することができます。  

!!! info "ブロック生成スケジュール取得のタイミング"
    ブロック生成スケジュールは、**エポックスロットが約302,400を超えた時点**で**次エポックのスケジュールを自動取得**します。これは **次エポック開始の約1.5日前** に相当します。

!!! tip "1エポックで1ブロック割り当てられる委任量の目安"
    | 委任量 | 割り当て確率 |
    |------|-------------|
    | 1M ADA | 約60% |
    | 2M ADA | 約85% |
    | 3M ADA | 約95% |

!!! tip "プール開設後のエポックの流れ"
    新しくプールを登録した場合、**ブロック割り当ては約2エポック後から開始**されます。

    | エポック | 状態 |
    |---------|------|
    | 603 | プール登録 |
    | 604 | 待機期間（次エポックスケジュール算出） |
    | 605 | 委任有効 / ブロック生成開始 |
    | 606 | 報酬計算 |
    | 607 | 報酬支払い |

## **9. CNCLI更新手順**

!!! warning "注意"
    **以下は最新版がリリースされた場合に実行してください。**  
    **１時間以内にブロック生成スケジュールがないことを確認してから、以下を実施してください。**

**CNCLIのアップデート**

```bash
cd $HOME
cncli_release="$(curl -s https://api.github.com/repos/cardano-community/cncli/releases/latest | jq -r '.tag_name' | sed -e "s/^.\{1\}//")"
```
```bash
curl -sLJ https://github.com/cardano-community/cncli/releases/download/v${cncli_release}/cncli-${cncli_release}-ubuntu22-x86_64-unknown-linux-gnu.tar.gz -o $HOME/cncli-${cncli_release}-x86_64-unknown-linux-gnu.tar.gz
```
```bash
tar xzvf $HOME/cncli-${cncli_release}-x86_64-unknown-linux-gnu.tar.gz -C $HOME/.cargo/bin/
```
```bash
rm $HOME/cncli-${cncli_release}-x86_64-unknown-linux-gnu.tar.gz
```

**バージョン確認**
```bash
cncli --version
```
> cncli 6.7.0

**ノード再起動**
```bash
sudo systemctl reload-or-restart cardano-node
```
> ノードの同期を確認

**ログ確認**
```bash
cnclilog
```
>100% syncedになったことを確認


### **9-1. スケジュールにないブロックが生成される場合**

!!! tip "ヒント"
    CNCLIのブロック生成スケジュールは正しい値が取得できていれば、100%正確です。  
    cncli.dbを再作成することで正しいスケジュールを取得することができます。

**サービス停止**
```bash
sudo systemctl stop cnode-cncli-sync.service
```

**cncli.dbを削除**
```bash
rm $NODE_HOME/guild-db/cncli/cncli.db
```

**サービス再起動**
```bash
sudo systemctl restart cnode-cncli-sync.service
```

**ログ確認**
```bash
cnclilog
```
> 100% syncedになるまでお待ちください。

!!! info "制作クレジット"
    このツールは海外ギルドオペレーター制作の[CNCLI By AndrewWestberg](https://github.com/cardano-community/cncli){target="_blank" rel="noopener"}、[Guild LiveView](https://cardano-community.github.io/guild-operators/#/Scripts/gliveview){target="_blank" rel="noopener"}、[BLOCK LOG for CNTools](https://cardano-community.github.io/guild-operators/#/Scripts/cntools){target="_blank" rel="noopener"}を組み合わせたツールとなっております。カスタマイズするにあたり、開発者の[AHLNET(AHL)](https://twitter.com/olaahlman){target="_blank" rel="noopener"}にご協力頂きました。ありがとうございます。

---