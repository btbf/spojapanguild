## **1.事前準備**

### 1-1. ターミナルソフトインストール

1.R-Login(Windows)   
[https://kmiya-culti.github.io/RLogin/](https://kmiya-culti.github.io/RLogin/) 
!!! tip "R-Login推奨設定"

    **カラー設定**  
    <img src=../images/r-login-setting2.png width="500px">
    
    **接続状態維持設定**  
    <img src=../images/r-login-setting.png width="500px">

2.Termius(Win/Mac/Linux/iPhone/Android)  
[https://termius.com/](https://termius.com/)


3.Terminal(Mac)  
[https://www.webdesignleaves.com/pr/plugins/mac_terminal_basics_01.html](https://www.webdesignleaves.com/pr/plugins/mac_terminal_basics_01.html) 


### 1-2. SSH鍵作成

=== "Windowsの場合"
    ターミナルを管理者で起動する  

    1.Win + X を押す  
    2.ターミナル（管理者）を選択する

    SSHクライアント確認  
    ```
    Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
    ```
    > State : Installed

    ??? hint "`State : NotPresent`の場合はSSHクライアントをインストールしてください"
        ```
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
        ```
    
    SSH鍵生成
    ```
    mkdir ~/.ssh -Force
    cd ~/.ssh
    ssh-keygen -t ed25519 -N '""' -C "ssh_connect" -f ./ssh_ed25519
    ```
    
    公開鍵リネーム
    ```
    cd ~/.ssh
    mv ssh_ed25519.pub authorized_keys
    ```

=== "Macの場合"
    ターミナルを起動する 
    1. ⌘ + Space（command + スペース）
    2.「terminal」 と入力
    3. Enter

    sshディレクトリを確認する
    ```
    mkdir -p ~/.ssh
    ```
    SSH鍵生成
    ```
    ssh-keygen -t ed25519 -N "" -C "ssh_connect" -f ~/.ssh/ssh_ed25519
    ```

    公開鍵リネーム
    ```
    cd ~/.ssh
    mv ssh_ed25519.pub authorized_keys
    ```

ssh_ed25519 秘密鍵  
authorized_keys 公開鍵  
