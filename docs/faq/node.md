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




## Q2.ノードが再起動を繰り返します

??? note "A.ディスク空き容量を確認してください"
    ```
    df -h /usr
    ```
    戻り値の`Use%`が100%に近いとノードDBを更新する空き容量が足りないため、再起動を繰り返します。契約VPSのサーバースペックを変更してください。
    