# サーバー間同期設定(RSYNC+SSH)

!!! note "概要"
    サーバー間で任意のデータを転送する設定です。  
    新ノード更新時に発生するDB再構築時のダウンタイムを抑えたり、ビルドされたバイナリファイル(NODE/CLI)をそのまま任意のサーバーへ転送できます。

    1.転送元のサーバーを1台決めます。(リレーノードもしくはバックアップノードを推奨)  
    2.転送先は複数台のサーバーを事前に設定出来ます。  
    3.RSYNC+SSH専用の認証キーを作成し接続します。  
    4.転送先サーバーは、指定した転送元IPからのアップロードのみ受け付けます。 

    {==**構成イメージ**==}
    ``` mermaid
    flowchart LR
        a[転送元リレー1] -->|RSYNC+SSH| b[リレー2] & c[リレー3] & d[BP]
    ```


## **1.転送元サーバー設定**

リレーノードもしくはバックアップノード

### 1-1.RSYNC専用SSH認証キーの作成

=== "転送元サーバー設定"

ed25519暗号で認証キーを作成する
```
ssh-keygen -t ed25519 -N '' -C Data_Transfer -f ~/.ssh/rsync_ed25519
```

!!! note "生成された認証キーを確認する"
    ```
    ls ~/.ssh/
    ```

    * `rsync_ed25519`・・・秘密鍵
    * `rsync_ed25519.pub`・・・公開鍵
    
    この2つのファイルが生成されていることを確認する。USBなどへバックアップ推奨


### 1-2.SSH設定ファイル作成

!!! note "コマンド内訳"
    必ず自分の環境に合わせてコマンドを完成させてください。

    Host [転送先サーバーの任意名]　※接続時のエイリアス名になります  
    HostName [転送先IPまたはドメイン]  
    User [転送先のUser名]  
    port [転送先のSSHポート]  
    IdentityFile [SSH秘密鍵のパス]  

    転送先が複数台ある場合は上記を1セットとして追加する

サンプルコード
```bash
cat > ~/.ssh/config << EOF
Host BP
    HostName xxx.xxx.xxx.xx
    User xxxxx
    Port xx
    IdentityFile ~/.ssh/rsync_ed25519

Host Relay2
    HostName xxx.xx.xxx.xx
    User xxxxx
    Port xx
    IdentityFile ~/.ssh/rsync_ed25519
EOF
```

アクセス権を変更する
```
chmod 600 ~/.ssh/config
```

### 1-3.SSH公開鍵ファイル転送

公開鍵を`cnode`へ移動する
```
mv ~/.ssh/rsync_ed25519.pub $NODE_HOME/
```

### 1-4.ZStandardインストール
```
sudo apt install zstd
```


## **2.転送先サーバー設定**


**転送元にある`rsync_ed25519.pub`を転送先へコピーしてください。**


!!! danger "【重要】ファイル転送"
    転送元サーバーの`cnode`直下にある公開鍵ファイル`rsync_ed25519.pub`を、転送先サーバーの`cnode`フォルダへコピーする
    
    ``` mermaid
    graph LR
        A[転送元] -->|rsync_ed25519.pub| B[転送先];
    ``` 

### 2-1.SSH公開鍵の追記

コマンドと公開鍵の組み合わせでファイルを生成する
```
echo 'command="rsync --server --daemon --config='$NODE_HOME'/rsyncd.conf .",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding '$(cat $NODE_HOME/rsync_ed25519.pub)'' > $NODE_HOME/rsync.txt
```

公開鍵コマンドを`authorized_keys`に追記する
```
cat $NODE_HOME/rsync.txt >> ~/.ssh/authorized_keys
```

### 2-2.RSYNC設定ファイル作成

`allowIP`変数に転送元IPを代入する。x.x.x.xを転送元のIPに変更して実行する。
```
allowIP=x.x.x.x
```

以下コマンドを一括コピーして、実行する。
```
cat > $NODE_HOME/rsyncd.conf << EOF
# SSHで一般ユーザの場合は使えないのでno
use chroot = no
# 書き込む必要があるのでread onlyはno
read only = no
# 逆に読み取る必要はないのでwrite onlyをyesに
write only = yes
# 一旦すべて拒否
hosts deny = *
# 圧縮済みの物は再圧縮しない
dont compress = *.pdf *.jpg *.jpeg *.gif *.png *.mp3 *.mp4 *.ogg *.avi *.7z *.z *.gz *.tgz *.zip *.lzh *.bz2 *.rar *.xz

[Server]
  #アクセス許可パス
  path = $NODE_HOME
  # 接続元のIPアドレスを設定
  hosts allow = $allowIP
EOF
```

## **3.転送テスト**

転送元から転送先へファイルをアップロードします。
=== "転送元サーバー"

    転送用ファイルを作成する
    ```
    cd $NODE_HOME
    cardano-cli conway query protocol-parameters \
        --mainnet \
        --out-file params-test.json
    ```

    転送コマンドを実行する

    !!! note "コマンド内訳"
        rsync -P --rsh=ssh [転送元転送ファイルパス] [転送先エイリアス名]::Server/[転送ファイル名]
        
        * [転送先エイリアス名]には、1-2で設定した転送先Host名(エイリアス)を指定します。

    サンプルコマンド
    ```
    rsync -P --rsh=ssh $NODE_HOME/params-test.json Relay2::Server/params-test.json
    ```
    > * 初回接続時のみフィンガープリントの確認が入るので`yes`を入力する  
    > * `Verification code:` が表示される場合は、転送先サーバーの2段階認証コードを入力してください。

転送先で受信したファイルを確認する。
=== "転送先サーバー"
    ```
    ls $NODE_HOME/params-test.json
    ```
> ファイルパスの戻り値があれば転送成功。

## **4.転送先を追加する場合**
!!! note "転送先を追加する場合"
    * 1-2のSSH設定ファイルに転送先を追記する
    * 新しい転送先で2と3を実施する