# ** ブロック生成ステータス通知 **

!!! info "概要"
    * ブロックログで表示されるブロック生成結果をお好みのソーシャルアプリへ通知します。 
    ![*](../images/block_notify/image.png)

    * 対応アプリ LINE/Slack/discord/telegram
 
    * ブロックログと連動しておりますので、まだ設定されてない場合は[ブロックログ導入手順](./10-blocklog-setup.md)を先に導入してください。

    * 以下の作業はguild-dbが存在するBPサーバーのみで実施し、ブロック生成スケジュールがないタイミングで実施してください。 

    * 設定は任意です。(設定しなくてもブロック生成に影響はありません)

!!! info ""
    最終更新日：2022/02/15  v1.6


??? info "更新履歴▼"
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

### **Python環境をセットアップする**

pythonバージョンを確認する
```bash
python3 -V
```
> Python 3.8.10以上 

パッケージを更新する
```bash
sudo apt update -y
```

```bash
sudo apt install -y python3-watchdog python3-tz python3-dateutil python3-requests build-essential libssl-dev libffi-dev python3-dev python3-pip
```
```bash
pip install discordwebhook python-dotenv slackweb
```

### **実行スクリプトと設定ファイルをダウンロードする**

```bash
cd $NODE_HOME/guild-db/blocklog
wget -N https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/block_notify/block_check.py
wget -N https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/block_notify/.env
chmod 755 block_check.py
```

## **11-2. 通知アプリの設定**

通知させたいアプリのタブをクリックし設定を確認してください。

=== "LINE"

    * 1.[LINE Notifyマイページ](https://notify-bot.line.me/my/)にアクセスする  
    
    * 2.トークンを発行するをクリックします  
    ![*](../images/block_notify/2-1-1.jpg)
    
    * 3.トークン名「ブロック生成通知」(任意)を入力し、「1：1でLINE Notifyから通知を受け取る」を選択する  
    ![*](../images/block_notify/2-1-2.JPG)
    
    * 4.「発行する」をクリックする
    
    * 5.表示されたトークンをコピーし、一旦メモ帳などに貼り付ける（発行されたトークンを閉じると2度と確認できませんのでご注意ください）  
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

###  **設定ファイルの編集**
```bash
cd $NODE_HOME/guild-db/blocklog
nano .env
```
> .envは隠しファイルになっているので、`ls -a`コマンドで一覧表示されます。

!!! hint "envファイル内容詳細"
    | 項目      | 使用用途                          |
    | ----------- | ------------------------------------ |
    | `ticker`       | プールティッカー名を入力する  |
    | `line_notify_token`      | Line Notifyトークンを入力する |
    | `dc_notify_url`    | DiscordウェブフックURLを入力する |
    | `slack_notify_url`    | SlackウェブフックURLを入力する |
    | `teleg_token`    | Telegram APIトークンを入力する |
    | `teleg_id`    | Telegram ChatIDを入力する |
    | `b_timezone`    | お住いのタイムゾーンを指定する |
    | `bNotify`    | 通知先を指定する |
    | `bNotify_st`    | 通知基準を設定する |


### **サービスファイルを設定する**
=== "ブロックプロデューサーノード"
    ```bash
    cat > $NODE_HOME/service/cnode-blockcheck.service << EOF 
    # file: /etc/systemd/system/cnode-blockcheck.service

    [Unit]
    Description=Cardano Node - CNCLI blockcheck
    BindsTo=cnode-cncli-sync.service
    After=cnode-cncli-sync.service

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    Restart=on-failure
    RestartSec=20
    User=$(whoami)
    WorkingDirectory=$NODE_HOME
    ExecStart=/usr/bin/tmux new -d -s blockcheck
    ExecStartPost=/usr/bin/tmux send-keys -t blockcheck 'cd $NODE_HOME/guild-db/blocklog' Enter
    ExecStartPost=/usr/bin/tmux send-keys -t blockcheck python3 Space block_check.py Enter
    ExecStop=/usr/bin/tmux kill-session -t blockcheck
    KillSignal=SIGINT
    RestartKillSignal=SIGINT
    SuccessExitStatus=143
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=cnode-blockcheck
    TimeoutStopSec=5

    [Install]
    WantedBy=cnode-cncli-sync.service
    EOF
    ```

    ```
    sudo cp $NODE_HOME/service/cnode-blockcheck.service /etc/systemd/system/cnode-blockcheck.service
    sudo chmod 644 /etc/systemd/system/cnode-blockcheck.service
    ```

    ```
    sudo systemctl daemon-reload
    sudo systemctl enable cnode-blockcheck.service
    ```
    ノードを再起動する
    ```
    sudo systemctl reload-or-restart cardano-node
    ```

### **起動確認**
```
tmux a -t blockcheck
```
> 「db-monitoring started」 が表示されていればOKです  
> cnode-cncli-sync.serviceと同じく、node再起動・停止と連動します

### **通知確認**
ブロック生成スケジュール予定時刻が過ぎてから、約15分以内に通知が届きます。

## **11-4. バージョンアップ手順**

=== "1.2以降から最新へのアップデート"
    ```
    cd $NODE_HOME/guild-db/blocklog
    wget https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/block_notify/block_check.py -O block_check.py
    ```

=== "1.1から最新へのアップデート"

    Slack用モジュールをインストールする
    ```bash
    pip install slackweb
    ```

    既に設定済みの通知用トークンやURLを控える
    ```
    cd $NODE_HOME/guild-db/blocklog
    nano .env
    ```

    設定ファイル、プログラムを更新する
    ```
    cd $NODE_HOME/guild-db/blocklog
    wget https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/block_notify/.env -O .env
    wget https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/block_notify/block_check.py -O block_check.py
    ```

    各通知先の設定は[11-2.通知アプリの設定](./11-blocknotify-setup#11-2)を参照してください

    設定ファイルを変更する
    ```
    nano .env
    ```
    > Ticker、通知先、通知基準などを変更する

サービスを再起動する
```
sudo systemctl reload-or-restart cnode-blockcheck.service
```

サービス起動確認
```
tmux a -t blockcheck
```
> 「db-monitoring started」 が表示されていればOKです。(デタッチして戻る)  

**バージョン確認**
```
cd $NODE_HOME/guild-db/blocklog
cat block_check.py | grep -HnI -m1 -r btbf
```
> block_check.py:1:#2022/02/15 v1.6 @btbf

## **11-5.通知を停止(アンインストール)する手順**

```
sudo systemctl stop cnode-blockcheck.service
sudo systemctl disable cnode-blockcheck.service
sudo rm /etc/systemd/system/cnode-blockcheck.service
```
