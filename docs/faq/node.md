# ノードに関するよくある質問

## Q1. ノードが起動・同期しません

??? note "A. 起動ログを確認してください"
    ノードの起動ログを確認し、エラーが出ていないか確認してください。
    ```bash
    journalctl --unit=cardano-node --follow
    ```
    !!! warning "注意"
        ノードが完全同期する前に、起動・再起動コマンドを実行すると、DBの再チェックが再度発生し、同期がさらに遅くなりますのでご注意ください。

    ???+ tip "「InvalidYaml (Just (YamlParseException」が表示される場合"
        * `mainnet-config.json` に構文エラーがあるためファイル内容を見直してください。
        > `,` `{}` `()`などの記号が不足していたり、余分に記述されている場合があります。

        修正後、ノードを再起動してください。
        ```bash
        sudo systemctl reload-or-restart cardano-node
        ```

        [JSON構文チェックツール（ラッコツールズ）](https://rakko.tools/tools/63/)  
        ※ **このツールを使うとJSONの構文エラー（不足・過剰な記号など）をチェックできます。**

    ???+ tip "「Is your topology file formatted correctly?」 が表示される場合"
        * `mainnet-topology.json` に構文エラーがあるためファイル内容を見直してください。

        修正後、ノードを再起動してください。
        ```bash
        sudo systemctl reload-or-restart cardano-node
        ```
    ???+ tip "Progress: xx.xx%の表示がある場合"
        * 前回ノードがメモリ不足などで強制終了したため、DBの再チェックが行われています。  
        同期までに約20分以上かかることがありますので、そのままお待ちください。

    ???+ tip "BPが同期しない場合"
        リレーとの接続状態を確認してください。  

        * BP側の`mainnet-topology.json`
        * BP側のファイアウォール設定
        * リレーのファイアウォール設定
        * 契約サーバー特有の仕様（通信制限など）


## Q2. ノードが再起動を繰り返します

??? note "A. ディスク空き容量を確認してください"
    ```bash
    df -h /usr
    ```
    戻り値の`Use%`が100%に近い場合、ノードのDBを更新するための空き容量が不足しており、ノードが再起動を繰り返します。  
    契約中のVPSのサーバースペックを変更してください。
    