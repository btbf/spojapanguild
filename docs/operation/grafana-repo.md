# Grafanaリポジトリ設定変更手順

!!! note "概要"

    * このマニュアルでは旧式のGrafana更新用APTリポジトリを更新します。
    * Grafanaがインストールされているサーバー(Relay1)のみ対象です。

    * <font color=red>設定済みのAPTリポジトリを確認する</font>
    ```
    cat /etc/apt/sources.list.d/grafana.list | grep "https://packages.grafana.com/oss/deb"
    ```
    > `deb https://packages.grafana.com/oss/deb stable main`の戻り値がある場合、以下の作業対象です。


## **1.GPGキーの確認**
インストール済みのGPG署名キーを確認する

```
sudo apt-key list | grep -B 1 Grafana
```
> Ubuntu22.04の場合は「Warning: apt-key is deprecated. Manage keyring files in trusted.gpg.d instead (see apt-key(8)).」という文字が出ますが無視で大丈夫です。

**戻り値  例）**
```  { .yaml .no-copy }
       4E40 DDF6 D76E 284A 4A67  80E4 8C8C 34C5 2409 8CB6
 uid           [ unknown] Grafana <info@grafana.com>
```

## **2.旧GPG署名キー削除**

キーをコピーして削除コマンドを作成して実行する。

削除コマンド 例）
```
sudo apt-key del "4E40 DDF6 D76E 284A 4A67  80E4 8C8C 34C5 2409 8CB6"
```

!!! danger "確認"
    * ""内のキーは、サーバーに表示されているものに変更してください。  
    * 戻り値にキーが複数ある場合は、全てのキーを削除してください。  
    * Ubuntu22.04の場合は「Warning: apt-key is deprecated. Manage keyring files in trusted.gpg.d instead (see apt-key(8)).」という文字が出ますが無視で大丈夫です。

## **3.新リポジトリ追加**

```
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee -i /etc/apt/sources.list.d/grafana.list
```

!!! note "Ubuntu22.04の場合はこちらも実行"
    ```
    sudo apt update -y && sudo apt install -y needrestart
    ```
    ```
    echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/50local.conf
    ```
    ```
    echo "\$nrconf{blacklist_rc} = [qr(^cardano-node\\.service$) => 0,];" | sudo tee -a /etc/needrestart/conf.d/50local.conf
    ```

依存関係インストール
```
sudo apt install -y apt-transport-https software-properties-common
```

新GPGキーインストール
```
sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
```

システムアップデート
```
sudo apt update -y && sudo apt upgrade -y
```

Grafanaバージョン確認
```
grafana-server -v
```
> Version 10.1.2 (commit: 8e428858dd, branch: HEAD)  
> バージョンは実施時期によって変動します。


以上です。