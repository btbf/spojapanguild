#!/bin/bash
#2022/03/31 v0.1 @btbf

#
# 入力値チェック/セット
#

main () {
clear
update
if [ ${NETWORK_NAME} == "Testnet" ]; then
    networkmagic="--testnet-magic 1097911063"
elif [ ${NETWORK_NAME} == "Mainnet" ]; then
    networkmagic="--mainnet"
else
    networkmagic=""
fi

node_type=`filecheck "$NODE_HOME/$POOL_OPCERT_FILENAME"`


if [ ${node_type} == "true" ]; then
    node_name="BP"
else
    node_name="Relay"
fi

echo '------------------------------------------------'
echo -e ">> SPO JAPAN GUILD TOOL \e[33mv:0.1\e[m \e[32m-${NETWORK_NAME}-\e[m \e[33m-$node_name-\e[m <<"
echo '------------------------------------------------'
echo '
[1] ウォレット操作
[2] KES更新チェック
[3] ブロック生成状態チェック
[0] 終了
'
read -n 1 num
case ${num} in
  1)
    ################################################
    ## ウォレット操作 
    ################################################
    clear
    echo '----------------------------'
    echo '>> ウォレット操作'
    echo '----------------------------'
    echo '
[1] ウォレット残高確認
[2] プール報酬確認
[3] 報酬/資金出金
    '
    read -n 1 wallet
    case ${wallet} in
      1)
        clear
        echo '----------------------------'
        echo '>> ウォレット残高確認'
        echo '----------------------------'
        echo
        efile_check=`filecheck "$NODE_HOME/$WALLET_PAY_ADDR_FILENAME"`
        if [ ${efile_check} == "true" ]; then
          echo "■paymentアドレス"
          echo "$(cat $WALLET_PAY_ADDR_FILENAME)"
          cardano-cli query utxo \
            --address $(cat $WALLET_PAY_ADDR_FILENAME) \
            $networkmagic
        else
          echo "$WALLET_PAY_ADDR_FILENAMEファイルが見つかりません"
          echo
          echo "$NODE_HOMEに$WALLET_PAY_ADDR_FILENAMEをコピーするか"
          echo "envファイルのWALLET_PAY_ADDR_FILENAME変数の指定値をご確認ください"
        fi
        select_rtn
        ;;
      2)
        clear
        echo '----------------------------'
        echo '>> プール報酬確認'
        echo '----------------------------'
        echo
        efile_check=`filecheck "$NODE_HOME/$WALLET_STAKE_ADDR_FILENAME"`
        if [ ${efile_check} == "true" ]; then
          echo "■stakeアドレス"
          echo "$(cat $WALLET_STAKE_ADDR_FILENAME)"
          stake_json=`cardano-cli query stake-address-info --address $(cat $WALLET_STAKE_ADDR_FILENAME) $networkmagic > $NODE_HOME/scripts/stake_json.txt`
          pool_reward=`cat $NODE_HOME/scripts/stake_json.txt | grep rewardAccountBalance`
          #echo $pool_reward
          pool_reward_split=(${pool_reward//,/})
          pool_reward_Amount=`scale1 ${pool_reward_split[1]}`
          echo "報酬額:$pool_reward_Amount ADA (${pool_reward_split[1]})"
          rm $NODE_HOME/scripts/stake_json.txt
        else
          echo "$WALLET_STAKE_ADDR_FILENAMEファイルが見つかりません"
          echo
          echo "$NODE_HOMEに$WALLET_STAKE_ADDR_FILENAMEをコピーするか"
          echo "envファイルのWALLET_STAKE_ADDR_FILENAME変数の指定値をご確認ください"
        fi
        select_rtn
        ;;
      3)
        clear
        echo '----------------------------'
        echo '>> 報酬/資金出金'
        echo '----------------------------'
        echo 
        echo '■プール報酬出金(stake.addr)
----------------------------
[1] 任意のアドレスへ出金
[2] payment.addrへ出金

■プール資金出金(payment.addr)
----------------------------
[3] 任意のアドレスへ出金
    '
        read -n 1 withdrawl
        case ${withdrawl} in
          #[START] payment.addr ⇒ 任意のアドレス [START] 

          1)
            clear
            echo '------------------------------------------------------------------------'
            echo "資金移動"
            echo -e ">> \e[33mstake.addr\e[m から \e[33m任意のアドレス\e[m への出金"
            echo
            echo "■ 注意 ■"
            echo "報酬は全額引き出しのみとなります"
            echo '------------------------------------------------------------------------'
            efile_check=`filecheck "$NODE_HOME/$WALLET_STAKE_ADDR_FILENAME"`
            if [ ${efile_check} == "true" ]; then
              #stake.addr残高算出
              echo
              reward_Balance
              
              #出金先アドレスチェック
              send_address


              #現在のスロット
              current_Slot

              #ウォレット残高とUTXO参照
              payment_utxo

              withdrawalString="$(cat stake.addr)+${rewardBalance}"

              #トランザクションファイル仮作成
              cardano-cli transaction build-raw \
              ${tx_in} \
              --tx-out $(cat payment.addr)+0 \
              --tx-out ${destinationAddress}+0 \
              --invalid-hereafter $(( ${currentSlot} + 10000)) \
              --fee 0 \
              --withdrawal ${withdrawalString} \
              --out-file tx.tmp

              #手数料計算
              fee=$(cardano-cli transaction calculate-min-fee \
                  --tx-body-file tx.tmp \
                  --tx-in-count ${txcnt} \
                  --tx-out-count 2 \
                  $networkmagic \
                  --witness-count 2 \
                  --byron-witness-count 0 \
                  --protocol-params-file params.json | awk '{ print $1 }')


              #残高-手数料-出金額
              txOut=$((${total_balance}-${fee}))
              #echo Change Output: ${txOut}

              tx_Check $destinationAddress ${rewardBalance} $fee ${txOut}


              #最終トランザクションファイル作成
              cardano-cli transaction build-raw \
              ${tx_in} \
              --tx-out $(cat payment.addr)+${txOut} \
              --tx-out ${destinationAddress}+${rewardBalance} \
              --invalid-hereafter $(( ${currentSlot} + 10000)) \
              --fee ${fee} \
              --withdrawal ${withdrawalString} \
              --out-file tx.raw

              #エアギャップ操作メッセージ
              air_gap
              
              #トランザクション送信
              tx_submit
            else
              echo "$WALLET_STAKE_ADDR_FILENAMEファイルが見つかりません"
              echo
              echo "$NODE_HOMEに$WALLET_STAKE_ADDR_FILENAMEをコピーするか"
              echo "envファイルのWALLET_STAKE_ADDR_FILENAME変数の指定値をご確認ください"
            fi

            select_rtn
            ;;
          2)
            clear
            echo '------------------------------------------------------------------------'
            echo "資金移動"
            echo -e ">> \e[33mstake.addr\e[m から \e[33mpayment.addr\e[m への出金"
            echo
            echo "■ 注意 ■"
            echo "報酬は全額引き出しのみとなります"
            echo '------------------------------------------------------------------------'
            payfile_check=`filecheck "$NODE_HOME/$WALLET_PAY_ADDR_FILENAME"`
            stakefile_check=`filecheck "$NODE_HOME/$WALLET_STAKE_ADDR_FILENAME"`
            if [ ${payfile_check} == "true" ] && [ ${stakefile_check} == "true" ]; then
              #stake.addr残高算出
              reward_Balance

              #現在のスロット
              current_Slot

              #payment.addr
              destinationAddress=$(cat payment.addr)
              echo 出金先: $destinationAddress

              #ウォレット残高とUTXO参照
              payment_utxo

              withdrawalString="$(cat stake.addr)+${rewardBalance}"

              #トランザクションファイル仮作成
              cardano-cli transaction build-raw \
              ${tx_in} \
              --tx-out $(cat payment.addr)+0 \
              --invalid-hereafter $(( ${currentSlot} + 10000)) \
              --fee 0 \
              --withdrawal ${withdrawalString} \
              --out-file tx.tmp

              #手数料計算
              fee=$(cardano-cli transaction calculate-min-fee \
                  --tx-body-file tx.tmp \
                  --tx-in-count ${txcnt} \
                  --tx-out-count 1 \
                  $networkmagic \
                  --witness-count 2 \
                  --byron-witness-count 0 \
                  --protocol-params-file params.json | awk '{ print $1 }')
              

              #残高-手数料-出金額
              txOut=$((${total_balance}-${fee}+${rewardBalance}))
              #echo Change Output: ${txOut}

              tx_Check $destinationAddress ${rewardBalance} $fee ${txOut}

              #最終トランザクションファイル作成
              cardano-cli transaction build-raw \
                ${tx_in} \
                --tx-out $(cat payment.addr)+${txOut} \
                --invalid-hereafter $(( ${currentSlot} + 10000)) \
                --fee ${fee} \
                --withdrawal ${withdrawalString} \
                --out-file tx.raw

              #エアギャップ操作メッセージ
              air_gap
              
              #トランザクション送信
              tx_submit

            else
              echo "$WALLET_STAKE_ADDR_FILENAMEまたは$WALLET_PAY_ADDR_FILENAMEファイルが見つかりません"
              echo
              echo "$NODE_HOMEに$WALLET_STAKE_ADDR_FILENAMEまたは$WALLET_PAY_ADDR_FILENAMEをコピーするか"
              echo "envファイルのWALLET_STAKE_ADDR_FILENAMEまたは"
              echo "WALLET_PAY_ADDR_FILENAME変数の指定値をご確認ください"
            fi

            select_rtn
            ;;
          3)
            clear
            echo '------------------------------------------------------------------------'
            echo "資金移動"
            echo -e ">> \e[33mpayment.addr\e[m から \e[33m任意のアドレス\e[m への出金"
            echo
            echo "■ 注意 ■"
            echo "payment.addrには誓約で設定した額以上のADAが入金されてる必要があります"
            echo "出金には十分ご注意ください"
            echo '------------------------------------------------------------------------'
            efile_check=`filecheck "$NODE_HOME/$WALLET_PAY_ADDR_FILENAME"`
            if [ ${efile_check} == "true" ]; then
              #出金先アドレスチェック
              echo
              send_address
              
              #出金額指定
              clear
              echo '------------------------------------------------------------------------'
              echo -e ">> \e[33mpayment.addr\e[m から \e[33m任意のアドレス\e[m への出金"
              echo '------------------------------------------------------------------------'
              echo
              echo "出金額をlovelaces形式で入力してください"
              echo '1 ADA = 1,000,000'
              echo
              read -p "出金額： > " amountToSend
              cal_amount=`scale1 $amountToSend`
              echo

              #現在のスロット
              current_Slot

              #ウォレット残高とUTXO参照
              payment_utxo
              
              #echo UTXOs: ${txcnt}

              #トランザクションファイル仮作成
              cardano-cli transaction build-raw \
                  ${tx_in} \
                  --tx-out $(cat $WALLET_PAY_ADDR_FILENAME)+0 \
                  --tx-out ${destinationAddress}+0 \
                  --invalid-hereafter $(( ${currentSlot} + 10000)) \
                  --fee 0 \
                  --out-file tx.tmp

              #手数料計算
              fee=$(cardano-cli transaction calculate-min-fee \
              --tx-body-file tx.tmp \
              --tx-in-count ${txcnt} \
              --tx-out-count 2 \
              $networkmagic \
              --witness-count 1 \
              --byron-witness-count 0 \
              --protocol-params-file params.json | awk '{ print $1 }')


              #残高-手数料-出金額
              txOut=$((${total_balance}-${fee}-${amountToSend}))
              
              tx_Check $destinationAddress $cal_amount $fee ${txOut}

              #printf "$rows" "出金後残高:" "`scale1 ${txOut}` ADA"

              #最終トランザクションファイル作成
              cardano-cli transaction build-raw \
                  ${tx_in} \
                  --tx-out $(cat payment.addr)+${txOut} \
                  --tx-out ${destinationAddress}+${amountToSend} \
                  --invalid-hereafter $(( ${currentSlot} + 10000)) \
                  --fee ${fee} \
                  --out-file tx.raw
              
              #エアギャップ操作メッセージ
              air_gap
              
              #トランザクション送信
              tx_submit
            else
              echo "$WALLET_PAY_ADDR_FILENAMEファイルが見つかりません"
              echo
              echo "$NODE_HOMEに$WALLET_PAY_ADDR_FILENAMEをコピーするか"
              echo "envファイルのWALLET_PAY_ADDR_FILENAME変数の指定値をご確認ください"
            fi

            select_rtn
            ;;
          #[END] payment.addr ⇒ 任意のアドレス [END] 
          *)
            echo '番号が不正です'
            select_rtn
            ;;
        esac
        ;;
      *)
        echo '番号が不正です'
        select_rtn
        ;;
    esac
    ;;
  2)
    DOMAIN='b.example.com'
    CF_ID='xxxxx'
    echo $DOMAIN
    ;;
  3)
    DOMAIN='b.example.com'
    CF_ID='xxxxx'
    echo $DOMAIN
    ;;
  0)
    exit
    ;;
  *)
    echo '番号が不正です'
    main
    ;;
esac
}

################################################
## 関数 
################################################
select_rtn(){
  echo
  echo '[h] メイン画面へ戻る　[q] 終了'
  echo
  read -n 1 retun_cmd
  case ${retun_cmd} in
    h) main ;;
    q) 
      clear
      echo
      echo "SPO JAPAN GUILD TOOL Closed!" 
      echo
      exit ;;
  esac
}

air_gap(){
  echo
  echo
  echo '■エアギャップ操作'
  echo
  echo -e "\e[33m1. tx.raw をエアギャップのcnodeディレクトリにコピーしてください\e[m"
  echo '----------------------------------------'
  echo ">> [BP] ⇒ tx.raw ⇒ [エアギャップ]"
  echo '----------------------------------------'
  echo
  echo -e "\e[33m2. エアギャップでトランザクションファイルに署名してください\e[m"
  echo '----------------------------------------'
  echo 'cd $NODE_HOME'
  echo 'cardano-cli transaction sign \'
  echo '  --tx-body-file tx.raw \'
  echo '  --signing-key-file payment.skey \'
  echo '  --signing-key-file stake.skey \'
  echo "  $networkmagic "'\'
  echo '  --out-file tx.signed'
  echo '----------------------------------------'
  echo
  echo -e "\e[33m3. エアギャップの tx.signed をBPのcnodeディレクトリにコピーしてください\e[m"
  echo '----------------------------------------'
  echo ">> [エアギャップ] ⇒ tx.signed ⇒ [BP]"
  echo '----------------------------------------'
  echo
  echo "1~3の操作が終わったらEnterを押してください"
  read Wait
}

#ファイル存在確認
filecheck(){
  if [ -f ${1} ]; then
    file_CHK="true"
  else
    file_CHK="false"
  fi
  echo $file_CHK
}

############################################
# 出金フロー関数
############################################
#共通
#stake.addr残高確認
reward_Balance(){
  cd $NODE_HOME
    rewardBalance=$(cardano-cli query stake-address-info \
        $networkmagic \
        --address $(cat stake.addr) | jq -r ".[0].rewardAccountBalance")
    echo "プール報酬: `scale1 $rewardBalance` ADA"

  if [ ${rewardBalance} == 0 ]; then
    echo "出金可能な報酬はありません"
    select_rtn
  fi
}


#現在のスロット
current_Slot(){
  currentSlot=$(cardano-cli query tip $networkmagic | jq -r '.slot')
  #echo Current Slot: $currentSlot
}

#payment.addrUTXO算出
payment_utxo(){
  cardano-cli query utxo \
    --address $(cat $WALLET_PAY_ADDR_FILENAME) \
    $networkmagic > fullUtxo.out

  tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

  tx_in=""
  total_balance=0
  while read -r utxo; do
      in_addr=$(awk '{ print $1 }' <<< "${utxo}")
      idx=$(awk '{ print $2 }' <<< "${utxo}")
      utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
      total_balance=$((${total_balance}+${utxo_balance}))
      #echo TxHash: ${in_addr}#${idx}
      #echo ADA: ${utxo_balance}
      tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
  done < balance.out
  txcnt=$(cat balance.out | wc -l)
}

#トランザクション送信
tx_submit(){
  echo
  echo '[1] Txを送信する　[2] キャンセル'
  echo
  read -n 1 retun_cmd
  case ${retun_cmd} in
    1) 
      tx_result=`cardano-cli transaction submit --tx-file tx.signed $networkmagic`
      echo
      if [[ $tx_result == "Transaction"* ]]; then
        echo '----------------------------------------'
        echo 'Tx送信結果'
        echo '----------------------------------------'
        echo $tx_result
        echo
        echo 'Tx送信に成功しました。'
      else
        echo '----------------------------------------'
        echo 'Tx送信結果'
        echo '----------------------------------------'
        echo $tx_result
        echo
        echo 'Tx送信に失敗しました'
      fi
      ;;
    2) 
      echo
      echo "送信をキャンセルしました"
      echo
      select_rtn
      echo
  esac

}

#出金先アドレスチェック
send_address(){
  while :
    do
      read -p "出金先のアドレスを入力してください： > " destinationAddress
      if [[ "$destinationAddress" == *addr* ]]; then

        echo
        echo '------------------------------------------------'
        echo 出金先: $destinationAddress
        echo '------------------------------------------------'
        echo

        read -n 1 -p "出金先はこちらでよろしいですか？：(y/n) > " send_check
        if [ "$send_check" == "y" -o "$send_check" == "Y" ]; then
            break 1
        else
          echo
          echo "出金先アドレスを再度入力してください"
          continue 1
        fi

      else
          echo
          echo "出金先アドレスを再度入力してください"
      fi
  done
}

#出金前チェック
tx_Check(){
  rows="%15s %-15s\n"
  #printf "$rows" "Send_Address:" "${destinationAddress::20}...${destinationAddress: -20}"
  printf "$rows" "Send_Address:" "$destinationAddress"
  printf "$rows" "Send_ADA:" "$cal_amount ADA"
  printf "$rows" "Tx fee:" "`scale3 $fee` ADA"
  printf "$rows" "Wallet_Amount:" "`scale1 ${total_balance}` ADA"

}

#loverace変換
scale1(){
  r_amount=`echo "scale=1; $1 / 1000000" | bc`
  echo $r_amount
}

scale3(){
  r_amount=`echo "scale=3; $1 / 1000000" | bc | awk '{printf "%.5f\n", $0}'`
  echo $r_amount
}

update(){
  cd /tmp/cnode
  wget https://raw.githubusercontent.com/btbf/spojapanguild/master/script/sjgtool.sh -O sjgtool.sh.tmp
  tmp256=`sha256sum sjgtool.sh.tmp`
  sh256=`sha256sum $NODE_HOME/scripts/sjgtool.sh`
  arr_tmp256=(${tmp256//,/})
  arr_sh256=(${sh256//,/})
  
  echo ${arr_tmp256[0]}
  echo
  echo ${arr_sh256[0]}


  if [[ ! ${arr_tmp256[0]} == ${arr_sh256[0]} ]]; then
  cd $NODE_HOME/scripts
  wget -q https://raw.githubusercontent.com/btbf/spojapanguild/master/script/sjgtool.sh -O sjgtool.sh
  ./sjgtool.sh
  fi
  rm sjgtool.sh.tmp
}


source ./env
cd $NODE_HOME

#ノード起動確認
node_check=`ps -ef | grep cardano-node | grep -v grep | wc -l`
echo $node_check
clear
if [ ${node_check} == "1" ]; then
  while :
  do
    slot_check=`curl -s localhost:12798/metrics | grep slotNum_int`
    if [ -z "$slot_check" ]; then
        echo "ノードが起動するまでこのままお待ちください"
        sleep 30
    else
      main;
      break
    fi
  
  done
    
else 
    echo "ノードを起動して再度実行してください"
    exit
fi
