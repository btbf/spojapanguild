#!/bin/bash
#
# 入力値チェック/セット
#

TOOL_VERSION="3.7.5"
COLDKEYS_DIR='$HOME/cold-keys'

# General exit handler
cleanup() {
  [[ -n $1 ]] && err=$1 || err=$?
  [[ $err -eq 0 ]] && clear
  tput cnorm # restore cursor
  [[ -n ${exit_msg} ]] && echo -e "\n${exit_msg}\n" || echo -e "\nSPO JAPAN GUILD TOOL Closed!\n"
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
#getEraIdentifier
if [ $? == 1 ]; then
  cd $NODE_HOME/scripts
  $0 "$@" "-u"
  myExit 0
fi

#echo $NETWORK_IDENTIFIER
#echo $NETWORK_NAME
#echo $KOIOS_API

node_type=`filecheck "$NODE_HOME/$POOL_OPCERT_FILENAME"`
NETWORK_ERA=$(${CCLI} query tip ${NETWORK_IDENTIFIER} 2>/dev/null | jq -r '.era //empty')

if [ ${node_type} == "true" ]; then
    node_name="BP"
else
    node_name="Relay"
fi

#プロトコルパラメータファイル作成
cd $NODE_HOME
cardano-cli query protocol-parameters \
  $NETWORK_IDENTIFIER \
  --out-file params.json

node_version=$(${CNODEBIN} version | head -1 | cut -d' ' -f2)
cli_version=$(${CCLI} version | head -1 | cut -d' ' -f2)

db_size=$(du -sh $NODE_HOME/db | awk '{print $1}')
avail_disk=$(df -h /usr | awk 'NR==2 {print $4}')

echo -e " >> SPO JAPAN GUILD TOOL ${FG_YELLOW}ver$TOOL_VERSION${NC} <<"
echo ' ---------------------------------------------------------------------'
echo -e " Server:${FG_YELLOW}-$node_name-${NC} | NetWork:${FG_GREEN}-${NETWORK_NAME}-${NC} | Era:${FG_YELLOW}${NETWORK_ERA}${NC} |"
echo ' ---------------------------------------------------------------------'
echo -e " Node:${FG_YELLOW}${node_version}${NC} | CLI:${FG_YELLOW}${cli_version}${NC} | Disk残容量:${FG_YELLOW}${avail_disk}${NC} | DBサイズ:${FG_YELLOW}${db_size}${NC} |"
echo '
 [1] ウォレット操作
 [2] ブロック生成状態チェック
 [3] KES更新
 [4] envUpdateフラグ切替
 ---------------------------------
 [5] Catalyst有権者登録
 [6] gLiveView アップデート(1.28.x)
 ---------------------------------
 [q] 終了
'
echo
read -n 1 -p "メニュー番号を入力してください : >" num
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
[1] ウォレット未使用UTXO確認
[2] プール報酬確認
[3] 報酬/資金出金
[b] 戻る 
    '
    read -n 1 -p "メニュー番号を入力してください : >" wallet
    case ${wallet} in
      1)
        clear
        echo '----------------------------'
        echo '>> ウォレット未使用UTXO確認'
        echo '----------------------------'
        echo
        efile_check=`filecheck "$NODE_HOME/$WALLET_PAY_ADDR_FILENAME"`
        if [ ${efile_check} == "true" ]; then
          echo "■paymentアドレス"
          printf "${FG_YELLOW}$(cat $WALLET_PAY_ADDR_FILENAME)${NC}\n\n"

          # cardano-cli query utxo \
          #   --address $(cat $WALLET_PAY_ADDR_FILENAME) \
          #   $NETWORK_IDENTIFIER

          payment_utxo

          cat fullUtxo.out
          echo 
          payment_addr_total=$(scale3 $total_balance)
          printf "ウォレット残高合計:${FG_YELLOW}${payment_addr_total}${NC} ADA\n"
          echo 
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
          printf "${FG_YELLOW}$(cat $WALLET_STAKE_ADDR_FILENAME)${NC}\n\n"
          pool_reward=$(cardano-cli query stake-address-info --address $(cat $WALLET_STAKE_ADDR_FILENAME) $NETWORK_IDENTIFIER | jq .[].rewardAccountBalance)
          #pool_reward=`cat $PARENT/stake_json.txt | grep rewardAccountBalance | awk '{ print $2 }'`
          #echo $pool_reward
          pool_reward_Amount=`scale1 $pool_reward`
          printf "報酬額:${FG_GREEN}$pool_reward_Amount${NC} ADA ($pool_reward Lovelace)\n"

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
        printf "${FG_MAGENTA}■プール報酬出金($WALLET_STAKE_ADDR_FILENAME)${NC}
----------------------------
[1] 任意のアドレス(ADAHandle)へ出金
[2] $WALLET_PAY_ADDR_FILENAMEへ出金
\n
${FG_MAGENTA}■プール資金出金($WALLET_PAY_ADDR_FILENAME)${NC}
----------------------------
[3] 任意のアドレス(ADAHandle)へ出金
\n
----------------------------
[h] ホームへ戻る　[q] 終了
\n
"
        read -n 1 -p "メニュー番号を入力してください : >" withdrawl
        case ${withdrawl} in
          #[START] payment.addr ⇒ 任意のアドレス(ADAHandle) [START] 

          1)
            clear
            echo '------------------------------------------------------------------------'
            echo "資金移動"
            echo -e ">> ${FG_YELLOW}$WALLET_STAKE_ADDR_FILENAME${NC} から ${FG_YELLOW}任意のアドレス(ADAHandle)${NC} への出金"
            echo
            echo "■ 注意 ■"
            echo "報酬は全額引き出しのみとなります"
            echo '------------------------------------------------------------------------'
            
            efile_check=`filecheck "$NODE_HOME/$WALLET_STAKE_ADDR_FILENAME"`
            if [ ${efile_check} == "true" ]; then
              #stake.addr残高算出
              echo
              reward_Balance
              printf "\n${FG_YELLOW}出金をキャンセルする場合は 1 を入力してEnterを押してください${NC}\n\n"
              #出金先アドレスチェック
              send_address

              printf "\n\nTx作成中...\n\n"
              
              #現在のスロット
              current_Slot

              #ウォレット残高とUTXO参照
              payment_utxo

              withdrawalString="$(cat $WALLET_STAKE_ADDR_FILENAME)+${rewardBalance}"

              #トランザクションファイル仮作成
              cardano-cli transaction build-raw \
              ${tx_in} \
              --tx-out $(cat $WALLET_PAY_ADDR_FILENAME)+${total_balance} \
              --tx-out ${destinationAddress}+${rewardBalance} \
              --invalid-hereafter $(( ${currentSlot} + 10000)) \
              --fee 200000 \
              --withdrawal ${withdrawalString} \
              --out-file tx.tmp

              #手数料計算
              fee=$(cardano-cli transaction calculate-min-fee \
                  --tx-body-file tx.tmp \
                  --witness-count 2 \
                  --protocol-params-file params.json | awk '{ print $1 }')


              #残高-手数料-出金額
              txOut=$((${total_balance}-${fee}))
              #echo Change Output: ${txOut}

              tx_Check $destinationAddress ${rewardBalance} $fee ${txOut}


              #最終トランザクションファイル作成
              cardano-cli transaction build-raw \
              ${tx_in} \
              --tx-out $(cat $WALLET_PAY_ADDR_FILENAME)+${txOut} \
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
            echo -e ">> ${FG_YELLOW}$WALLET_STAKE_ADDR_FILENAME${NC} から ${FG_YELLOW}$WALLET_PAY_ADDR_FILENAME${NC} への出金"
            echo
            echo "■ 注意 ■"
            echo "報酬は全額引き出しのみとなります"
            echo '------------------------------------------------------------------------'
            payfile_check=`filecheck "$NODE_HOME/$WALLET_PAY_ADDR_FILENAME"`
            stakefile_check=`filecheck "$NODE_HOME/$WALLET_STAKE_ADDR_FILENAME"`
            if [ ${payfile_check} == "true" ] && [ ${stakefile_check} == "true" ]; then
              #stake.addr残高算出
              reward_Balance

              printf "\n\nTx作成中...\n\n"

              #現在のスロット
              current_Slot

              #payment.addr
              destinationAddress=$(cat $WALLET_PAY_ADDR_FILENAME)

              #ウォレット残高とUTXO参照
              payment_utxo

              withdrawalString="$(cat $WALLET_STAKE_ADDR_FILENAME)+${rewardBalance}"
              tempRewardAmount=$(( ${total_balance}+${rewardBalance} ))
              #トランザクションファイル仮作成
              cardano-cli transaction build-raw \
              ${tx_in} \
              --tx-out $(cat $WALLET_PAY_ADDR_FILENAME)+${tempRewardAmount} \
              --invalid-hereafter $(( ${currentSlot} + 10000)) \
              --fee 200000 \
              --withdrawal ${withdrawalString} \
              --out-file tx.tmp

              #手数料計算
              fee=$(cardano-cli transaction calculate-min-fee \
                  --tx-body-file tx.tmp \
                  --witness-count 2 \
                  --protocol-params-file params.json | awk '{ print $1 }')
              

              #残高-手数料-出金額
              txOut=$((${total_balance}-${fee}+${rewardBalance}))
              #echo Change Output: ${txOut}

              tx_Check $destinationAddress ${rewardBalance} $fee ${txOut}

              #最終トランザクションファイル作成
              cardano-cli transaction build-raw \
                ${tx_in} \
                --tx-out $(cat $WALLET_PAY_ADDR_FILENAME)+${txOut} \
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
            echo -e ">> ${FG_YELLOW}$WALLET_PAY_ADDR_FILENAME${NC} から ${FG_YELLOW}任意のアドレス(ADAHandle)${NC} への出金"
            echo
            echo "■ 注意 ■"
            echo "$WALLET_PAY_ADDR_FILENAMEには誓約で設定した額以上のADAが入金されてる必要があります"
            echo "出金には十分ご注意ください"
            echo '------------------------------------------------------------------------'
            printf "${FG_YELLOW}出金をキャンセルする場合は 1 を入力してEnterを押してください${NC}\n\n"
            efile_check=`filecheck "$NODE_HOME/$WALLET_PAY_ADDR_FILENAME"`
            if [ ${efile_check} == "true" ]; then
              #出金先アドレスチェック
              echo
              send_address
              
              #出金額指定
              clear
              echo '------------------------------------------------------------------------'
              echo -e ">> ${FG_YELLOW}$WALLET_PAY_ADDR_FILENAME${NC} から ${FG_YELLOW}任意のアドレス(ADAHandle)${NC} への出金"
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

              printf "\n\nTx作成中...\n\n"
              
              #現在のスロット
              current_Slot

              #ウォレット残高とUTXO参照
              payment_utxo
              
              #echo UTXOs: ${txcnt}
              tempBalanceAmont=$(( ${total_balance}-${amountToSend} ))
              #トランザクションファイル仮作成
              cardano-cli transaction build-raw \
                  ${tx_in} \
                  --tx-out $(cat $WALLET_PAY_ADDR_FILENAME)+${tempBalanceAmont} \
                  --tx-out ${destinationAddress}+${amountToSend} \
                  --invalid-hereafter $(( ${currentSlot} + 10000)) \
                  --fee 200000 \
                  --out-file tx.tmp

              #手数料計算
              fee=$(cardano-cli transaction calculate-min-fee \
              --tx-body-file tx.tmp \
              --witness-count 1 \
              --protocol-params-file params.json | awk '{ print $1 }')


              #残高-手数料-出金額
              txOut=$((${total_balance}-${fee}-${amountToSend}))
              
              tx_Check $destinationAddress $amountToSend $fee ${txOut}

              #printf "$rows" "出金後残高:" "`scale1 ${txOut}` ADA"

              #最終トランザクションファイル作成
              cardano-cli transaction build-raw \
                  ${tx_in} \
                  --tx-out $(cat $WALLET_PAY_ADDR_FILENAME)+${txOut} \
                  --tx-out ${destinationAddress}+${amountToSend} \
                  --invalid-hereafter $(( ${currentSlot} + 10000)) \
                  --fee ${fee} \
                  --out-file tx.raw
              
              #エアギャップ操作メッセージ
              air_gap_payment_only
              
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
          h)
            main ;;
          q) 
            clear
            echo
            echo "SPO JAPAN GUILD TOOL Closed!" 
            echo
            exit ;;
          *)
            echo '番号が不正です'
            select_rtn
            ;;
        esac
        ;;
      b)
        main ;;
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

    poolfileCheck
    kesfileCheck

    #kes_vk_file_check=`filecheck "$NODE_HOME/$POOL_HOTKEY_VK_FILENAME"`
    #if [ $kes_vk_file_check == "false" ]; then
    #  printf "\n${FG_RED}$POOL_HOTKEY_VK_FILENAMEが見つかりません${NC}\n\n"
    #  printf "エアギャップにある${FG_GREEN}$POOL_HOTKEY_VK_FILENAME${NC}をBPの${FG_YELLOW}$NODE_HOME${NC}にコピーし再度実行してください\n"
    #  select_rtn
    #fi


    mempool_CHK=`cat $CONFIG | jq ".TraceMempool"`
    p2p_CHK=`cat $CONFIG | jq ".EnableP2P"`

    get_pooldata

    #メトリクスKES
    metrics_KES=$(curl -s localhost:${PROM_PORT}/metrics | grep remainingKES | awk '{ print $2 }')
    Expiry_KES=$(curl -s localhost:${PROM_PORT}/metrics | grep ExpiryKES | awk '{ print $2 }')
    Start_KES=$(curl -s localhost:${PROM_PORT}/metrics | grep StartKES | awk '{ print $2 }')
    current_KES=$(curl -s localhost:${PROM_PORT}/metrics | grep currentKES | awk '{ print $2 }')
    current_epoch=$(curl -s localhost:${PROM_PORT}/metrics | grep epoch_int | awk '{ print $2 }')
    
    if [ -z "$metrics_KES" ]; then
      echo "KESメトリクスを取得できませんでした"
      echo "このノードがBPであることを確認してください"
      select_rtn
    fi

    active_ST_check(){
      if [ $1 != 0 ]; then
        printf "${FG_CYAN}`scale1 $1`${NC} ADA"
      else
        printf "$1 ADA \n (ライブステークが有効になるまでスケジュール割り当てはありません)\n"
      fi
    }
    live_Stake=`cat $NODE_HOME/pooldata.txt | jq -r ".[].live_stake"`
    live_Stake=`scale1 $live_Stake`
    active_Stake=`cat $NODE_HOME/pooldata.txt | jq -r ".[].active_stake"`

    active_Stake=`active_ST_check $active_Stake`
    pledge=`cat $NODE_HOME/pooldata.txt | jq -r ".[].pledge"`
    pledge_scale=`scale1 $pledge`

    active_epoch=`cat $NODE_HOME/pooldata.txt | jq -r ".[].active_epoch_no"`
    future_pledge=`cardano-cli query pool-params --stake-pool-id $(cat $NODE_HOME/pool.id-bech32) | jq .[].futurePoolParams.pledge`
    current_pledge=`cardano-cli query pool-params --stake-pool-id $(cat $NODE_HOME/pool.id-bech32) | jq .[].poolParams.pledge`

  
    printf "ノード起動タイプ:BP ${FG_GREEN}OK${NC}　ネットワーク:${FG_YELLOW}$NETWORK_NAME${NC}\n"
    echo
    printf "　　対象プール :${FG_CYAN}[`cat $NODE_HOME/pooldata.txt | jq -r ".[].meta_json.ticker"`] `cat $NODE_HOME/pooldata.txt | jq -r ".[].meta_json.name"`${NC}\n"
    printf "　　　プールID :${FG_CYAN}`cat $NODE_HOME/pooldata.txt | jq -r ".[].pool_id_bech32"`${NC}\n"
    printf "ライブステーク :${FG_GREEN}$live_Stake${NC} ADA\n"
    printf "　有効ステーク :$active_Stake\n"
    echo
    okCnt=1

    #MetaHashチェック
    
    metaChainHash=`cat $NODE_HOME/pooldata.txt | jq -r ".[].meta_hash"`
    metaFileUrl=`cat $NODE_HOME/pooldata.txt | jq -r ".[].meta_url"`
    mkdir $NODE_HOME/metaCheck
    wget -q $metaFileUrl -O $NODE_HOME/metaCheck/poolMetaData.json
    cat $NODE_HOME/metaCheck/poolMetaData.json | jq . > $NODE_HOME/metaCheck/metaCheck.json 2>&1
    metaCheck=`cat $NODE_HOME/metaCheck/metaCheck.json | grep name`
    printf "${FG_MAGENTA}■メタデータチェック${NC}： "
    if [ -z "$metaCheck" ]; then
      printf "${FG_RED}NG${NC}　"
      printf "メタデータ構文エラーです\n"
      echo "サーバー(またはGithub)にアップロードされているpoolMetaData.jsonの構文エラーを修正し"
      echo "プール運用マニュアルの「プール情報更新」で再登録してください"
      echo
    else
      metaFileHash=`cardano-cli stake-pool metadata-hash --pool-metadata-file $NODE_HOME/metaCheck/poolMetaData.json`
      if [ $metaChainHash == $metaFileHash ]; then
        printf "${FG_GREEN}OK${NC}\n"
        printf "チェーン登録ハッシュ：${FG_YELLOW}$metaChainHash${NC}\n"
        printf "　　ファイルハッシュ：${FG_YELLOW}$metaFileHash${NC}\n"
        okCnt=$((${okCnt}+1))
      else
        printf "${FG_RED}NG${NC}　"
        printf "チェーン登録ハッシュとファイルハッシュが異なります。\n"
        printf "チェーン登録ハッシュ：${FG_YELLOW}$metaChainHash${NC}\n"
        printf "　　ファイルハッシュ：${FG_YELLOW}$metaFileHash${NC}\n"
        echo プール運用マニュアルの「プール情報更新」で再登録してください。
      fi
    fi
    
    rm -rf $NODE_HOME/metaCheck
    
    koios_stake_total=`curl -s -X POST "$KOIOS_API/account_info" -H "Accept: application/json" -H "content-type: application/json" -d "{\"_stake_addresses\":[\"$(cat $NODE_HOME/$WALLET_STAKE_ADDR_FILENAME)\"]}" | jq -r '.[].total_balance'`

    if [ $active_epoch -gt $current_epoch ] && [ $future_pledge -ne $current_pledge ]; then
      pledge=$current_pledge
      pledge_scale=`scale1 $pledge`
      future_pledge_scale=`scale1 $future_pledge`
      print_pledge="${FG_YELLOW}$pledge_scale${NC} ADA → ${FG_RED}$future_pledge_scale${NC} ADA ($active_epoch エポックで有効)\n"
    else
      print_pledge="${FG_YELLOW}$pledge_scale${NC} ADA\n"
    fi

    #誓約チェック
    if [[ $koios_stake_total -ge $pledge ]]; then
      echo
      printf "${FG_MAGENTA}■誓約チェック${NC}： ${FG_GREEN}OK${NC}\n"
      okCnt=$((${okCnt}+1))
    else
      echo
      printf "${FG_MAGENTA}■誓約チェック${NC}： ${FG_RED}NG${NC} ${FG_YELLOW}payment.addrに宣言済み誓約(Pledge)以上のADAを入金してください${NC}\n"
    fi
      printf "　宣言済み誓約 :$print_pledge"
      printf "　　委任合計　 :$(scale1 ${koios_stake_total}) ADA (payment.addr + stake.addr報酬合計)\n"

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
    printf "${FG_MAGENTA}■BPファイル存在確認${NC}\n"
    if [ $kes_path ]; then
      kes_name=${kes_path##*/}
      kes_CHK=`filecheck "$NODE_HOME/$kes_name"`
      if [ $kes_CHK == "true" ]; then
        printf "　 $kes_name: ${FG_GREEN}OK${NC}\n"
        okCnt=$((${okCnt}+1))
      else
        printf "　 $kes_name: ${FG_RED}NG${NC}\n"
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
        printf "　 $vrf_name: ${FG_GREEN}OK${NC}\n"
        okCnt=$((${okCnt}+1))
      else
        printf "　 $vrf_name: ${FG_RED}NG${NC}\n"
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
        printf "　$cert_name: ${FG_GREEN}OK${NC}\n"
        okCnt=$((${okCnt}+1))
      else
        printf "　$cert_name: ${FG_RED}NG${NC}\n"
      fi

    else
      cert_name=""
      cert_CHK="$NODE_HOME/relay"
      echo certファイルはありません
    fi

    #ノード同期状況確認
    #APIから最新ブロックNo取得
    koios_blockNo=`curl -s -X GET "$KOIOS_API/tip" -H "Accept: application/json" | jq -r '.[].block_no'`
    

    #ノードから同期済みブロック取得
    currentblock=$(cardano-cli query tip $NETWORK_IDENTIFIER | jq -r '.block')
    

    block_diff=$koios_blockNo-$currentblock
    if [[ $block_diff -ge 2 ]]; then
      clear
      echo
      echo "ノードが最新ブロックに同期してから再度ご確認ください"
      select_rtn
    else
      echo
      printf "${FG_MAGENTA}■ノード同期状況${NC}： ${FG_GREEN}OK${NC}\n"
      printf "  ネットワーク最新ブロック :${FG_YELLOW}$koios_blockNo${NC}\n"
      printf "ローカルノード最新ブロック :${FG_YELLOW}$currentblock${NC}\n"
      okCnt=$((${okCnt}+1))
    fi

    #メトリクスTx数
    metrics_tx=$(curl -s localhost:${PROM_PORT}/metrics | grep txsProcessedNum_int | awk '{ print $2 }')
    if [ -z $metrics_tx ]; then
      metrics_tx="0"
    fi
    
    # Tx流入判定
    if [ $mempool_CHK = "true" ] && [ $metrics_tx -gt 0 ]; then
      tx_count="${FG_GREEN}OK${NC}"
      okCnt=$((${okCnt}+1))
    elif [ $mempool_CHK = "false" ] && [ $metrics_tx -eq 0 ]; then
      tx_count="${FG_GREEN}条件付きOK${NC}"
      okCnt=$((${okCnt}+1))
    else
      printf "${FG_RED}NG${NC}"
    fi

    printf "\n${FG_MAGENTA}■Tx流入数${NC}:${FG_YELLOW}$metrics_tx${NC} $tx_count TraceMempool:${FG_YELLOW}$mempool_CHK${NC}\n"
    if [[ $tx_count = *NG* ]]; then
      printf "\nTxが入ってきていません。1分後に再実行してください\n"
      printf "\n再実行してもNGの場合は、以下の点を再確認してください\n"
      printf "・BPのファイアウォールの設定\n"
      printf "・リレーノードのトポロジーアップデーター設定(フェッチリストログファイルなど)\n"
      printf "・リレーノードの$TOPOLOGYに当サーバーのIPが含まれているか\n\n"
    fi

    echo
    
    peers_in=$(ss -tnp state established 2>/dev/null | grep "${CNODE_PID}," | grep -v "127.0.0.1" | awk -v port=":${CNODE_PORT}" '$3 ~ port {print}' | wc -l)
    if [ $p2p_CHK = "true" ]; then
      #ダイナミックP2P
      peers_out=$(curl -s localhost:${PROM_PORT}/metrics | grep outgoingConns | awk '{ print $2 }')
      p2p_type="ダイナミックP2P(台帳P2P)"

    else
    #手動P2P

      peers_out=$(ss -tnp state established 2>/dev/null | grep "${CNODE_PID}," | awk -v port=":(${CNODE_PORT}|${EKG_PORT}|${PROM_PORT})" '$3 !~ port {print}' | wc -l)
      p2p_type="マニュアルP2P(トポロジーアップデータ)"
    fi
  
    if [[ $peers_in -eq 0 ]]; then
      peer_in_judge=" ${FG_RED}NG${NC} リレーから接続されていません"
    else
      peer_in_judge=" ${FG_GREEN}OK${NC}"
      okCnt=$((${okCnt}+1))
    fi
    if [[ $peers_out -eq 0 ]]; then
      peer_out_judge=" ${FG_RED}NG${NC} リレーに接続出来ていません"
    else
      peer_out_judge=" ${FG_GREEN}OK${NC}"
      okCnt=$((${okCnt}+1))
    fi
    printf "${FG_MAGENTA}■Peer接続状況${NC}(${FG_YELLOW}${p2p_type}${NC})\n"
    printf "　incoming :${FG_YELLOW}$peers_in $peer_in_judge${NC}\n"
    printf "　outgoing :${FG_YELLOW}$peers_out $peer_out_judge${NC}\n"

    chain_Vrf_hash=`cat $NODE_HOME/pooldata.txt | jq -r ".[].vrf_key_hash"`

    #ローカルVRFファイル検証
    mkdir $NODE_HOME/vrf_check
    cp $NODE_HOME/$POOL_VRF_SK_FILENAME $NODE_HOME/vrf_check/
    cardano-cli key verification-key --signing-key-file $NODE_HOME/vrf_check/$POOL_VRF_SK_FILENAME --verification-key-file $NODE_HOME/vrf_check/vrf.vkey
    cardano-cli node key-hash-VRF --verification-key-file $NODE_HOME/vrf_check/vrf.vkey --out-file $NODE_HOME/vrf_check/vkeyhash.txt
    local_vrf_hash=$(cat $NODE_HOME/vrf_check/vkeyhash.txt)
    
    if [ $chain_Vrf_hash == $local_vrf_hash ]; then
      hash_check=" ${FG_GREEN}OK${NC}\n"
      okCnt=$((${okCnt}+1))
    else
      hash_check=" ${FG_RED}NG${NC}\n"
    fi

    echo
    printf "${FG_MAGENTA}■VRFハッシュ値チェック${NC}$hash_check" 
    printf "　　チェーン登録ハッシュ値 :${FG_YELLOW}$chain_Vrf_hash${NC}\n"
    printf "ローカルファイルハッシュ値 :${FG_YELLOW}$local_vrf_hash${NC}\n"

    rm -rf $NODE_HOME/vrf_check

    chain_cert_counter=`cat $NODE_HOME/pooldata.txt | jq -r ".[].op_cert_counter"`
    local_cert_counter=`cardano-cli text-view decode-cbor --in-file $POOL_OPCERT_FILENAME | grep int | head -1 | cut -d"(" -f2 | cut -d")" -f1`
    kes_remaining=$(curl -s http://localhost:${PROM_PORT}/metrics | grep KESPeriods_int | awk '{ print $2 }')
    kes_days=`bc <<< "$kes_remaining * 1.5"`
    kes_cborHex=`cat $NODE_HOME/$POOL_HOTKEY_VK_FILENAME | jq '.cborHex' | tr -d '"'`
    cert_cborHex=`cardano-cli text-view decode-cbor --in-file $NODE_HOME/$POOL_OPCERT_FILENAME | awk 'NR==4,NR==6 {print}' | sed 's/ //g' | sed 's/#.*//' | tr -d '\n'`

    #証明書判定
    if [ $kes_cborHex == $cert_cborHex ]; then
      if [ $chain_cert_counter != "null" ] && [ $local_cert_counter -ge $(($chain_cert_counter+2)) ] && [ $kes_remaining -ge 1 ]; then
        cc="${FG_RED}NG カウンター番号がチェーンより2以上大きいです${NC}\n"
      elif [ $chain_cert_counter != "null" ] && [ $local_cert_counter -ge $chain_cert_counter ] && [ $kes_remaining -ge 1 ] ; then
        cc="${FG_GREEN}OK${NC}\n"
        okCnt=$((${okCnt}+1))
      elif [ $chain_cert_counter != "null" ] && [ $local_cert_counter -lt $chain_cert_counter ] && [ $kes_remaining -ge 1 ]; then
        cc="${FG_RED}NG カウンター番号がチェーンより小さいです${NC}\n"
      elif [ $chain_cert_counter == "null" ] && [ $kes_remaining -ge 1 ]; then
        cc="${FG_GREEN}OK (ブロック未生成)${NC}\n"
        okCnt=$((${okCnt}+1))
      else
        cc="${FG_RED}NG KESの有効期限が切れています${NC}\n"
      fi
    else
      cc="${FG_RED}NG CERTファイルに署名された$POOL_HOTKEY_VK_FILENAMEファイルが異なります。${NC}\n"
    fi

    echo
    printf "${FG_MAGENTA}■プール運用証明書チェック${NC}($POOL_OPCERT_FILENAME) $cc\n"
    printf "　    チェーン上カウンター :${FG_YELLOW}$chain_cert_counter${NC}\n"
    printf "　　CERTファイルカウンター :${FG_YELLOW}$local_cert_counter${NC}\n"
    printf "　　　　　　　 KES残り日数 :${FG_YELLOW}$kes_days日${NC}\n"
    printf "　  CERTファイルKES-VK_Hex :${FG_YELLOW}$cert_cborHex${NC}\n"
    printf "　      ローカルKES-VK_Hex :${FG_YELLOW}$kes_cborHex${NC}\n"

    echo
    kes_int=$(($current_KES-$Start_KES+$metrics_KES))

    #KES整合性判定
    if [ $kes_int == 62 ]; then
      kic="${FG_GREEN}OK${NC}\n"
      okCnt=$((${okCnt}+1))
    else
      "${FG_RED}NG KES整合性は62である必要があります。KESファイルを作り直してください${NC}\n"
    fi

    printf "${FG_MAGENTA}■KES整合性${NC}:${FG_YELLOW}$kes_int${NC} $kic\n\n"

    if [ $mempool_CHK == "false" ]; then
      echo -e "----${FG_YELLOW}確認${NC}--------------------------------------------------------------"
      printf "$CONFIGのTraceMempoolが${FG_YELLOW}false${NC}になっています\n"
      printf "正確にチェックする場合は${FG_GREEN}true${NC}へ変更し、ノード再起動後再度チェックしてください\n"
      echo "--------------------------------------------------------------------"
      echo
    fi

    if [ $okCnt -eq 13 ]; then
      echo
      echo -e "----${FG_GREEN}OK${NC}--------------------------------------------------------"
      printf " > 全ての項目が ${FG_GREEN}OK${NC} になりブロック生成の準備が整いました！\n"
      echo "--------------------------------------------------------------"
    else
      echo
      echo -e "----${FG_RED}NG${NC}--------------------------------------------------------"
      printf " > 1つ以上 ${FG_RED}NG${NC} がありました。プール構成を見直してください\n"
      echo "--------------------------------------------------------------"
      echo
    fi

    select_rtn
    ;;
  
  3)
    clear

    #KEStimenig
    slotNumInt=$(curl -s http://localhost:${PROM_PORT}/metrics | grep cardano_node_metrics_slotNum_int | awk '{ print $2 }')
    kesTiming=`echo "scale=6; ${slotNumInt} / 129600" | bc | awk '{printf "%.5f\n", $0}'`

    echo '------------------------------------------------------------------------'
    echo -e "> KES更新作業"
    echo '------------------------------------------------------------------------'

    kesfileCheck

    node_cert_file_check=`filecheck "$NODE_HOME/$POOL_OPCERT_FILENAME"`
    if [ $node_cert_file_check == "false" ]; then
      printf "\n${FG_RED}$POOL_OPCERT_FILENAMEが見つかりません${NC}\n\n"
      printf "$NODE_HOME/scripts/envの${FG_YELLOW}[POOL_OPCERT_FILENAME]${NC}の値を正しいファイル名(例：${FG_GREEN}node.cert${NC})に書き換えてください\n"
      select_rtn
    fi

    echo '------------------------------------------------------------------------'
    echo -e "■ 実行フロー"
    echo ' 1.既存のKESファイル/CERTファイルバックアップ'
    echo ' 2.既存のKESファイル/CERTファイル削除'
    echo ' 3.新規KESファイル作成'
    echo ' 4.エアギャップ操作/CERTファイル移動(手動)'
    echo ' 5.ノード再起動(選択可)'
    echo
    echo ' -------ここまで当ツールが実行--------'
    echo
    echo ' 6.ノード同期確認(手動)'
    echo ' 7.GuildToolにてブロック生成可能状態確認(手動)'
    echo '------------------------------------------------------------------------'
    echo
    printf "KESファイルを更新する前に、1時間以内にブロック生成スケジュールが無いことを確認してください\n\n"
    printf "${FG_YELLOW}KES更新作業を開始しますか？${NC}\n\n"
    echo "[1] 開始　[2] キャンセル"

    echo

    #YESNO関数
    yes_no
     
    echo
    printf "${FG_MAGENTA}KES更新タイミングチェック${NC}:$kesTiming\n"
    sleep 1

    kesTimingDecimal=${kesTiming#*.}
    if [ $kesTimingDecimal -ge 99800 ]; then
      printf "KesStartがもうすぐ切り替わります($kesTiming)\n"
      nextkes=`printf $kesTiming | awk '{printf("%d\n",$1+1)}'`
      printf "startKesPeriodが$nextkesへ切り替わってから再度実行してください\n"
      select_rtn
    else
      printf "${FG_GREEN}OK${NC}\n\n"
    fi
    sleep 2

    #最新ブロックカウンター番号チェック
    kesperiodinfo=$(cardano-cli query kes-period-info ${NETWORK_IDENTIFIER} --op-cert-file $NODE_HOME/$POOL_OPCERT_FILENAME --out-file $NODE_HOME/kesperiod.json)
    lastBlockCnt=`cat kesperiod.json | jq -r '.qKesNodeStateOperationalCertificateNumber'`
    rm $NODE_HOME/kesperiod.json
  
    #現在のKESPeriod算出
    slotNo=$(cardano-cli query tip ${NETWORK_IDENTIFIER} | jq -r '.slot')
    slotsPerKESPeriod=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r '.slotsPerKESPeriod')
    kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
    startKesPeriod=${kesPeriod}
    
    kesfolder="$NODE_HOME/kes-backup"
    if [ ! -d $kesfolder ]; then
      mkdir $kesfolder
      printf "$kesfolderディレクトリを作成しました\n"
    fi

    date=`date +\%Y\%m\%d\%H\%M`
    printf "${FG_MAGENTA}■旧KESファイルのバックアップ...${NC}\n"
    sleep 2
    cp $NODE_HOME/$POOL_HOTKEY_VK_FILENAME $kesfolder/$date-$POOL_HOTKEY_VK_FILENAME
    printf "$NODE_HOME/$POOL_HOTKEY_VK_FILENAME を $kesfolder/$date-$POOL_HOTKEY_VK_FILENAMEへコピーしました\n"
    cp $NODE_HOME/$POOL_HOTKEY_SK_FILENAME $kesfolder/$date-$POOL_HOTKEY_SK_FILENAME
    printf "$NODE_HOME/$POOL_HOTKEY_SK_FILENAME を $kesfolder/$date-$POOL_HOTKEY_SK_FILENAMEへコピーしました\n"
    cp $NODE_HOME/$POOL_OPCERT_FILENAME $kesfolder/$date-$POOL_OPCERT_FILENAME
    printf "$NODE_HOME/$POOL_OPCERT_FILENAME を $kesfolder/$date-$POOL_OPCERT_FILENAMEへコピーしました\n\n"

    kesVkey256=`sha256sum $POOL_HOTKEY_VK_FILENAME | awk '{ print $1 }'`
    kesSkey256=`sha256sum $POOL_HOTKEY_SK_FILENAME | awk '{ print $1 }'`

    printf "${FG_MAGENTA}■旧KESファイルの削除...${NC}\n"
    sleep 2
    rm $NODE_HOME/$POOL_HOTKEY_VK_FILENAME
    printf "$NODE_HOME/$POOL_HOTKEY_VK_FILENAME を削除しました\n"
    rm $NODE_HOME/$POOL_HOTKEY_SK_FILENAME
    printf "$NODE_HOME/$POOL_HOTKEY_SK_FILENAME を削除しました\n"
    #rm $NODE_HOME/$POOL_OPCERT_FILENAME
    #printf "$NODE_HOME/$POOL_OPCERT_FILENAME を削除しました\n\n"

    printf "${FG_MAGENTA}■新しいKESファイルの作成...${NC}\n"
    cardano-cli node key-gen-KES \
    --verification-key-file $NODE_HOME/$POOL_HOTKEY_VK_FILENAME \
    --signing-key-file $NODE_HOME/$POOL_HOTKEY_SK_FILENAME
    sleep 5
    
    kesVkey256=`sha256sum $POOL_HOTKEY_VK_FILENAME | awk '{ print $1 }'`
    kesSkey256=`sha256sum $POOL_HOTKEY_SK_FILENAME | awk '{ print $1 }'`


    printf "$NODE_HOME/$POOL_HOTKEY_VK_FILENAME ${FG_YELLOW}$kesVkey256${NC}を作成しました\n"
    printf "$NODE_HOME/$POOL_HOTKEY_SK_FILENAME ${FG_YELLOW}$kesSkey256${NC}を作成しました\n\n"
    sleep 5
    clear

    sleep 2
    echo
    echo
    echo '■エアギャップオフラインマシンで以下の操作を実施してください'
    echo '(項目1～6まであります)'
    echo
    sleep 2
    echo
    echo -e "${FG_YELLOW}1. BPの$POOL_HOTKEY_VK_FILENAMEと$POOL_HOTKEY_SK_FILENAME をエアギャップのcnodeディレクトリにコピーしてください${NC}"
    echo '----------------------------------------'
    echo ">> [BP] ⇒ $POOL_HOTKEY_VK_FILENAME / $POOL_HOTKEY_SK_FILENAME ⇒ [エアギャップ]"
    echo '----------------------------------------'
    sleep 1
    echo
    echo -e "${FG_YELLOW}2. ファイルハッシュ値確認${NC}"
    echo '----------------------------------------'
    echo 'cd $NODE_HOME'
    echo "sha256sum $POOL_HOTKEY_VK_FILENAME"
    echo "sha256sum $POOL_HOTKEY_SK_FILENAME"
    echo '----------------------------------------'
    echo '上記コマンドの戻り値が以下のハッシュ値と等しいか確認する'
    echo
    echo -e "$POOL_HOTKEY_VK_FILENAME >> ${FG_YELLOW}$kesVkey256${NC}"
    echo -e "$POOL_HOTKEY_SK_FILENAME >> ${FG_YELLOW}$kesSkey256${NC}"
    echo
    read -p "上記を終えたらEnterを押して次の操作を表示します"

    clear
    echo
    #lastBlockCnt=" "
    echo "■カウンター番号情報"
    if expr "$lastBlockCnt" : "[0-9]*$" >&/dev/null; then
      counterValue=$(( $lastBlockCnt +1 ))
      printf "${FG_MAGENTA}チェーン上カウンター番号${NC}: ${FG_YELLOW}${lastBlockCnt}${NC} \n\n"
      printf "${FG_MAGENTA}今回更新のカウンター番号${NC}: ${FG_YELLOW}$counterValue${NC} \n\n"
      printf "node.cert生成時に指定するカウンター番号は\n必ずチェーン上カウンター番号 ${FG_YELLOW}+1${NC} を指定する必要があります\n\n\n"
    else
      counterValue=0
      echo
      echo "ブロック未生成です"
      echo -e "今回更新のカウンター番号は ${FG_YELLOW}$counterValue${NC} で更新します"
    fi
    echo '■エアギャップオフラインマシンで以下の操作を実施してください'
    echo
    echo -e "${FG_YELLOW}3. カウンターファイル生成${NC} (生成カウンター ${FG_YELLOW}$counterValue${NC} )"
    echo '----------------------------------------'
    echo "chmod u+rwx $COLDKEYS_DIR"
    echo 'cardano-cli node new-counter \'
    echo "  --cold-verification-key-file $COLDKEYS_DIR/$POOL_COLDKEY_VK_FILENAME"' \'
    echo '  --counter-value '$counterValue' \'
    echo "  --operational-certificate-issue-counter-file $COLDKEYS_DIR/$POOL_OPCERT_COUNTER_FILENAME"
    echo '----------------------------------------'
    sleep 1
    echo
    echo -e "${FG_YELLOW}4. カウンター番号確認${NC}"
    echo '----------------------------------------'
    echo 'cardano-cli text-view decode-cbor \'
    echo " --in-file  $COLDKEYS_DIR/$POOL_OPCERT_COUNTER_FILENAME"' \'
    echo ' | grep int | head -1 | cut -d"(" -f2 | cut -d")" -f1'
    echo '----------------------------------------'
    echo -e "${FG_RED}上記コマンド実行の戻り値が ${FG_YELLOW}$counterValue ${FG_RED}であることを確認してください${NC}"
    echo
    read -p "上記を終えたらEnterを押して次の操作を表示します"

    clear
    echo
    echo '■エアギャップオフラインマシンで以下の操作を実施してください'
    echo
    printf "${FG_MAGENTA}現在のstartKesPeriod${NC}: ${FG_YELLOW}${startKesPeriod}${NC}\n\n"
    sleep 2
    echo
    echo -e "${FG_YELLOW}5. $POOL_OPCERT_FILENAMEファイルを作成する${NC}"
    echo '----------------------------------------'
    echo 'cd $NODE_HOME'
    echo 'cardano-cli node issue-op-cert \'
    echo "  --kes-verification-key-file $POOL_HOTKEY_VK_FILENAME "'\'
    echo "  --cold-signing-key-file $COLDKEYS_DIR/$POOL_COLDKEY_SK_FILENAME"' \'
    echo "  --operational-certificate-issue-counter $COLDKEYS_DIR/$POOL_OPCERT_COUNTER_FILENAME"' \'
    echo "  --kes-period ${startKesPeriod} "'\'
    echo "  --out-file $POOL_OPCERT_FILENAME"
    echo "chmod a-rwx $COLDKEYS_DIR"
    echo '----------------------------------------'
    sleep 1
    echo
    echo -e "${FG_YELLOW}6. エアギャップの $POOL_OPCERT_FILENAME をBPのcnodeディレクトリにコピーしてください${NC}"
    echo '----------------------------------------'
    echo ">> [エアギャップ] ⇒ $POOL_OPCERT_FILENAME ⇒ [BP]"
    echo '----------------------------------------'
    echo
    read -p "操作が終わったらEnterを押してください"

    echo
    echo "新しいKESファイルを有効化するにはノードを再起動する必要があります"
    echo "ノードを再起動しますか？"
    echo
    echo "[1] このまま再起動する　[2] 手動で再起動する"
    echo
    while :
      do
        read -n 1 restartnum
        if [ "$restartnum" == "1" ] || [ "$restartnum" == "2" ]; then
          case ${restartnum} in
            1) 
              sudo systemctl reload-or-restart cardano-node
              printf "\n${FG_GREEN}ノードを再起動しました。${NC}\nglive viewを起動して同期状況を確認してください\n\n"
              printf "${FG_RED}ノード同期完了後、当ツールの[2] ブロック生成状態チェックを実行してください${NC}\n\n"
              break
              ;;
            2) 
              clear
              echo "SPO JAPAN GUILD TOOL Closed!" 
              exit ;;
          esac
          break
        elif [ "$kesnum" == '' ]; then
          printf "入力記号が不正です。再度入力してください\n"
        else
          printf "入力記号が不正です。再度入力してください\n"
        fi
    done

    exit
    ;;

  4)
  clear

  envCheck=`cat $NODE_HOME/scripts/env | grep "#UPDATE_CHECK="`
  if [ -n "$envCheck" ]; then
    sed -i $NODE_HOME/scripts/env \
      -e '1,77s!#UPDATE_CHECK!UPDATE_CHECK!'
  fi

  upFlag=`sed -n '1,77p' $NODE_HOME/scripts/env | grep "UPDATE_CHECK=" | cut -c 15`

    echo '------------------------------------------------------------------------'
    echo -e "> envUpdateチェックフラグ切替　　　現在のフラグ状態：${FG_GREEN} $upFlag${NC}"   
    echo '------------------------------------------------------------------------'
    echo
    echo 'この作業はGliveView、cncli.shに関連するファイルの自動更新フラグを切り替えます'
    echo
    echo '■手順（Yにする場合）'
    echo '[1]Yes(Y)にするを選択'
    echo 'GliveViewを起動し、アップデートメッセージにYを入力してEnter'
    echo 'SJGToolを再度起動し、[2]No(N)にするを選択'
    echo
    echo '------------------------------------------------------------------------'
printf "
\n
Updateチェックフラグを
[1] ${FG_GREEN}Yes(Y)にする${NC}
[2] ${FG_RED}No(N)にする${NC}
\n
----------------------------
[h] ホームへ戻る　[q] 終了
\n
"

read -n 1 -p "メニュー番号を入力してください : >" patch
    case ${patch} in
      1)
        clear

        if [ $upFlag = "N" ]; then
          sed -i $NODE_HOME/scripts/env \
            -e '1,77s!UPDATE_CHECK="N"!UPDATE_CHECK="Y"!'
          
          upFlag_fix=`sed -n '1,77p' $NODE_HOME/scripts/env | grep "UPDATE_CHECK=" | cut -c 15`
          echo
          echo -e "envファイルのUpdateチェックを${FG_GREEN} $upFlag_fix ${NC}にしました。"
          echo "GliveViewを起動し、UpdateチェックでYを入力してください"
          echo
          select_rtn

        else
          echo
          echo -e "現在のフラグは${FG_GREEN} Y ${NC}になっています"
          echo "GliveViewを起動し、UpdateチェックでYを入力してください"
          echo
          select_rtn
        fi

      ;;

      2)
        clear
        if [ $upFlag = "Y" ]; then
          sed -i $NODE_HOME/scripts/env \
            -e '1,77s!UPDATE_CHECK="Y"!UPDATE_CHECK="N"!'
          
          upFlag_fix=`sed -n '1,77p' $NODE_HOME/scripts/env | grep "UPDATE_CHECK=" | cut -c 15`
          echo
          echo -e "envファイルのUpdateチェックを${FG_GREEN} $upFlag_fix ${NC}にしました。"
          select_rtn
        else
          echo
          echo -e "現在のフラグは${FG_GREEN} N ${NC}になっています"
          echo
          select_rtn
        fi
      ;;

      h)
        main ;;
      q) 
        clear
        echo
        echo "SPO JAPAN GUILD TOOL Closed!" 
        echo
        exit ;;
      *)
        echo '番号が不正です'
        select_rtn
        ;;
      esac
    ;;

  ################################################
  ## Catalyst有権者登録 
  ################################################
  5)
  clear

    echo '------------------------------------------------------------------------'
    echo -e "> Catalyst有権者登録"
    echo '------------------------------------------------------------------------'
    
    poolfileCheck
    get_pooldata
    bech32_path="$(which bech32)"
    signer_path="$(which cardano-signer)"
    toolbox_path="$(which catalyst-toolbox)"
    pool_ticker="$(cat $NODE_HOME/pooldata.txt | jq -r ".[].meta_json.ticker")"
    version_chk=0

    pre_check(){
      #依存関係インストールチェック
      echo
      echo " Catalyst有権者登録 要件チェック"
      echo " --------------------------------------------------------"
      if [ -n "$bech32_path" ]; then
        bech32_version="$(bech32 -v)"
        printf " 　　　　　bech32 : ${FG_GREEN}$bech32_version${NC}\n"
        version_chk=$(($version_chk+1))
      else
        printf " 　　　　　bech32 : ${FG_RED}未インストール${NC}\n"
      fi

      if [ -n "$signer_path" ]; then
        signer_version="$(cardano-signer help | grep -m 1 "cardano-signer" | cut -d' ' -f2)"
        printf " 　cardano-signer : ${FG_GREEN}$signer_version${NC}\n"
        version_chk=$(($version_chk+1))
      else
        printf " 　cardano-signer : ${FG_RED}未インストール${NC}\n"
      fi
      
      if [ -n "$toolbox_path" ]; then
        toolbox_version="$(catalyst-toolbox --version | cut -d' ' -f2)"
        printf " catalyst-toolbox : ${FG_GREEN}$toolbox_version${NC}\n"
        version_chk=$(($version_chk+1))
      else
        printf " catalyst-toolbox : ${FG_RED}未インストール${NC}\n\n"
      fi

      if [ $version_chk -eq 3 ]; then
        #payment.addr残高チェック
        payment_utxo
        #total_balance=490000000
        if [ $total_balance -lt 500000000 ]; then
          printf " $WALLET_PAY_ADDR_FILENAME残高 : ${FG_RED}$(scale1 ${total_balance}) ADA${NC}\n"
          printf " 　　$WALLET_PAY_ADDR_FILENAME : ${FG_GREEN}$(cat $NODE_HOME/$WALLET_PAY_ADDR_FILENAME)${NC}\n\n"
          printf " ${FG_RED}有権者登録には500ADA以上の残高が必要です${NC}\n"
          printf " $WALLET_PAY_ADDR_FILENAMEに500ADA以上入金してから実施してください\n\n"
          select_rtn
        else
          printf " $WALLET_PAY_ADDR_FILENAME残高 : ${FG_GREEN}$(scale1 ${total_balance}) ADA${NC}\n"
          printf " 　　$WALLET_PAY_ADDR_FILENAME : ${FG_GREEN}$(cat $NODE_HOME/$WALLET_PAY_ADDR_FILENAME)${NC}\n"
          printf " 　　 Pool Ticker : ${FG_GREEN}$pool_ticker${NC}\n\n"
          
          printf " 有権者登録が可能です\n\n"
        fi

      else
        printf "${FG_RED}依存関係がインストールされていません${NC}\n\n"
        select_rtn
      fi

      voting_dir="$HOME/CatalystVoting"
      if [ ! -d $voting_dir ]; then
        mkdir $voting_dir
        printf "作業ディレクトリ ${FG_GREEN}$voting_dir${NC} を作成しました\n\n"
      fi
    }
    

    create_voting_keys(){
      #Votingキーファイル作成
      cardano-signer keygen \
      --cip36 \
      --json-extended \
      --out-skey $HOME/CatalystVoting/${pool_ticker}_voting.skey \
      --out-vkey $HOME/CatalystVoting/${pool_ticker}_voting.vkey \
      --out-file $HOME/CatalystVoting/${pool_ticker}_voting.json

      printf "${FG_YELLOW}投票用キーファイルとjsonを作成しました${NC}\n"
      printf "${FG_GREEN}$HOME/CatalystVoting/${pool_ticker}_voting.skey${NC}\n"
      printf "${FG_GREEN}$HOME/CatalystVoting/${pool_ticker}_voting.vkey${NC}\n"
      printf "${FG_GREEN}$HOME/CatalystVoting/${pool_ticker}_voting.json${NC}\n\n"
      echo
      printf " ${FG_RED}■ 重要事項 ■${NC}\n"
      echo '---------------------------------------------------------------------------------------------------------------------------------'
      printf " 1. 上記の3ファイルを使用して有権者登録作業を行うため、まだ削除しないでください\n\n"
      printf " 1. 上記の3ファイルをダウンロードして、USBなどへバックアップしてください\n\n"
      printf " 2. ${FG_YELLOW}${pool_ticker}_voting.json${NC} には、${FG_RED}復元フレーズ${NC}が含まれています\n"
      printf " 　　Fund11から開始予定のWeb版Catalyst投票センターを使用する際に必要になりますので、${FG_RED}厳重に保管して下さい${NC}\n"
      echo '---------------------------------------------------------------------------------------------------------------------------------'
      echo
      read -p "重要事項を実行・理解したらEnterを押して下さい"
      echo
    }

    create_regist_cbor(){
      echo
      echo "エアギャップオフラインマシンで以下の操作を実施してください"
      echo
      echo -e "${FG_YELLOW}1. 上記でダウンロードした${pool_ticker}_voting.vkey をエアギャップのcnodeディレクトリにコピーしてください${NC}"
      echo '----------------------------------------'
      echo ">> [BP] ⇒ ${pool_ticker}_voting.vkey ⇒ [エアギャップ]"
      echo '----------------------------------------'
      echo
      echo -e "${FG_YELLOW}2. エアギャップで登録ファイルを作成してください${NC}"
      echo '----------------------------------------'
      echo 'cd $NODE_HOME'
      echo 'cardano-signer sign --cip36 \'
      echo "  --payment-address $(cat $NODE_HOME/$WALLET_PAY_ADDR_FILENAME)"' \'
      echo "  --vote-public-key ${pool_ticker}_voting.vkey"' \'
      echo '  --secret-key stake.skey \'
      #echo '  --json \'
      echo '  --out-cbor vote-registration.cbor'
      echo '----------------------------------------'
      echo
      echo -e "${FG_YELLOW}3. エアギャップの vote-registration.cbor をBPの${FG_RED}$HOME/CatalystVoting${NC} ディレクトリにコピーしてください${NC}"
      echo '----------------------------------------'
      echo ">> [エアギャップ] ⇒ vote-registration.cbor ⇒ [BP]"
      echo '----------------------------------------'
      read -p "1～3の操作が終わったらEnterを押してください"
    }
    

    submited_voting_tx(){
      #トランザクション作成
      while :
        do
        regifile_check=`filecheck "$HOME/CatalystVoting/vote-registration.cbor"`
        if [ $regifile_check == "true" ]; then
          break
        else
          printf "\n ${FG_RED}vote-registration.cborが見つかりません${NC}\n"
          read -p " BPの$HOME/CatalystVotingディレクトリにコピーしたらEnterを押して下さい"
        fi
      done
      
      clear
      echo "トランザクションを作成します..."

      
      current_Slot
      payment_utxo

      echo -e "\nWallet残高 :$(scale1 ${total_balance}) ADA\n"
      #トランザクションファイル仮作成
      cardano-cli transaction build-raw \
      ${tx_in} \
      --tx-out $(cat $NODE_HOME/$WALLET_PAY_ADDR_FILENAME)+${total_balance} \
      --invalid-hereafter $(( ${currentSlot} + 10000)) \
      --fee 200000 \
      --metadata-cbor-file $HOME/CatalystVoting/vote-registration.cbor \
      --out-file tx.tmp

      #手数料計算
      fee=$(cardano-cli transaction calculate-min-fee \
      --tx-body-file tx.tmp \
      --witness-count 1 \
      --protocol-params-file $NODE_HOME/params.json | awk '{ print $1 }')
      
      txOut=$((${total_balance}-${fee}))

      cardano-cli transaction build-raw \
      ${tx_in} \
      --tx-out $(cat $NODE_HOME/$WALLET_PAY_ADDR_FILENAME)+${txOut} \
      --invalid-hereafter $(( ${currentSlot} + 10000)) \
      --fee ${fee} \
      --metadata-cbor-file $HOME/CatalystVoting/vote-registration.cbor \
      --out-file tx.raw

      #エアギャップ操作メッセージ
      echo
      echo
      echo
      echo '■Txファイルを作成しました。エアギャップオフラインマシンで以下の操作を実施してください'
      echo
      echo -e "${FG_YELLOW}1. BPのtx.raw をエアギャップのcnodeディレクトリにコピーしてください${NC}"
      echo '----------------------------------------'
      echo ">> [BP] ⇒ tx.raw ⇒ [エアギャップ]"
      echo '----------------------------------------'
      echo
      echo -e "${FG_YELLOW}2. エアギャップでトランザクションファイルに署名してください${NC}"
      echo '----------------------------------------'
      echo 'cd $NODE_HOME'
      echo 'cardano-cli transaction sign \'
      echo '  --tx-body-file tx.raw \'
      echo '  --signing-key-file payment.skey \'
      echo "  $NETWORK_IDENTIFIER "'\'
      echo '  --out-file tx.signed'
      echo '----------------------------------------'
      echo
      echo -e "${FG_YELLOW}3. エアギャップの tx.signed をBPのcnodeディレクトリにコピーしてください${NC}"
      echo '----------------------------------------'
      echo ">> [エアギャップ] ⇒ tx.signed ⇒ [BP]"
      echo '----------------------------------------'
      echo
      echo "1～3の操作が終わったらEnterを押してください"
      read -p "トランザクション送信をキャンセルする場合はEnterを押して2を入力してください"

      #トランザクション送信
      tx_submit

      echo $tx_id > $HOME/CatalystVoting/txhash.log

      #トランザクション確認
      printf "\n${FG_YELLOW}Tx承認を確認しています。このまましばらくお待ち下さい...${NC}\n\n"
      while :
        do
        koios_tx_status=`curl -s -X POST "$KOIOS_API/tx_status" -H "Accept: application/json" -H "content-type: application/json" -d "{\"_tx_hashes\":[\"$tx_id\"]}" | jq -r '.[].num_confirmations'`
        if [ $koios_tx_status != "null" ] && [ $koios_tx_status -gt 1 ]; then
          printf "確認済みブロック:$koios_tx_status ${FG_GREEN}Txが承認されました${NC}\n\n"
          sleep 3s
          break
        else
          sleep 30s
        fi
      done
    }
    
    create_qrcode(){
      #QRコード作成
      clear
      echo
      echo "-----------------------------------------------"
      printf " 投票アプリで使用するQRコードを作成します\n"
      echo "-----------------------------------------------"
      echo
      sleep 3s

      while :
        do
        read -n 4 -p " 任意の4桁PINコード(数字4桁)を入力してください > " send_pincode
        if [[ "$send_pincode" =~ ^[0-9]{4}+$ ]]; then
          printf "\n\n 入力したPINコードは ${FG_GREEN}$send_pincode${NC} です\n\n"
          printf "この数字で決定しますか？ ${FG_YELLOW}決定する場合は数字を忘れないよう保管してください。${NC}\n\n"
          printf " [1] 決定する　[2] 変更する\n"
          read -s -n 1 pin_retun_msg
            if [ $pin_retun_msg -eq 1 ]; then
              break 1
            else
              printf "\n ${FG_RED}PINコードを再度入力してください${NC}\n\n"
              continue 1
            fi
        else
          printf "\n ${FG_RED}PINコードは4桁の数字で入力してください${NC}\n\n"
        fi
      done
      
      while :
        do
        skey_check=`filecheck "$HOME/CatalystVoting/${pool_ticker}_voting.skey"`
        if [ ${skey_check} == "true" ]; then
          catalyst-toolbox qr-code encode \
            --pin $(echo ${send_pincode}) \
            --input <(cat $HOME/CatalystVoting/${pool_ticker}_voting.skey | jq -r .cborHex | cut -c 5-132 | bech32 "ed25519e_sk") \
            --output $HOME/CatalystVoting/${pool_ticker}_vote_qrcode.png \
            img
            break
        else
          printf "\n ${FG_RED}${pool_ticker}_voting.skeyが見つかりません${NC}\n"
          read -p " ${FG_YELLOW}$HOME/CatalystVoting${NC} ディレクトリに保存してENTERを押して下さい"
        fi
      done


      qr_check=`filecheck "$HOME/CatalystVoting/${pool_ticker}_vote_qrcode.png"`
      if [ $qr_check == "true" ]; then
        echo
        echo "QRコードを作成しました"
        echo "---------------------------------------------------------------------------------------------------------"
        printf " $HOME/CatalystVoting/ ディレクトリに ${FG_GREEN}${pool_ticker}_vote.qrcode.png${NC} が作成されました\n"
        printf " ${FG_YELLOW}このファイルをダウンロードして保管してください${NC}\n\n"
        printf " このQRコードとPINコードを使用して、Catalyst Voting appで投票することが可能です\n\n"
        echo "---------------------------------------------------------------------------------------------------------"
      else
        printf " QRコードの作成に失敗しました\n"
      fi

    select_rtn
    }

    #起動チェック
    voting_s_file_check=`filecheck "$HOME/CatalystVoting/${pool_ticker}_voting.skey"`
    voting_v_file_check=`filecheck "$HOME/CatalystVoting/${pool_ticker}_voting.vkey"`
    voting_j_file_check=`filecheck "$HOME/CatalystVoting/${pool_ticker}_voting.json"`
    cbor_file_check=`filecheck "$HOME/CatalystVoting/vote-registration.cbor"`
    txlog_file_check=`filecheck "$HOME/CatalystVoting/txhash.log"`
    qrcode_file_check=`filecheck "$HOME/CatalystVoting/${pool_ticker}_vote_qrcode.png"`

    if [ $voting_s_file_check == "false" ] && [ $voting_v_file_check == "false" ] && [ $voting_j_file_check == "false" ] && [ $cbor_file_check == "false" ] && [ $txlog_file_check == "false" ] && [ $qrcode_file_check == "false" ]; then
      printf "投票用キーファイル作成: ${FG_YELLOW}未作成${NC}　CBORファイル作成: ${FG_YELLOW}未作成${NC}　トランザクション送信: ${FG_YELLOW}未送信${NC}　QRコード作成: ${FG_YELLOW}未作成${NC}\n\n"
      sleep 3s
      pre_check
      create_voting_keys
      create_regist_cbor
      submited_voting_tx
      create_qrcode
    elif [ $voting_s_file_check == "true" ] && [ $voting_v_file_check == "true" ] && [ $voting_j_file_check == "true" ] && [ $cbor_file_check == "false" ] && [ $txlog_file_check == "false" ] && [ $qrcode_file_check == "false" ]; then
      printf "投票用キーファイル作成: ${FG_GREEN}作成済${NC}　CBORファイル作成: ${FG_YELLOW}未作成${NC}　トランザクション送信: ${FG_YELLOW}未送信${NC}　QRコード作成: ${FG_YELLOW}未作成${NC}\n\n"
      sleep 3s
      create_regist_cbor
      submited_voting_tx
      create_qrcode
    elif [ $voting_s_file_check == "true" ] && [ $voting_v_file_check == "true" ] && [ $voting_j_file_check == "true" ] && [ $cbor_file_check == "true" ] && [ $txlog_file_check == "false" ] && [ $qrcode_file_check == "false" ]; then
      printf "投票用キーファイル作成: ${FG_GREEN}作成済${NC}　CBORファイル作成: ${FG_GREEN}作成済${NC}　トランザクション送信: ${FG_YELLOW}未送信${NC}　QRコード作成: ${FG_YELLOW}未作成${NC}\n\n"
      sleep 3s
      submited_voting_tx
      create_qrcode
    elif [ $voting_s_file_check == "true" ] && [ $voting_v_file_check == "true" ] && [ $voting_j_file_check == "true" ] && [ $cbor_file_check == "true" ] && [ $txlog_file_check == "true" ] && [ $qrcode_file_check == "false" ]; then
      printf "投票用キーファイル作成: ${FG_GREEN}作成済${NC}　CBORファイル作成: ${FG_GREEN}作成済${NC}　トランザクション送信: ${FG_GREEN}送信済${NC}　QRコード作成: ${FG_YELLOW}未作成${NC}\n\n"
      sleep 3s
      create_qrcode
    elif [ $txlog_file_check == "true" ] && [ $qrcode_file_check == "true" ]; then
      printf " 有権者登録済です\n\n"
      select_rtn
    else
      printf " 有権者登録済です\n\n"
      select_rtn
    fi
    
  ;;

  6)
    clear

    echo "------------------------------------------------------------"
    echo -e ">> gLiveView 1.27.x → 1.28.x アップデート"
    echo "------------------------------------------------------------"

    current_glive_ver="$(cat $NODE_HOME/scripts/gLiveView.sh | grep "GLV_VERSION=")"
    current_glive_ver=${current_glive_ver#GLV_VERSION=v}

    update_glive() {
      clear
      cd $NODE_HOME/scripts
      printf "既存ファイルをバックアップ...\n\n"
      cp cncli.sh cncli.sh-1.27
      echo "$NODE_HOME/scripts/cncli.sh-1.27"
      cp env env-1.27
      echo "$NODE_HOME/scripts/env-1.27"
      cp gLiveView.sh gLiveView.sh-1.27
      echo "$NODE_HOME/scripts/gLiveView.sh-1.27"
      cp cntools.library cntools.library-1.27
      echo "$NODE_HOME/scripts/cntools.library-1.27"
      echo

      wget -q https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/cncli.sh -O ./cncli.sh
      wget -q https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env -O ./env
      wget -q https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh -O ./gLiveView.sh
      wget -q https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/cntools.library -O cntools.library
      printf "${FG_GREEN}依存ファイルを更新しました${NC}\n\n"

      PORT=`grep "PORT=" $NODE_HOME/startBlockProducingNode.sh`
      b_PORT=${PORT#"PORT="}

      sed -i $NODE_HOME/scripts/env \
        -e '1,73s!#CNODEBIN="${HOME}/.local/bin/cardano-node"!CNODEBIN="/usr/local/bin/cardano-node"!' \
        -e '1,73s!#CCLI="${HOME}/.local/bin/cardano-cli"!CCLI="/usr/local/bin/cardano-cli"!' \
        -e '1,73s!#CNCLI="${HOME}/.local/bin/cncli"!CNCLI="${HOME}/.cargo/bin/cncli"!' \
        -e '1,73s!#CNODE_HOME="/opt/cardano/cnode"!CNODE_HOME='${NODE_HOME}'!' \
        -e '1,73s!#CNODE_PORT=6000!CNODE_PORT='${b_PORT}'!' \
        -e '1,73s!#UPDATE_CHECK="Y"!UPDATE_CHECK="N"!' \
        -e '1,73s!#CONFIG="${CNODE_HOME}/files/config.json"!CONFIG="${CNODE_HOME}/'${NODE_CONFIG}'-config.json"!' \
        -e '1,73s!#SOCKET="${CNODE_HOME}/sockets/node0.socket"!SOCKET="${CNODE_HOME}/db/socket"!' \
        -e '1,73s!#BLOCKLOG_TZ="UTC"!BLOCKLOG_TZ="Asia/Tokyo"!' \
        -e '1,73s!#POOL_NAME=""!POOL_DIR="${CNODE_HOME}"!' \
        -e '1,73s!#WALLET_PAY_ADDR_FILENAME="payment.addr"!WALLET_PAY_ADDR_FILENAME="payment.addr"!' \
        -e '1,73s!#WALLET_STAKE_ADDR_FILENAME="reward.addr"!WALLET_STAKE_ADDR_FILENAME="stake.addr"!' \
        -e '1,73s!#POOL_HOTKEY_VK_FILENAME="hot.vkey"!POOL_HOTKEY_VK_FILENAME="kes.vkey"!' \
        -e '1,73s!#POOL_HOTKEY_SK_FILENAME="hot.skey"!POOL_HOTKEY_SK_FILENAME="kes.skey"!' \
        -e '1,73s!#POOL_COLDKEY_VK_FILENAME="cold.vkey"!POOL_COLDKEY_VK_FILENAME="node.vkey"!' \
        -e '1,73s!#POOL_COLDKEY_SK_FILENAME="cold.skey"!POOL_COLDKEY_SK_FILENAME="node.skey"!' \
        -e '1,73s!#POOL_OPCERT_COUNTER_FILENAME="cold.counter"!POOL_OPCERT_COUNTER_FILENAME="node.counter"!' \
        -e '1,73s!#POOL_OPCERT_FILENAME="op.cert"!POOL_OPCERT_FILENAME="node.cert"!' \
        -e '1,73s!#POOL_VRF_SK_FILENAME="vrf.skey"!POOL_VRF_SK_FILENAME="vrf.skey"!'
      
      printf "${FG_YELLOW}envファイルのユーザー変数を変更しました${NC}\n"

      sed -i $NODE_HOME/scripts/cncli.sh \
        -e '1,73s!#POOL_ID=""!POOL_ID="'$(cat $NODE_HOME/$POOL_ID_FILENAME)'"!' \
        -e '1,73s!#POOL_ID_BECH32=""!POOL_ID_BECH32="'$(cat $NODE_HOME/$POOL_ID_FILENAME-bech32)'"!' \
        -e '1,73s!#POOL_VRF_SKEY=""!POOL_VRF_SKEY="${CNODE_HOME}/vrf.skey"!' \
        -e '1,73s!#POOL_VRF_VKEY=""!POOL_VRF_VKEY="${CNODE_HOME}/vrf.vkey"!'
      
      printf "${FG_YELLOW}cncli.shのユーザー変数を変更しました${NC}\n\n"
      
      api_key=$(cat $NODE_HOME/scripts/cncli.sh-1.27 | grep "^PT_API_KEY=" | awk '{ sub(" .*$",""); print $0; }')
      pt_ticker=$(cat $NODE_HOME/scripts/cncli.sh-1.27 | grep "^POOL_TICKER=" | awk '{ sub(" .*$",""); print $0; }')

      if [[ -n $api_key || -n $pt_ticker ]]; then

        api_key=${api_key#PT_API_KEY=}
        pt_ticker=${pt_ticker#POOL_TICKER=}

        sed -i $NODE_HOME/scripts/cncli.sh \
          -e '1,73s!#PT_API_KEY=""!PT_API_KEY='${api_key}'!' \
          -e '1,73s!#POOL_TICKER=""!POOL_TICKER='${pt_ticker}'!'
        
        printf "${FG_YELLOW}cncli.shにPOOL-TOOl API-KEYを追記しました${NC}\n"
        
      fi

    }
    
    printf "現在のバージョン: ${FG_YELLOW}$current_glive_ver${NC}\n"

    if [ ${current_glive_ver::-2} != "1.28" ]; then
      echo "アップデートを開始しますか？"
      echo
      echo "[1]開始する [2]キャンセル"
      yes_no
      echo
      update_glive
      printf "gLiveViewを起動してください\n\n"
    else
      library_file_check=$(cat $NODE_HOME/scripts/cntools.library | grep 'getPoolID()')
      if [ -n "$library_file_check" ]; then
        echo "cntools.libraryがアップデートされていません"
      else
        echo "すでにアップデート済みです"
        select_rtn
      fi
    fi
  
  select_rtn
  ;;

  # 6)
  # clear

  # efile_check=`filecheck "$NODE_HOME/$WALLET_PAY_ADDR_FILENAME"`

  # if [ ${efile_check} == "false" ]; then
  #   echo "${WALLET_PAY_ADDR_FILENAME}ファイルが見つかりません"
  #   echo
  #   echo "${NODE_HOME}に${WALLET_PAY_ADDR_FILENAME}をコピーするか"
  #   echo "envファイルのWALLET_PAY_ADDR_FILENAME変数の指定値をご確認ください"
  #   select_rtn
  # fi

  # idfile_check=`filecheck "$NODE_HOME/stakepoolid_hex.txt"`
  # if [ $idfile_check == "false" ]; then
  #   echo "stakepoolid_hex.txtが見つかりません"
  #   echo "エアギャップで作成し、$NODE_HOMEにコピーしてください"
  #   echo
  #   echo "エアギャップ stakepoolid_hex.txt作成コマンド"
  #   echo '---------------------------------------------------------------'
  #   echo "chmod u+rwx $COLDKEYS_DIR"
  #   echo 'cardano-cli stake-pool id \'
  #   echo    "--cold-verification-key-file $COLDKEYS_DIR/$POOL_COLDKEY_VK_FILENAME"' \'
  #   echo    '--output-format hex > $NODE_HOME/stakepoolid_hex.txt'
  #   echo "chmod a-rwx $COLDKEYS_DIR"
  #   echo '---------------------------------------------------------------'
  #   select_rtn
  # fi

  # poll_dir=$HOME/git/spo-poll
  # cli_version="$(cardano-cli version | head -1 | cut -d' ' -f2)"
  # #cli_version="1.35.5"
  # cli_version_check="${cli_version:0:1}"
  # echo "------------------------------------------------------------"
  # echo -e ">> SPO投票(CIP-0094) | cardano-cli: ${FG_YELLOW}${cli_version}${NC}"
  # echo "------------------------------------------------------------"

  
  # if [ $cli_version_check -lt 8 ]; then
  #   cli_path="$poll_dir/cardano-cli"
  #   if [ ! -d $poll_dir ]; then
  #     mkdir $poll_dir
  #     echo -e "作業ディレクトリ ${FG_GREEN}$poll_dir${NC} を作成しました"
  #     cd $poll_dir
  #     wget -q https://github.com/btbf/spojapanguild/raw/d7cd9792ab4cb532b74a8cd1bf30de3c1c03b8a6/scripts/spo-poll/cardano-cli.gz
  #     echo -e "投票用cli(8.0.0-untested)をダウンロードしました\n"
  #     gzip -d cardano-cli.gz
  #     chmod 755 ./cardano-cli
  #     echo -e "投票用CLIパスは ${FG_GREEN}${cli_path}${NC} です"
  #     $cli_path version
  #   fi
  # else
  #     if [ ! -d $poll_dir ]; then
  #       mkdir $poll_dir
  #       echo -e "作業ディレクトリ ${FG_GREEN}$poll_dir${NC} を作成しました"
  #     fi
  #     cli_path=$(which cardano-cli)
  # fi


  # echo -e "\n投票用CLIパス:${FG_GREEN}$(which $cli_path)${NC} | バージョン:${FG_GREEN}$($cli_path version | head -1 | cut -d' ' -f2)${NC}"
  # echo
  # echo -e "この手順は途中でも中断できます\n"

  # cd $poll_dir

  # read -p "投票トランザクションハッシュを入力してください > " txHash
  
  # tx=$(curl -sX POST "$KOIOS_API/tx_metadata" -H "accept: application/json" -H "content-type: application/json"  -d "{\"_tx_hashes\":[\"${txHash}\"]}")
  
  # question_str_length=""
  # option_str=()

  # transrate_jp(){
  #     transrate="MDgxNGQ0YzItZjg3Yi0wY2Q4LTk0ZWUtYzQxMTBlM2Y4ZTVkOmZ4"
  #     dapk=$(echo $transrate | base64 -d)
  #     question_str_jp_response=$(curl -sX POST "https://api-free.deepl.com/v2/translate" -H "Authorization: DeepL-Auth-Key $dapk" -d "text=$1" -d "target_lang=JA")
  #     question_str_jp_text=$(echo $question_str_jp_response | jq -r ".translations[0].text")
  #     echo $question_str_jp_text
  # }


  # if [[ -n $(echo $tx | grep tx_hash) ]]; then
  #   txMeta=$(echo $tx | jq -r .[0].metadata)
  #   if [[ $(echo $txMeta | grep '{ "94":' ) ]]; then
  #     echo -e "\nCIP-0094投票を表示します"

  #     #質問抽出
  #     question_str_length=$(echo $txMeta | jq -r ".\"94\".\"0\" | length")
  #     for (( str_cnt=0; str_cnt<${question_str_length}; str_cnt++ ))
  #     do 
  #       question_str+=$(echo $txMeta | jq -r ".\"94\".\"0\"[${str_cnt}]")
  #     done
      
  #     question_str_jp=$(transrate_jp "$question_str")

  #     echo -e "\n質問：${FG_GREEN}$question_str${NC}"
  #     echo -e "翻訳：${FG_YELLOW}$question_str_jp${NC}\n"

  #     #選択肢抽出
  #     options_str_length=$(echo $txMeta | jq -r ".\"94\".\"1\" | length")
  #     for (( str_cnt=0; str_cnt<${options_str_length}; str_cnt++ ))
  #     do
  #       options_entry_length=$(echo $txMeta | jq -r ".\"94\".\"1\"[${str_cnt}] | length")
  #       for (( str_cnt2=0; str_cnt2<${options_entry_length}; str_cnt2++ ))
  #       do
  #         option_str[${str_cnt}]+=$(echo $txMeta | jq -r ".\"94\".\"1\"[${str_cnt}][${str_cnt2}]")
  #         option_str_jp=$(transrate_jp "${option_str[${str_cnt}]}")
  #         echo -e [${str_cnt}]:${FG_GREEN}${option_str[${str_cnt}]}${NC} : ${FG_YELLOW}$option_str_jp${NC}
  #       done
  #     done

  #     echo
  #     while :
  #     do
  #       read -n 1 -p "どの選択肢に投票しますか？カッコ内の番号を入力してください > " poll_num
  #       if [ -n "$poll_num" ] && [[ $poll_num -lt $options_str_length ]]; then
  #         echo -e "\n\nあなたが入力した項目は [${poll_num}]:${FG_YELLOW}${option_str[${poll_num}]}${NC} です\n"
  #         echo -e "投票データに簡易メッセージを添付しますか？\n"
  #         echo '[1] 添付する　[2] 添付しない'
  #         while :
  #         do
  #           read -n 1 retun_msg
  #           if [ "$retun_msg" == "1" ] || [ "$retun_msg" == "2" ]; then
  #             case ${retun_msg} in
  #               1)
  #                 echo -e "\n------------------------------------------------------------------------\n"
  #                 echo -e "　＊1行(メッセージ)64byteまで入力可能(日本語文字の場合は約22文字(UTF-8:3byte計算))\n"
  #                 echo -e "　＊メッセージは複数行挿入可能。 | で区切ってください\n"
  #                 echo -e "　＊例）${FG_YELLOW}この投票はダミーですよろしくお願いします。|私は別の案を提案します${NC}\n"
  #                 echo -e "------------------------------------------------------------------------\n"
                  
  #                 wget -q https://raw.githubusercontent.com/btbf/spojapanguild/master/scripts/spo-poll/msg-metadata.json -O $poll_dir/msg-metadata.json
  #                 msg_metadata=$(cat $poll_dir/msg-metadata.json)
                  
  #                 ##メタデータに簡易メッセージを添付します
  #                 ## 参考元：https://github.com/gitmachtl/scripts/blob/master/cardano/testnet/13b_sendSpoPoll.sh

  #                 while :
  #                 do
  #                   read -p "添付メッセージを入力してください > " input_message

  #                   if [ -n "$input_message" ]; then
  #                     IFS='|' read -ra message_arr <<< "${input_message}"
  #                     for (( tmpCnt3=0; tmpCnt3<${#message_arr[@]}; tmpCnt3++ ))
  #                     do
  #                       tmpMessage=${message_arr[tmpCnt3]}
  #                       if [[ $(byteLength "${tmpMessage}") -le 64 ]]; then
  #                         msg_metadata=$(jq ".\"674\".map[0].v.list += [ {\"string\": \"${tmpMessage}\"} ]" <<< $msg_metadata);
  #                         echo
  #                       else
  #                         echo -e "\n${FG_RED}メッセージエラー:\"${tmpMessage}\"は64バイトを超えています。入力された文字は $(byteLength "${tmpMessage}") バイトです${NC}"
  #                         echo -e "最初からもう一度やり直してください。\n"
  #                         exit
  #                       fi
  #                     done

  #                     #最終msg-metadata.json作成
  #                     echo $msg_metadata | jq . > $poll_dir/msg-metadata.json
  #                     message_flg=0
  #                     break
  #                   else
  #                     printf "\n${FG_YELLOW}メッセージが未入力です。再度入力してください${NC}\n"
  #                   fi
  #                 done
  #               ;;
  #               2) 
  #                 message_flg=1
  #                 break
  #             esac
  #             break
  #           elif [ "$retun_msg" == '' ]; then
  #             printf "\n${FG_YELLOW}入力記号が不正です。再度入力してください${NC}\n"
  #           else
  #             printf "\n${FG_YELLOW}入力記号が不正です。再度入力してください${NC}\n"
  #           fi
  #         done
  #       break
  #       else
  #         echo -e "\n\n${FG_YELLOW}入力された番号は無効です。再度入力してください${NC}\n"
  #       fi
  #     done

  #     #投票データ作成
  #     txCBOR=$(curl -s GET "https://raw.githubusercontent.com/cardano-foundation/CIP-0094-polls/main/networks/${NODE_CONFIG}/${txHash}/poll.json")
  #     echo "$txCBOR" > $poll_dir/poll_${txHash}-CBOR.json
      
  #     #cliバージョン振り分け
  #     #if [ $cli_version_check -lt 8 ]; then
  #     ${cli_path} governance answer-poll --poll-file $poll_dir/poll_${txHash}-CBOR.json --answer ${poll_num} > $poll_dir/poll_${txHash}-poll-answer.json
  #     #else
  #     #  ${cli_path} governance answer-poll --poll-file $poll_dir/poll_${txHash}-CBOR.json --answer ${poll_num} --out-file $poll_dir/poll_${txHash}-poll-answer.json 2> /dev/null
  #     #fi

  #     if [[ $message_flg -eq 0 ]]; then
  #       tmp_message=$(cat $poll_dir/msg-metadata.json)
  #       tmp_poll_metadata=$(cat ${poll_dir}/poll_${txHash}-poll-answer.json | jq ". |= .+${tmp_message}")
  #       echo $tmp_poll_metadata | jq . > ${poll_dir}/poll_${txHash}-poll-answer.json
  #     else
  #       tmp_poll_metadata=$(cat ${poll_dir}/poll_${txHash}-poll-answer.json | jq .)
  #     fi

  #     echo -e "\n投票メタデータを作成しました！"
  #     echo -e "${FG_DGRAY}${tmp_poll_metadata}${NC}\n"
  #     echo -e "${FG_GREEN}$poll_dir/poll_${txHash}-poll-answer.json${NC}\n"
  #     sleep 2

  #     while :
  #       do
  #         read -n 1 -p "投票Txデータを作成してよろしいですか？ y/n > " create_tx_data
  #         if [ "$create_tx_data" == "y" ] || [ "$create_tx_data" == "n" ]; then
  #           case ${create_tx_data} in
  #             y) 
  #               #echo $create_poll_data
  #               break
  #               ;;
  #             n) 
  #               #echo $create_poll_data
  #               echo -e "\n\nSPO JAPAN GUILD TOOL Closed!" 
  #               echo "投票を最初からやり直してください"
  #               echo
  #               exit ;;
  #           esac
  #           break
  #         elif [ "${create_tx_data}" == '' ]; then
  #           printf "\n${FG_YELLOW}入力記号が不正です。再度入力してください${NC}\n"
  #         else
  #           printf "\n${FG_YELLOW}入力記号が不正です。再度入力してください${NC}\n"
  #         fi
  #       done
      

  #     echo -e "\nTxデータを作成します..."
  #     sleep 2
  #     clear

  #     #ウォレット残高とUTXO参照
  #     payment_utxo
  #     #echo ${tx_in}

  #     echo -e "\nWallet残高 :$(scale1 ${total_balance}) ADA\n"
  #     cardano-cli transaction build \
  #       ${tx_in} \
  #       --change-address $(cat $WALLET_PAY_ADDR_FILENAME) \
  #       --metadata-json-file $poll_dir/poll_${txHash}-poll-answer.json \
  #       --json-metadata-detailed-schema \
  #       --required-signer-hash $(cat $NODE_HOME/stakepoolid_hex.txt) \
  #       $NETWORK_IDENTIFIER \
  #       --out-file $NODE_HOME/poll-answer.tx > /dev/null

  #     #Txサイズチェック
  #     protocolParametersJSON=$(cat $NODE_HOME/params.json)
  #     maxTxSize=$(jq -r .maxTxSize <<< ${protocolParametersJSON})
      
  #     tx_cborHex=$(cat $NODE_HOME/poll-answer.tx | jq -r .cborHex)
  #     txSize=$(( ${#tx_cborHex} / 2 ))

  #     if [[ ${txSize} -le ${maxTxSize} ]]; then
  #       echo  -e "${FG_GREEN}トランザクションサイズ: ${txSize} バイト (最大: ${maxTxSize})${NC}\n"
  #     else
  #       echo -e "${FG_RED}トランザクションサイズがオーバーしています: ${txSize} バイト (最大: ${maxTxSize})${NC}\n"
  #       echo -e"最初からもう一度やり直してください。\n"
  #       exit
  #     fi

  #     echo "$NODE_HOME/poll-answer.txファイルを作成しました"
  #     echo
  #     echo -e "1. BPの${FG_GREEN}poll-answer.tx${NC} をエアギャップのcnodeディレクトリにコピーしてください"
  #     echo '----------------------------------------'
  #     echo ">> [BP] ⇒ poll-answer.tx ⇒ [エアギャップ]"
  #     echo '----------------------------------------'
  #     echo
  #     echo "エアギャップオフラインマシンで以下の操作を実施してください"
  #     echo
  #     echo -e "${FG_YELLOW}2. エアギャップでトランザクションファイルに署名してください${NC}"
  #     echo '----------------------------------------'
  #     echo 'cd $NODE_HOME'
  #     echo 'chmod u+rwx $HOME/cold-keys'
  #     echo 'cardano-cli transaction sign \'
  #     echo '  --tx-body-file poll-answer.tx \'
  #     echo '  --signing-key-file $HOME/cold-keys/node.skey \'
  #     echo '  --signing-key-file payment.skey \'
  #     echo "  $NETWORK_IDENTIFIER "'\'
  #     echo '  --out-file poll-answer-tx.signed'
  #     echo 'chmod a-rwx $HOME/cold-keys'
  #     echo '----------------------------------------'
  #     echo
  #     echo -e "3. エアギャップの ${FG_GREEN}poll-answer-tx.signed${NC} をBPのcnodeディレクトリにコピーしてください"
  #     echo '----------------------------------------'
  #     echo ">> [エアギャップ] ⇒ poll-answer-tx.signed' ⇒ [BP]"
  #     echo '----------------------------------------'
  #     echo
  #     echo "1～3の操作が終わったらEnterを押してください"
  #     read -p "投票送信確認。キャンセルする場合はEnterを押して2を入力してください"

  #     signe_file=`filecheck "$NODE_HOME/poll-answer-tx.signed"`

  #     if [ ${signe_file} == "false" ]; then
  #       echo -e "\n${FG_RED}$NODE_HOMEディレクトリにpoll-answer-tx.signedファイルが見つかりません${NC}"
  #       echo -e "${FG_RED}投票を最初からやり直してください${NC}\n"
  #       exit
  #     fi

  #     #cardano-cli transaction view --tx-file $NODE_HOME/poll-answer-tx.signed
      
  #     echo
  #     echo '[1] 投票Txを送信する　[2] キャンセル'
  #     echo
  #     while :
  #       do
  #         read -n 1 retun_cmd
  #         if [ "$retun_cmd" == "1" ] || [ "$retun_cmd" == "2" ]; then
  #           case ${retun_cmd} in
  #             1) 
  #               tx_id=`cardano-cli transaction txid --tx-file $NODE_HOME/poll-answer.tx`
  #               tx_result=`cardano-cli transaction submit --tx-file $NODE_HOME/poll-answer-tx.signed $NETWORK_IDENTIFIER`
  #               echo
  #               if [[ $tx_result == "Transaction"* ]]; then
  #                 echo '----------------------------------------'
  #                 echo 'Tx送信結果'
  #                 echo '----------------------------------------'
  #                 echo $tx_result
  #                 echo
  #                 echo 'トランザクションURL'
  #                 if [ ${NETWORK_NAME} == 'Mainnet' ]; then
  #                   echo "https://cardanoscan.io/transaction/$tx_id"
  #                 elif [ ${NETWORK_NAME} == 'PreProd' ]; then
  #                   echo "https://preprod.cardanoscan.io/transaction/$tx_id"
  #                 elif [ ${NETWORK_NAME} == 'Preview' ]; then
  #                   echo "https://preview.cardanoscan.io/transaction/$tx_id"
  #                 else
  #                   echo "TxID:$tx_id"
  #                 fi
                  
  #                 printf "\n${FG_GREEN}Tx送信に成功しました${NC}\n"

  #               else
  #                 echo '----------------------------------------'
  #                 echo 'Tx送信結果'
  #                 echo '----------------------------------------'
  #                 echo $tx_result
  #                 echo
  #                 printf "${FG_RED}Tx送信に失敗しました${NC}\n"
  #               fi
  #               ;;
  #             2) 
  #               echo
  #               echo "送信をキャンセルしました"
  #               exit
  #               echo
  #           esac
  #           break
  #         elif [ "$retun_cmd" == '' ]; then
  #           printf "入力記号が不正です。再度入力してください\n"
  #         else
  #           printf "入力記号が不正です。再度入力してください\n"
  #         fi 
  #     done


	#     #echo ""
  #     #echo "Metadata for your answer TX is ready in $poll_dir/poll_${txHash}-poll-answer.json"
  #   else
  #     echo -e "\n${FG_YELLOW}指定のトランザクションにはcip-0094投票データがありません${NC}\n"
  #   fi
  # else
  #   echo -e "\n${FG_RED}TxIDが無効です${NC}\n"
  # fi

  # ;;

  q)
    clear
    echo
    echo "SPO JAPAN GUILD TOOL Closed!" 
    echo
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
byteLength(){
  strings=$1
  echo -n ${strings} | wc -c
}


select_rtn(){
  echo
  echo '[h] メイン画面へ戻る　[q] 終了'
  echo
  while :
    do
      read -n 1 retun_cmd
      if [ "$retun_cmd" == "h" ] || [ "$retun_cmd" == "q" ]; then
        case ${retun_cmd} in
          h) main ;;
          q) 
            clear
            echo
            echo "SPO JAPAN GUILD TOOL Closed!" 
            echo
            exit ;;
        esac
        break
      elif [ "$retun_cmd" == '' ]; then
        printf "入力記号が不正です。再度入力してください\n"
      else
        printf "入力記号が不正です。再度入力してください\n"
      fi
  done
}

kesfileCheck(){
  kes_vk_file_check=`filecheck "$NODE_HOME/$POOL_HOTKEY_VK_FILENAME"`
  if [ $kes_vk_file_check == "false" ]; then
    printf "\n${FG_RED}$POOL_HOTKEY_VK_FILENAMEが見つかりません${NC}\n\n"
    printf "$NODE_HOME/scripts/envの${FG_YELLOW}[POOL_HOTKEY_VK_FILENAME]${NC}の値を正しいファイル名(例：${FG_GREEN}kes.vkey${NC})に書き換えるか\n"
    printf "または、エアギャップにある${FG_GREEN}$POOL_HOTKEY_VK_FILENAME${NC}をBPの${FG_YELLOW}$NODE_HOME${NC}にコピーし再度実行してください\n"
    select_rtn
  fi

  kes_sk_file_check=`filecheck "$NODE_HOME/$POOL_HOTKEY_SK_FILENAME"`
  if [ $kes_sk_file_check == "false" ]; then
    printf "\n${FG_RED}$POOL_HOTKEY_SK_FILENAMEが見つかりません${NC}\n\n"
    printf "$NODE_HOME/scripts/envの${FG_YELLOW}[POOL_HOTKEY_SK_FILENAME]${NC}の値を正しいファイル名(例：${FG_GREEN}kes.skey${NC})に書き換えるか\n"
    printf "または、エアギャップにある${FG_GREEN}$POOL_HOTKEY_SK_FILENAME${NC}をBPの${FG_YELLOW}$NODE_HOME${NC}にコピーし再度実行してください\n"
    select_rtn
  fi
}


air_gap(){
  echo
  echo
  echo
  echo '■Txファイルを作成しました。エアギャップオフラインマシンで以下の操作を実施してください'
  echo
  echo -e "${FG_YELLOW}1. BPのtx.raw をエアギャップのcnodeディレクトリにコピーしてください${NC}"
  echo '----------------------------------------'
  echo ">> [BP] ⇒ tx.raw ⇒ [エアギャップ]"
  echo '----------------------------------------'
  echo
  echo -e "${FG_YELLOW}2. エアギャップでトランザクションファイルに署名してください${NC}"
  echo '----------------------------------------'
  echo 'cd $NODE_HOME'
  echo 'cardano-cli transaction sign \'
  echo '  --tx-body-file tx.raw \'
  echo '  --signing-key-file payment.skey \'
  echo '  --signing-key-file stake.skey \'
  echo "  $NETWORK_IDENTIFIER "'\'
  echo '  --out-file tx.signed'
  echo '----------------------------------------'
  echo
  echo -e "${FG_YELLOW}3. エアギャップの tx.signed をBPのcnodeディレクトリにコピーしてください${NC}"
  echo '----------------------------------------'
  echo ">> [エアギャップ] ⇒ tx.signed ⇒ [BP]"
  echo '----------------------------------------'
  echo
  echo "1～3の操作が終わったらEnterを押してください"
  read -p "出金をキャンセルする場合はEnterを押して2を入力してください"
}

air_gap_payment_only(){
  echo
  echo
  echo
  echo '■Txファイルを作成しました。エアギャップオフラインマシンで以下の操作を実施してください'
  echo
  echo -e "${FG_YELLOW}1. BPのtx.raw をエアギャップのcnodeディレクトリにコピーしてください${NC}"
  echo '----------------------------------------'
  echo ">> [BP] ⇒ tx.raw ⇒ [エアギャップ]"
  echo '----------------------------------------'
  echo
  echo -e "${FG_YELLOW}2. エアギャップでトランザクションファイルに署名してください${NC}"
  echo '----------------------------------------'
  echo 'cd $NODE_HOME'
  echo 'cardano-cli transaction sign \'
  echo '  --tx-body-file tx.raw \'
  echo '  --signing-key-file payment.skey \'
  echo "  $NETWORK_IDENTIFIER "'\'
  echo '  --out-file tx.signed'
  echo '----------------------------------------'
  echo
  echo -e "${FG_YELLOW}3. エアギャップの tx.signed をBPのcnodeディレクトリにコピーしてください${NC}"
  echo '----------------------------------------'
  echo ">> [エアギャップ] ⇒ tx.signed ⇒ [BP]"
  echo '----------------------------------------'
  echo
  echo "1～3の操作が終わったらEnterを押してください"
  read -p "出金をキャンセルする場合はEnterを押して2を入力してください"
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
        $NETWORK_IDENTIFIER \
        --address $(cat $WALLET_STAKE_ADDR_FILENAME) | jq -r ".[0].rewardAccountBalance")
    echo "プール報酬: `scale1 $rewardBalance` ADA"
    echo

  if [ ${rewardBalance} == 0 ]; then
    
    printf "${FG_RED}出金可能な報酬はありません${NC}\n"
    select_rtn
  fi
}


#現在のスロット
current_Slot(){
  currentSlot=$(cardano-cli query tip $NETWORK_IDENTIFIER | jq -r '.slot')
  #echo Current Slot: $currentSlot
}

#payment.addrUTXO算出
payment_utxo(){
  cd $NODE_HOME
  cardano-cli query utxo \
    --address $(cat $WALLET_PAY_ADDR_FILENAME) \
    $NETWORK_IDENTIFIER > fullUtxo.out

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
  while :
    do
      read -s -n 1 retun_cmd
      if [ "$retun_cmd" == "1" ] || [ "$retun_cmd" == "2" ]; then
        case ${retun_cmd} in
          1) 
            tx_id=`cardano-cli transaction txid --tx-body-file tx.raw`
            tx_result=`cardano-cli transaction submit --tx-file tx.signed $NETWORK_IDENTIFIER`
            echo
            if [[ $tx_result == "Transaction"* ]]; then
              echo '----------------------------------------'
              echo 'Tx送信結果'
              echo '----------------------------------------'
              echo $tx_result
              echo
              echo 'トランザクションURL'
              if [ ${NETWORK_NAME} == 'Mainnet' ]; then
                echo "https://cardanoscan.io/transaction/$tx_id"
              elif [ ${NETWORK_NAME} == 'PreProd' ]; then
                echo "https://preprod.cardanoscan.io/transaction/$tx_id"
              elif [ ${NETWORK_NAME} == 'Preview' ]; then
                echo "https://preview.cardanoscan.io/transaction/$tx_id"
              else
                echo "TxID:$tx_id"
              fi
              
              printf "\n${FG_GREEN}Tx送信に成功しました${NC}\n"

            else
              echo '----------------------------------------'
              echo 'Tx送信結果'
              echo '----------------------------------------'
              echo $tx_result
              echo
              printf "${FG_RED}Tx送信に失敗しました${NC}\n"
            fi
            ;;
          2) 
            echo
            echo "送信をキャンセルしました"
            echo
            select_rtn
            echo
        esac
        break
      elif [ "$retun_cmd" == '' ]; then
        printf "入力記号が不正です。再度入力してください\n"
      else
        printf "入力記号が不正です。再度入力してください\n"
      fi 
  done
}

#出金先アドレスチェック
send_address(){
  while :
    do
      read -p "出金先のアドレス(またはADAHandle)を入力してください： > " destinationAddress
      cntDestADDRESS=`echo ${#destinationAddress}`
      if { [ $cntDestADDRESS -ge 30 ]; } && { [[ "$destinationAddress" == addr* ]] || [[ "$destinationAddress" == DdzF* ]]; }; then
        if { [ ${NETWORK_NAME} = "Mainnet" ] && [[ "$destinationAddress" != *_test* ]]; } || { [ ${NETWORK_NAME} != "Mainnet" ] && [[ "$destinationAddress" = *_test* ]]; } ; then
          echo
          echo '------------------------------------------------'
          printf "出金先: ${FG_GREEN}$destinationAddress${NC}\n"
          echo '------------------------------------------------'
          echo

          read -n 1 -p "出金先はこちらでよろしいですか？：(y/n) > " send_check
          if [ "$send_check" == "y" -o "$send_check" == "Y" ]; then
              break 1
          else
            printf "\n${FG_RED}出金先アドレスを再度入力してください${NC}\n\n"
            continue 1
          fi

        else
          printf "\n${FG_RED}現在のネットワーク${NC}(${FG_GREEN}${NETWORK_NAME}${NC})${FG_RED}と異なるアドレスが入力されました。再度ご確認ください${NC}\n"
        fi
      elif [ "$destinationAddress" == "1" ]; then
        printf "\n${FG_YELLOW}出金手続きをキャンセルしました${NC}\n"
        select_rtn
        break
      elif [ -z $destinationAddress ]; then
        printf "\n${FG_RED}出金先アドレスを再度入力してください${NC}\n\n"
      else
      #adahandle
        adahandleADDRESS=`adahandleConvert $destinationAddress`
        #echo $adahandleADDRESS
        if [ -n "$adahandleADDRESS" ]; then
          echo
          echo '------------------------------------------------'
          printf "ADA Handle　　: ${FG_YELLOW}$destinationAddress${NC}\n"
          printf "出金先アドレス: ${FG_GREEN}$adahandleADDRESS${NC}\n"
          echo '------------------------------------------------'
          echo
          destinationAddress=$adahandleADDRESS
          read -n 1 -p "出金先はこちらでよろしいですか？：(y/n) > " send_check
          if [ "$send_check" == "y" -o "$send_check" == "Y" ]; then
              break 1
          else
            printf "\n${FG_RED}出金先アドレスを再度入力してください${NC}\n\n"
            continue 1
          fi
        else
          printf "\n${FG_RED}ADAHandleが見つかりません。再度入力してください${NC}\n\n"
          continue 1
        fi
      fi
  done
}

#アドレス確認繰り返し
send_address_CHECK(){
    read -n 1 -p "出金先はこちらでよろしいですか？：(y/n) > " send_check
  if [ "$send_check" == "y" -o "$send_check" == "Y" ]; then
      break 1
  else
    printf "\n${FG_RED}出金先アドレスを再度入力してください${NC}\n\n"
    continue 1
  fi
}

#adahandleConvert
adahandleConvert(){
  adahandlePolicyID="f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a"
  assetNameHex=`echo -n "${1}" | xxd -b -ps -c 80 | tr -d '\n'`
  curl -s -X GET "$KOIOS_API/asset_addresses?_asset_policy=${adahandlePolicyID}&_asset_name=${assetNameHex}" -H "Accept: application/json" | jq -r '.[].payment_address'
}

#出金前チェック
tx_Check(){
  rows36="%15s ${FG_CYAN}%-15s${NC}\n"
  rows32="%15s ${FG_GREEN}%-15s${NC}\n"
  #printf "$rows" "Send_Address:" "${destinationAddress::20}...${destinationAddress: -20}"
  printf "$rows36" "送金先アドレス:" "$1"
  printf "$rows32" "       送金ADA:" "`scale1 $2` ADA"
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


#プールIDファイルチェック
poolfileCheck(){
  idfile_check=`filecheck "$NODE_HOME/$POOL_ID_BECH32_FILENAME"`
  if [ $idfile_check == "false" ]; then
    echo "$POOL_ID_BECH32_FILENAMEが見つかりません"
    echo "エアギャップで作成し、$NODE_HOMEにコピーしてください"
    echo
    echo "エアギャップ $POOL_ID_BECH32_FILENAME作成コマンド"
    echo '---------------------------------------------------------------'
    echo "chmod u+rwx $COLDKEYS_DIR"
    echo 'cardano-cli stake-pool id \'
    echo    "--cold-verification-key-file $COLDKEYS_DIR/$POOL_COLDKEY_VK_FILENAME"' \'
    echo    "--output-format bech32 > \$NODE_HOME/$POOL_ID_BECH32_FILENAME"
    echo "chmod a-rwx $COLDKEYS_DIR"
    echo '---------------------------------------------------------------'
    select_rtn
  fi
}

#プールデータAPI取得
get_pooldata(){
  #APIリクエストクエリjson生成
  pId_json="{\""_pool_bech32_ids"\":[\""$(cat $NODE_HOME/$POOL_ID_BECH32_FILENAME)"\"]}"

  #API プールデータ取得
  curl -s -X POST "$KOIOS_API/pool_info" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d $pId_json > $NODE_HOME/pooldata.txt
  wait

  pooldata_chk=`cat pooldata.txt`
  if [[ $pooldata_chk != *"pool_id_bech32"* ]]; then
    echo "APIからプールデータを取得できませんでした。再度お試しください"
    select_rtn
  fi
}

yes_no(){
  while :
      do
        read -n 1 kesnum
        if [ "$kesnum" == "1" ] || [ "$kesnum" == "2" ]; then
          case ${kesnum} in
            1) break ;;
            2) 
              clear
              main
              exit ;;
          esac
          break
        elif [ "$kesnum" == '' ]; then
          printf "入力記号が不正です。再度入力してください\n"
        else
          printf "入力記号が不正です。再度入力してください\n"
        fi
    done
}

update(){
  printf "Update Check...\n"
  wget -q https://raw.githubusercontent.com/btbf/spojapanguild/master/scripts/sjgtool.sh -O $NODE_HOME/scripts/sjgtool.sh.tmp
  tmp256=`sha256sum $NODE_HOME/scripts/sjgtool.sh.tmp | awk '{ print $1 }'`
  sh256=`sha256sum $NODE_HOME/scripts/sjgtool.sh | awk '{ print $1 }'`

  
  if [[ ! $tmp256 == $sh256 ]]; then
    CUR_VERSION=$(grep -r ^TOOL_VERSION= "$NODE_HOME/scripts/sjgtool.sh" | cut -d'=' -f2)
    GIT_VERSION=$(grep -r ^TOOL_VERSION= "$NODE_HOME/scripts/sjgtool.sh.tmp" | cut -d'=' -f2)
    mv $NODE_HOME/scripts/sjgtool.sh.tmp $NODE_HOME/scripts/sjgtool.sh
    chmod 755 $NODE_HOME/scripts/sjgtool.sh
    printf "SPO JAPAN GUILD TOOL UPDATE\n"
    printf "Ver.${FG_YELLOW}$CUR_VERSION${NC}から${FG_GREEN}$GIT_VERSION${NC}へアップデートしました\n"
    echo "Enterを押してリロードしてください"
    read Wait
    return 1
  else
    rm $NODE_HOME/scripts/sjgtool.sh.tmp
    clear
    return 2
  fi
}

PARENT=$(cd $(dirname $0);pwd)

env_chk=`filecheck $PARENT/env`
if [ $env_chk == "true" ]; then
  source ./env
  cd $NODE_HOME
else
  clear
  printf "\n\e[31menvファイルが見つかりません\e[0m\n"
  printf "$PARENTディレクトリを確認してください\n"
  select_rtn
fi

clear
POOL_ID_BECH32_FILENAME="${POOL_ID_FILENAME}-bech32"

#poolIDファイルリネーム
poolid_file=`filecheck "$NODE_HOME/stakepoolid_hex.txt"`
new_poolid_file=`filecheck "$NODE_HOME/$POOL_ID_FILENAME"`
if [ ${new_poolid_file} == "false" ]; then
  if [ ${poolid_file} == "true" ]; then
      mv $NODE_HOME/stakepoolid_hex.txt $NODE_HOME/$POOL_ID_FILENAME
      echo -e "${FG_YELLOW}gLiveview1.28シリーズに対応するためプールIDファイルをリネームしました${NC}"
      echo "HEX: stakepoolid_hex.txt → $POOL_ID_FILENAME"
  else
    echo -e "${FG_RED}エラー：poolidファイル(hex)が見つかりませんでした${NC}"
  fi
fi

poolid_file=`filecheck "$NODE_HOME/stakepoolid_bech32.txt"`
new_poolid_bech32_file=`filecheck "$NODE_HOME/$POOL_ID_BECH32_FILENAME"`
if [ ${new_poolid_bech32_file} == "false" ]; then
  if [ ${poolid_file} == "true" ]; then
      mv $NODE_HOME/stakepoolid_bech32.txt $NODE_HOME/$POOL_ID_BECH32_FILENAME
      echo "Bech32: stakepoolid_bech32.txt → $POOL_ID_BECH32_FILENAME"
  else
    echo -e "${FG_RED}エラー：poolidファイル(bech32)が見つかりませんでした${NC}"
  fi
fi

if [[ ${new_poolid_file} == "false" || ${new_poolid_bech32_file} == "false" ]]; then
  echo
  read -p "上記メッセージを確認したらEnterを押してください: "
  clear
fi

#ノード起動確認
CNODE_PID=$(pgrep -fn "$(basename ${CNODEBIN}).*.port ${CNODE_PORT}")
clear
if [[ -n $CNODE_PID ]]; then
  while :
  do
    slot_check=$(curl -s localhost:${PROM_PORT}/metrics | grep slotNum_int)
    if [ -z "$slot_check" ]; then
        echo "ノードが起動するまでこのままお待ちください"
        sleep 30
    else
      main;
      break
    fi
  
  done
    
else 
    printf "\n${FG_RED}ノードを起動して再度実行してください${NC}\n\n"
    exit
fi