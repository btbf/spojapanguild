# **SPO BlockNotify設定**

!!! info "概要"
    最終更新日：2025/3/6  v2.5.0

    * ブロックログで表示されるブロック生成結果を任意のソーシャルアプリへ通知します。   
    ![*](../../images/block_notify/image.png)

    * ブロック生成スケジュールを自動取得し、取得スケジュール一覧を通知します。  
    ![*](../../images/block_notify/auto_leader.png)

    * 通知先対応アプリ : `LINE`/`Slack`/`Discord`/`Telegram`

    * 多言語ファイルを用意することで様々な言語に対応しました！
 
    * ブロックログと連動しておりますので、まだ設定されてない場合は[ブロックログ設定](../setup/blocklog-setup.md)を先に導入してください。

    * 以下の作業はguild-dbが存在するBPサーバーのみで実施し、ブロック生成スケジュールがないタイミングで実施してください。 

    * 設定は任意です。(設定しなくてもブロック生成に影響はありません)

    * <font color=red>各サービスのAPIを利用するため送信データが各サービスのサーバーに流れます。その点を十分に理解しご活用ください。</font>

    * エポックのスケジュール通知はオン/オフ設定可能です


??? info "更新履歴▼"
    * 2.5.0  ・LINE Messaging API対応
    * 2.3.0  ・通知にブロックサイズを表示
    　　　　　・スペイン語、フランス語、ポルトガル語を追加
    * 2.2.2  ・任意のPrometheusポートを設定可能
    　　　　　・データベース接続の最適化
    * 2.2.1  ・特定の条件下における無限ループバグを解消
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
    　　　・通知基準設定( 全て/confirm以外全て/Missedとinvalidのみ)  
    　　　・通知内容を変更(X番目/トータルスケジュール数)  
    * 1.1 スケジュール取得時、その他通知判定修正  
    * 1.0.1 軽微な修正  
    * 1.0 初版リリース  



## **1. 依存プログラムのインストール**

**Python環境のセットアップ**

パッケージの更新
```bash
sudo apt update && sudo apt upgrade -y
```

pythonバージョンの確認
```bash
python3 -V
```
> Python 3.10以上

依存関係のインストール
```bash
sudo apt install -y python3-pip python3-venv python3-full
```

```bash
python3 -m venv ~/notify-venv
~/notify-venv/bin/pip install -U pip
~/notify-venv/bin/pip install watchdog pytz python-dateutil requests discordwebhook slackweb i18nice[YAML] python-dotenv
```

確認
```bash
~/notify-venv/bin/python -c "import watchdog, pytz, dateutil, requests, discordwebhook, slackweb, i18n, dotenv; print('OK')"
```
> `OK`と表示されれば問題ありません。


**実行スクリプトと設定ファイルのダウンロード**

```bash
bn_release="$(curl -s https://api.github.com/repos/btbf/block-notify/releases/latest | jq -r '.tag_name')"
wget https://github.com/btbf/block-notify/archive/refs/tags/${bn_release}.tar.gz -P $NODE_HOME/scripts
cd $NODE_HOME/scripts
tar zxvf ${bn_release}.tar.gz block-notify-${bn_release}/block_notify.py block-notify-${bn_release}/config.ini block-notify-${bn_release}/i18n/ 
mv block-notify-${bn_release} block-notify
rm ${bn_release}.tar.gz

```

## **2. 通知アプリの設定**

通知させたいアプリのタブをクリックし設定を確認してください。

=== "LINE"
    !!! danger "お知らせ"
        2025年3月末をもってLINE Notifyサービス終了に伴い、LINE Messaging APIに対応しました。
        無料版においては、月の送信上限が200通までとなっております。  
        (複数人で運用する場合は「送信数×人数」でカウントされますのでご注意ください)
        <br>
        <font color=red>新しいAPIはLINE公式アカウントを通じて配信されるため、設定を間違えるとセキュリティ漏洩のリスクがあります。複数人で運用する場合はご注意ください</font>  

    * **1.LINEビジネスIDの作成**  
    LINE Business ID [https://manager.line.biz/](https://manager.line.biz/){target="_blank" rel="noopener"} にアクセスし、お持ちのLINEアカウントでログインするか新規でBusinessIDを作成してください
    ![*](../../images/block_notify/line-message-api0.jpg)

    * **2.LINE公式アカウントの作成**  
    ![*](../../images/block_notify/line-message-api1.jpg)  
    ![*](../../images/block_notify/line-message-api2.jpg)  
    
    !!! info ""
        アカウント名：任意の名前  
        運用目的：その他  
        主な使い方：メッセージ配信用  

    ![*](../../images/block_notify/line-message-api3.jpg)  
    LINEヤフー for Businessを友だち追加のチェックを外します
    ![*](../../images/block_notify/line-message-api4.jpg)  
    <br>
    LINE Official Account Managerへをクリック
    ![*](../../images/block_notify/line-message-api5.jpg)  
    
    * **3.Messaging APIの設定**  
    <br>
    **右上の「設定」をクリック**  
    ![*](../../images/block_notify/line-message-api6.jpg)  
    <br>
    **プロフィール画像を編集するとプールアイコンを設定できます**  
    ![*](../../images/block_notify/line-message-api6-1.jpg)  
    <br>
    **左メニューの「Messaging API」をクリックし、「Messaging APIを利用する」をクリック**  
    ![*](../../images/block_notify/line-message-api7.jpg)  
    <br>
    **「プロバイダーを作成」欄に「notify」と入力し、「同意する」をクリック**  
    ![*](../../images/block_notify/line-message-api8.jpg)  
    <br>
    **空欄のまま「OK」をクリック**  
    ![*](../../images/block_notify/line-message-api9.jpg)  
    
    * **4.LINE Developers設定**  
    <br>
    ![*](../../images/block_notify/line-message-api10.jpg)  
    <br>
    **コンソールにログイン**  
    ![*](../../images/block_notify/line-message-api11.jpg)  
    <br>
    **プロバイダーから先ほど作成した「notify」をクリック**  
    ![*](../../images/block_notify/line-message-api12.jpg)  
    <br>
    **2で作成したLINE公式アカウントをクリック**  
    ![*](../../images/block_notify/line-message-api13.jpg)  
    <br>
    **「Messaging API」タブをクリック**  
    ![*](../../images/block_notify/line-message-api14.jpg)  
    <br>
    **ページ下部の「チャンネルアクセストークン(長期)」で「実行」をクリック**  
    ![*](../../images/block_notify/line-message-api15.jpg)  
    <br>
    **発行されたトークンを控えます**  
    （発行されたトークンはいつでも確認することができます）  
    `line_notify_token`の値として使用します  
    ![*](../../images/block_notify/line-message-api16.jpg)  
    <br>
    **上部に戻り「チャンネル基本設定」をクリック**  
    ![*](../../images/block_notify/line-message-api17.jpg)  
    <br>
    **「あなたのユーザーID」を控えます**  
    `line_user_id`の値として使用します  
    ![*](../../images/block_notify/line-message-api18.jpg)  


=== "Discord"

    * 1.サーバーを追加  
    ![*](../../images/block_notify/3-1-1.jpg)
    
    * 2.「オリジナルの作成」を選択  
    ![*](../../images/block_notify/3-1-2.jpg)
    
    * 3.「自分と友達のため」を選択  
    ![*](../../images/block_notify/3-1-3.jpg)
    
    * 4.任意のサーバー名を入力して「新規作成」をクリック  
    ![*](../../images/block_notify/3-1-4.jpg)
    
    * 5.通知したいチャンネルの歯車マークをクリック  
    ![*](../../images/block_notify/3-1-5.jpg)
    
    * 6.「連携サービス」をクリックし、「ウェブフックを作成」をクリック  
    ![*](../../images/block_notify/3-1-6.jpg)
    
    * 7.「ウェブフックURLをコピー」をクリックし、一旦メモ帳などに貼り付けます  
    ![*](../../images/block_notify/3-1-7.jpg)


=== "Telegram"
    * 1.Telegramの検索欄で「@botFather」を検索して認証マーク付きのアカウントをクリック  
    ![*](../../images/block_notify/4-1-1.jpg)

    * 2.「START」をクリック  
    ![*](../../images/block_notify/4-1-2.jpg)

    * 3.「/newbot」コマンドを入力  
    ![*](../../images/block_notify/4-1-3.jpg)

    * 4.任意のbot名を入力する 例）「btbf_bot」最後は必ず`_bot`で終わるようにします  
    ![*](../../images/block_notify/4-1-4.jpg)

    * 5.緑で隠した部分のAPIトークンをメモ帳に控えます  
    ![*](../../images/block_notify/4-1-4.jpg)

    * 6.赤枠で囲ったbotチャンネルに参加  
    ![*](../../images/block_notify/4-1-4-1.jpg)

    * 7.検索欄で「@RawDataBot」を検索してクリック  
    ![*](../../images/block_notify/4-1-5.jpg)

    * 8.「START」をクリック  
    ![*](../../images/block_notify/4-1-6.jpg)

    * 9.「Chat id」をメモ帳に控えます  
    ![*](../../images/block_notify/4-1-7.jpg)

=== "Slack"
    * 1.Slackを起動し、通知用のワークスペースとチャンネルの設定

    * 2.[Incoming Webhook](https://my.slack.com/services/new/incoming-webhook/){target="_blank" rel="noopener"}の設定ページへアクセス

    * 3.通知したいワークスペースとチャンネルを選択  
    ![*](../../images/block_notify/5-1-1.jpg)

    * 4.「Webhook URL」をメモ帳に控えます  
    ![*](../../images/block_notify/5-1-2.jpg)

    * 5.ページ下部の「設定を保存する」をクリック  
    ![*](../../images/block_notify/5-1-3.jpg)

## **3. 通知プログラムの設定**

**設定ファイルをSJG用にします**
```
cd $NODE_HOME/scripts/block-notify
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
    | `pool_ticker`      | ex.) SJG | プールティッカー名を入力  |
    | `notify_language` | 英語:`en`<br>日本語:`ja`| 通知言語を入力 |
    | `notify_timezone`   | Asia/Tokyo<br>[タイムゾーン一覧](https://gist.github.com/heyalexej/8bf688fd67d7199be4a1682b3eec7568){target="_blank" rel="noopener"} | お住いの[タイムゾーン](https://gist.github.com/heyalexej/8bf688fd67d7199be4a1682b3eec7568){target="_blank" rel="noopener"}を指定 |
    | `notify_platform`   | `Line`<br>`Discord`<br>`Slack`<br>`Telegram` | 通知先プラットフォームを指定<br> (複数指定は無効) |
    | `notify_level`   |全て:`All`<br>Confirm以外:`ExceptConfirm`<br>Missのみ:`OnlyMissed`  | 通知基準を設定 |
    | `nextepoch_leader_date`   |概要のみ:`SummaryOnly`<br>概要と日付:`SummaryDate` | 次エポックスケジュール日時の通知有無<br>次エポックスケジュール日付一覧を通知に流したくない場合は`SummaryOnly`を記載してください |
    | `line_notify_token`     |[LINE設定](../setup/blocknotify-setup.md/#__tabbed_1_1)で発行したチャンネルアクセストークン | Line通知用のトークンを入力 |
    | `line_user_id`     |[LINE設定](../setup/blocknotify-setup.md/#__tabbed_1_1)で発行したユーザーID | Line通知用のユーザーIDを入力 |
    | `discord_webhook_url`   |[Discord設定の(7)](../setup/blocknotify-setup.md/#__tabbed_1_2)で発行したウェブフックURL| DiscordウェブフックURLを入力 |
    | `slack_webhook_url`   |[Slack設定の(4)](../setup/blocknotify-setup.md/#__tabbed_1_4)で発行したWebhook URL| SlackウェブフックURLを入力 |
    | `telegram_token`   |[Telegram設定の(5)](../setup/blocknotify-setup.md/#__tabbed_1_3)で発行したAPIトークン | Telegram APIトークンを入力 |
    | `telegram_id`   |[Telegram設定の(9)](../setup/blocknotify-setup.md/#__tabbed_1_3)で表示されたChat id| Telegram ChatIDを入力 |
    | `node_home` |ex.)`/home/usr/cnode`| node_homeディレクトリパスを入力 |
    | `guild_db_dir` |ex.)`%(node_home)s/guild-db/blocklog/`| guild-dbのパスを入力<br>`%(node_home)s`は変数のため変更しないでください |
    | `shelley_genesis` |ex.)`%(node_home)s/files/shelley-genesis.json`| shelley_genesisのファイルパスを入力<br>`%(node_home)s`は変数のため変更しないでください |
    | `byron_genesis` |ex.)`%(node_home)s/files/byron-genesis.json`| byron_genesisのファイルパスを入力<br>`%(node_home)s`は変数のため変更しないでください |



**サービスファイルの設定**
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
    ExecStart=/home/${USER}/notify-venv/bin/python -u ${NODE_HOME}/scripts/block-notify/block_notify.py
    Restart=on-failure
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=cnode-blocknotify

    [Install]
    WantedBy=cnode-cncli-sync.service
    EOF
    ```

    ```bash
    sudo cp $NODE_HOME/service/cnode-blocknotify.service /etc/systemd/system/cnode-blocknotify.service
    ```

    ```bash
    sudo chmod 644 /etc/systemd/system/cnode-blocknotify.service
    ```
    ```bash
    sudo systemctl daemon-reload
    ```
    ```bash
    sudo systemctl enable --now cnode-blocknotify.service
    ```

    環境変数にログ確認用エイリアスを追加
  
    ```bash
    echo alias blocknotify='"journalctl --no-hostname -u cnode-blocknotify -f"' >> $HOME/.bashrc
    ```

    環境変数再読み込み
  
    ```bash
    source $HOME/.bashrc
    ```

    起動確認
  
    ```bash
    blocknotify
    ```
    以下の表示なら正常です。
    > [***] SPO Block Notify(v2.*.*)を起動しました


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

## **4. アップデート手順**

SPO BlockNotifyの停止
```
sudo systemctl stop cnode-blocknotify.service
```

アップデートファイルのダウンロード
```bash
bn_release="$(curl -s https://api.github.com/repos/btbf/block-notify/releases/latest | jq -r '.tag_name')"
wget https://github.com/btbf/block-notify/archive/refs/tags/${bn_release}.tar.gz -P $NODE_HOME/scripts
cd $NODE_HOME/scripts
tar zxvf ${bn_release}.tar.gz block-notify-${bn_release}/block_notify.py block-notify-${bn_release}/i18n
cp block-notify-${bn_release}/block_notify.py block-notify/block_notify.py
cp -r block-notify-${bn_release}/i18n block-notify/
rm -rf block-notify-${bn_release} ${bn_release}.tar.gz
```

!!! info "v2.4.1以下からv2.5.0へアップデートの場合は以下も実施"
    ```
    cd $NODE_HOME/scripts/block-notify/
    sed -i '13a line_user_id = ' config.ini
    ```

!!! danger "LINE通知を使用している方へ"
    2025年3月末をもってLINE Notifyサービス終了に伴い、LINE Messaging APIに対応しました。
    無料版においては、月の送信上限が200通までとなっております。  
    (複数人で運用する場合は「送信数×人数」でカウントされますのでご注意ください)  
    <br>
    <font color=red>新しいAPIはLINE公式アカウントを通じて配信されるため、設定を間違えるとセキュリティ漏洩のリスクがあります。複数人で運用する場合はご注意ください</font>  
    <br>
    上記の点を踏まえ、他の通知システム(Discord/Telegram/Slack)へ移行するか新しい[LINE通知の設定](../setup/blocknotify-setup.md/#__tabbed_1_1)を実施してください。（流れで11-3まで実施しないでください）  
    LINE公式アカウント発行後、`config.ini`の`line_notify_token`と`line_user_id`を発行した値に書き換えてください。

SPO BlockNotifyの起動
```
sudo systemctl start cnode-blocknotify.service
```

バージョンの確認
```
$HOME/notify-venv/bin/python $NODE_HOME/scripts/block-notify/block_notify.py version
```

## **5. アンインストール手順**

```bash
sudo systemctl stop cnode-blocknotify.service
```
```bash
sudo systemctl disable cnode-blocknotify.service
```
```bash
sudo systemctl daemon-reload
```
```bash
sudo rm /etc/systemd/system/cnode-blocknotify.service
```
```bash
sudo rm -rf $NODE_HOME/scripts/block-notify
```
```bash
sudo rm -rf $HOME/notify-venv
```

---