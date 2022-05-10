

!!! hint ""
    [[WYAM] WYAM-StakePool](https://adapools.org/pool/940d6893606290dc6b7705a8aa56a857793a8ae0a3906d4e2afd2119) Akyoさんからご提供いただきました。ありがとうございます！

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

## **ブロックチェックサービス再起動**
```
sudo systemctl reload-or-restart cnode-blockcheck.service
```

## **パラメータファイル更新**
**補足**
- バックアップ及び更新、確認
```
cd $NODE_HOME
date=`date +\%Y\%m\%d`
mv params.json params-$date.json
cardano-cli query protocol-parameters \
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