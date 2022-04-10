# SPO JAPAN GUILD TOOL

最終更新日：2022/04/11 v1.2-Beta

!!! info "主な機能"
    * payment.addr 未使用UTXO照会  
    * stake.addr オペレータ報酬照会
    * 報酬・資金出金
    * ブロック生成可能状態/KES整合性チェック
    * プログラム自動更新
    * Mainnet / Testnet 自動認識

## **設定**

**スクリプトダウンロード**
```
cd $NODE_HOME/scripts
wget https://raw.githubusercontent.com/btbf/spojapanguild/master/script/sjgtool.sh -O sjgtool.sh
chmod 755 sjgtool.sh
```

**envファイル修正**

~/cnode/scripts/envファイル内の以下の変数に対し、先頭の#を削除しご自身の環境に合わせてファイル名を設定してください。  
!!! memo ""
    WALLET_PAY_ADDR_FILENAME="payment.addr"  
    WALLET_STAKE_ADDR_FILENAME="stake.addr"  
    POOL_HOTKEY_VK_FILENAME="kes.vkey"  
    POOL_OPCERT_FILENAME="node.cert"  
    POOL_VRF_SK_FILENAME="vrf.skey"  


**envファイル修正　参考スクリプト**
```
sed -i $NODE_HOME/scripts/env \
    -e '1,73s!#WALLET_PAY_ADDR_FILENAME="payment.addr"!WALLET_PAY_ADDR_FILENAME="payment.addr"!' \
    -e '1,73s!#WALLET_STAKE_ADDR_FILENAME="reward.addr"!WALLET_STAKE_ADDR_FILENAME="stake.addr"!' \
    -e '1,73s!#POOL_HOTKEY_VK_FILENAME="hot.vkey"!POOL_HOTKEY_VK_FILENAME="kes.vkey"!' \
    -e '1,73s!#POOL_OPCERT_FILENAME="op.cert"!POOL_OPCERT_FILENAME="node.cert"!' \
    -e '1,73s!#POOL_VRF_SK_FILENAME="vrf.skey"!POOL_VRF_SK_FILENAME="vrf.skey"!'
```

**スクリプトへのパスを通し、任意の単語で起動出来るようにする**
```
echo alias gtool="'cd $NODE_HOME/scripts; ./sjgtool.sh'" >> $HOME/.bashrc
source $HOME/.bashrc
```

TOOLを実行する
```
gtool
```
