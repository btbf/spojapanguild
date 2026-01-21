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

---