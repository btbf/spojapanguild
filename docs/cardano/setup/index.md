# **プール構築マニュアル**

## **事前準備**

### **ターミナルソフトのインストール**

ステークプールの構築・運用では、各サーバーへSSH接続するためのターミナルソフトが必要です。  
ターミナルソフトにはさまざまな種類がありますが、このマニュアルでは代表的なものを紹介します。  
ご使用のOSに合わせてインストールしてください。  

!!! note "各種ターミナルソフト一覧"
    !!! info "R-Login（Windows）"
        Windows向けの軽量SSHクライアントです。  
        タブ管理やカラー設定が容易で、SPOの利用実績も多い安定したソフトです。

        ダウンロード：[https://kmiya-culti.github.io/RLogin/](https://kmiya-culti.github.io/RLogin/){target="_blank" rel="noopener"}

        ??? tip "R-Login 推奨設定"

            **カラー設定**  
            <img src=../../images/r-login-setting2.png width="500px">
            
            **接続状態維持設定**  
            <img src=../../images/r-login-setting.png width="500px">

    !!! info "Terminal（macOS 標準ターミナル）"
        macOSに標準搭載されているターミナルアプリです。  
        追加インストール不要で、そのままSSH接続に利用できます。

        参考：[https://www.webdesignleaves.com/pr/plugins/mac_terminal_basics_01.html](https://www.webdesignleaves.com/pr/plugins/mac_terminal_basics_01.html){target="_blank" rel="noopener"}

    !!! info "Termius（Windows / macOS / Linux / iOS / Android）"
        複数OSに対応した高機能SSHクライアントです。  
        クラウド同期により、PCとスマホ間で設定を共有できます。

        公式サイト：[https://termius.com/](https://termius.com/){target="_blank" rel="noopener"}


### **SSH鍵作成**

=== "Windowsの場合"
    **1. OpenSSH Client の確認**  

    SSHクライアントの有無を確認します。  
    `Win + R` を押下し、`cmd`と入力し、`Enter`
    ```cmd
    where ssh
    ```
    > PATHが表示されていること

    ??? tip "表示されない場合"

        表示されない場合は、管理者モードで以下を実行してください。  
        > `Win + R` を押下し、`cmd`と入力後、`Ctrl + Shift + Enter`→「`はい`」を選択
        ```cmd
        powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
        ```
        > 追加後、`where ssh`を実行し、PATHが表示されていることを確認  

        ※ OpenSSH の追加のみ管理者権限が必要です。以降は通常モードの cmd で実行してください。
    
    **2. SSH鍵生成**  
    ```cmd
    mkdir "%USERPROFILE%\.ssh"
    ssh-keygen -t ed25519 -N "" -C "ssh_connect" -f "%USERPROFILE%\.ssh\ssh_ed25519"
    ```
    
    **3. 公開鍵ファイル名の変更**
    ```cmd
    cd "%USERPROFILE%\.ssh"
    move ssh_ed25519.pub authorized_keys
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

---