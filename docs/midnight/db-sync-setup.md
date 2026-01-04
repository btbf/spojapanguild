# **カルダノIndexerセットアップ**

本ドキュメントは、`cardano-db-sync` と `PostgreSQL` を Linux 環境で構築するための手順です。Midnight バリデーター用途で preview テストネットで構成しております。

## **カルダノノードセットアップ**

### 事前準備

??? hint "任意ユーザー未作成の場合は以下手順で作成してください"

    ターミナルソフトを使用し、サーバーに割り当てられた初期アカウント(rootなど)でログインする。
    任意ユーザーの追加　(例：cardano)
    ```
    adduser cardano
    ```

    ```{ .yaml .no-copy py title="情報は未入力状態で ++enter++"} 
    New password:           # ユーザーのパスワードを設定
    Retype new password:    # 確認再入力

    Enter the new value, or press ENTER for the default
            Full Name []:   # フルネーム等の情報を設定 (不要であればブランクでも OK)
            Room Number []:
            Work Phone []:
            Home Phone []:
            Other []:
    Is the information correct? [Y/n]:y
    ```
    ユーザー(cardano)をsudoグループに追加する
    ```
    usermod -G sudo cardano
    ```

    rootユーザーからログアウトする
    ```
    exit
    ```

    ターミナルソフトのユーザーをパスワードを上記で作成したユーザーとパスワードに書き換えて再接続してください。

??? warning "SSH接続でログインする場合は、事前にローカル環境でSSH認証キーを作成してください"

    === "Windowsの場合"
        **1. 管理者モードでターミナルを起動します。**  

        `Win + X` を押下し、ターミナル（管理者）を選択し、SSHクライアントの有無を確認します。  
        ```powershell
        Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
        ```
        > `State : Installed`であれば問題ありません。

        ??? tip "`State : NotPresent`の場合"

            以下のコマンドで追加してください。
            ```powershell
            Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
            ```
        
        **2. SSH鍵生成**  
        ```powershell
        mkdir ~/.ssh -Force
        ssh-keygen -t ed25519 -N "" -C "ssh_connect" -f ~/.ssh/ssh_ed25519
        ```
        
        **3. 公開鍵ファイル名の変更**
        ```powershell
        cd ~/.ssh
        mv ssh_ed25519.pub authorized_keys
        ```


    === "Macの場合"
        **1. ターミナルを起動します。**  

        `⌘ + Space（Command + Space）`を押下し、「`terminal`」と入力し、Enterを押下します。

        **2. SSH鍵生成**
        ```bash
        mkdir -p ~/.ssh
        ssh-keygen -t ed25519 -N "" -C "ssh_connect" -f ~/.ssh/ssh_ed25519
        ```

        **3. 公開鍵ファイル名の変更**
        ```bash
        cd ~/.ssh
        mv ssh_ed25519.pub authorized_keys
        ```

    !!! danger "注意"
        以下の鍵は絶対に紛失しないでください。  
        紛失するとサーバーへ接続できなくなります。  

        `ssh_ed25519` （秘密鍵）  
        `authorized_keys` （公開鍵）

### SPOKITインストール
```
wget -qO- https://spokit.spojapanguild.net/install.sh | bash
```

セットアップノードタイプ（リレー）を選択して ++enter++
![](../images/spokit/2.jpg)

接続ネットワーク (Preview-Testnet) を選択して ++enter++
![](../images/spokit/3-preview.jpg)

作業ディレクトリパス指定　そのまま ++enter++
![](../images/spokit/4.jpg)

セットアップ内容に問題なければ ++enter++
![](../images/spokit/5.jpg)

環境設定読み込み  
赤枠に表示されているコマンドをコピーして実行  
![](../images/spokit/6.jpg)


### Ubuntuセキュリティ設定

!!! Question "Ubuntuセキュリティ設定モードについて"
    このモードでは、Cardanoノード実行に推奨されるUbuntuセキュリティ設定が含まれています。
    ４～９については選択制となっておりますので、環境に応じて設定してください。

```{ py title="実行コマンド" }
spokit ubuntu
```

Ubuntuセキュリティ設定ウィザート  
１～４は自動インストール・有効化されます。

はい を選択して ++enter++  
![](../images/spokit/7.jpg)

chronyインストール・設定
> システム時刻を正確かつ安定して同期するための時刻同期デーモンです。

はい を選択して ++enter++  
![](../images/spokit/8.jpg)

SSH設定  
> リモートサーバを安全に操作・管理するための通信プロトコル

はい を選択して ++enter++  
![](../images/spokit/9-1.jpg)

> rootログイン可否設定

![](../images/spokit/9-2.jpg)

SSHポート設定
> セキュリティを高めるためにはポート番号を変更してください

![](../images/spokit/9-3.jpg)

> ランダムな番号を割り当てるかカスタムで任意の番号を指定してください

![](../images/spokit/9-4.jpg)

> Ubuntu内部ファイアウォールを使用する場合は、はい を選択して ++enter++ 

![](../images/spokit/10.jpg)

> <font color="red">↓ここの注意事項をよく読んでください</font>

![](../images/spokit/10-1.jpg)


### ノードインストール

```{ py title="実行コマンド" }
spokit pool
```

ノードインストールを選択して ++enter++
![](../images/spokit/11.jpg)

はい を選択して ++enter++
![](../images/spokit/12.jpg)

ノード起動ポートを指定ます  
表示されたランダムな数字またはカスタムで任意の数字を割り当てできます。
![](../images/spokit/13.jpg)

依存関係インストールを含め、チェーン同期まで自動実行されます。
![](../images/spokit/14.jpg)

ノードが最新ブロックと同期するまでお待ち下さい。
![](../images/spokit/15.jpg)

SPOKITウィザードを閉じて以下コマンドで、カルダノノードライブモニターを表示できます。
```
glive
```
![](../images/spokit/16.jpg)

## **PostgreSQLセットアップ**

### **PostgreSQLインストール**

PostgreSQL 17 を使用します。

```bash
sudo apt update
sudo apt install -y curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -s -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
  https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt -y install postgresql-17 postgresql-server-dev-17 postgresql-contrib libghc-hdbc-postgresql-dev
```

依存関係インストール

```bash
sudo apt install git jq bc automake tmux rsync htop curl build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ wget libncursesw5 libtool autoconf liblmdb-dev -y
```

### **PostgreSQL 初期設定**

PostgreSQL用の自身のsuを作成する
```
sudo -u postgres psql -c "CREATE ROLE \"$(whoami)\" LOGIN SUPERUSER;"
```

db-sync用テーブル作成
```
psql postgres -c "CREATE DATABASE cexplorer;"
```

.pgpass作成
```
cat <<EOF > $NODE_HOME/.pgpass
/var/run/postgresql:5432:cexplorer:*:*
EOF
chmod 600 $NODE_HOME/.pgpass
```

postgresqlパフォーマンス設定

!!! hint ""
    - cardano-db-sync / Midnight-node 専用チューニング
    - TCPオーバヘッド回避およびスループット向上の為、UNIXソケット待ち受け起動限定

```
sudo sed -i /etc/postgresql/17/main/postgresql.conf \
    -e 's!#synchronous_commit = on!synchronous_commit = off!' \
    -e 's!shared_buffers = 128MB!shared_buffers = 2GB!' \
    -e 's!#effective_cache_size = 4GB!effective_cache_size = 8GB!' \
    -e 's!#work_mem = 4MB!work_mem = 16MB!' \
    -e 's!#maintenance_work_mem = 64MB!maintenance_work_mem = 512MB!' \
    -e 's!max_wal_size = 1GB!max_wal_size = 4GB!' \
    -e 's!min_wal_size = 80MB!min_wal_size = 1GB!' \
    -e "s/^#listen_addresses = 'localhost'/listen_addresses = ''/"
```
!!! hint ""

postgresql再起動
```
sudo systemctl restart postgresql
```


## **cardano-db-syncセットアップ**

### **依存関係インストール**

**libsodiumインストール**

リビジョンを取得する
```
REV=$(curl -sL https://github.com/input-output-hk/iohk-nix/releases/latest/download/INFO \
  | awk '$1 == "debian.libsodium-vrf.deb" { rev = gensub(/.*-(.*)\.deb/, "\\1", "g", $2); print rev }')
echo $REV
```

ダウンロード
```
cd $HOME/git
git clone https://github.com/IntersectMBO/libsodium
cd libsodium
git checkout $REV
```
ビルド
```
./autogen.sh
./configure
make
make check
sudo make install
```

**Secp256k1インストール**

リビジョンを取得する
```
REV=$(curl -L https://github.com/input-output-hk/iohk-nix/releases/latest/download/INFO \
  | awk '$1 == "debian.libsecp256k1.deb" { rev = gensub(/.*-(.*)\.deb/, "\\1", "g", $2); print rev }')
echo $REV
```
ダウンロード
```
cd $HOME/git
git clone https://github.com/bitcoin-core/secp256k1
cd secp256k1
git checkout $REV
```
ビルド
```
./autogen.sh
./configure --enable-module-schnorrsig --enable-experimental
make
make check
sudo make install
```

ライブラリキャッシュ更新
```
sudo ldconfig
```
確認
```
ldconfig -p | grep libsecp256k1
```
> OK

**blstインストール**

リビジョンを取得する
```
REV=$(curl -L https://github.com/input-output-hk/iohk-nix/releases/latest/download/INFO \
  | awk '$1 == "debian.libblst.deb" { rev = gensub(/.*-(.*)\.deb/, "\\1", "g", $2); print rev }')
echo $REV
```

ダウンロード
```
cd $HOME/git
git clone https://github.com/supranational/blst
cd blst
git checkout v$REV
```
ビルド
```
./build.sh
```

インストール
```
cat > libblst.pc << EOF
prefix=/usr/local
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libblst
Description: Multilingual BLS12-381 signature library
URL: https://github.com/supranational/blst
Version: 0.3.10
Cflags: -I\${includedir}
Libs: -L\${libdir} -lblst
EOF
```
```
sudo cp libblst.pc /usr/local/lib/pkgconfig/
sudo cp bindings/blst_aux.h bindings/blst.h bindings/blst.hpp  /usr/local/include/
sudo cp libblst.a /usr/local/lib
sudo chmod u=rw,go=r /usr/local/{lib/{libblst.a,pkgconfig/libblst.pc},include/{blst.{h,hpp},blst_aux.h}}
```

**GHCUPインストール**

インストール変数設定
```
cd $HOME
export BOOTSTRAP_HASKELL_NO_UPGRADE=1
export BOOTSTRAP_HASKELL_GHC_VERSION=9.6.7
export BOOTSTRAP_HASKELL_CABAL_VERSION=3.12.1.0
BOOTSTRAP_HASKELL_NONINTERACTIVE=1
BOOTSTRAP_HASKELL_INSTALL_STACK=1
BOOTSTRAP_HASKELL_ADJUST_BASHRC=1
unset BOOTSTRAP_HASKELL_INSTALL_HLS
export BOOTSTRAP_HASKELL_NONINTERACTIVE BOOTSTRAP_HASKELL_INSTALL_STACK BOOTSTRAP_HASKELL_ADJUST_BASHRC
```
インストール
```
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | bash
```

バージョン確認
```
source ~/.bashrc
cabal update
cabal --version
ghc --version
```

### **db-syncインストール**
```
cd ~/git
git clone https://github.com/intersectmbo/cardano-db-sync
cd cardano-db-sync
```

最新リポジトリを適用する
```
git fetch --tags --all
git checkout tags/13.6.0.5
```

ビルドGHCバージョンの明示
```
echo "with-compiler: ghc-9.6.7" >> cabal.project.local
```

ビルド
```
cabal update
cabal build all
```

db-syncバイナリーファイルコピー
```
mkdir -p ~/.local/bin
cp -p \
  "$(find . -name cardano-db-sync -executable -type f)" \
  ~/.local/bin/
```

バージョン確認
```
cardano-db-sync --version
```
> cardano-db-sync 13.6.0.5 - linux-x86_64 - ghc-9.6  
git revision cb61094c82254464fc9de777225e04d154d9c782


### スナップショットDL

!!! hint "cardano-db-syncスナップショット詳細"

    - ネットワーク：Preview
    - エポック：1165
    - ブロック高：391050l1
    - DLサイズ：約 3.58 GB
    

```
cd $NODE_HOME
curl -LO https://spojapanguild.net/db-sync/preview/db-sync-snapshot-schema-13.6-block-3910501-x86_64.tgz
```

ファイル検証
```
cd $NODE_HOME
curl -LO https://spojapanguild.net/db-sync/preview/db-sync-snapshot-schema-13.6-block-3910501-x86_64.tgz.sha256
sha256sum -c db-sync-snapshot-schema-13.6-block-3910501-x86_64.tgz.sha256
```
> db-sync-snapshot-schema-13.6-block-3910501-x86_64.tgz.sha256: OK

スナップショット復元
```
mkdir -p $NODE_HOME/ledger-state
cd ~/git/cardano-db-sync
PGPASSFILE=$NODE_HOME/.pgpass scripts/postgresql-setup.sh --restore-snapshot $NODE_HOME/db-sync-snapshot-schema-13.6-block-3910501-x86_64.tgz $NODE_HOME/ledger-state
```

```{ .yaml .no-copy py title="復元には数十分かかります"} 
~~~
db/4277.dat.gz
db/4191.dat.gz
db/4327.dat.gz
db/4225.dat.gz
db/4236.dat.gz
81671502-536882b92e.lstate.gz
All good!
```

```
exit
```

スナップショット削除
```
rm $NODE_HOME/preview-dbsyncsnap.tgz
```

### **db-sync環境設定**

Schemaシンボリックリンク作成
```
ln -s ~/git/cardano-db-sync/schema $NODE_HOME
```

設定ファイルダウンロード
```
cd $NODE_HOME
wget https://book.world.dev.cardano.org/environments/${NODE_CONFIG}/db-sync-config.json
```

設定ファイル修正
```
sed -i $NODE_HOME/db-sync-config.json \
    -e 's!"NodeConfigFile": "config.json"!"NodeConfigFile": "'${NODE_CONFIG}'-config.json"!'
```

起動スクリプト作成
```
cat > $NODE_HOME/startDbSync.sh << EOF 
#!/bin/bash
PGPASSFILE=$NODE_HOME/.pgpass
export PGPASSFILE
$HOME/.local/bin/cardano-db-sync \\
--config $NODE_HOME/db-sync-config.json \\
--socket-path $NODE_HOME/db/socket \\
--state-dir $NODE_HOME/ledger-state \\
--schema-dir $NODE_HOME/schema/
EOF
```

権限設定
```
chmod 755 $NODE_HOME/startDbSync.sh
```

db-sync　systemdサービス化 (任意)

``` bash { py title="ボックス内のコピーボタンでコピーして実行してください" }
cat > $NODE_HOME/cardano-db-sync.service << EOF 
[Unit]
Description=Cardano DB Sync
After=network.target postgresql.service

[Service]
Type=simple
User=${USER}
WorkingDirectory=${NODE_HOME}
ExecStart=/bin/bash -l -c "exec ${NODE_HOME}/startDbSync.sh"
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=300
LimitNOFILE=32768
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=db-sync

[Install]
WantedBy=multi-user.target
EOF
```

```bash
sudo cp $NODE_HOME/cardano-db-sync.service /etc/systemd/system/cardano-db-sync.service
```
```bash
sudo chmod 644 /etc/systemd/system/cardano-db-sync.service
```


systemd有効化

``` bash { py title="1行づつ実行してください" }
sudo systemctl daemon-reload
sudo systemctl enable cardano-db-sync
sudo systemctl start cardano-db-sync
```

## **動作確認**

```bash
sudo systemctl status cardano-db-sync
```
```{ .yaml .no-copy py title="戻り値　Active: active"} 
● cardano-db-sync.service - Cardano DB Sync
     Loaded: loaded (/etc/systemd/system/cardano-db-sync.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2025-12-30 07:18:14 UTC; 4h 42min ago
   Main PID: 212117 (startDbSync.sh)
      Tasks: 18 (limit: 18679)
     Memory: 3.0G
        CPU: 3h 3min 55.713s
```

チェーン同期確認
``` bash { py title="ボックス内のコピーボタンでコピーして実行してください" }
sudo -u postgres psql -d cexplorer -c "
SELECT 100 * (
  EXTRACT(EPOCH FROM (MAX(time) AT TIME ZONE 'UTC')) -
  EXTRACT(EPOCH FROM (MIN(time) AT TIME ZONE 'UTC'))
) / (
  EXTRACT(EPOCH FROM (NOW() AT TIME ZONE 'UTC')) -
  EXTRACT(EPOCH FROM (MIN(time) AT TIME ZONE 'UTC'))
) AS sync_percent
FROM public.block;
"
```

db-syncが同期するまでお待ち下さい
``` { .yaml .no-copy py title="戻り値　100"} 
    sync_percent     
---------------------
 99.9999
```

セットアップが完了しました！  
SPO バリデーター登録へ進んでください。  

(付録) db-syncログ確認
```bash
sudo journalctl --unit=cardano-db-sync --follow
```