# **Ubuntu初期設定**

!!! tip "ヒント"
    この手順は、エアギャップオフラインマシンのUbuntuでは実施する必要はございません。

!!! info "AWSをご利用の方"
    `AWS EC2` / `Lightsail` では SSH 鍵認証やユーザー構成が異なるため、本マニュアル通りに動作しない場合があります。


## **1. サーバーログイン（初回のみ / root）**

!!! warning "重要"
    この手順は **初回ログイン時のみ** 使用します。  
    以降の設定で、`root`ログインおよびパスワード認証は無効化します。

| 項目 | 設定値 |
|---|---|
| **ホスト** | サーバーIP |
| **ポート** | SSH（22） |
| **ユーザー** | root |
| **パスワード** | 契約時に送付される初期 root パスワード |


## **2. ユーザーアカウント作成**
!!! info "ヒント"
    日常運用では`root`アカウントを使用せず、sudo権限を付与した一般ユーザーで操作します。

新しいユーザーを作成します。  
> 任意のアルファベット文字を入力してください。  
> この例では`cardano` ユーザーとして以降進めます。

```bash
adduser cardano
```

``` { .yaml .no-copy }
New password:           # パスワードを設定
Retype new password:    # 確認のため再入力

Enter the new value, or press ENTER for the default
        Full Name []:   # フルネーム等の情報を設定（不要であればブランクでも問題ありません）
        Room Number []:
        Work Phone []:
        Home Phone []:
        Other []:
Is the information correct? [Y/n] : y
```

`cardano`にsudo権限を付与します。
```bash
usermod -aG sudo cardano
```

rootからログアウトします。
```bash
exit
```

!!! tip "ヒント"
    ターミナルソフトのユーザー名とパスワードを上記で作成したユーザー名とパスワードに書き換えて再接続します。

**`Ubuntu 22.04`以降の設定**

ブラケットペースト機能を無効化します。
```bash
echo "set enable-bracketed-paste off" >> ~/.inputrc
```
> 設定反映のため、ターミナルから一度ログアウトして再ログインしてください。

デーモン再起動を自動化します。
```bash
echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/50local.conf
```
```bash
echo "\$nrconf{blacklist_rc} = [qr(^cardano-node\\.service$) => 0, qr(^cnode-blocknotify\\.service$) => 0, qr(^cnode-cncli-sync\\.service$) => 0,];" | sudo tee -a /etc/needrestart/conf.d/50local.conf
```

## **3. SSH設定変更**

!!! info "SSH強化設定ルール"

    * SSHログイン時パスワード無効化（秘密鍵を使用）
    * SSHデフォルトポート（22）の変更
    * rootアカウントでのSSHログイン無効化（root権限が必要な操作は `sudo` を使用します。）
    * 許可されていないアカウントからのログイン試行をログに記録（fail2ban 等で対策）  
    * SSHログイン元のIPアドレス範囲のみに限定（希望する場合のみ）※利用プロバイダーによっては、定期的にグローバルIPが変更されるので注意が必要

!!! tip "SSHポートのヒント"
    SSHポートは世界標準で22番が割り当てられています。  
    しかし、ポートスキャンやブルートフォース攻撃の標的となりやすいため、本マニュアルでは任意のポート番号への変更を推奨します。  
    ポート番号は、IANAが定義する動的／プライベートポート範囲である<font color=red>49513～65535</font>の中から指定してください。

SSHディレクトリを作成します。
```bash
mkdir -p ~/.ssh
```

!!! important "ファイル転送"
    [事前準備](../setup/index.md/#_2)で生成した`authorized_keys`を対象サーバーの`$HOME/.ssh`ディレクトリにコピーします。
    ```mermaid
    graph LR
        A[ローカルのホストマシン] -->|**authorized_keys**| B[対象サーバー];
    ``` 

パーミッションを設定します。
```bash
chown -R "$USER:$USER" ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

`49513～65535`の範囲内でSSHポート番号を`""`内に指定してください。
```bash
PORT_NUM=""
```

```bash
sudo tee /etc/ssh/sshd_config.d/01-custom-ssh.conf > /dev/null << EOF
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
Port ${PORT_NUM}
EOF
```

構文をチェックします。
```bash
sudo sshd -t
```

有効設定を確認します。
```bash
sudo sshd -T | grep -iE 'passwordauthentication|kbdinteractiveauthentication|permitrootlogin|port'
```
``` { .yaml .no-copy }
port xxxxx
permitrootlogin no
passwordauthentication no
kbdinteractiveauthentication no
gatewayports no
```

問題がなければ、SSHサービスを再起動します。
```bash
sudo systemctl restart ssh
```

!!! info "ターミナルソフト設定について"
    - 現在起動中のターミナルは接続したままにしてもう一つ起動してください。
    - 接続設定のSSHポート番号を変更し秘密鍵を設定しサーバーへログインできるか確認して下さい。
    - 接続できない場合は、接続されてるターミナル画面でサーバー設定を確認して下さい。

## **4. ファイアウォール有効化**

標準のファイアウォール（UFW）を使用して、インバウンドのアクセス可能なポートを限定します。

!!! warning "注意事項"
    !!! tip "設定前の注意事項"
        ご利用のVPSによっては管理画面からファイアウォールを設定する必要があります。（例AWS系など）  
        その場合は以下の設定を行わず、VPSマイページ管理画面などから個別に設定してください。

    !!! tip "さくらVPSをご利用の場合"
        管理画面からパケットフィルターを、”利用しない”に設定してください。    


SSHポートを許可します。
```bash
SSH_PORT=$(sudo sshd -T | awk '$1=="port"{print $2}')
```
```bash
echo "有効なSSHポート: ${SSH_PORT}"
```

```bash
sudo ufw allow ${SSH_PORT}/tcp
```

ファイアウォールを有効化します。
```bash
sudo ufw enable
```
以下のメッセージが表示されたら `y` を入力して `Enter`
> Command may disrupt existing ssh connections. Proceed with operation (y|n)? y

ステータスを確認します。
```bash
sudo ufw status
```
以下の戻り値があればOK
> Status: active

## **5. システム更新**

!!! tip "重要"
    不正アクセスを予防するには、システムに最新のパッチを適用することが重要です。

パッケージリストを更新し、依存関係を含めた包括的なアップグレードを実行します。
```bash
sudo apt update -y && sudo apt full-upgrade -y
```

不要なパッケージを削除します。
```bash
sudo apt autoremove -y
```

パッケージキャッシュを整理します。
```bash
sudo apt autoclean -y
```

セキュリティ更新の自動適用を有効にします。
```bash
sudo apt install unattended-upgrades
```
```bash
sudo dpkg-reconfigure --priority=low unattended-upgrades
```
> `YES`を選択し、Enterを押下


## **6. rootアカウントの無効化設定**
`root`アカウントを無効化します。
> サーバーのセキュリティ維持のため、頻繁に root アカウントでログインしないでください。

!!! info "`root`アカウント無効"
    ```bash
    sudo passwd -l root
    ```

??? info "`root`アカウント有効"
    ```bash
    sudo passwd -u root
    ```
    > 何らかの理由でrootアカウントを有効にする必要がある場合


## **7. 共有メモリのセキュリティ強化**

システムで共有されるメモリを保護します。

以下の設定を`/etc/fstab`の最終行に追記します。
```bash
echo 'tmpfs /run/shm tmpfs ro,noexec,nosuid 0 0' | sudo tee -a /etc/fstab
```

追記の確認をします。
```bash
tail -n 1 /etc/fstab
```
> `tmpfs /run/shm tmpfs ro,noexec,nosuid 0 0`が最終行に入力されていることを確認します。

## **8. Fail2banのインストール**

!!! info "Fail2banについて"
    Fail2banは、ログファイルを監視し、ログイン試行に失敗した特定のパターンを監視する侵入防止システムです。  
    特定のIPアドレスから、指定された時間内に一定数のログイン失敗が検知された場合、Fail2banはそのIPアドレスからのアクセスをブロックします。

```bash
sudo apt install nano fail2ban -y
```
> `nano`エディタも未インストールなのでインストールしておきます。

SSHログインを監視する設定ファイルを開きます。
```bash
sudo nano /etc/fail2ban/jail.local
```

ファイルの最後に次の行を追加し保存します。
> コマンド中の (SSHポートを入力してください) については1-3で設定したSSHポートを入力してください。(**)は不要です。

```bash
[sshd]
enabled = true
port = (SSHポートを入力してください)
filter = sshd
logpath = /var/log/auth.log
maxretry = 6
```

自動起動を有効化し、即時起動します。
```bash
sudo systemctl enable --now fail2ban
```

有効化されているかを確認します。
```bash
sudo systemctl status fail2ban --no-pager
```
> `Active: active (running)`となっていることを確認してください。

## **9. Chronyの設定**

chronyをインストールします。
```bash
sudo apt install chrony -y
```

`/etc/chrony/chrony.conf`を更新します。
> 以下をすべてコピーして実行してください。

```bash
cat > $HOME/chrony.conf << EOF
pool time.google.com       iburst minpoll 2 maxpoll 2 maxsources 3 maxdelay 0.3
pool time.facebook.com     iburst minpoll 2 maxpoll 2 maxsources 3 maxdelay 0.3
pool time.euro.apple.com   iburst minpoll 2 maxpoll 2 maxsources 3 maxdelay 0.3
pool time.apple.com        iburst minpoll 2 maxpoll 2 maxsources 3 maxdelay 0.3
pool ntp.ubuntu.com        iburst minpoll 2 maxpoll 2 maxsources 3 maxdelay 0.3

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Uncomment the following line to turn logging on.
#log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 5.0

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can’t be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 0.1 -1

# Get TAI-UTC offset and leap seconds from the system tz database
leapsectz right/UTC

# Serve time even if not synchronized to a time source.
local stratum 10
EOF
```

作成した`chrony.conf`を`/etc/chrony/chrony.conf`に移動します。
```bash
sudo mv $HOME/chrony.conf /etc/chrony/chrony.conf
```

UFWで以下を設定します。
```bash
sudo ufw allow 123/udp
```

設定を有効にするには、Chronyを再起動します。
```bash
sudo systemctl reload-or-restart chronyd.service
```

!!! tip "ヘルプコマンド"
    同期データのソース確認
    ```bash
    chronyc sources
    ```

    現在のステータス表示
    ```bash
    chronyc tracking
    ```


## **補足：SSH2段階認証（任意作業・上級者向け）**

!!! danger "注意"
    本設定は必須ではありません。  
    ただし、本手順を実施したサーバーでは、SSHログインに2FAを要求します（= `Google Authenticator` 未設定ユーザーはログインできません）。  
    本番サーバー（VPS 等）で適用する場合は、必ず復旧手段（クラウドコンソール等）と予備セッションを確保してから実施してください。
    

??? info "`Google Authenticator`を用いたSSH2段階設定（任意）"
    システムを更新して`libpam-google-authenticator`をインストールします。
    ```bash
    sudo apt update -y
    ```
    ```bash
    sudo apt install libpam-google-authenticator -y
    ```

    **google-authenticator**コマンドを実行します。
    ```bash
    google-authenticator
    ```

    !!! tip "推奨設定"
        質問事項に対して推奨設定をします。  

        !!! warning "注意"
            プロセス中に大きなQRコードが表示されます。  
            その下に緊急時のスクラッチコードが表示されますので、忘れずに書き留めておいて下さい。  
            スマートフォンでGoogle認証システムアプリを開き、QRコードを読み取り2段階認証を機能させてください。

        - `認証トークンを時間ベースにしたいですか？`に対して「`y`」を入力します。
        > 表示される `secret key` / `スクラッチコード` は、スクリーンショットではなく安全な保管方法（オフライン保管等）で保存してください。
        ``` { .yaml .no-copy }
        Do you want authentication tokens to be time-based (y/n) : y
        ```

        - `Google Authenticator`でQRコードを読み込み、表示された6桁のコードを入力
        ``` { .yaml .no-copy }
        Enter code from app (-1 to skip) : ******
        ```

        - スクラッチコードも控えておきます。
        ``` { .yaml .no-copy }
        Code confirmed
        Your emergency scratch codes are : 
          ********
          ********
          ********
          ********
          ********
        ```

        - `「/home/$USER/.google_authenticator」ファイルを更新しますか？`に対して「`y`」を入力
        ``` { .yaml .no-copy }
        Do you want me to update your "/home/$USER/.google_authenticator" file? (y/n) : y
        ```

        - `同じ認証トークンの複数回使用を禁止しますか？これにより、約30秒ごとに1回のログインに制限されますが、中間者攻撃を検知したり、防止したりする可能性が高まります。`に対して「`y`」を入力
        ``` { .yaml .no-copy }
        Do you want to disallow multiple uses of the same authentication
        token? This restricts you to one login about every 30s, but it increases
        your chances to notice or even prevent man-in-the-middle attacks (y/n) : y
        ```

        - `デフォルトでは、モバイルアプリによって30秒ごとに新しいトークンが生成されます。クライアントとサーバー間の時刻のずれを補正するため、現在時刻の前後に追加のトークンを許可しています。これにより、認証サーバーとクライアント間の時刻のずれは最大30秒まで許容されます。時刻同期がうまくいかない場合は、ウィンドウサイズをデフォルトの3コード（前のコード1つ、現在のコード、次のコード）から17コード（前のコード8つ、現在のコード、次のコード8つ）に増やすことができます。これにより、クライアントとサーバー間の時刻のずれ最大4分まで許容されます。これを実行しますか？`に対して「`n`」を入力
        ``` { .yaml .no-copy }
        By default, a new token is generated every 30 seconds by the mobile app.
        In order to compensate for possible time-skew between the client and the server,
        we allow an extra token before and after the current time. This allows for a
        time skew of up to 30 seconds between authentication server and client. If you
        experience problems with poor time synchronization, you can increase the window
        from its default size of 3 permitted codes (one previous code, the current
        code, the next code) to 17 permitted codes (the 8 previous codes, the current
        code, and the 8 next codes). This will permit for a time skew of up to 4 minutes
        between client and server.
        Do you want to do so? (y/n) : n
        ```

        - `ログイン先のコンピューターがブルートフォース攻撃によるログイン試行に対して強化されていない場合は、認証モジュールのレート制限を有効にすることができます。デフォルトでは、攻撃者によるログイン試行は30秒ごとに3回までに制限されます。レート制限を有効にしますか？`に対して「`y`」を入力
        ``` { .yaml .no-copy }
        If the computer that you are logging into isn't hardened against brute-force
        login attempts, you can enable rate-limiting for the authentication module.
        By default, this limits attackers to no more than 3 login attempts every 30s.
        Do you want to enable rate-limiting? (y/n) : y
        ```

    PAMの設定（※ SSH 専用・OTP 必須構成）
    > 本手順では `/etc/pam.d/sshd` の `@include common-auth` を無効化し、`pam_google_authenticator.so` を必須認証として設定します。

    ```bash
    sudo sed -i '/pam_google_authenticator\.so/d' /etc/pam.d/sshd
    ```

    `@include common-auth`をコメントアウト
    ```bash
    sudo sed -i -E 's/^[[:space:]]*@include[[:space:]]+common-auth[[:space:]]*$/# @include common-auth/' /etc/pam.d/sshd
    ```

    追記位置の前提に依存せず末尾へ追加
    ```bash
    echo 'auth required pam_google_authenticator.so' | sudo tee -a /etc/pam.d/sshd > /dev/null
    ```

    確認
    ```bash
    grep -n -E 'common-auth|pam_google_authenticator' /etc/pam.d/sshd
    ```
    ``` { .yaml .no-copy }
    4:# @include common-auth
    56:auth required pam_google_authenticator.so
    ```

    `02-2fa.conf`ファイルに設定します。
    ```bash
    sudo tee /etc/ssh/sshd_config.d/02-2fa.conf > /dev/null << 'EOF'
    UsePAM yes
    KbdInteractiveAuthentication yes
    AuthenticationMethods publickey,keyboard-interactive
    PasswordAuthentication no
    EOF
    ```
    > `AuthenticationMethods publickey,keyboard-interactive` は、「公開鍵認証 かつ ワンタイムパスワード認証」の両方を要求します。

    `KbdInteractiveAuthentication no` の存在を確認します。
    ```bash
    sudo grep -RIn --color=auto \
      -E '^\s*KbdInteractiveAuthentication\s+no\b' \
      /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null
    ```
    ``` { .yaml .no-copy }
    /etc/ssh/sshd_config:61:KbdInteractiveAuthentication no
    /etc/ssh/sshd_config.d/01-custom-ssh.conf:2:KbdInteractiveAuthentication no
    ```

    `sshd_config` と `01-custom-ssh.conf` にある `KbdInteractiveAuthentication no` を「無効化」します（後続の `02-2fa.conf` の `yes` を確実に有効にするため）。
    ```bash
    sudo sed -i \
      -e 's/^[[:space:]]*KbdInteractiveAuthentication[[:space:]]\+no.*$/# KbdInteractiveAuthentication no/' \
      /etc/ssh/sshd_config \
      /etc/ssh/sshd_config.d/01-custom-ssh.conf
    ```

    構文チェックし、リロードします。
    ```bash
    sudo sshd -t
    ```
    ```bash
    sudo systemctl reload ssh
    ```

    グローバル設定の実効値を確認します。
    ```bash
    sudo sshd -T | egrep -i 'usepam|kbdinteractiveauthentication|authenticationmethods|passwordauthentication'
    ```
    ``` { .yaml .no-copy }
    usepam yes
    passwordauthentication no
    kbdinteractiveauthentication yes
    authenticationmethods publickey,keyboard-interactive
    ```

    ### **最終確認（必須）**

    既存の SSH セッションは切断せず、**別ターミナルから新規接続**を行い、以下を必ず確認してください。

    - 公開鍵認証が成功すること
    - 続いてワンタイムパスワード（OTP）が要求されること
    - 正しいコードでログインできること

    以下の実効値が表示されていれば、設定は正しく反映されています。


    ## **SSH 2FA（Google Authenticator）完全クリーンアップ**

    SSH 側：2FA 強制を解除
    ```bash
    sudo mv /etc/ssh/sshd_config.d/02-2fa.conf \
        /etc/ssh/sshd_config.d/02-2fa.conf.bak
    ```
    ```bash
    sudo sshd -t
    ```
    ```bash
    sudo systemctl reload ssh
    ```

    確認します。
    ```bash
    sudo sshd -T | egrep -i 'authenticationmethods|kbdinteractiveauthentication'
    ```
    ``` { .yaml .no-copy } 
    usepam yes
    passwordauthentication no
    kbdinteractiveauthentication yes
    authenticationmethods any
    ```
    > `kbdinteractiveauthentication yes` が表示されていても、`authenticationmethods any` の場合、OTP は要求されません。

    PAM 側：Google Authenticator を削除
    ```bash
    sudo sed -i '/pam_google_authenticator\.so/d' /etc/pam.d/sshd
    ```
    ```bash
    sudo sed -i -E 's/^#\s*@include\s+common-auth/@include common-auth/' /etc/pam.d/sshd
    ```

    確認します。
    ```bash
    grep -n -E 'common-auth|pam_google_authenticator' /etc/pam.d/sshd
    ```
    ``` { .yaml .no-copy } 
    4:@include common-auth
    ``` 

    反映 & 確認
    ```bash
    sudo sshd -t
    ```
    ```bash
    sudo systemctl reload ssh
    ```
    > 別ターミナルから新規 SSH 接続し、OTP が要求されないことを確認

    完全クリーンアップします。
    ```bash
    sudo apt remove libpam-google-authenticator
    ```
    ```bash
    sudo apt autoremove
    ```
    ```bash
    rm -f ~/.google_authenticator
    ```

---