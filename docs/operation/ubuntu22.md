Ubuntu20.04→22.04アップグレードマニュアルです

SSH鍵の種類を確認する

R-loginなどのターミナルに設定中のSSH秘密鍵の種類を確認してください。

=== "id_rsaの場合"
    鍵の暗号方式が古いため、新しい鍵ペアを作成します。

    **ペア鍵の作成**

    ```sh
    ssh-keygen -t ed25519 -N '' -C ssh_connect -f ~/.ssh/ssh_ed25519
    ```

    ```sh
    cd ~/.ssh
    ls
    ```
    ssh_ed25519（秘密鍵）とssh_ed25519.pub（公開鍵）というファイルが作成されているか確認する。

    ```sh
    cat ssh_ed25519.pub >> authorized_keys
    ```

    !!! note "SSH鍵ファイルをダウンロードする" 

        1. R-loginの場合はファイル転送ウィンドウを開く  
        2. 左側ウィンドウ(ローカル側)は任意の階層にフォルダを作成する。  
        3. 右側ウィンドウ(サーバ側)は「.ssh」フォルダを選択する  
        4. 右側ウィンドウから、ssh_ed25519とssh_ed25519.pubの上で右クリックして  「ファイルのダウンロード」を選択する  
        5. 一旦サーバからログアウトする  
        6. R-Loginのサーバ接続編集画面を開き、「SSH認証鍵」をクリックし4でダウンロードしたssh_ed25519ファイルを選ぶ  
        7. サーバへ接続する 

        <font color=red>※4でローカルにダウンロードしたSSH鍵ペアはバックアップを作成することをオススメします。</font>

    サーバーに接続できたことを確認して、サーバー内の鍵を削除する
    ```
    rm ~/.ssh/ssh_ed25519
    rm ~/.ssh/ssh_ed25519.pub
    ```


=== "ssh_ed25519の場合"
    Ubuntu22.04に対応した暗号方式です。次の項目に移動して下さい。
    

## ノードを停止する
```
sudo systemctl stop cardano-node
```

自動起動を一旦停止する
```
sudo systemctl disable cardano-node
```

## 現在のUbuntuバージョンを確認する

```
cat /etc/os-release | grep "VERSION="
```
> VERSION="20.04.x LTS (Focal Fossa)"　xの数字はアップグレード時期によって変わります

## アップグレード可能なバージョンを確認する

```
sudo do-release-upgrade -c | grep "New release"
```
> New release '22.04.x LTS' available.　xの数字はアップグレード時期によって変わります

## システムアップデート
```
sudo apt update -y && sudo apt upgrade -y
```

## キャッシュ削除
```
sudo apt autoremove -y
```
```
sudo apt autoclean -y
```

## システムを再起動
```
sudo reboot
```

## アップグレード開始

```
sudo do-release-upgrade
```

以下、確認メッセージ

バックアップSSHポート開放
```
Continue running under SSH? 

This session appears to be running under ssh. It is not recommended 
to perform a upgrade over ssh currently because in case of failure it 
is harder to recover. 

If you continue, an additional ssh daemon will be started at port 
'1022'. 
Do you want to continue? 

Continue [yN] y
```

```
Starting additional sshd 

To make recovery in case of failure easier, an additional sshd will 
be started on port '1022'. If anything goes wrong with the running 
ssh you can still connect to the additional one. 
If you run a firewall, you may need to temporarily open this port. As 
this is potentially dangerous it's not done automatically. You can 
open the port with e.g.: 
'iptables -I INPUT -p tcp --dport 1022 -j ACCEPT' 

To continue please press [ENTER]
```

```
Updating repository information

No valid mirror found 

While scanning your repository information no mirror entry for the 
upgrade was found. This can happen if you run an internal mirror or 
if the mirror information is out of date. 

Do you want to rewrite your 'sources.list' file anyway? If you choose 
'Yes' here it will update all 'focal' to 'jammy' entries. 
If you select 'No' the upgrade will cancel. 

Continue [yN] y
```

```
Do you want to start the upgrade? 


3 installed packages are no longer supported by Canonical. You can 
still get support from the community. 

5 packages are going to be removed. 117 new packages are going to be 
installed. 629 packages are going to be upgraded. 

You have to download a total of 694 M. This download will take about 
2 minutes with a 40Mbit connection and about 18 minutes with a 5Mbit 
connection. 

Fetching and installing the upgrade can take several hours. Once the 
download has finished, the process cannot be canceled. 

 Continue [yN]  Details [d] y
```

chrony,opne-ssh


```
Remove obsolete packages? 


73 packages are going to be removed. 

 Continue [yN]  Details [d] y
```


System upgrade is complete.

Restart required 

To finish the upgrade, a restart is required. 
If you select 'y' the system will be restarted. 

Continue [yN] 

## ブラケットペースモードOFF
```
echo "set enable-bracketed-paste off" >> ~/.inputrc
```

## 現在のUbuntuバージョンを確認する

```
cat /etc/os-release | grep "VERSION="
```
> VERSION="22.04.x LTS (Jammy Jellyfish)"　xの数字はアップグレード時期によって変わります


依存関係再インストール
```
sudo apt install git jq bc automake tmux rsync htop curl build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ wget libncursesw5 libtool autoconf liblmdb-dev -y
```

libssl3アンインストール
```
sudo apt --purge remove libssl-dev
```

libssl-dev1.1インストール
```
cd $HOME
wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2.17_amd64.deb
sudo dpkg -i libssl-dev_1.1.1f-1ubuntu2.17_amd64.deb
```

libssl1.1インストール
```
wget wget wget wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.17_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2.17_amd64.deb
```

DLファイル削除
```
rm $HOME/libssl-dev_1.1.1f-1ubuntu2.17_amd64.deb
rm $HOME/libssl1.1_1.1.1f-1ubuntu2.17_amd64.deb
```
