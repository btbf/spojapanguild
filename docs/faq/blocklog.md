# **よくある質問：ブロックログ関連**

## Q1. ブロック生成に失敗しました。原因は何でしょうか？

??? note "A. ステータスを確認します"
    === "Stolenの場合"
        **通称：スロットバトル（SlotBattle / Stolen）**

        スロットバトルとは、複数のプールに同じスロットが割り当てられた時に発生する現象です。  
        Cardanoでは、1スロットにつき1ブロックしか採用されないため、どのプールのブロックが選ばれるかをVRFのランダム値で決定します。  
        各プールが生成するVRF値を比較し、最も値が小さいプールのブロックが採用されます。  
        VRFの比較は完全にランダムであるため、ステーク量による優位性はなく、運次第で結果が決まります。

    === "Ghostedの場合"
        **通称：ハイトバトル（HeightBattle / Ghosted）**

        Ghostedは、主に次の2つの理由で発生します。  

        ???+ tip "**原因1：VRF値による判定(運要素)**"  
            ブロック伝播のタイミング差が影響します。  
            Cardanoでは「ブロックが5秒以内に伝播すれば安全」とされていますが、ブロックサイズやスクリプトメモリの増加に伴い、伝播速度が遅くなることがあります。  
            その結果、同じスロット周辺（1~3秒以内）に複数のプールにスケジュールが割り当てられると、伝播の遅いブロックが不利になり、VRF値の比較によってどのブロックを採用するかが決定されます。  
            これは、地理的な伝播速度の差による不公平を避けるための仕組みです。  

        ???+ tip "**原因2：サーバー時間のズレ**"  
            Cardanoはリアルタイム同期が必須のため、サーバー内部時計がNTPサーバーと正確に同期している必要があります。  
            予定スケジュールで連続してGhostedが発生する場合は、BPおよびリレーのChrony設定を確認してください。

            ```bash
            chronyc tracking
            ```
            > 「Leap status」が **Normal**：問題ありません。  
            > 「Leap status」が **Not synchronized**：問題があります。

    === "Missedの場合"
        **確認方法**  

        Missedとなったスロット番号を用いて、ログを確認します。  
        > 例：**`55901248`を実際のMissedのスロット番号に置き換えて実行してください。**

        ```bash
        cd $NODE_HOME/logs
        cat node*.json | grep 55901248
        ```

        ???+ tip "**slotsMissedとは？**"  
            BPノードは毎秒、スロットリーダーかどうかを確認していますが、ノード状態やサーバー負荷によりチェックが失敗することがあります。  
            このタイミングでスケジュールが重なるとブロック生成できず`Missed`になります。  
            現状では、ノード起動スクリプトにRTSオプションを設定することで軽減可能です。  
            ただし、契約サーバーの内部仕様（CPU割り当てなど）によっても発生率が変わるため、`slotsMissed`が多い場合はサーバー乗換えも検討してください。（サーバー内部使用はオペレーター側で変更できません。）

        ???+ info "**該当スロットのログが表示される場合**"  
            ブロック伝播の遅延が原因の可能性があります。  
            1秒～3秒以内に複数のプールへスケジュールが割り当てられると、自プールのブロック生成時までに最新ブロックを受信できず `Missed`が発生しやすくなります。  
        
        ???+ info "**該当スロットのログが表示されない場合**"  
            ノードがシャットダウンしていたか、`slotsMissed`が発生していた可能性があります。  
            リレー1台構成の場合、そのリレーノードが落ちるとBPは、ブロックを生成できません。  
            リレーノードが稼働していても、BPノードが停止していれば同様に生成不可となります。  
            Grafanaなどでノード稼働状態を監視し、停止時にスマホへ通知されるよう設定しておきましょう。
            また、Missedとなったスロットの前後、20~30スロットを検索してログが出てくる場合は、ノード自体は稼働していた可能性が高いです。

    === "Invalidの場合"
        **確認方法**

        KES更新や運用証明書（opcert）の発行に失敗している可能性がありますので`logmonitor` に表示されるbase64コードをデコードして、原因を特定します。
        
        まず`logmonitor`のtmuxセッションにアタッチします。  
        ```bash
        tmux a -t logmonitor
        ```

        ログモニターに表示されている`echo ～ | base64 -d | jq -r`までのコマンドをコピーします。  
        以下のコードは一例です。  
        !!! quote ""
            echo eyJ0aHJlYWQiOiIxMzUiLCJzZXYiOiJFcnJvciIsImRhdGEiOnsidmFsIjp7ImtpbmQiOiJUcmFjZUZvcmdlZEludmFsaWRCbG9jayIsInNsb3QiOjQ5MTY1ODc5LCJyZWFzb24iOnsia2luZCI6IlZhbGlkYXRpb25FcnJvciIsImVycm9yIjp7ImtpbmQiOiJIZWFkZXJQcm90b2NvbEVycm9yIiwiZXJyb3IiOnsiZmFpbHVyZXMiOlt7Im9wQ2VydEV4cGVjdGVkS0VTRXZvbHV0aW9ucyI6IjI1Iiwia2luZCI6IkludmFsaWRLZXNTaWduYXR1cmVPQ0VSVCIsIm9wQ2VydEtFU1N0YXJ0UGVyaW9kIjoiMzU0Iiwib3BDZXJ0S0VTQ3VycmVudFBlcmlvZCI6IjM3OSIsImVycm9yIjoiUmVqZWN0In1dLCJraW5kIjoiQ2hhaW5UcmFuc2l0aW9uRXJyb3IifX19fSwiY3JlZGVudGlhbHMiOiJDYXJkYW5vIn0sImxvYyI6bnVsbCwiZW52IjoiMS4zMi4xOjRmNjVmIiwibXNnIjoiIiwiYXBwIjpbXSwiaG9zdCI6ImlwLTE3Mi0yIiwiYXQiOiIyMDIxLTEyLTI4VDIyOjU2OjEwLjQzWiIsIm5zIjpbImNhcmRhbm8ubm9kZS5Gb3JnZSJdLCJwaWQiOiIzODY1MzAifQ== | base64 -d | jq -r
        
        `Ctrl+b d`でtmuxからデタッチした後、先ほどコピーしたコマンドをシェルで実行します。  

        出力されたJSONの`"error":"failures":"kind":`などの値が失敗した理由を示しています。
        !!! quote ""
            <pre>{
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
                }</pre>


## Q2. 割り当てられたブロック生成スケジュールをSNSで公開してもいいですか？
??? note "A. NGです"
    **未来のブロック生成スケジュールを公開すると、その時間を狙って悪意のある攻撃を受ける可能性があります。**  
    このため、予定スケジュールを公開する行為は**Cardanoネットワークのセキュリティを損なう重大な問題となるため、絶対に公開してはいけません。**

---