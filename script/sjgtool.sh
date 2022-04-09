#!/bin/bash
#
# 入力値チェック/セット
#

TOOL_VERSION=1.0

# General exit handler
cleanup() {
  [[ -n $1 ]] && err=$1 || err=$?
  [[ $err -eq 0 ]] && clear
  tput cnorm # restore cursor
  [[ -n ${exit_msg} ]] && echo -e "\n${exit_msg}\n" || echo -e "\nSPO JAPAN GUILD TOOLを終了しました。\n"
  tput sgr0  # turn off all attributes
  exit $err
}
trap cleanup HUP INT TERM
trap 'stty echo' EXIT

# Command     : myExit [exit code] [message]
# Description : gracefully handle an exit and restore terminal to original state
myExit() {
  exit_msg="$2"
  cleanup "$1"
}



main () {
clear
update
if [ $? == 1 ]; then
  cd $NODE_HOME/scripts
  $0 "$@" "-u"
  myExit 0
fi

if [ ${NETWORK_NAME} == "Testnet" ]; then
    networkmagic="--testnet-magic 1097911063"
    koios="testnet"
    config_name="testnet"
elif [ ${NETWORK_NAME} == "Mainnet" ]; then
    networkmagic="--mainnet"
    koios="api"
    config_name="mainnet"
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
echo -e ">> SPO JAPAN GUILD TOOL \e[33mver.1.0\e[m \e[32m-${NETWORK_NAME}-\e[m \e[33m-$node_name-\e[m <<"
echo '------------------------------------------------'
echo '
[1] ウォレット操作
[2] ブロック生成状態チェック
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
          pool_reward=`cat $NODE_HOME/scripts/stake_json.txt | grep rewardAccountBalance | awk '{ print $2 }'`
          #echo $pool_reward
          pool_reward_Amount=`scale1 $pool_reward`
          echo "報酬額:$pool_reward_Amount ADA ($pool_reward)"
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
              

              while :
              do
                read -p "出金額： > " amountToSend
                if [[ "$amountToSend" -ge 1000000 ]]; then
                  cal_amount=`scale1 $amountToSend`
                  break
                else
                    echo
                    echo "出金額は1000000 Lovelaces(1ADA)以上を指定してください"
                    echo
                fi
              done

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
    clear
    log_file="$HOME/dirname-`date +'%Y-%m-%d_%H-%M-%S'`.log"
    echo '------------------------------------------------------------------------'
    echo -e "> BPブロック生成可能状態チェック"
    echo '------------------------------------------------------------------------'
    idfile_check=`filecheck "$NODE_HOME/stakepoolid_bech32.txt"`
    if [ $idfile_check == "false" ]; then
      echo "stakepoolid_bech32.txtが見つかりません"
      echo "エアギャップで作成し、$NODE_HOMEにコピーしてください"
      echo
      echo "エアギャップ stakepoolid_bech32.txt作成コマンド"
      echo '---------------------------------------------------------------'
      echo 'cardano-cli stake-pool id \'
      echo    '--cold-verification-key-file $HOME/cold-keys/node.vkey \'
      echo    '--output-format bech32 > $NODE_HOME/stakepoolid_bech32.txt'
      echo '---------------------------------------------------------------'
      select_rtn
    fi

    mempool_CHK=`cat $CONFIG | jq ".TraceMempool"`


    #APIリクエストクエリjson生成
    pId_json="{\""_pool_bech32_ids"\":[\""$(cat $NODE_HOME/stakepoolid_bech32.txt)"\"]}"

    #API プールデータ取得
    curl -s -X POST "https://$koios.koios.rest/api/v0/pool_info" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d $pId_json > $NODE_HOME/pooldata.txt
    wait

    pooldata_chk=`cat pooldata.txt`
    if [[ $pooldata_chk != *"pool_id_bech32"* ]]; then
      echo "APIからプールデータを取得できませんでした。再度お試しください"
      select_rtn
    fi

    #メトリクスKES
    metrics_KES=`curl -s localhost:12798/metrics | grep remainingKES | awk '{ print $2 }'`
    Expiry_KES=`curl -s localhost:12798/metrics | grep ExpiryKES | awk '{ print $2 }'`
    Start_KES=`curl -s localhost:12798/metrics | grep StartKES | awk '{ print $2 }'`
    current_KES=`curl -s localhost:12798/metrics | grep currentKES | awk '{ print $2 }'`

    if [ -z "$metrics_KES" ]; then
      echo "KESメトリクスを取得できませんでした"
      echo "このノードがBPであることを確認してください"
      select_rtn
    fi

    active_ST_check(){
      if [ $1 != 0 ]; then
        printf "\e[36m`scale1 $1`\e[m ADA"
      else
        printf "$1 ADA \n (ライブステークが有効になるまでスケジュール割り当てはありません)\n"
      fi
    }
    live_Stake=`cat $NODE_HOME/pooldata.txt | jq -r ".[].live_stake"`
    live_Stake=`scale1 $live_Stake`
    active_Stake=`cat $NODE_HOME/pooldata.txt | jq -r ".[].active_stake"`

    active_Stake=`active_ST_check $active_Stake`
    
    printf "ノード起動タイプ:BP \e[32mOK\e[m　ネットワーク:\e[33m$NETWORK_NAME\e[m\n"
    echo
    printf "　　対象プール :\e[36m[`cat $NODE_HOME/pooldata.txt | jq -r ".[].meta_json.ticker"`] `cat $NODE_HOME/pooldata.txt | jq -r ".[].meta_json.name"`\e[m\n"
    printf "　　　プールID :\e[36m`cat $NODE_HOME/pooldata.txt | jq -r ".[].pool_id_bech32"`\e[m\n"
    printf "ライブステーク :\e[32m$live_Stake\e[m ADA\n"
    printf "　有効ステーク :$active_Stake\n"


   #ノード起動スクリプトファイル名読み取り
    exec_path=`grep -H "ExecStart" /etc/systemd/system/cardano-node.service`
    exec_path=${exec_path##*/}
    script_name=${exec_path/%?/}
    script_path="$NODE_HOME/$script_name"
    script_path=$script_path

    #起動スクリプトからBP起動ファイル読み取り
    kes_path=`grep -H "KES=" $script_path`
    vrf_path=`grep -H "VRF=" $script_path`
    cert_path=`grep -H "CERT=" $script_path`
    echo
    printf "\e[35m■BPファイル存在確認\e[m\n"
    if [ $kes_path ]; then
      kes_name=${kes_path##*/}
      kes_CHK=`filecheck "$NODE_HOME/$kes_name"`
      if [ $kes_CHK == "true" ]; then
        printf "　 $kes_name: \e[32mOK\e[m\n"
      else
        printf "　 $kes_name: \e[31mNG\e[m\n"
      fi

    else
      kes_name=""
      kes_CHK="$NODE_HOME/relay"
      echo kesファイルはありません
    fi

    if [ $vrf_path ]; then
      vrf_name=${vrf_path##*/}
      vrf_CHK=`filecheck "$NODE_HOME/$vrf_name"`
      if [ $vrf_CHK == "true" ]; then
        printf "　 $vrf_name: \e[32mOK\e[m\n"
      else
        printf "　 $vrf_name: \e[31mNG\e[m\n"
      fi

    else
        vrf_name=""
        vrf_CHK="$NODE_HOME/relay"
        echo vrfファイルはありません
    fi

    if [ $cert_path ]; then
    cert_name=${cert_path##*/}
    cert_CHK=`filecheck "$NODE_HOME/$cert_name"`
      if [ $cert_CHK == "true" ]; then
        printf "　$cert_name: \e[32mOK\e[m\n"
      else
        printf "　$cert_name: \e[31mNG\e[m\n"
      fi

    else
      cert_name=""
      cert_CHK="$NODE_HOME/relay"
      echo certファイルはありません
    fi

    #ノード同期状況確認
    #APIから最新ブロックNo取得
    koios_blockNo=`curl -s -X GET "https://$koios.koios.rest/api/v0/tip" -H "Accept: application/json" | grep -E -o "\"block_no\":[0-9A-Za-z]{7,}"`
    koios_blockNo=${koios_blockNo#"\"block_no\":"}
    

    #ノードから同期済みブロック取得
    currentblock=$(cardano-cli query tip $networkmagic | jq -r '.block')
    

    block_diff=$koios_blockNo-$currentblock
    if [[ $block_diff -ge 2 ]]; then
      clear
      echo
      echo "ノードが最新ブロックに同期してから再度ご確認ください"
      select_rtn
    else
      echo
      printf "\e[35m■ノード同期状況\e[m： \e[32mOK\e[m\n"
      printf "　  ネットワーク最新ブロック :\e[33m$koios_blockNo\e[m\n"
      printf "　ローカルノード最新ブロック :\e[33m$currentblock\e[m\n"
    fi

    #メトリクスTx数
    metrics_tx=`curl -s localhost:12798/metrics | grep txsProcessedNum_int | awk '{ print $2 }'`

    tx_chk(){
      if [[ "$2" != "false" ]] && [ $1 == " " ] ; then
        if [[ "$2" = "true" ]] && [[ $1 > 0 ]]; then
          printf "\e[32mOK\e[m"
        else
          printf "\e[31mNG\e[m Txが入ってきていません。リレーノードのトポロジーアップデーターを再確認してください\n"
        fi
      else
        printf "\e[32m条件付きOK\e[m"
      fi
    }
  
    tx_count=`tx_chk $metrics_tx $mempool_CHK`
    echo
    printf "\e[35m■Tx流入数\e[m:\e[33m$metrics_tx\e[m $tx_count TraceMempool:\e[33m$mempool_CHK\e[m\n"

    echo
    printf "\e[35m■Peer接続状況\e[m\n"
    peers_in=$(ss -tnp state established 2>/dev/null | grep "${CNODE_PID}," | awk -v port=":${CNODE_PORT}" '$3 ~ port {print}' | wc -l)
    peers_out=$(ss -tnp state established 2>/dev/null | grep "${CNODE_PID}," | awk -v port=":(${CNODE_PORT}|${EKG_PORT}|${PROM_PORT})" '$3 !~ port {print}' | wc -l)

    if [[ $peers_in -eq 0 ]]; then
      peer_in_judge=" \e[31mNG\e[m リレーから接続されていません"
    else
      peer_in_judge=" \e[32mOK\e[m"
    fi
    if [[ $peers_out -eq 0 ]]; then
      peer_out_judge=" \e[31mNG\e[m リレーに接続出来ていません"
    else
      peer_out_judge=" \e[32mOK\e[m"
    fi
    printf "　incoming :\e[33m$peers_in $peer_in_judge\e[m\n"
    printf "　outgoing :\e[33m$peers_out $peer_out_judge\e[m\n"

    chain_Vrf_hash=`cat $NODE_HOME/pooldata.txt | jq -r ".[].vrf_key_hash"`

    #ローカルVRFファイル検証
    mkdir $NODE_HOME/vrf_check
    cp $NODE_HOME/vrf.skey $NODE_HOME/vrf_check/
    cardano-cli key verification-key --signing-key-file $NODE_HOME/vrf_check/vrf.skey --verification-key-file $NODE_HOME/vrf_check/vrf.vkey
    cardano-cli node key-hash-VRF --verification-key-file $NODE_HOME/vrf_check/vrf.vkey --out-file $NODE_HOME/vrf_check/vkeyhash.txt
    local_vrf_hash=$(cat $NODE_HOME/vrf_check/vkeyhash.txt)
    
    if [ $chain_Vrf_hash == $local_vrf_hash ]; then
      hash_check=" \e[32mOK\e[m\n"
    else
      hash_check=" \e[31mNG\e[m\n"
    fi

    echo
    printf "\e[35m■VRFハッシュ値チェック\e[m$hash_check" 
    printf "　　　　チェーン登録ハッシュ値 :\e[33m$chain_Vrf_hash\e[m\n"
    printf "　　ローカルファイルハッシュ値 :\e[33m$local_vrf_hash\e[m\n"

    rm -rf $NODE_HOME/vrf_check

    chain_cert_counter=`cat $NODE_HOME/pooldata.txt | jq -r ".[].op_cert_counter"`
    local_cert_counter=`cardano-cli text-view decode-cbor --in-file $POOL_OPCERT_FILENAME | grep int | head -1 | cut -d"(" -f2 | cut -d")" -f1`
    kes_remaining=`curl -s http://localhost:12798/metrics | grep KESPeriods_int | awk '{ print $2 }'`
    kes_days=`bc <<< "$kes_remaining * 1.5"`
    kes_cborHex=`cat $NODE_HOME/$POOL_HOTKEY_VK_FILENAME | jq '.cborHex' | tr -d '"'`
    cert_cborHex=`cardano-cli text-view decode-cbor --in-file $NODE_HOME/$POOL_OPCERT_FILENAME | awk 'NR==4,NR==6 {print}' | sed 's/ //g' | sed 's/#.*//' | tr -d '\n'`

    cert_counter(){
      if [ $kes_cborHex == $cert_cborHex ]; then
        if [ $1 != "null" ] && [[ $1 -ge $2 ]] && [[ $kes_remaining -ge 1 ]]; then
          printf "\e[32mOK\e[m\n"
        elif [ $1 != "null" ] && [[ $1 -lt $2 ]] && [[ $kes_remaining -ge 1 ]]; then
          printf "\e[31mNG カウンター番号がチェーンより小さいです\e[m\n"
        elif [ $1 == "null" ] && [[ $kes_remaining -ge 1 ]]; then
          printf "\e[32mOK (ブロック未生成)\e[m\n"
        else
          printf "\e[31mNG KESの有効期限が切れています\e[m\n"
        fi
      else
        printf "\e[31mNG CERTファイルに署名された$POOL_HOTKEY_VK_FILENAMEファイルが異なります。\e[m\n"
      fi
    }
    cc=`cert_counter $chain_cert_counter $local_cert_counter`



    echo
    printf "\e[35m■プール運用証明書チェック\e[m(node.cert) $cc\n"
    printf "　    チェーン上カウンター :\e[33m$chain_cert_counter\e[m\n"
    printf "　　CERTファイルカウンター :\e[33m$local_cert_counter\e[m\n"
    printf "　　　　　　　 KES残り日数 :\e[33m$kes_days日\e[m\n"
    printf "　  CERTファイルKES-VK_Hex :\e[33m$cert_cborHex\e[m\n"
    printf "　      ローカルKES-VK_Hex :\e[33m$kes_cborHex\e[m\n"

    echo
    kes_int=$(($current_KES-$Start_KES+$metrics_KES))
    kes_int_chk(){
      if [ $1 == 62 ]; then
        printf "\e[32mOK\e[m\n"
      else
        "\e[31mNG KES整合性は62である必要があります。KESファイルを作り直してください\e[m\n"
      fi
    }
    kic=`kes_int_chk $kes_int`

    printf "\e[35m■KES整合性\e[m:\e[33m$kes_int\e[m $kic\n"
    echo
    echo
    echo "ブロック生成可能状態チェックが完了しました"

    if [ $mempool_CHK == "false" ]; then
      printf "\e[31m$config_name-config.jsonのTraceMempoolがfalseになっています\n"
      printf "\e[31m正確にチェックする場合はtrueへ変更し、ノード再起動後再度チェックしてください\e[m"
      echo
    fi
    echo
    echo "--注意--------------------------------------------------------"
    printf " > 1つでも \e[31mNG\e[m があった場合はプール構成を見直してください\n"
    echo "--------------------------------------------------------------"
    echo
    select_rtn
    ;;
  0)
    clear
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
    *) 
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
  echo '■エアギャップオフラインマシンで以下の操作を実施してください'
  echo
  echo -e "\e[33m1. BPのtx.raw をエアギャップのcnodeディレクトリにコピーしてください\e[m"
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
  echo "1～3の操作が終わったらEnterを押してください"
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
    echo

  if [ ${rewardBalance} == 0 ]; then
    
    printf "\e[31m出金可能な報酬はありません\e[m\n"
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

  tail -n +3 fullUtxo.out | sort -k3 -nr | sed -e '/lovelace + [0-9]/d' > balance.out

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
  rows36="%15s \e[36m%-15s\e[m\n"
  rows32="%15s \e[32m%-15s\e[m\n"
  #printf "$rows" "Send_Address:" "${destinationAddress::20}...${destinationAddress: -20}"
  printf "$rows36" "送金先アドレス:" "$1"
  printf "$rows32" "       送金ADA:" "$2 ADA"
  printf "$rows32" "　　　  手数料:" "`scale3 $3` ADA"
  printf "$rows32" "    Wallet残高:" "`scale1 $4` ADA"

}

#loverace変換
scale1(){
  #r_amount=`echo "scale=1; $1 / 1000000" | bc`
  r_amount=`echo "scale=6; $1 / 1000000" | bc`
  echo $r_amount
}

scale3(){
  #r_amount=`echo "scale=3; $1 / 1000000" | bc | awk '{printf "%.5f\n", $0}'`
  r_amount=`echo "scale=6; $1 / 1000000" | bc | awk '{printf "%.5f\n", $0}'`
  echo $r_amount
}

update(){
  printf "Update Check..."
  wget -q https://raw.githubusercontent.com/btbf/spojapanguild/master/script/sjgtool.sh -O $NODE_HOME/scripts/sjgtool.sh.tmp
  tmp256=`sha256sum $NODE_HOME/scripts/sjgtool.sh.tmp | awk '{ print $1 }'`
  sh256=`sha256sum $NODE_HOME/scripts/sjgtool.sh | awk '{ print $1 }'`

  
  if [[ ! $tmp256 == $sh256 ]]; then
    CUR_VERSION=$(grep -r ^TOOL_VERSION= "$NODE_HOME/scripts/sjgtool.sh" | cut -d'=' -f2)
    GIT_VERSION=$(grep -r ^TOOL_VERSION= "$NODE_HOME/scripts/sjgtool.sh.tmp" | cut -d'=' -f2)
    mv $NODE_HOME/scripts/sjgtool.sh.tmp $NODE_HOME/scripts/sjgtool.sh
    chmod 755 $NODE_HOME/scripts/sjgtool.sh
    printf "SPO JAPAN GUILD TOOL UPDATE\n"
    printf "Ver.\e[33m$CUR_VERSION\e[mから\e[32m$GIT_VERSION\e[mへアップデートしました\n"
    echo "Enterを押してリロードしてください"
    read Wait
    return 1
  else
    rm $NODE_HOME/scripts/sjgtool.sh.tmp
    clear
    return 2
  fi
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
