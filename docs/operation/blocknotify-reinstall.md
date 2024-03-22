---
status: new
---
#　SPO Block Notify移行マニュアル

!!! note "このマニュアルについて"

    **■アップデート対象パターン**

    1. 「旧ブロック生成ステータス通知 v.1.x.x」→「SPO Block Notify v.2.2.0」
    2. 「SPO Block Notify v.2.1.2/v2.1.3」→「SPO Block Notify v.2.2.0」
    3. 「旧ブロック生成ステータス通知 未導入」→「SPO Block Notify v.2.2.0」

    **■対象サーバー**

    * BPサーバー

    **■ブロック生成ステータス通知からの変更点**

    *  `~/cnode/scripts/block-notify/i18n/`内にある言語ファイルで多言語通知が可能
    * 設定ファイルを`.env`から`config.ini`へ変更
    * tmuxでの常駐を廃止し、systemd単体で常駐させる
    * `leaderlog.service`によるブロック生成スケジュール取得自動化へ変更
    * 次エポックスケジュール日付の通知有無を選択可能


以下は現在のインストール状況に合わせて選択してください。

??? danger "旧ブロック生成ステータス通知 v.1.x.xからのアップデート"
    ## 旧ブロック生成ステータス通知 v.1.x.xからのアップデート

    パッケージを更新する
    ```bash
    sudo apt update && sudo apt upgrade -y
    ```

    pythonバージョンを確認する
    ```bash
    python3 -V
    ```
    > Python 3.10以上

    ??? "Python 3.9以下の場合こちらのツールでアップデートしてください"
        pythonUpdate.shをダウンロードして自動アップデートする
        ```
        cd
        wget https://raw.githubusercontent.com/btbf/spojapanguild/v13.2.x/scripts/pythonUpdate.sh
        chmod +x pythonUpdate.sh
        ./pythonUpdate.sh
        ```

    依存関係をインストールする
    ```bash
    sudo apt install -y build-essential libssl-dev libffi-dev python3-dev python3-pip python3-testresources
    ```
    ```bash
    pip3 install --upgrade watchdog pytz python-dateutil requests discordwebhook slackweb i18nice
    ```

    ### 1. サービスファイル修正

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
    ``` title="Ubuntu22.04の場合は１行づつ実行してください"
    sudo systemctl disable cnode-blockcheck.service
    sudo rm /etc/systemd/system/cnode-blockcheck.service
    sudo systemctl daemon-reload
    ```

    新しいサービスファイルを作成する  
    それぞれのタブを全て実行してください。

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

    === "blocknotify"
        ```bash title="このボックスはすべてコピーして実行してください"
        cat > $NODE_HOME/service/cnode-blocknotify.service << EOF 
        # file: /etc/systemd/system/cnode-blocknotify.service

        [Unit]
        Description=Cardano Node - SPO Blocknotify
        BindsTo=cnode-cncli-sync.service
        After=cnode-cncli-sync.service

        [Service]
        Type=simple
        User=$(whoami)
        WorkingDirectory=${NODE_HOME}/scripts/block-notify
        ExecStart=/bin/bash -c 'cd ${NODE_HOME}/scripts/block-notify/ && python3 -u block_notify.py'
        Restart=on-failure
        StandardOutput=syslog
        StandardError=syslog
        SyslogIdentifier=cnode-blocknotify

        [Install]
        WantedBy=cnode-cncli-sync.service
        EOF
        ```

    サービスファイルをシステムディレクトリへコピーする

    ``` title="Ubuntu22.04の場合は１行づつ実行してください"
    sudo cp $NODE_HOME/service/cnode-cncli-sync.service /etc/systemd/system/cnode-cncli-sync.service
    sudo cp $NODE_HOME/service/cnode-cncli-validate.service /etc/systemd/system/cnode-cncli-validate.service
    sudo cp $NODE_HOME/service/cnode-cncli-leaderlog.service /etc/systemd/system/cnode-cncli-leaderlog.service
    sudo cp $NODE_HOME/service/cnode-logmonitor.service /etc/systemd/system/cnode-logmonitor.service
    sudo cp $NODE_HOME/service/cnode-blocknotify.service /etc/systemd/system/cnode-blocknotify.service
    ```

    権限を変更する
    ``` title="Ubuntu22.04の場合は１行づつ実行してください"
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

    ### 2.SPO Block Notify設定

    依存関係インストール

    Block Notifyダウンロード
    <!--bn_release="$(curl -s https://api.github.com/repos/btbf/block-notify/releases/latest | jq -r '.tag_name')"-->
    ```
    bn_release="$(curl -s https://api.github.com/repos/btbf/block-notify/releases/latest | jq -r '.tag_name')"
    wget https://github.com/btbf/block-notify/archive/refs/tags/${bn_release}.tar.gz -P $NODE_HOME/scripts
    ```

    スクリプト展開
    ```
    cd $NODE_HOME/scripts
    tar zxvf ${bn_release}.tar.gz block-notify-${bn_release}/block_notify.py block-notify-${bn_release}/i18n/ block-notify-${bn_release}/config.ini
    mv block-notify-${bn_release} block-notify
    rm ${bn_release}.tar.gz
    cd block-notify
    ```

    旧`.env`設定ファイルバックアップ
    ```
    cp $NODE_HOME/guild-db/blocklog/.env $NODE_HOME/scripts/block-notify/.env
    ```

    設定ファイル値変更  
    ```
    sed -i config.ini \
        -e 's!/opt/cardano/cnode!'${NODE_HOME}'!' \
        -e 's!files/!'${NODE_CONFIG}-'!' \
        -e 's!notify_language = en!notify_language = ja!' \
        -e 's!Etc/UTC!Asia/Tokyo!'
    ```

    以下の設定ファイル内容詳細を参照し、ご自身の環境に合わせた値を設定してください。

    ```bash
    cd $NODE_HOME/scripts/block-notify
    nano config.ini
    ```
    旧`.env`ファイルに設定中の値を確認する場合は
    ```
    cat $NODE_HOME/scripts/block-notify/.env
    ```

    !!! hint "設定ファイル内容詳細"
        | 項目      | 値      | 使用用途                          |
        | ----------- |---------| ------------------------------------ |
        | `pool_ticker`      | ex.) SJG | プールティッカー名を入力する  |
        | `notify_language` | 英語:`en`<br>日本語:`ja`| 通知言語を入力する |
        | `notify_timezone`   | Asia/Tokyo<br>[タイムゾーン一覧](https://gist.github.com/heyalexej/8bf688fd67d7199be4a1682b3eec7568) | お住いの[タイムゾーン](https://gist.github.com/heyalexej/8bf688fd67d7199be4a1682b3eec7568)を指定する |
        | `notify_platform`   | `Line`<br>`Discord`<br>`Slack`<br>`Telegram` | 通知先プラットフォームを指定する<br> (複数指定は無効) |
        | `notify_level`   |全て:`All`<br>Confirm以外:`ExceptCofirm`<br>Missのみ:`OnlyMissed`  | 通知基準を設定する |
        | `nextepoch_leader_date`   |概要のみ:`SummaryOnly`<br>概要と日付:`SummaryDate` | 次エポックスケジュール日時の通知有無<br>次エポックスケジュール日付一覧を通知に流したくない場合は`SummaryOnly`を記載してください |
        | `line_notify_token`     |[LINE設定の(8)](#__tabbed_1_1)で発行したトークンID | Line Notifyトークンを入力する |
        | `discord_webhook_url`   |[Discord設定の(7)](#__tabbed_1_2)で発行したウェブフックURL| DiscordウェブフックURLを入力する |
        | `slack_webhook_url`   |[Slack設定の(4)](#__tabbed_1_4)で発行したWebhook URL| SlackウェブフックURLを入力する |
        | `telegram_token`   |[Telegram設定の(5)](#__tabbed_1_3)で発行したAPIトークン | Telegram APIトークンを入力する |
        | `telegram_id`   |[Telegram設定の(9)](#__tabbed_1_3)で表示されたChat id| Telegram ChatIDを入力する |
        | `node_home` |ex.)`/home/usr/cnode`| node_homeディレクトリパスを入力する |
        | `guild_db_dir` |ex.)`%(node_home)s/guild-db/blocklog/`| guild-dbのパスを入力する<br>`%(node_home)s`は変数のため変更しないでください |
        | `shelley_genesis` |ex.)`%(node_home)s/files/shelley-genesis.json`| shelley_genesisのファイルパスを入力する<br>`%(node_home)s`は変数のため変更しないでください |
        | `byron_genesis` |ex.)`%(node_home)s/files/byron-genesis.json`| byron_genesisのファイルパスを入力する<br>`%(node_home)s`は変数のため変更しないでください |

    バージョン確認
    ```
    python3 $NODE_HOME/scripts/block-notify/block_notify.py version
    ```

    ### 3.サービス起動
    !!! note "サービス起動について"

        * `cncli`および`logmonitor`は`cnode-node.service`に紐づいて起動します
        * `validate`、`leaderlog`、`blockNotifi`は`cnode-cncli-sync.service`に紐づいて起動します。

    ``` title="Ubuntu22.04の場合は１行づつ実行してください"
    sudo systemctl start cnode-cncli-sync.service
    sudo systemctl start cnode-logmonitor.service
    ```



    ### 4.サービス起動確認

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
        `cnclilog`　`validate`　`leaderlog`　`logmonitor` `blocknotify`


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

    === "blockNotify"

        !!! info ""
            こちらのサービスはブロック生成ステータスを任意のプラットフォームへ通知します。

            ```
            blocknotify
            ```

            以下の表示なら正常です。  

            > [xxx] ブロック生成ステータス通知を起動しました 

            Ctrl+cで閉じます

    ### 5. 旧ファイル削除
    ```
    rm $NODE_HOME/guild-db/blocklog/block_check.py $NODE_HOME/guild-db/blocklog/send.txt
    ```


??? danger "SPO Block Notify v.2.1.2/v2.1.3からのアップデート"
    ## SPO Block Notify v.2.1.2/v2.1.3からのアップデート

    パッケージを更新する
    ```bash
    sudo apt update && sudo apt upgrade -y
    ```

    pythonバージョンを確認する
    ```bash
    python3 -V
    ```
    > Python 3.10以上

    ??? "Python 3.9以下の場合こちらのツールでアップデートしてください"
        pythonUpdate.shをダウンロードして自動アップデートする
        ```
        cd
        wget https://raw.githubusercontent.com/btbf/spojapanguild/v13.2.x/scripts/pythonUpdate.sh
        chmod +x pythonUpdate.sh
        ./pythonUpdate.sh
        ```

    依存関係をインストールする
    ```bash
    sudo apt install -y build-essential libssl-dev libffi-dev python3-dev python3-pip python3-testresources
    ```
    ```bash
    pip3 install --upgrade watchdog pytz python-dateutil requests discordwebhook slackweb i18nice
    ```

    ### 1. サービスファイル修正

    サービスを停止する
    ```
    sudo systemctl stop cnode-cncli-sync.service
    ```

    サービスファイルを更新する

    === "blocknotify"
        ```bash title="このボックスはすべてコピーして実行してください"
        cat > $NODE_HOME/service/cnode-blocknotify.service << EOF 
        # file: /etc/systemd/system/cnode-blocknotify.service

        [Unit]
        Description=Cardano Node - SPO Blocknotify
        BindsTo=cnode-cncli-sync.service
        After=cnode-cncli-sync.service

        [Service]
        Type=simple
        User=$(whoami)
        WorkingDirectory=${NODE_HOME}/scripts/block-notify
        ExecStart=/bin/bash -c 'cd ${NODE_HOME}/scripts/block-notify/ && python3 -u block_notify.py'
        Restart=on-failure
        StandardOutput=syslog
        StandardError=syslog
        SyslogIdentifier=cnode-blocknotify

        [Install]
        WantedBy=cnode-cncli-sync.service
        EOF
        ```

    サービスファイルをシステムディレクトリへコピーする

    ``` bash
    sudo cp $NODE_HOME/service/cnode-blocknotify.service /etc/systemd/system/cnode-blocknotify.service
    ```

    サービスデーモンを再起動する
    ```
    sudo systemctl daemon-reload
    ```


    ### 2.SPO Block Notify再設定

    `.env`バックアップ
    ```
    cp $NODE_HOME/scripts/block-notify/.env $NODE_HOME/scripts/block-notify-env
    ```

    既存スクリプト削除
    ```
    rm -rf $NODE_HOME/scripts/block-notify
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
    tar zxvf ${bn_release}.tar.gz block-notify-${bn_release}/block_notify.py block-notify-${bn_release}/i18n/ block-notify-${bn_release}/config.ini
    mv block-notify-${bn_release} block-notify
    rm ${bn_release}.tar.gz
    cd block-notify
    ```

    設定ファイル値変更  
    ```
    sed -i config.ini \
        -e 's!/opt/cardano/cnode!'${NODE_HOME}'!' \
        -e 's!files/!'${NODE_CONFIG}-'!' \
        -e 's!notify_language = en!notify_language = ja!' \
        -e 's!Etc/UTC!Asia/Tokyo!'
    ```

    以下の設定ファイル内容詳細を参照し、ご自身の環境に合わせた値を設定してください。

    ```bash
    cd $NODE_HOME/scripts/block-notify
    nano config.ini
    ```
    旧`.env`ファイルに設定中の値を確認する場合は
    ```
    cat $NODE_HOME/scripts/block-notify-env
    ```

    !!! hint "設定ファイル内容詳細"
        | 項目      | 値      | 使用用途                          |
        | ----------- |---------| ------------------------------------ |
        | `pool_ticker`      | ex.) SJG | プールティッカー名を入力する  |
        | `notify_language` | 英語:`en`<br>日本語:`ja`| 通知言語を入力する |
        | `notify_timezone`   | Asia/Tokyo<br>[タイムゾーン一覧](https://gist.github.com/heyalexej/8bf688fd67d7199be4a1682b3eec7568) | お住いの[タイムゾーン](https://gist.github.com/heyalexej/8bf688fd67d7199be4a1682b3eec7568)を指定する |
        | `notify_platform`   | `Line`<br>`Discord`<br>`Slack`<br>`Telegram` | 通知先プラットフォームを指定する<br> (複数指定は無効) |
        | `notify_level`   |全て:`All`<br>Confirm以外:`ExceptCofirm`<br>Missのみ:`OnlyMissed`  | 通知基準を設定する |
        | `nextepoch_leader_date`   |概要のみ:`SummaryOnly`<br>概要と日付:`SummaryDate` | 次エポックスケジュール日時の通知有無<br>次エポックスケジュール日付一覧を通知に流したくない場合は`SummaryOnly`を記載してください |
        | `line_notify_token`     |[LINE設定の(8)](#__tabbed_1_1)で発行したトークンID | Line Notifyトークンを入力する |
        | `discord_webhook_url`   |[Discord設定の(7)](#__tabbed_1_2)で発行したウェブフックURL| DiscordウェブフックURLを入力する |
        | `slack_webhook_url`   |[Slack設定の(4)](#__tabbed_1_4)で発行したWebhook URL| SlackウェブフックURLを入力する |
        | `telegram_token`   |[Telegram設定の(5)](#__tabbed_1_3)で発行したAPIトークン | Telegram APIトークンを入力する |
        | `telegram_id`   |[Telegram設定の(9)](#__tabbed_1_3)で表示されたChat id| Telegram ChatIDを入力する |
        | `node_home` |ex.)`/home/usr/cnode`| node_homeディレクトリパスを入力する |
        | `guild_db_dir` |ex.)`%(node_home)s/guild-db/blocklog/`| guild-dbのパスを入力する<br>`%(node_home)s`は変数のため変更しないでください |
        | `shelley_genesis` |ex.)`%(node_home)s/files/shelley-genesis.json`| shelley_genesisのファイルパスを入力する<br>`%(node_home)s`は変数のため変更しないでください |
        | `byron_genesis` |ex.)`%(node_home)s/files/byron-genesis.json`| byron_genesisのファイルパスを入力する<br>`%(node_home)s`は変数のため変更しないでください |

    バージョン確認
    ```
    python3 $NODE_HOME/scripts/block-notify/block_notify.py version
    ```

    ### 3.サービス起動
    !!! note "サービス起動について"

        * `cncli`および`logmonitor`は`cnode-node.service`に紐づいて起動します
        * `validate`、`leaderlog`、`blockNotifi`は`cnode-cncli-sync.service`に紐づいて起動します。

    ``` title="Ubuntu22.04の場合は１行づつ実行してください"
    sudo systemctl start cnode-cncli-sync.service
    sudo systemctl start cnode-logmonitor.service
    ```

    サービスの起動確認
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

    === "blockNotify"

        !!! info ""
            こちらのサービスはブロック生成ステータスを任意のプラットフォームへ通知します。

            ```
            blocknotify
            ```

            以下の表示なら正常です。  

            > [xxx] ブロック生成ステータス通知を起動しました 

            Ctrl+cで閉じます

??? danger "旧ブロック生成ステータス通知 未導入からのインストール"
    ## 旧ブロック生成ステータス通知 未導入からのインストール

    !!! danger "前提条件"
        TMUX起動のブロックログが導入済みでかつ旧ブロック生成ステータス通知が未導入の場合

    ### 1. サービスファイル修正

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


    新しいサービスファイルを作成する  
    それぞれのタブを全て実行してください。

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

    サービスファイルをシステムディレクトリへコピーする

    ``` title="Ubuntu22.04の場合は１行づつ実行してください"
    sudo cp $NODE_HOME/service/cnode-cncli-sync.service /etc/systemd/system/cnode-cncli-sync.service
    sudo cp $NODE_HOME/service/cnode-cncli-validate.service /etc/systemd/system/cnode-cncli-validate.service
    sudo cp $NODE_HOME/service/cnode-cncli-leaderlog.service /etc/systemd/system/cnode-cncli-leaderlog.service
    sudo cp $NODE_HOME/service/cnode-logmonitor.service /etc/systemd/system/cnode-logmonitor.service
    ```

    権限を変更する
    ``` title="Ubuntu22.04の場合は１行づつ実行してください"
    sudo chmod 644 /etc/systemd/system/cnode-cncli-sync.service
    sudo chmod 644 /etc/systemd/system/cnode-cncli-validate.service
    sudo chmod 644 /etc/systemd/system/cnode-cncli-leaderlog.service
    sudo chmod 644 /etc/systemd/system/cnode-logmonitor.service
    ```
    サービスデーモンを再起動する
    ```
    sudo systemctl daemon-reload
    ```
    サービスを起動する
    ```
    sudo systemctl start cnode-cncli-sync.service
    sudo systemctl start cnode-logmonitor.service
    ```

    ### 2.SPO Block Notify設定

    [11.SPO BlockNotify設定](../setup/11-blocknotify-setup.md)を実施してください。

