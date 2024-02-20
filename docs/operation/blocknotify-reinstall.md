#　SPO Block Notify移行マニュアル

!!! note "このマニュアルについて"
    このマニュアルは「ブロック生成ステータス通知 v.1.x.x」から「SPO Block Notify v.2.x.x」へ移行するマニュアルとなっております。

    SPO Block Notifyを新規インストールする場合は[11.SPO BlockNotify設定](../setup/11-blocknotify-setup.md)をご参照ください。

## 1. サービスファイルを修正する

* サービスを停止する
```
sudo systemctl stop cnode-cncli-sync.service
```

* 新しいサービスファイルを作成する

