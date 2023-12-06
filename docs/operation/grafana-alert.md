# Grafanaアラート設定

!!! note "概要"
    サーバー異常状態発生時に任意のアプリへ通知を送信する設定です。  
    サーバー監視には必須設定となります。

## 1.事前確認

* Grafanaバージョンv9.4.1以上
* Grafana [SJG最新ダッシュボード](../setup/9-monitoring-tools-setup.md#9-4grafana)適用済み

### Grafanaバージョン確認

```
grafana-cli -v
```

### Grafanaアップデート
```
sudo apt update -y && sudo apt upgrade -y
```

## 2.アラートルールの作成

通知の基準となるアラートルールを作成します。  

1.「左サイドメニュー」→「Alerting」の右の矢印→「Alert rules」→「New alert rule」の順にクリックする
![](../images/grafana-alert/1-0.png)

### 2-1.ノードスロット監視

* ①:`Relay1-スロット監視`など任意のルール名
* ②:`Metrics Browser`をクリック
* ③:`cardano_node_metrics_slotInEpoch_int`を選択
* ④:`alias`が選択されていることを確認
* ⑤:監視するノード名を選択
* ⑥:`Use query`をクリック
![](../images/grafana-alert/1-1.png)

* ⑦:`B`のゴミ箱マークをクリック
* ⑧:`C`のゴミ箱マークをクリック
* ⑨:`Add expression`をクリックし、`Classic_condition`を選択
![](../images/grafana-alert/1-2.png)

* ⑩:`last() / A / HAS NO VALUE`選択
* ⑪:`Set as alert condition`をクリックし、`Alert condition`の表示に変える
* ⑫:`New folder`を選択し、`SJG`を入力して`Create`
* ⑬:`New evaluation group`を選択し、`Evaluation group name`に`ノード監視`、`Evaluation interval`に`10s`を入力して`Create`
* ⑭:`20s`を入力
* ⑮:`Alerting`を選択
* ⑯:`Alerting`を選択
![](../images/grafana-alert/1-3.png)

* ⑰:`Add custom annotaion`を選択
* ⑱:`検知内容`を入力
* ⑲:フィールドに検知メッセージを入力
例）`Relay1のスロットを取得出来ませんでした。ノード起動状態を確認してください`
* ⑳:ページ上部の`Save rule and exit`を選択
![](../images/grafana-alert/1-4.png)


残りの全てのノードのスロット監視を設定する  

上記で作成したルールをコピーする
![](../images/grafana-alert/1-5.png)

* ①を書き換える
* ②:`Metrics Browser`を書き換える  
例）  
`cardano_node_metrics_slotInEpoch_int{alias="block-producing-node"}`  
`cardano_node_metrics_slotInEpoch_int{alias="relaynode2"}`

* 「4 Add annotations」の検知内容のメッセージ内容を書き換える
* ⑳:ページ上部の`Save rule and exit`を選択



### 2-2.BP→リレー接続監視
上記で作成したルールをコピーする
![](../images/grafana-alert/1-5.png)

* ①:`BPリレー接続監視`など任意のルール名に書き換える
* ②:`Metrics Browser`を`cardano_node_metrics_peers_connectedPeers_int{alias="block-producing-node"}`に置き換える
* ⑩:`last()` / `A` / `IS BELOW`に切り替え`1`を入力
* ⑮:`Alerting`を選択
* ⑯:`Alerting`を選択
* 「4 Add annotation」の検知内容のメッセージ内容を書き換える  
例）`BPからリレーへの接続が確認できません。接続状況を確認してください`
* ⑳:ページ上部の`Save rule and exit`を選択

### 2-3.チェーン密度監視
上記で作成したルールをコピーする
![](../images/grafana-alert/1-5.png)

* ①:`チェーン密度監視`など任意のルール名に書き換える
* ②:`Metrics Browser`を`cardano_node_metrics_density_real{alias="relaynode1"} * 100`に置き換える
* ⑩:`last()` / `A` / `IS BELOW`に切り替え`4.5`を入力
* ⑮:`OK`を選択
* ⑯:`OK`を選択
* 「4 Add annotation」の検知内容のメッセージ内容を書き換える  
例）`チェーン密度が4.5％を下回っています。これはカルダノチェーン全体の問題です`
* ⑳:ページ上部の`Save rule and exit`を選択

### 2-4.ノードタイム監視
上記で作成したルールをコピーする
![](../images/grafana-alert/1-5.png)

* ①:`Relay1-ノードタイム監視`など任意のルール名に書き換える
* ②:`Metrics Browser`を`node_timex_maxerror_seconds{alias="relaynode1"} * 1000`に置き換える 
* ⑩:`last()` / `A` / `IS ABOVE`に切り替え`100`を入力
* ⑮:`OK`を選択
* ⑯:`OK`を選択
* 「4 Add annotation」の検知内容のメッセージ内容を書き換える  
例）`Relay1のノードタイムが100msを超えています。chronyを再起動してください`
* ⑳:ページ上部の`Save rule and exit`を選択


残り全てのノードのノードタイム監視を設定する  

上記で作成したルールをコピーする
![](../images/grafana-alert/1-5.png)

* ①を書き換える
* ②:`Metrics Browser`を書き換える  
例）  
`node_timex_maxerror_seconds{alias="block-producing-node"} * 1000`  
`node_timex_maxerror_seconds{alias="relaynode2"} * 1000`  

* 「4 Add annotation」の検知内容のメッセージ内容を書き換える
* ⑳:ページ上部の`Save rule and exit`を選択

### 2-5.KES残り日数監視
上記で作成したルールをコピーする
![](../images/grafana-alert/1-5.png)

* ①:`BP-KES残り日数監視`など任意のルール名に書き換える
* ②:`Metrics Browser`を`(cardano_node_metrics_remainingKESPeriods_int * 1.5)`に置き換える
* ⑩:`last()` / `A` / `IS BELOW`に切り替え`10`を入力
* ⑮:`OK`を選択
* ⑯:`OK`を選択
* 「4 Add annotation」の検知内容のメッセージ内容を書き換える  
例）`KESキーの期限が迫っています。ブロック生成予定のないタイミングでKESキーを更新してください`
* ⑳:ページ上部の`Save rule and exit`を選択

### 2-6.ディスク使用率監視
上記で作成したルールをコピーする
![](../images/grafana-alert/1-5.png)

* ①:`Relay1-ディスク使用率監視`など任意のルール名に書き換える
* ②:`Metrics Browser`を`1 - node_filesystem_avail_bytes / node_filesystem_size_bytes{alias="relaynode1",mountpoint="/"}`に置き換える 
* ⑩:`last()` / `A` / `IS ABOVE`に切り替え`0.9`を入力
* ⑮:`OK`を選択
* ⑯:`OK`を選択
* 「4 Add annotation」の検知内容のメッセージ内容を書き換える  
例）`Relay1のディスク使用率が90%を超えています。100%に達する前に契約サーバーのアップグレードなどを行う必要があります`
* ⑳:ページ上部の`Save rule and exit`を選択


残り全てのノードのディスク使用率監視を設定する  

上記で作成したルールをコピーする
![](../images/grafana-alert/1-5.png)

* ①を書き換える
* ②:`Metrics Browser`を書き換える  
例）  
`1 - node_filesystem_avail_bytes / node_filesystem_size_bytes{alias="block-producing-node",mountpoint="/"}`  
`1 - node_filesystem_avail_bytes / node_filesystem_size_bytes{alias="relaynode2",mountpoint="/"}`  

* 「4 Add annotation」の検知内容のメッセージ内容を書き換える
* ⑳:ページ上部の`Save rule and exit`を選択



## 3.通知先アプリの設定

!!! note "通知先アプリの設定"
    アラートの通知先はLINE/Discord/Telegram/Slackを複数指定することが可能です。  
    ブロック生成ステータス通知の[通知アプリ設定](../setup/11-blocknotify-setup.md#11-2)で設定した手順と同様に、通知先名などを変えてトークンを発行してください。  

## 4.通知テンプレート設定

* 「Contact points」をクリックし「Add template」をクリック
![](../images/grafana-alert/1-6.png)

* 任意のテンプレート名`SJG`を入力し、以下のテンプレートデータを入力
```
{{ define "myalert" }}
{{ if gt (len .Annotations) 0 }}{{ range .Annotations.SortedPairs }}{{ .Name }}: {{ .Value }}{{ end }}
{{ end }}{{ end }}


{{ define "mymessage" }}
{{ if gt (len .Alerts.Firing) 0 }} 【 ❌障害発生❌ 】{{len .Alerts.Firing}}件 {{ range .Alerts.Firing }}
{{ template "myalert" .}} {{ end }}{{ end }}
{{ if gt (len .Alerts.Resolved) 0 }}✅以下の障害は復旧しました✅{{len .Alerts.Resolved}}件{{ range .Alerts.Resolved }}
{{ template "myalert" .}} {{ end }}{{ end }}
{{ end }}
```
![](../images/grafana-alert/1-7.png)

* 「Save tempelate」をクリック 

## 5.通知先設定
* 「Add contact point」をクリック
![](../images/grafana-alert/1-8.png)

通知先を指定する

* 任意の通知名`Self-Alert`を入力
* 通知先を選択し情報を入力
* [[3.通知先アプリの設定]](../setup/11-blocknotify-setup.md#11-2)で取得した通知アプリごとのトークンIDやWebhookURLを入力する
* `Option *** Settings`をクリックし`Discription`に以下のタグを入力
```
{{ template "mymessage" . }}
```

!!! hint "通知先ごとのタグ入力欄表記違い"

    * LINE→Description
    * Discord→Message Content
    * Slack→Text Body
    * Telegram→Message

![](../images/grafana-alert/1-9.png)


* 「Save contact point」をクリック

!!! hint "複数の通知先を設定可能"
    「Add contact point integration」をクリックすれば、複数の通知先を設定可能


* 「Notification policies」→「Edit」をクリック
![](../images/grafana-alert/1-10.png)

* `Self-Alert`を選択
* `Group by`に`grafana_folder`と`alertname`を指定
* `Group interval`→ `1 Minutes`に設定
* `Repeat interval`→ `10 Minutes`に設定
* 「Update default policy」をクリック
![](../images/grafana-alert/1-11.png)



## 6.通知内容URLカスタマイズ

!!! note "注意"
    * 事前に[Grafanaセキュリティ設定](./grafana-security.md)を実施してください
    * 以下はGrafanaインストールサーバーで実施してください


`xxxx.bbb.com`を[[Grafanaセキュリティ設定]](./grafana-security.md#1)で取得したドメイン(サブドメイン)に置き換えて実行する  
`https://`は不要
```
domain=xxxx.bbb.com
```

以下コマンドをすべてコピーして実行する
```
sudo sed -i /etc/grafana/grafana.ini \
    -e 's!;domain = localhost!domain = '${domain}'!' \
    -e 's!;root_url = %(protocol)s://%(domain)s:%(http_port)s/!root_url = https://%(domain)s/!'
```

Grafanaを再起動する
```
sudo systemctl restart grafana-server.service
```
