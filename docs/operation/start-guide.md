# **カルダノステークプール運用ガイド**


!!! tip "サポート"
    サポートが必要な場合は、[SPO JAPAN GUILDコミュニティ](https://discord.gg/U3gU54c)で現役のSPOに質問できます


## **パラメーターを理解する**

| 項目      | 値        | 用途        |
| :---------- | :----------- | :----------- |
| **optimal_pool_count(K)**      | 500 |飽和閾値設定用 |
| **a0**       | 0.3 |誓約報酬係数　|
| **max_tx_size**   | 16384 |最大トランザクションサイズ　|
| **max_block_size**   | 90112 |最大ブロックサイズ　|
| **epochLength**    | 432000 |1エポックのスロット数　|
| **slotsPerKESPeriod**    | 129600 |1KES当たりのスロット数　|
| **maxKESEvolutions**    | 62 |KES有効期間　|
| **activeSlotsCoeff**    | 0.05 |1エポック内の有効スロット率　|


## **スロットを理解する**

* Slot = ジェネシススロットからのスロット  
* Slot epoch = エポック内のスロット  

* 1スロット＝1秒  
* 1エポック＝432000スロット(epochLength)  
  (432000 / 60 = 7200分 / 60 = 120時間 / 24 = 5日)  


## **ブロック生成スロットリーダー**

1エポック内のブロック生成有効スロットは5%(432000スロット × 5% ＝ 約21600スロット)  
委任量に応じて、スロットリーダーがランダムに決定されます。

1エポックで1ブロック割り当てられるために必要な委任量の目安は以下の通りです。  

* 1M 60%  
* 2M 85%  
* 3M 95%

スロットリーダーの割り当ては、プール間同士で調整されないため以下のタイプのバトルが発生します。

!!! tip "スロットバトル(stolen)"
    他プールと同じスロットに割り当てられた際に発生  
    vrf値によるサイコロゲームが行われ出た目の小さいプールのブロックが採用されます。(ステーク量による優位性はなくランダム)

!!! tip "ハイトバトル(Ghosted / missed)"
    他プールと5秒以内に割り当てられた場合や、前ブロック生成プールのサーバー設定・環境によりブロック伝播遅延が発生することで引き起こる現象。地理的優位性を無くすため、vrf値によるサイコロゲームが行われ出た目の小さいプールのブロックが採用されます。(ステーク量による優位性はなくランダム)

## **KESとは？**
!!! tip "KES＝Key-Evolving Signatures"
    ブロック生成署名用鍵ファイル。過去のブロック署名を書き換えることが出来ないよう90日ごとに更新が必要。

## **VRFとは？**
!!! tip "VRF=Verifiable Random Function"
    Ouroboros Praosは、VRF（Verifiable Random Function）キーによって、ブロック生成にさらなるセキュリティ層を追加しています。
    Ouroboros Praosのスロットリーダーのスケジュールは非公開となっており、VRFキーを使ってスロットリーダーの検証を行っております。

## **各ファイルの役割と保管場所**

### 証明書とペアキー
:lock:・・・ロック必須・再作成不可・紛失不可  
:arrows_clockwise:・・・更新時書き換え・再作成可能  
🔴・・・BP起動で使用  
🔷・・・ブロックログで使用

!!! note "鍵ファイルバックアップについて"
    :lock:マークが付いたファイルはプール運営にとても重要なファイルです。紛失・削除するとプール運営が継続できなくなったり、資金を引き出せなくなります。そのため同一ファイルを複数のUSBなどへ分散保管するようにしましょう。

| ファイル      | 用途                          | 推奨保管場所 | 重要度 |
| ----------- | ------------------------------------ | ---------------- | :------: | 
| **payment.vkey**       | paymentアドレス公開鍵  | エアギャップ ／ USB | :lock: |
| **payment.skey**       | paymentアドレス秘密鍵 | エアギャップ ／ USB | :lock: |
| **stake.vkey**      | ステークアドレス公開鍵  | エアギャップ ／ USB | :lock: |
| **stake.skey**      | ステークアドレス秘密鍵  | エアギャップ ／ USB | :lock: |
| **vrf.vkey**🔷    | VRF公開鍵 | **BP** ／ エアギャップ ／ USB | :lock: |
| **vrf.skey**🔴    | VRF秘密鍵 | **BP** ／ エアギャップ ／ USB | :lock: |
| **node.vkey**    | コールド公開鍵 | エアギャップ ／ USB | :lock: |
| **node.skey**    | コールド秘密鍵 | エアギャップ ／ USB | :lock: |
| **payment.addr**    | paymentアドレスファイル | **BP** ／ エアギャップ ／ USB | :arrows_clockwise: |
| **stake.addr**       | ステークアドレス秘密鍵 | **BP** ／ エアギャップ ／ USB | :arrows_clockwise: |
| **kes.vkey**    | KES公開鍵 | エアギャップ ／ USB | :arrows_clockwise: |
| **kes.skey**🔴    | KES秘密鍵 | **BP** ／ エアギャップ ／ USB | :arrows_clockwise: |
| **node.cert**🔴    | プール運用証明書 | **BP** ／ エアギャップ ／ USB | :arrows_clockwise: |
| **pool.cert**    | プール登録証明書 | エアギャップ ／ USB | :arrows_clockwise: |
| **node.counter**    | カウンターファイル | エアギャップ ／ USB | :arrows_clockwise: |

### ノード起動用設定ファイル

| ファイル      | 用途                          |
| ----------- | ------------------------------------ |
| **mainnet-byron-genesis.json**       | Byron設定ファイル  |
| **mainnet-shelley-genesis.json**       | Shelley設定ファイル |
| **mainnet-alonzo-genesis.json**      | Alonzo設定ファイル  |
| **mainnet-conway-genesis.json**      | Conway設定ファイル  |
| **mainnet-config.json**      | ノード設定ファイル  |
| **mainnet-topology.json**    | トポロジーファイル |

### スクリプトファイルやその他

| ファイル      | 用途                          | 推奨保管場所 | 重要度 |
| ----------- | ------------------------------------ | ---------------- | :------: | 
| **startRelayNode1.sh**       | リレー用ノード起動スクリプト  | リレー | :arrows_clockwise: |
| **startBlockProducingNode.sh**       | BP用ノード起動スクリプト | BP | :arrows_clockwise: |
| **gLiveView.sh**      | ノードGUI用スクリプト  | リレー/BP | :arrows_clockwise: |
| **params.json**      | パラメーターファイル  | BP | :arrows_clockwise: |
| **poolMetaData.json**      | プール情報JSON  | BP | :arrows_clockwise: |
| **poolMetaDataHash.txt**      | poolMetaData.jsonハッシュ値ファイル  | BP | :arrows_clockwise: |
| **fullUtxo.out**    | UTXO出力ファイル | 使用後削除可 | - |
| **balance.out**    | ウォレット残高出力ファイル | 使用後削除可 | - |
| **tx.tmp**    | 仮トランザクションファイル | 使用後削除可 | - |
| **tx.raw**    | トランザクションファイル | 使用後削除可 | - |
| **tx.signed**       | トランザクション署名付きファイル | 使用後削除可 | - |

## **作業内容チェックリスト**

:material-tooltip-edit-outline: **日次作業**

* ノード稼働状況チェック(Grafana等)
* ブロック生成ステータス

:material-tooltip-edit-outline: **エポック毎作業**

* 次エポックのブロック生成スケジュール確認  
  (320000スロットを超えてからエポック終了までに)  


:material-tooltip-edit-outline: **3か月毎作業**

* [KES更新(1-KESの更新)](kes-update.md)

:material-tooltip-edit-outline: **不定期作業**

* Ubuntuパッケージアップデート
* ノードアップデート
* サードパーティ製アプリアップデート
* サーバー障害対応
* プール設定変更など


