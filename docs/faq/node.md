# ノードに関するよくある質問

## Q1.ノードが起動・同期しません

??? note "A.起動ログを確認してください"
    ノード起動ログを確認してエラー表示を確認してください
    ```
    journalctl --unit=cardano-node --follow
    ```

    
    ==**^^「InvalidYaml (Just (YamlParseException」が表示される場合^^**==

    * `mainnet-config.json` 構文エラーのためファイル内を見直してください。
    > `,` `{}` `()`などが抜けていたり、多かったりします。 

    ファイルを修正したらノードを再起動します
    ```
    sudo systemctl reload-or-restart cardano-node
    ```

    [JSON構文チェックツール（ラッコツールズ）](https://rakko.tools/tools/63/)


    ==** ^^「Is your topology file formatted correctly?」 が表示される場合^^**==

    * mainnet-topology.json 構文エラーのため、トポロジーファイルを見直してください

    ファイルを確認したらノードを再起動します
    ```
    sudo systemctl reload-or-restart cardano-node
    ```

    ==**^^Progress: xx.xx%の表示がある場合^^**==  
    前回ノード終了時にメモリ不足などで強制終了したため、DB再チェックが行われています。同期までに約20分以上かかりますのでそのままお待ちください。
    
    !!! warning "注意"
        ノードが完全同期しないうちにノード起動・再起動コマンドを実行すると、DB再チェックが行われるため同期がさらに遅くなりますのでご注意ください


    ==**^^BPが同期しない場合^^**==  
    リレーとの接続を確認してください。  

    * BPのmainnet-topology.json
    * BPのファイアウォール設定
    * リレーのファイアウォール設定
    * 契約サーバー独自の仕様




## Q2.BPノードが再起動を繰り返します

??? note "A.SWAPを設定してください"
    ** 1. メモリ領域の確認 **
    ```
    free -h
    ```
    !!! example "戻り値が以下の条件をみたしているか確認"
        * Mem:Total⇒`15Gi`以上 
        * Swap:Total⇒`8.0Gi`以上

    === "Mem:Total⇒ 15Gi 未満の場合"
        サーバーメモリを16GB以上にスケールアップするか、16GBスペックを再契約し再構築する

    === "Swap:Total⇒ 8.0Gi 未満の場合"
        ** 既存のスワップファイルを削除する **
        ```
        sudo swapoff /swapfile
        rm /swapfile
        ```
        ** 新しいスワップファイルを設定する **
        ```
        cd $HOME
        sudo fallocate -l 8G /swapfile

        sudo chmod 600 /swapfile

        sudo mkswap /swapfile
        sudo swapon /swapfile
        sudo swapon --show

        sudo cp /etc/fstab /etc/fstab.bak
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
        echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
        cat /proc/sys/vm/vfs_cache_pressure
        cat /proc/sys/vm/swappiness
        ```
        サーバー再起動
        ```
        sudo systemctl stop cardano-node
        sudo reboot
        ```