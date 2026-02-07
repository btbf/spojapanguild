# **サーバー間ファイル転送**


!!! note "メリット"
    **複数台のサーバーがある場合に、以下の処理を行うことでビルド時間の短縮やノードのダウンタイムを抑えることが出来ます。**

!!! error "デメリット"
    * RSYNC+SSHを利用したアップデート方法は、転送元・転送先サーバーのディスク空き容量が150GB以上必要となります。

!!! hint "はじめに"

    * RSYNCを使用する場合、最初に[事前設定](./rsync-ssh.md)を行ってください


## **1. バイナリファイル(node/cli)転送の場合**

### **1-1.転送元サーバー作業**

=== "転送元サーバー"
    **バイナリーファイルを転送フォルダ用にコピーする**
    ```
    mkdir $NODE_HOME/Transfer
    cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-cli") $NODE_HOME/Transfer/cardano-cli
    cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-node") $NODE_HOME/Transfer/cardano-node
    ```

    バージョン確認
    ```
    $NODE_HOME/Transfer/cardano-cli version
    $NODE_HOME/Transfer/cardano-node version
    ```
    > 希望するバージョンになっているか確認する



### **1-2.転送元から転送先へ転送する**

変数`for`に転送先エイリアスを代入する

=== "転送元サーバー"

    転送先エイリアスを指定する

    ```
    for=xxxx
    ```
    > 転送先エイリアスは、事前設定の [1-2.SSH設定ファイル作成](./rsync-ssh.md#1-2ssh) で設定した転送先Host名(エイリアス)を指定します。

    ファイルを転送する
    ```
    rsync -P --rsh=ssh $NODE_HOME/Transfer/cardano-cli $for::Server/cardano-cli
    ```
    > 転送が完了するまで待つ

    ```
    rsync -P --rsh=ssh $NODE_HOME/Transfer/cardano-node $for::Server/cardano-node
    ```
    > 転送が完了するまで待つ



### **1-3.転送先サーバー作業**


=== "転送先サーバー"

    ノードを停止する
    ```
    sudo systemctl stop cardano-node
    ```

    バイナリーファイルをシステムフォルダーへコピーする
    ```
    sudo cp $NODE_HOME/cardano-cli /usr/local/bin/cardano-cli
    ```
    ```
    sudo cp $NODE_HOME/cardano-node /usr/local/bin/cardano-node
    ```
    バージョン確認
    ```
    cardano-cli version
    cardano-node version
    ```

    > 希望するバージョンになっているか確認する


    ノードを起動する
    ```
    sudo systemctl start cardano-node
    ```

    !!! info "ヒント"  
        * GliveViewでノード状況を確認する
        * Syncing 100%がTip(diff): ** :)となるまで待つ


## **2. DBフォルダ転送の場合**

### **2-1. 転送元サーバー作業**

**容量確認**
**転送元・転送先サーバー両方で確認してください**
```
df -h /usr
```
<strong><font color=red>Availが180GB以上あることを確認してください。</font></strong>

=== "転送元サーバー"
    **ノードを停止する**
    ```
    sudo systemctl stop cardano-node
    ```

    **DBフォルダを圧縮する**

    新しいTMUXセッションを開く
    ```
    tmux new -s tar
    ```
    圧縮する
    ```
    tar cvzf $NODE_HOME/Transfer/cardano-db.tar.gz -C $NODE_HOME db
    ```

    圧縮が終了したらTMUXを閉じる
    ```
    exit
    ```

    **ノードをスタートする**
    ```
    sudo systemctl start cardano-node
    ```


### **2-2. 転送元から転送先へ転送する**


=== "転送元サーバー"

    新しいTMUXセッションを開く
    ```
    tmux new -s rsync
    ```

    転送先エイリアスを指定する。変数`for`に転送先エイリアスを代入する

    ```
    for=xxxx
    ```
    > 転送先エイリアスは、事前設定の [1-2.SSH設定ファイル作成](./rsync-ssh.md#1-2ssh) で設定した転送先Host名(エイリアス)を指定します。

    圧縮されたDBを転送する
    ```
    rsync -P --rsh=ssh $NODE_HOME/Transfer/cardano-db.tar.gz $for::Server/cardano-db.tar.gz
    ```
    > 転送が完了するまで待つ

    転送が終了したらTMUXを閉じる
    ```
    exit
    ```



### **2-3. 転送先サーバー作業**

新しいTMUXセッションを開く
```
tmux new -s tar
```

=== "転送先サーバー"

    SSDの空き容量を再確認する
    ```
    df -h /usr
    ```
    <strong><font color=red>Availが100GB以上あることを確認してください。</font></strong>


    DBを解凍する
    ```
    mkdir $NODE_HOME/temp
    tar -xzvf $NODE_HOME/cardano-db.tar.gz -C $NODE_HOME/temp/
    ```
    > DBの解凍が終わるまで待ちます

    解凍が終わったらTMUXを閉じる
    ```
    exit
    ```

    ノードを停止する
    ```
    sudo systemctl stop cardano-node
    ```

    DBフォルダを入れ替える
    ```
    mv $NODE_HOME/db $NODE_HOME/db_134
    mv $NODE_HOME/temp/db $NODE_HOME/db
    ```
    
    ノードを起動する
    ```
    sudo systemctl start cardano-node
    ```

    !!! info "ヒント"  
        * GliveViewでノード状況を確認する
        * Syncing 100%がTip(diff): ** :)となるまで待つ



    バイナリーファイルを移動する
    ```
    cd $HOME/git
    rm -rf cardano-node-old/
    mv $HOME/git/cardano-node/ $HOME/git/cardano-node-old/
    mkdir cardano-node
    mv $NODE_HOME/cardano-cli $HOME/git/cardano-node/
    mv $NODE_HOME/cardano-node $HOME/git/cardano-node/
    ```


    !!! hint "確認"
        ノードの同期が成功しブロック生成に成功し数エポック様子を見たあと、転送用ファイル・バックアップDBを削除してください
        === "転送元"
            ```
            rm -rf $NODE_HOME/Transfer
            ```
        === "転送先"
            ```
            rm -rf $NODE_HOME/db_134
            rm $NODE_HOME/1.35.3-db.tar.gz
            ```

---