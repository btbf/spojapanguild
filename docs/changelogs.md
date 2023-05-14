# 変更履歴

## 2023/05/13　ver. 12.7.0
!!! note ""
    * Cardano-node8.0.0対応
    * [ノードアップデート手順](./operation/node-update.md)更新


## 2023/05/4　ver. 12.6.3
!!! note ""
    * SPO投票(テストネット)手順追加

## 2023/04/13　ver. 12.6.2
!!! note ""
    * CNCLI 5.3.2 muslビルド対応

## 2023/04/04　ver. 12.6.1
!!! note ""
    * CNCLI 5.3.2対応
    * P2P設定トポロジーファイルフォーマット追加

## 2023/04/04　ver. 12.6.0
!!! note ""
    * Cardano-node1.35.7対応
    * [[ダイナミックP2P設定](./operation/p2p-settings.md)] マニュアル追加
    * ブロック生成ステーテス通知 v1.9.3
    * [SJGラーニング](./learning.md)資料追加

## 2023/03/07　ver. 12.5.1
!!! note ""
    * [[監視ツールセットアップ](./setup/9-monitoring-tools-setup.md#9-2)] prometheus.yml内容修正
    * ブロック生成ステーテス通知 v1.9.0

## 2023/03/07　ver. 12.5.0
!!! note ""
    * Grafanaセキュリティ強化設定追加
    * Grafanaアラート設定追加
    * ブロック生成ステーテス通知 v1.8.9
    　通知設定有無検知、起動時通知機能追加
    * CNCLI5.3.1対応
    * 軽微な修正


## 2023/02/10　ver. 12.4.8

!!! note ""
    * ブロック生成ステーテス通知 v1.8.6  
    　スケジュール取得自動化機能追加

## 2023/02/08　ver. 12.4.7

!!! note ""
    * ブロック生成ステーテス通知 v1.8  
    　スケジュール取得自動化機能追加

## 2023/02/04　ver. 12.4.6

!!! note ""
    * CNCLI5.3.0対応
    * 軽微な修正

## 2023/01/29　ver. 12.4.5

!!! note ""
    * Cardano-node1.35.5対応
    * cncli.shアップデート
    * ブロックログ [スケジュール取得手順](./setup/10-blocklog-setup.md#10-9)を変更
    * [貢献者ページ](./contributors.md)を追加
    * 軽微な修正

## 2023/01/23　ver. 12.4.4

!!! note ""
    * [SJGラーニング](./changelogs.md)を追加
    * 軽微な修正

## 2023/01/05　ver. 12.4.3

!!! note ""
    * [リレーサーバー増設マニュアル](./operation/add-relay.md)を追加
    * 軽微な修正


## 2022/12/20　ver. 12.4.2

!!! note ""
    * 最新リリース1.35.4ビルド失敗の回避コマンドを追記
    * 軽微な修正

## 2022/12/03　ver. 12.4.1

!!! note ""
    * 軽微な修正

## 2022/12/02　ver. 12.4.0

!!! note ""
    * Cardano-node1.35.4対応
    * prometheus-node-exporter1.5.0アップデート手順追加  
        ([9.監視ツールセットアップ](./setup/9-monitoring-tools-setup.md)、[ノードアップデート](./operation/node-update.md#1-3node-exporter))
    * [エアギャップマシン作成](./setup/air-gap-guid.md) ページ新設。Version7対応
    * [1.Ubuntu初期設定](./setup/1-ubuntu-setup.md)ファイアウォール設定の一部を変更  
        (設定が必要な各ページ([3-リレー/BPの接続](./setup/3-relay-bp-setup.md)、[9.監視ツールセットアップ](./setup/9-monitoring-tools-setup.md))へ移動)
    * リレー2台目以降の設定手順を各ページに追加
    * [Grafanaダッシュボードテンプレート](./setup/9-monitoring-tools-setup.md#4grafana)を更新。  
        (KoiosAPIを利用しティッカー名、プール委任量、委任者数情報表示)
    * [プール運用ガイド](./operation/start-guide.md)カテゴリを整理
    * 軽微な修正

## 2022/10/17　ver. 12.3.6

!!! note ""
    * [2. ノードインストール](./setup/2-node-setup.md#2-3) ノード設定ファイルダウンロード元URLを変更
    * configファイル修正内容コマンド化
    * リレーノードでもログ出力するよう手順修正
    * 接続するネットワーク(メインネット/テストネット)を選択可能にするコマンドを追加
    * 軽微な修正


## 2022/09/10　ver. 12.3.5

!!! note ""
    * [9.監視ツールセットアップ](./setup/9-monitoring-tools-setup.md#4grafana) (項目9のJSONファイルを変更)
    * [SPO JAPAN GUILD TOOL](./operation/tool.md) v3.3.0 リリース

## 2022/08/28　ver. 12.3.4

!!! note ""
    * [ノードアップデート手順](./operation/node-update.md)内、エアギャップsecp256k1インストール手順修正

## 2022/08/27　ver. 12.3.3

!!! note ""
    * logMonitor.sh取得先を変更 

## 2022/08/27　ver. 12.3.2

!!! note ""
    * [ノードアップデート手順](./operation/node-update.md)一部修正 
    * [SSH認証鍵ファイル生成コード](./setup/1-ubuntu-setup.md#1-3ssh)をSHA2に変更

## 2022/08/25　ver. 12.3.1

!!! note ""
    * [ノードアップデート手順](./operation/node-update.md)一部修正 

## 2022/08/25　ver. 12.3.0
!!! note ""
    * cardano-node v1.35.3 に対応
    * エアギャップ作成手順更新
    * [ノードアップデート手順](./operation/node-update.md)更新
    * [SFTPソフト設定手順](./operation/sftp.md)追加    

## 2022/07/24　ver. 12.2.0
!!! note ""
    * [RSYNC+SSHサーバー間転送設定](./operation/rsync-ssh.md)手順追加

## 2022/06/06　ver. 12.1.1
!!! note ""
    * envファイルのCCLI行にRTSフラグを追加
    * 軽微な修正

## 2022/05/30　ver. 12.1
!!! note ""
    * [ノード起動スクリプト](../setup/2-node-setup/#2-4)コードを修正   
    　ノード起動コマンドにガベージコレクション問題に対応したRTSオプションを追加

## 2022/05/10　ver. 12.0
!!! note ""
    * [エアギャップマシン作成手順](../setup/0-start-guide/#0-4)を追加  
    * [Linuxコマンド集](./operation/command.md)を追加
    * [SJG Tool](./operation/tool.md)のバージョンアップ
    * その他軽微な修正
    

## 2022/04/20　ver. 11.4
!!! note ""
    * ノード起動・再起動・停止エイリアスコマンド追加  
    ([2-ノードインストール](./setup/2-node-setup.md#2-6-systemd))
    * 寄付先アドレスに[ada $handle](http://49.12.225.142:8000/setup/99-donation-credit/)を追加


## 2022/04/14　ver. 11.3
!!! note ""
    * [SPO JAPAN GUILD TOOL](./operation/tool.md)をリリース

## 2022/04/07　ver. 11.2
!!! note ""
    * payment.addrにネイティブトークンが含まれている場合のTx送信エラー修正  
    [プール情報の更新](./operation/cert-update.md) / [資金引き出し](./operation/withdrawal.md) / [プール廃止](./operation/pool-retire.md)  
    * [運用ガイド](./operation/start-guide.md)内リンク修正

## 2022/03/11　ver. 11.1
!!! note ""
    * [8-P2Pトポロジー設定](./setup/8.topology-setup.md) に[ノード起動最終調整](./setup/8.topology-setup.md#_4)を追加しました。

## 2022/03/07　ver. 11.0
!!! note ""
    * cardano-node v1.34.1 に対応

## 2022/03/01　ver. 10.0
!!! note ""
    * カルダノステークプール構築手順日本語翻訳を刷新し、「SPO JAPAN GUILD DOCS」として生まれ変わりました！