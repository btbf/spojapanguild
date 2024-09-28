

!!! hint ""
    [[AKYO] AKYO🥁](https://jp.cexplorer.io/pool/pool1jsxk3ymqv2gdc6mhqk52544g2aun4zhq5wgx6n32l5s3jlne70n) Akyoさんからご提供いただきました。ありがとうございます！

## **ノード停止**
```
sudo systemctl stop cardano-node
```

※[エイリアス](../setup/2-node-setup.md#_1)設定済みの場合
```
cnstop
```

## **ノード起動**
```
sudo systemctl start cardano-node
```

※[エイリアス](../setup/2-node-setup.md#_1)設定済みの場合
```
cnstart
```

## **ノード再起動**
```
sudo systemctl reload-or-restart cardano-node
```

※[エイリアス](../setup/2-node-setup.md#_1)設定済みの場合
```
cnrestart
```

## **サーバ再起動**
**補足**
- ノード停止してから実施しましょう。
```
sudo reboot
```

## **プロセス確認**
**補足**
- カルダノノードサービス
```
ps aux | grep cardano-node
```

## **ネットワーク確認**
```
networkctl status -a
```

## **ネットワーク疎通確認**
```
nc -vz <IP> <Port>
```

## **ブロックログ各サービス再起動**
**補足**
- (cncli / leaderlog / validate / logmonitor)
```
sudo systemctl reload-or-restart cnode-cncli-sync.service
```


## **パラメータファイル更新**
**補足**
- バックアップ及び更新、確認
```
cd $NODE_HOME
date=`date +\%Y\%m\%d`
mv params.json params-$date.json
cardano-cli conway query protocol-parameters \
    --mainnet \
    --out-file params.json
```
```
nano params.json
```

## **TraceMempoolをTrueからFalseにする**
```
cd $NODE_HOME
sed -i ${NODE_CONFIG}-config.json \
    -e "s/TraceMempool\": true/TraceMempool\": false/g"
```
- ノード再起動し設定を反映する
```
sudo systemctl reload-or-restart cardano-node
```

## **TraceMempoolをFalseからTrueにする**

```
cd $NODE_HOME
sed -i ${NODE_CONFIG}-config.json \
    -e "s/TraceMempool\": false/TraceMempool\": true/g"
```
- ノード再起動し設定を反映する
```
sudo systemctl reload-or-restart cardano-node
```

## **既存のスワップファイル削除**
```
cd $HOME
sudo swapoff /swapfile
sudo rm /swapfile
```

## **スワップファイル作成**
**補足**
- 8GBのスワップを設定するコマンド
```
sudo systemctl stop cardano-node
```
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
```
sudo reboot
```

## **SSH接続**
```
ssh -i /Users/ローカルユーザ名/ローカル格納先/id_rsa 接続先ユーザ名@接続先IP -p ポート番号
```

## **systemd活用コマンド**

#### 🗄 ログのフィルタリング

昨日のログ
```bash
journalctl --unit=cardano-node --since=yesterday
```
> コマンド入力に戻る場合は「Ctrl＋C」（ノードは終了しません）

今日のログ
```bash
journalctl --unit=cardano-node --since=today
```
> コマンド入力に戻る場合は「Ctrl＋C」（ノードは終了しません）

期間指定
```bash
journalctl --unit=cardano-node --since='2020-07-29 00:00:00' --until='2020-07-29 12:00:00'
```
> コマンド入力に戻る場合は「Ctrl＋C」（ノードは終了しません）