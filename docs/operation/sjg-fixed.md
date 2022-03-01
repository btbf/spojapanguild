# SJG 修正プログラム

## **envファイル対応**

!!! info ""
    最終更新日：2022/02/19 v1.0


**概要**

**■発生事象**  
gliveview.sh/cncli.sh実行時に、実行したディレクトリにenv/gliveview.sh/cncli.shが生成されてしまう。

**■原因**  
env内のアップデート関数処理変更に伴うもの

**■修正プログラム内容**  
⇒.bashrc内aliasに設定中の変数(glive/blocks)のコマンドを変更  
⇒cncli系サービスファイルのWorkingDirectoryを変更

**■対象者**
* プール構築中でブロックログの設定まで完了した方
* プール運営中SPOの方

**■対象サーバー**  
BP/リレー  

## **■修正プログラム適用手順**

### BP／リレー共通

**1.修正プログラムをダウンロードする(BP／リレー共通)**
```
cd $NODE_HOME/scripts
wget -q https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/service_fixed.sh -O service_fixed.sh
```

**2.パーミッションを設定し、実行する**
```
chmod 755 service_fixed.sh
./service_fixed.sh
```

**3.プログラムが終了するのを待つ**

**4. bashrcを読み込む**
```
source $HOME/.bashrc
```


**5.修正プログラムを削除する**
```
cd $NODE_HOME/scripts
rm service_fixed.sh
```

**6.アップデート確認対応**

```
cd $HOME
glive
```
> Script update(s) detected, do you want to download the latest version? (yes/no):***_yes_*** 

**再度、gliveviewを実行する**
```
cd $HOME
glive
```
アップデート確認が出なくなるまで**_yes_** で対応する。


### BPのみ


**9.（BPのみ）各サービスが動いているか確認する**
!!! info ""
    複数のサービスでアップデート確認が表示されている場合がありますが、どれか１つで`yes`にしたら他のサービスでは`no`にしてください  
    例）  
    * tmux a -t cncliでは`yes`  
    `Script update(s) detected, do you want to download the latest version? (yes/no):yes`  
    　  
    * tmux a -t validateでは`no`  
    `Script update(s) detected, do you want to download the latest version? (yes/no):no`


```
tmux a -t cncli
```
```
tmux a -t validate
```
```
tmux a -t leaderlog
```
```
tmux a -t logmonitor
```

!!! info ""
tmux a -t leaderlogは、今回のプログラムでは中断処理を入れてるので以下の表記になっていますが問題ありません。

    > Checking for script updates...  
    > ^C  

    次エポックのスケジュールを取得したい場合は、別途ノードを再起動してください。



お疲れさまでした。