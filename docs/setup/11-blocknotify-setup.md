# **SPO Block Notify設定**

!!! danger "お知らせ"
    ブロック生成ステータス通知が「SPO Block Notify」に生まれ変わりました！
    


!!! info "概要"
    最終更新日：2024/3/20  v2.2.0

    * ブロックログで表示されるブロック生成結果を任意のソーシャルアプリへ通知します。   
    ![*](../images/block_notify/image.png)

    * ブロック生成スケジュールを自動取得し、取得スケジュール一覧を通知します。  
    ![*](../images/block_notify/auto_leader.png)

    * 通知先対応アプリ LINE/Slack/discord/telegram

    * 多言語ファイルを用意することで様々な言語に対応しました！
 
    * ブロックログと連動しておりますので、まだ設定されてない場合は[ブロックログ導入手順](./10-blocklog-setup.md)を先に導入してください。

    * 以下の作業はguild-dbが存在するBPサーバーのみで実施し、ブロック生成スケジュールがないタイミングで実施してください。 

    * 設定は任意です。(設定しなくてもブロック生成に影響はありません)


??? info "更新履歴▼"

    * 2.2.0  ・サービス再起動時の強制終了バグを解消
    　　　　　・プログラム最適化
    　　　　　・Python3.10以上
    * 2.1.3　・次スケジュールが無い場合のエラー解消
    * 2.1.2　・次エポックスケジュール日付の通知有無対応
    * 2.1.1　・ブロックログサービスファイル対応
    * 2.0.0　・多言語対応
    * 1.9.5　・LINE通知不具合修正
    * 1.9.4　・スケジュール取得スロットを`303300`～`317700`間でランダム化
    * 1.9.0　・ノード再起動時のエラー修正
    * 1.8.9　・エポック境界の通知内容不具合修正  
    　　　・通知内容フォーマット変更
    
    * 1.8.8 ・ステータス通知サービス起動時に通知  
    　　　・通知先トークン未入力の場合にサービス画面でエラー排出
    * 1.8.7 ノード再起動後、通知されない不具合を修正
    * 1.8.6 スケジュール取得自動化導入(選択式)  
    　　　・取得スケジュール一覧通知
    * 1.7 スケジュール取得タイミング通知  
    　　　・生成ブロックのPooltoolリンク追加
    * 1.6 ブロック未生成プールで使用する場合の起動時エラーを修正
    * 1.5 10分以内に複数のスケジュールがある場合の通知バグ修正
    * 1.4 次のスケジュールを表示
    * 1.3 ノード再起動時の不具合を修正
    * 1.2.3 エポック取得フロー修正
    * 1.2.2 通知バグ修正
    * 1.2 ・Telegram、Slackに対応  
    　　　・通知基準設定( 全て/confirm以外全て/Missedとivaildのみ)  
    　　　・通知内容を変更(X番目/トータルスケジュール数)  
    * 1.1 スケジュール取得時、その他通知判定修正  
    * 1.0.1 軽微な修正  
    * 1.0 初版リリース  



## **11-1. 依存プログラムをインストールする**

**Python環境をセットアップする**

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
    wget https://raw.githubusercontent.com/btbf/spojapanguild/master/scripts/pythonUpdate.sh
    chmod +x pythonUpdate.sh
    ./pythonUpdate.sh
    ```

依存関係をインストールする
```bash
sudo apt install -y build-essential libssl-dev libffi-dev python3-dev python3-pip python3-testresources
```
```bash
pip3 install watchdog pytz python-dateutil requests discordwebhook slackweb i18nice
```

**実行スクリプトと設定ファイルをダウンロードする**

```bash
bn_release="$(curl -s https://api.github.com/repos/btbf/block-notify/releases/latest | jq -r '.tag_name')"
wget https://github.com/btbf/block-notify/archive/refs/tags/${bn_release}.tar.gz -P $NODE_HOME/scripts
cd $NODE_HOME/scripts
tar zxvf ${bn_release}.tar.gz block-notify-${bn_release}/block_notify.py block-notify-${bn_release}/config.ini block-notify-${bn_release}/i18n/ 
mv block-notify-${bn_release} block-notify
rm ${bn_release}.tar.gz

```

## **11-2. 通知アプリの設定**

通知させたいアプリのタブをクリックし設定を確認してください。

=== "LINE"
    * **1.LINEグループを作成する**  
    ![*](../images/block_notify/2-1-1-1.png)

    * **2.「Line Notify」を追加する**  
    ![*](../images/block_notify/2-1-1-2.png)

    * **3.任意のグループ名を設定し「作成」をクリックする**
    ![*](../images/block_notify/2-1-1-3.png)

    * **4.[LINE Notifyマイページ](https://notify-bot.line.me/my/)にアクセスする**  
    
    * **5.トークンを発行するをクリックします**  
    ![*](../images/block_notify/2-1-1.jpg)
    
    * **6.トークン名「ブロック生成通知」(任意)を入力し、3で作成したグループ名を選択する**  
    ![*](../images/block_notify/2-1-2.png)
    
    * **7.「発行する」をクリックする**
    
    * **8.表示されたトークンをコピーし、一旦メモ帳などに貼り付ける**    
    （発行されたトークンを閉じると2度と確認できませんのでご注意ください）  
    ![*](../images/block_notify/2-1-3.jpg)

=== "Discord"

    * 1.サーバーを追加する  
    ![*](../images/block_notify/3-1-1.jpg)
    
    * 2.「オリジナルの作成」を選択する  
    ![*](../images/block_notify/3-1-2.jpg)
    
    * 3.「自分と友達のため」を選択する  
    ![*](../images/block_notify/3-1-3.jpg)
    
    * 4.任意のサーバー名を入力して「新規作成」をクリックする  
    ![*](../images/block_notify/3-1-4.jpg)
    
    * 5.通知したいチャンネルの歯車マークをクリックする  
    ![*](../images/block_notify/3-1-5.jpg)
    
    * 6.「連携サービス」をクリックし、「ウェブフックを作成」をクリックする  
    ![*](../images/block_notify/3-1-6.jpg)
    
    * 7.「ウェブフックURLをコピー」をクリックし、一旦メモ帳などに貼り付ける  
    ![*](../images/block_notify/3-1-7.jpg)


=== "Telegram"
    * 1.Telegramの検索欄で「@botFather」を検索して認証マーク付きのアカウントをクリックする  
    ![*](../images/block_notify/4-1-1.jpg)

    * 2.「START」をクリックする  
    ![*](../images/block_notify/4-1-2.jpg)

    * 3.「/newbot」コマンドを入力する  
    ![*](../images/block_notify/4-1-3.jpg)

    * 4.任意のbot名を入力する 例）「btbf_bot」最後は必ず`_bot`で終わるようにする  
    ![*](../images/block_notify/4-1-4.jpg)

    * 5.緑で隠した部分のAPIトークンをメモ帳に控える  
    ![*](../images/block_notify/4-1-4.jpg)

    * 6.赤枠で囲ったbotチャンネルに参加する  
    ![*](../images/block_notify/4-1-4-1.jpg)

    * 7.検索欄で「@RawDataBot」を検索してクリックする  
    ![*](../images/block_notify/4-1-5.jpg)

    * 8.「START」をクリックする  
    ![*](../images/block_notify/4-1-6.jpg)

    * 9.「Chat id」をメモ帳に控える  
    ![*](../images/block_notify/4-1-7.jpg)

=== "Slack"
    * 1.Slackを起動し、通知用のワークスペースとチャンネルを設定する

    * 2.[Incoming Webhook](https://my.slack.com/services/new/incoming-webhook/)の設定ページへアクセスする

    * 3.通知したいワークスペースとチャンネルを選択する  
    ![*](../images/block_notify/5-1-1.jpg)

    * 4.「Webhook URL」をメモ帳に控える  
    ![*](../images/block_notify/5-1-2.jpg)

    * 5.ページ下部の「設定を保存する」をクリックする  
    ![*](../images/block_notify/5-1-3.jpg)

## **11-3. 通知プログラムの設定**

**設定ファイルをSJG用に書き換える**
```
cd block-notify
sed -i config.ini \
    -e 's!/opt/cardano/cnode!'${NODE_HOME}'!' \
    -e 's!files/!'${NODE_CONFIG}-'!' \
    -e 's!notify_language = en!notify_language = ja!' \
    -e 's!Etc/UTC!Asia/Tokyo!'
```

**設定ファイルの編集**  
以下の設定ファイル内容詳細を参照し、ご自身の環境に合わせた値を設定してください。

```bash
cd $NODE_HOME/scripts/block-notify
nano config.ini
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



**サービスファイルを設定する**
=== "ブロックプロデューサーノード"
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

    ```
    sudo cp $NODE_HOME/service/cnode-blocknotify.service /etc/systemd/system/cnode-blocknotify.service
    ```

    ```bash title="Ubuntu22.04の場合は１行づつ実行してください"
    sudo chmod 644 /etc/systemd/system/cnode-blocknotify.service
    sudo systemctl daemon-reload
    sudo systemctl enable cnode-blocknotify.service
    ```
    SPO BlockNotifyを起動する
    ```
    sudo systemctl start cnode-blocknotify.service
    ```

    環境変数にログ確認用エイリアスを追加する
    ```
    echo alias blocknotify='"journalctl --no-hostname -u cnode-blocknotify -f"' >> $HOME/.bashrc
    ```
    環境変数再読み込み
    ```
    source $HOME/.bashrc
    ```

    起動確認
    ```
    blocknotify
    ```
    以下の表示なら正常です。
    > [xxx] ブロック生成ステータス通知を起動しました 


!!! danger ""
    新規セットアップは以上です。

<!--
## **11-4. バージョンアップ手順**

サービスを停止する
```
sudo systemctl stop cnode-blocknotify.service
```

**バージョン確認**
```
cd $NODE_HOME/scripts/block-notify
cat block_notify.py | grep -HnI -m1 -r version
```

スクリプトをダウンロードする
```
cd $NODE_HOME/scripts/block-notify
bn_release="$(curl -s https://api.github.com/repos/btbf/block-notify/releases/latest | jq -r '.tag_name')"
wget -q https://raw.githubusercontent.com/btbf/block-notify/${bn_release}/block_notify.py
```
**バージョン確認**
```
cd $NODE_HOME/scripts/block-notify
cat block_notify.py | grep -HnI -m1 -r version
```
現在の最新バージョン
> version = "2.1.1"

サービスを再起動する
```
sudo systemctl start cnode-blocknotify.service
```

起動確認
```
blocknotify
```
> 「Guild-db monitoring started」 が表示されていればOKです。  
> 任意の通知先に通知が届いているか確認してください 

-->

## **11-4.アップデート手順**

SPO BlockNotifyを停止する
```
sudo systemctl stop cnode-blocknotify.service
```

アップデートファイルをダウンロードする
```bash
bn_release="$(curl -s https://api.github.com/repos/btbf/block-notify/releases/latest | jq -r '.tag_name')"
wget https://github.com/btbf/block-notify/archive/refs/tags/${bn_release}.tar.gz -P $NODE_HOME/scripts
cd $NODE_HOME/scripts
tar zxvf ${bn_release}.tar.gz block-notify-${bn_release}/block_notify.py
cp block-notify-${bn_release}/block_notify.py block-notify/block_notify.py
rm -rf block-notify-${bn_release} ${bn_release}.tar.gz
```

SPO BlockNotifyを起動する
```
sudo systemctl start cnode-blocknotify.service
```

バージョン確認
```
python3 $NODE_HOME/scripts/block-notify/block_notify.py version
```

## **11-5.アンインストール手順**

```
sudo systemctl stop cnode-blocknotify.service
```
```
sudo systemctl disable cnode-blocknotify.service
sudo rm /etc/systemd/system/cnode-blocknotify.service
```
