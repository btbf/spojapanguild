# ブロックログ関連のよくある質問

## Q1.スケジュールが取得できません

??? note "A.cncliサービスを確認します"

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

## Q2.ブロック生成に失敗しました。原因は何でしょうか？


??? note "A.ステータスを確認します"
    === "Stolenの場合"
        通称：SlotBattle  
        VRF値が小さいほうのブロックが採用されるため運次第となっており解決方法はありません。

        1エポック = 432000slotのうちブロック生成可能スロットは5%(21600slot)になっておりますが、割り当てられるスケジュールはプール間同士では調整されない仕様になっているため、複数のプールに同一スロットにスケジュールが割り当てられることがあります。  

        しかしブロックチェーンに採用されるブロックは1スロット1ブロックなので、どのプールのブロックを採用するかを決定する際、ブロック生成時にプールがランダムに排出するVRF値が小さい方のブロックを採用する仕様となっております。

    === "ghostedの場合"

        **原因1:VRF値による判定のため運次第**  
        通称：HeightBattle  
        ブロック伝播の影響を受けています。

        現在のカルダノブロックチェーンは5秒以内に伝播できればセキュリティ上問題ないとされています。しかしスケーラビリティとのトレードオフで、トランザクション処理速度をあげるためにブロックサイズやスマートコントラクトスクリプトメモリサイズなどを増やしていくとその分伝播速度も遅くなります。
        
        このことから、1秒～3秒前後に複数のプールで割り当てられたスケジュールで発生しやすく、分散化の観点からプール間の地理的優位性を無くすためにVRF値による判定で採用ブロックが決定されます。

        **原因2:サーバー時間のズレから発生**  
        カルダノブロックチェーンはリアルタイム要件が必要なため、サーバー内部時計とインターネット時間(NTPサーバー)が同期している必要があります。
        予定スケジュールで連続して発生している場合は、リレーおよびBPにてChrony設定を確認してください。
        ```
        chronyc tracking
        ```
        → 「Leap status」が「Normal」ならOK。「Not synchronized」ならNG
    
    === "Missedの場合"
        ミスしたスロット番号を用いて、ログを確認します  
        > 55901248をミスしたスロット番号に直してコマンドを実行してください

        ```
        cd $NODE_HOME/logs
        cat node*.json | grep 55901248
        ```

        **該当スロットのログが表示される場合**  
        ブロック伝播の影響を受けている可能性があります。  
        1秒～3秒前後に複数のプールで割り当てられたスケジュールで発生しやすく、自プールのブロック生成予定までに最新ブロックを受け取れない場合があります。
        地理的に分散したリレーノードを配置するか、リレー/BPの`mainnet-config.json`に`"MaxConcurrencyDeadline":4,`を設定してノードを起動します。

        **該当スロットのログが表示されない場合**  
        ノードがシャットダウンしていたか、slotsMissedになった可能性があります。  
        リレー1台の場合、リレーノードがシャットダウンするとBPでブロック生成することができません。
        かたやリレーノードが稼働していても、BPノードがシャットアウトしていた場合も生成することができません。
        Grafanaなどでノード稼働状態を監視し、シャットダウンした場合にスマホなどへ通知するように設定しましょう。
        missになったスロット番号の、前後のスロット番号20～30ぐらいをログ検索して出てくれば、ノードは動いていた可能性が高いです。

        **slotsMissedとは？**  
        [gLiveViewに表示されるMissed slot leader checks]   
        BPノードは毎秒ごとに自分がスロットリーダーなのかをチェックしていますが、ノードの状態やサーバー負荷によってスロットリーダーチェックに失敗します。
        このタイミングにスケジュールが重なるとブロック生成できません。

        現在わかっていることは、ノード起動スクリプトにRTSオプションを設定することで軽減できます。また契約サーバーの内部仕様によっても変わってくるようなので
        slotsMissedの発生が多い場合は、サーバー乗り換えも検討することをお勧めします。(サーバー内部設定はオペレーター側では変更できません)
    
    === "Invalidの場合"
        **KES更新・運用証明書の発行に失敗している可能性があります**

        logmonitorに表示される、base64コードをデコードして原因を探ります。
        
        ```
        tmux a -t logmonitor
        ```
        ログモニターに表示される、`echo ～ jq -r`までをコピーする  
        以下のコードは例です。
        !!! quote ""
            echo eyJ0aHJlYWQiOiIxMzUiLCJzZXYiOiJFcnJvciIsImRhdGEiOnsidmFsIjp7ImtpbmQiOiJUcmFjZUZvcmdlZEludmFsaWRCbG9jayIsInNsb3QiOjQ5MTY1ODc5LCJyZWFzb24iOnsia2luZCI6IlZhbGlkYXRpb25FcnJvciIsImVycm9yIjp7ImtpbmQiOiJIZWFkZXJQcm90b2NvbEVycm9yIiwiZXJyb3IiOnsiZmFpbHVyZXMiOlt7Im9wQ2VydEV4cGVjdGVkS0VTRXZvbHV0aW9ucyI6IjI1Iiwia2luZCI6IkludmFsaWRLZXNTaWduYXR1cmVPQ0VSVCIsIm9wQ2VydEtFU1N0YXJ0UGVyaW9kIjoiMzU0Iiwib3BDZXJ0S0VTQ3VycmVudFBlcmlvZCI6IjM3OSIsImVycm9yIjoiUmVqZWN0In1dLCJraW5kIjoiQ2hhaW5UcmFuc2l0aW9uRXJyb3IifX19fSwiY3JlZGVudGlhbHMiOiJDYXJkYW5vIn0sImxvYyI6bnVsbCwiZW52IjoiMS4zMi4xOjRmNjVmIiwibXNnIjoiIiwiYXBwIjpbXSwiaG9zdCI6ImlwLTE3Mi0yIiwiYXQiOiIyMDIxLTEyLTI4VDIyOjU2OjEwLjQzWiIsIm5zIjpbImNhcmRhbm8ubm9kZS5Gb3JnZSJdLCJwaWQiOiIzODY1MzAifQ== | base64 -d | jq -r
        
        `Ctrl+b d`でデタッチして、上記でコピーしたコマンドを実行する。  
        `"error":"failures":"kind":`の値が失敗した理由になっています。
        ```
        {
            "thread": "135",
            "sev": "Error",
            "data": {
                "val": {
                "kind": "TraceForgedInvalidBlock",
                "slot": 49165879,
                "reason": {
                    "kind": "ValidationError",
                    "error": {
                    "kind": "HeaderProtocolError",
                    "error": {
                        "failures": [
                        {
                            "opCertExpectedKESEvolutions": "25",
                            "kind": "InvalidKesSignatureOCERT",
                            "opCertKESStartPeriod": "354",
                            "opCertKESCurrentPeriod": "379",
                            "error": "Reject"
                        }
                        ],
                        "kind": "ChainTransitionError"
                    }
                    }
                }
                },
                "credentials": "Cardano"
            },
            "loc": null,
            "env": "1.32.1:4f65f",
            "msg": "",
            "app": [],
            "host": "ip-172-2",
            "at": "2021-12-28T22:56:10.43Z",
            "ns": [
                "cardano.node.Forge"
            ],
            "pid": "386530"
        }
        ```
## Q3.割り当てられたスケジュールをSNSで公開してもいいですか？
??? note "A.NGです"
    未来の生成予定スケジュールを公開すると、その時間を狙って悪意のある者から攻撃を受ける可能性があるため、
    予定スケジュールを公開することはカルダノネットワークのセキュリティを損なう重大な問題となります。

## Q4.スケジュール取得時「Error: database is locked」が表示される
??? note "A.スケジュールを再取得してください"
    `tmux a -t leaderlog`で取得されたスケジュールを確認すると「Error: database is locked」が表示される時があります。

    スケジュール取得時のblocklogデータベース書き込みエラーによるもので、スケジュールはあるもののデータベースに格納されません。  
    直近1時間以内にブロック生成が無いことを確認し、`tmux a -t leaderlog`を開き`$NODE_HOME/scripts/cncli.sh leaderlog force`コマンドを実行して、スケジュールを再取得してください。