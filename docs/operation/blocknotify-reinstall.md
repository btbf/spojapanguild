#　SPO Block Notify移行マニュアル

!!! note "このマニュアルについて"
    このマニュアルは「ブロック生成ステータス通知 v.1.x.x」から「SPO Block Notify v.2.x.x」へ移行するマニュアルとなっております。

    SPO Block Notifyを新規インストールする場合は[11.SPO BlockNotify設定](../setup/11-blocknotify-setup.md)をご参照ください。

    ■対象サーバー

    * ブロック生成ステータス通知設定済みのBPサーバー

    ■ブロック生成ステータス通知からの変更点

    *  `~/cnode/scripts/block-notify/i18n/`内にある言語ファイルで多言語通知が可能
    * `.env`にいくつかの変数追加
    * tmuxでの常駐を廃止し、systemd単体で常駐させる
    * `leaderlog.service`によるブロック生成スケジュール取得自動化へ変更
    * 次エポックスケジュール日付の通知有無を選択可能
    

## 1. サービスファイル修正

サービスを停止する
```
sudo systemctl stop cnode-cncli-sync.service
```

tmux終了確認
```
tmux ls
```
以下の戻り値を確認する
> no server running on ~~~~


既存のブロック生成ステータス通知サービスを削除する
```
sudo systemctl disable cnode-blockcheck.service
sudo rm /etc/systemd/system/cnode-blockcheck.service
sudo systemctl daemon-reload
```

新しいサービスファイルを作成する  
それぞれのタブを全て実行してください。

=== "cncli"
    ```bash
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
    ```bash
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
    ```bash
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
    ```bash
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

=== "blocknotify"
    ```bash
    cat > $NODE_HOME/service/cnode-blocknotify.service << EOF 
    # file: /etc/systemd/system/cnode-blocknotify.service

    [Unit]
    Description=Cardano Node - SPO Blocknotify
    BindsTo=cnode-cncli-sync.service
    After=cnode-cncli-sync.service

    [Service]
    Type=simple
    RemainAfterExit=yes
    Restart=on-failure
    RestartSec=20
    User=$(whoami)
    WorkingDirectory=${NODE_HOME}/scripts
    Environment="NODE_HOME=${NODE_HOME}"
    ExecStart=/bin/bash -c 'cd ${NODE_HOME}/scripts/block-notify/ && python3 -u ./block_notify.py'
    StandardInput=tty-force
    SuccessExitStatus=143
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=cnode-blocknotify
    TimeoutStopSec=5
    KillMode=mixed

    [Install]
    WantedBy=cnode-cncli-sync.service
    EOF
    ```

サービスファイルをシステムディレクトリへコピーする
!!! danger "実行時の注意"
    * コマンドを1行ずつコピーして実行するか、まとめてコピーする場合はターミナルソフト側で「1行送信」で実行してください
```
sudo cp $NODE_HOME/service/cnode-cncli-sync.service /etc/systemd/system/cnode-cncli-sync.service
sudo cp $NODE_HOME/service/cnode-cncli-validate.service /etc/systemd/system/cnode-cncli-validate.service
sudo cp $NODE_HOME/service/cnode-cncli-leaderlog.service /etc/systemd/system/cnode-cncli-leaderlog.service
sudo cp $NODE_HOME/service/cnode-logmonitor.service /etc/systemd/system/cnode-logmonitor.service
sudo cp $NODE_HOME/service/cnode-blocknotify.service /etc/systemd/system/cnode-blocknotify.service
```

権限を変更する
```
sudo chmod 644 /etc/systemd/system/cnode-cncli-sync.service
sudo chmod 644 /etc/systemd/system/cnode-cncli-validate.service
sudo chmod 644 /etc/systemd/system/cnode-cncli-leaderlog.service
sudo chmod 644 /etc/systemd/system/cnode-logmonitor.service
sudo chmod 644 /etc/systemd/system/cnode-blocknotify.service
```
サービスデーモンを再起動する
```
sudo systemctl daemon-reload
```
blockNotifyを登録する
```
sudo systemctl enable cnode-blocknotify.service
```

## 2.SPO Block Notify設定

依存関係インストール

```
sudo apt update -y && sudo apt upgrade -y
```

```
pip install i18nice
```

Block Notifyダウンロード
<!--bn_release="$(curl -s https://api.github.com/repos/btbf/block-notify/releases/latest | jq -r '.tag_name')"-->
```
bn_release="$(curl -s https://api.github.com/repos/btbf/block-notify/releases/latest | jq -r '.tag_name')"
wget https://github.com/btbf/block-notify/archive/refs/tags/${bn_release}.tar.gz -P $NODE_HOME/scripts
```

スクリプト展開
```
cd $NODE_HOME/scripts
tar zxvf ${bn_release}.tar.gz block-notify-${bn_release}/block_notify.py block-notify-${bn_release}/i18n/
mv block-notify-${bn_release} block-notify
rm ${bn_release}.tar.gz
cd block-notify
```

既存設定ファイル移植
```
mv $NODE_HOME/guild-db/blocklog/.env $NODE_HOME/scripts/block-notify/.env
```

変数設定変更  
<font color=red>この項目は複数回実行しないでください</font>
```
sed -i .env \
    -e "2i guild_db_dir = '${NODE_HOME}/guild-db/blocklog/'" \
    -e "2i shelley_genesis = '${NODE_HOME}/${NODE_CONFIG}-shelley-genesis.json'" \
    -e "2i byron_genesis = '${NODE_HOME}/${NODE_CONFIG}-byron-genesis.json'" \
    -e "2i language = \'ja\'\n" \
    -e 's!#リーダースケジュール自動取得 自動:1 手動:0!#次エポックスケジュール日時の通知有無 概要のみ=0 概要と日付=1!' \
    -e 's!auto_leader!nextepoch_leader_date!'
```

## 3.サービス起動
!!! note "サービス起動について"

    * `cncli`および`logmonitor`は`cnode-node.service`に紐づいて起動します
    * `validate`、`leaderlog`、`blockNotifi`は`cnode-cncli-sync.service`に紐づいて起動します。

```
sudo systemctl start cnode-cncli-sync.service
sudo systemctl start cnode-logmonitor.service
```



## 4.サービス起動確認

便利なエイリアス設定
!!! hint "エイリアス設定"
    スクリプトへのパスを通し、エイリアスで起動出来るようにする。
    ```
    echo alias cnclilog='"journalctl --no-hostname -u cnode-cncli-sync -f"' >> $HOME/.bashrc
    echo alias validate='"journalctl --no-hostname -u cnode-cncli-validate -f"' >> $HOME/.bashrc
    echo alias leaderlog='"journalctl --no-hostname -u cnode-cncli-leaderlog -f"' >> $HOME/.bashrc
    echo alias logmonitor='"journalctl --no-hostname -u cnode-logmonitor -f"' >> $HOME/.bashrc
    echo alias blocknotify='"journalctl --no-hostname -u cnode-blocknotify -f"' >> $HOME/.bashrc
    ```
    環境変数再読み込み
    ```
    source $HOME/.bashrc
    ```
    以下のコマンドを入力して実行すると、サービスファイルログが閲覧できます。  
    単語を入力するだけで、起動状態(ログ)を確認できます。  
    `cnclilog`　`validate`　`leaderlog`　`logmonitor`


他サービスの起動確認
=== "cncli"

    !!! info ""
        こちらのサービスはノードミニプロトコルからチェーンデータを取得します

        ```
        cnclilog
        ```

        以下の表示なら正常です。
        > INFO  cncli::nodeclient::sync > block xxxxxxxxx of xxxxxxxxx: 100.00% synced
        
        Ctrl+cで閉じます

=== "validate"

    !!! info ""
        こちらのサービスは生成したブロックのオンチェーンデータを確認します。

        ```
        validate
        ```

        以下の表示なら正常です。
        > ~ CNCLI Block Validation started ~
        
        Ctrl+cで閉じます

=== "leaderlog"

    !!! info ""

        こちらのサービスはスロットリーダーを自動的に算出します。 
        次エポックの1.5日前から次エポックのスケジュールを自動算出します。

        ```
        leaderlog
        ```

        以下の表示なら正常です。
        > ~ CNCLI Leaderlog started ~

        Ctrl+cで閉じます

=== "logmonitor"

    !!! info ""
        こちらのサービスはプールのノードログからブロック生成結果を抽出します。

        ```
        logmonitor
        ```

        以下の表示なら正常です。  

        > ~~ LOG MONITOR STARTED ~~  
        > monitoring logs/node.json for traces

        Ctrl+cで閉じます

=== "blockNotifi"

    !!! info ""
        こちらのサービスはブロック生成ステータスを任意のプラットフォームへ通知します。

        ```
        blocknotify
        ```

        以下の表示なら正常です。  

        > [xxx] ブロック生成ステータス通知を起動しました 

        Ctrl+cで閉じます

## 5. 旧ファイル削除
```
rm $NODE_HOME/guild-db/blocklog/block_check.py $NODE_HOME/guild-db/blocklog/send.txt
```
