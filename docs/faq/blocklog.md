# ブロックログ関連のよくある質問

## スケジュールが取得できません

** 1. サービスの起動状態を確認する **
```
tmux a -t cncli
```

** 戻り値を確認する **
=== "戻り値パターン①"
    ファイルアップデートを促すメッセージが表示されている
    !!! info "戻り値"
        Script update(s) detected, do you want to download the latest version? (yes/no):
    
    `yes` を入力。ファイルがアップデートされたらEnterを押し、デタッチ[Ctrl+b　d]して戻る

    **cncliサービスを再起動する**
    ```
    sudo systemctl reload-or-restart cnode-cncli-sync.service
    ```

    **「1. サービスの起動状態を確認する」に戻って再度戻り値を確認する**

    

=== "戻り値パターン②"
    !!! info "戻り値"
        Looks like cardano-node is running with socket-path as～～
    赤文字で大量にログが表示されている。⇒ノード起動待ち状態  
    （デタッチ[Ctrl+B D]して戻る） 
        
        
    **ノードログを確認する**
    ```
    journalctl --unit=cardano-node --follow
    ```
    !!! info "戻り値"
        Started opening Ledger DB
    この表示が出てくればOK。ログが流れるまで待機

    **ノード同期後、leaderlogサービスを確認する**
    ```
    tmux a -t leaderlog
    ```
    !!! info "戻り値"
        ~ CNCLI Leaderlog started ~  
        Node in sync, sleeping for 60s before running leaderlogs for current epoch
    
    この表示が出てくればOK（デタッチ[Ctrl+B D]して戻る）  
    スケジュールが計算されるまで数十分かかります。  

=== "戻り値パターン③"
    !!! info "戻り値"
        INFO  cardano_ouroboros_network::protocols::～～～ 100.00% synced
    この表示が出てくればOK（デタッチ[Ctrl+B D]して戻る）

    **leaderlogサービスを確認する**
    ```
    tmux a -t leaderlog
    ```
    !!! info "戻り値"
        ~ CNCLI Leaderlog started ~  
        Node in sync, sleeping for 60s before running leaderlogs for current epoch
    この表示が出てくればOK（デタッチ[Ctrl+B D]して戻る）



