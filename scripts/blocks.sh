#!/bin/bash
# shellcheck disable=SC1090,SC2086,SC2154,SC2034,SC2012,SC2140

#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2086,SC2154,SC2034,SC2012,SC2140,SC2028

######################################
# User Variables - Change as desired #
# Common variables set in env file   #
######################################

#TIMEOUT_NO_OF_SLOTS=600 # used when waiting for a new block to be created

# log cntools activities (comment or set empty to disable)
# LOG_DIR set in env file
#CNTOOLS_LOG="${LOG_DIR}/cntools-history.log"

# kes rotation warning (in seconds)
# if disabled KES check will be skipped on startup
#CHECK_KES=false
#KES_ALERT_PERIOD=172800 # default 2 days
#KES_WARNING_PERIOD=604800 # default 7 days

# Default Transaction TTL (slots after which transaction will expire from queue) to use
#TX_TTL=3600

# limit for extended wallet selection menu filtering (balance check and delegation status)
# if more wallets exist than limit set these checks will be disabled to improve performance
#WALLET_SELECTION_FILTER_LIMIT=10

# enable or disable chattr used to protect keys from being overwritten [true|false] (not supported on all systems)
# if disabled standard read-only permission is set instead
#ENABLE_CHATTR=true

# enable or disable dialog used to help in file/dir selection by providing a gui to see available files and folders. [true|false] (not supported on all systems)
# if disabled standard tty input is used
#ENABLE_DIALOG=true

# enable advanced/developer features like metadata transactions, multi-asset management etc. [true|false] (not needed for SPO usage)
#ENABLE_ADVANCED=false

######################################
# Do NOT modify code below           #
######################################

########## Global tasks ###########################################

# General exit handler
cleanup() {
  sleep 0.1
  if { true >&6; } 2<> /dev/null; then
    exec 1>&6 2>&7 3>&- 6>&- 7>&- 8>&- 9>&- # Restore stdout/stderr and close tmp file descriptors
  fi
  [[ -n $1 ]] && err=$1 || err=$?
  [[ $err -eq 0 ]] && clear
  [[ -n ${exit_msg} ]] && echo -e "\n${exit_msg}\n" || echo -e "\nCNTools terminated, cleaning up...\n"
  tput cnorm # restore cursor
  tput sgr0  # turn off all attributes
  exit $err
}
trap cleanup HUP INT TERM
STTY_SETTINGS="$(stty -g < /dev/tty)"
trap 'stty "$STTY_SETTINGS" < /dev/tty' EXIT

# Command     : myExit [exit code] [message]
# Description : gracefully handle an exit and restore terminal to original state
myExit() {
  exit_msg="$2"
  cleanup "$1"
}

usage() {
  cat <<-EOF
		Usage: $(basename "$0") [-o] [-a] [-b <branch name>]
		CNTools - The Cardano SPOs best friend
		
		-o    Activate offline mode - run CNTools in offline mode without node access, a limited set of functions available
		-a    Enable advanced/developer features like metadata transactions, multi-asset management etc (not needed for SPO usage)
    -u    Skip script update check overriding UPDATE_CHECK value in env
		-b    Run CNTools and look for updates on alternate branch instead of master of guild repository (only for testing/development purposes)
		
		EOF
}

CNTOOLS_MODE="CONNECTED"
ADVANCED_MODE="false"
SKIP_UPDATE=N
PARENT="$(dirname $0)"
[[ -f "${PARENT}"/.env_branch ]] && BRANCH="$(cat "${PARENT}"/.env_branch)" || BRANCH="master"

while getopts :oaub: opt; do
  case ${opt} in
    o ) CNTOOLS_MODE="OFFLINE" ;;
    a ) ADVANCED_MODE="true" ;;
    u ) SKIP_UPDATE=Y ;;
    b ) echo "${OPTARG}" > "${PARENT}"/.env_branch ;;
    \? ) myExit 1 "$(usage)" ;;
    esac
done
shift $((OPTIND -1))

#######################################################
# Version Check                                       #
#######################################################
clear

if [[ ! -f "${PARENT}"/env ]]; then
  echo -e "\nCommon env file missing: ${PARENT}/env"
  echo -e "This is a mandatory prerequisite, please install with prereqs.sh or manually download from GitHub\n"
  myExit 1
fi

# Source env file, re-sourced later
if [[ "${CNTOOLS_MODE}" == "OFFLINE" ]]; then
  . "${PARENT}"/env offline &>/dev/null
else
  . "${PARENT}"/env &>/dev/null
fi

# Do some checks when run in connected mode
if [[ ${CNTOOLS_MODE} = "CONNECTED" ]]; then
  # check to see if there are any updates available
  clear
  if [[ ${UPDATE_CHECK} = Y && ${SKIP_UPDATE} != Y ]]; then 

    echo "Checking for script updates..."

    # Check availability of checkUpdate function
    if [[ ! $(command -v checkUpdate) ]]; then
      myExit 1 "\nCould not find checkUpdate function in env, make sure you're using official guild docos for installation!"
    fi

    # check for env update
    ENV_UPDATED=N
    checkUpdate env N N N
    case $? in
      1) ENV_UPDATED=Y ;;
      2) myExit 1 ;;
    esac

    # source common env variables in case it was updated
    . "${PARENT}"/env
    case $? in
      1) myExit 1 "ERROR: CNTools failed to load common env file\nPlease verify set values in 'User Variables' section in env file or log an issue on GitHub" ;;
      2) clear ;;
    esac
  fi
fi


# get helper functions from library file
! . "${PARENT}"/cntools.library && myExit 1

archiveLog # archive current log and cleanup log archive folder

exec 6>&1 # Link file descriptor #6 with normal stdout.
exec 7>&2 # Link file descriptor #7 with normal stderr.
[[ -n ${CNTOOLS_LOG} ]] && exec > >( tee >( while read -r line; do logln "INFO" "${line}"; done ) )
[[ -n ${CNTOOLS_LOG} ]] && exec 2> >( tee >( while read -r line; do logln "ERROR" "${line}"; done ) >&2 )
[[ -n ${CNTOOLS_LOG} ]] && exec 3> >( tee >( while read -r line; do logln "DEBUG" "${line}"; done ) >&6 )
exec 8>&1 # Link file descriptor #8 with custom stdout.
exec 9>&2 # Link file descriptor #9 with custom stderr.


# Verify that shelley transition epoch was properly identified by env
if [[ ${SHELLEY_TRANS_EPOCH} -lt 0 ]]; then # unknown network
  clear
  myExit 1 "${FG_YELLOW}WARN${NC}: This is an unknown network, please manually set SHELLEY_TRANS_EPOCH variable in env file"
fi

###################################################################

function main {

while true; do # Main loop

# Start with a clean slate after each completed or canceled command excluding .dialogrc from purge
#find "${TMP_FOLDER:?}" -type f -not \( -name 'protparams.json' -o -name '.dialogrc' -o -name "offline_tx*" -o -name "*_cntools_backup*" \) -delete

  clear
        println DEBUG "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        println " >> ブロックログ @ Developed by Guild Operators & Customized by BTBF v2.0.0"
        println DEBUG "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        if ! command -v sqlite3 >/dev/null; then
          println ERROR "${FG_RED}ERROR${NC}: sqlite3 not found!"
          waitForInput && continue
        fi
        current_epoch=$(getEpoch)
        println DEBUG "現在のエポック: ${FG_LBLUE}${current_epoch}${NC}\n"
        println DEBUG "実績一覧、または特定のエポックのブロック生成内訳を表示します\n"
        select_opt "[s] 実績一覧" "[e] エポック内訳" "[Esc] 終了"
        case $? in
          0) getAnswerAnyCust epoch_enter "直近のエポック毎実績一覧を表示します (空Enterで直近10エポック、「2」なら直近2エポック)"
             epoch_enter=${epoch_enter:-10}
             if ! isNumber ${epoch_enter}; then
               println ERROR "\n${FG_RED}ERROR${NC}: not a number"
               waitForInput && continue
             fi
             view=1; view_output="${FG_YELLOW}[b] Block View${NC} | [i] Info"
             while true; do
               clear
               println DEBUG "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
               println " >> ブロックログ @ Developed by Guild Operators & Customized by BTBF v2.0.0"
               println DEBUG "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
               current_epoch=$(getEpoch)
               println DEBUG "現在のエポック: ${FG_LBLUE}${current_epoch}${NC}\n"
               if [[ ${view} -eq 1 ]]; then
                 [[ $(sqlite3 "${BLOCKLOG_DB}" "SELECT EXISTS(SELECT 1 FROM blocklog WHERE epoch=$((current_epoch+1)) LIMIT 1);" 2>/dev/null) -eq 1 ]] && ((current_epoch++))
                 first_epoch=$(( current_epoch - epoch_enter ))
                 [[ ${first_epoch} -lt 0 ]] && first_epoch=0
                 ideal_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(epoch_slots_ideal) FROM epochdata WHERE epoch BETWEEN ${first_epoch} and ${current_epoch} ORDER BY LENGTH(epoch_slots_ideal) DESC LIMIT 1;")
                 [[ ${ideal_len} -lt 5 ]] && ideal_len=5
                 luck_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(max_performance) FROM epochdata WHERE epoch BETWEEN ${first_epoch} and ${current_epoch} ORDER BY LENGTH(max_performance) DESC LIMIT 1;")
                 [[ $((luck_len+1)) -le 4 ]] && luck_len=4 || luck_len=$((luck_len+1))
                 printf '|' >&3; printf "%$((5+6+ideal_len+luck_len+7+9+6+7+6+7+27+2))s" | tr " " "=" >&3; printf '|\n' >&3
                 printf "| %-5s | %-6s | %-${ideal_len}s | %-${luck_len}s | ${FG_LBLUE}%-7s${NC} | ${FG_GREEN}%-9s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} |\n" "Epoch" "Leader" "Ideal" "Luck" "Adopted" "Confirmed" "Missed" "Ghosted" "Stolen" "Invalid" >&3
                 printf '|' >&3; printf "%$((5+6+ideal_len+luck_len+7+9+6+7+6+7+27+2))s" | tr " " "=" >&3; printf '|\n' >&3
                 while [[ ${current_epoch} -gt ${first_epoch} ]]; do
                   invalid_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='invalid';" 2>/dev/null)
                   missed_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='missed';" 2>/dev/null)
                   ghosted_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='ghosted';" 2>/dev/null)
                   stolen_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='stolen';" 2>/dev/null)
                   confirmed_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='confirmed';" 2>/dev/null)
                   adopted_cnt=$(( $(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='adopted';" 2>/dev/null) + confirmed_cnt ))
                   leader_cnt=$(( $(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='leader';" 2>/dev/null) + adopted_cnt + invalid_cnt + missed_cnt + ghosted_cnt + stolen_cnt ))
                   IFS='|' && read -ra epoch_stats <<< "$(sqlite3 "${BLOCKLOG_DB}" "SELECT epoch_slots_ideal, max_performance FROM epochdata WHERE epoch=${current_epoch};" 2>/dev/null)" && IFS=' '
                   if [[ ${#epoch_stats[@]} -eq 0 ]]; then
                     epoch_stats=("-" "-")
                   else
                     epoch_stats[1]="${epoch_stats[1]}%"
                   fi
                   printf "| ${FG_LGRAY}%-5s${NC} | ${FG_LGRAY}%-6s${NC} | ${FG_LGRAY}%-${ideal_len}s${NC} | ${FG_LGRAY}%-${luck_len}s${NC} | ${FG_LBLUE}%-7s${NC} | ${FG_GREEN}%-9s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} |\n" "${current_epoch}" "${leader_cnt}" "${epoch_stats[0]}" "${epoch_stats[1]}" "${adopted_cnt}" "${confirmed_cnt}" "${missed_cnt}" "${ghosted_cnt}" "${stolen_cnt}" "${invalid_cnt}" >&3
                   ((current_epoch--))
                 done
                 printf '|' >&3; printf "%$((5+6+ideal_len+luck_len+7+9+6+7+6+7+27+2))s" | tr " " "=" >&3; printf '|\n' >&3
               else
                 println OFF "ブロックログ項目:\n"
                 println OFF "Leader    - 当エポックに割り当てられたスケジュール数"
                 println OFF "Ideal     - アクティブステーク（シグマ）に基づいて割り当てられたブロック数の期待値/理想値"
                 println OFF "Luck      - 期待値における実際に割り当てられたスロットリーダー数の割合"
                 println OFF "Adopted   - ブロック生成成功数"
                 println OFF "Confirmed - 生成したブロックのうちオンチェーン上で確認された数"
                 println OFF "Missed    - スロットでスケジュールされているが、 cncli DB には記録されておらず"
                 println OFF "            他のプールの生成実績も確認できない数"
                 println OFF "Ghosted   - ハイトバトルまたはブロック伝播遅延が発生し、他のプールによってブロックが生成された数"
                 println OFF "Stolen    - 他プールと同一スロットにスケジュールが重なりスロットバトルが発生し"
                 println OFF "            他のプールによってブロックが生成された数"
                 println OFF "Invalid   - プールで生成したブロックに問題が発生した数(KES更新ミスなど)"
                 println OFF "            [logmonitor]に表示されるコードで原因を調べることができます"
               fi
               echo
               println OFF "[h] ホーム | ${view_output} | [*] Refresh"
               read -rsn1 key
               case ${key} in
                 h ) continue 2 ;;
                 b ) view=1; view_output="${FG_YELLOW}[b] ブロック実績${NC} | [i] 情報" ;;
                 i ) view=2; view_output="[b] ブロック実績 | ${FG_YELLOW}[i] 情報${NC}" ;;
                 * ) continue ;;
               esac
             done
             ;;
          1) [[ $(sqlite3 "${BLOCKLOG_DB}" "SELECT EXISTS(SELECT 1 FROM blocklog WHERE epoch=$((current_epoch+1)) LIMIT 1);" 2>/dev/null) -eq 1 ]] && println DEBUG "\n${FG_YELLOW}次エポック[$((current_epoch+1))]のスロットリーダースケジュールが表示可能になっています${NC}"
             echo && getAnswerAnyCust epoch_enter "表示したいエポックを入力してください (空Enterで現在のエポックを表示)"
             [[ -z "${epoch_enter}" ]] && epoch_enter=${current_epoch}
             if [[ $(sqlite3 "${BLOCKLOG_DB}" "SELECT EXISTS(SELECT 1 FROM blocklog WHERE epoch=${epoch_enter} LIMIT 1);" 2>/dev/null) -eq 0 ]]; then
               println "${epoch_enter}エポックには生成されたブロックはありません"
               waitForInput && continue
             fi
             view=1; view_output="${FG_YELLOW}[1] 表示 1${NC} | [2] 表示 2 | [3] 表示 3 | [i] 情報"
             while true; do
               clear
               println DEBUG "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
               println " >> ブロックログ @ Developed by Guild Operators & Customized by BTBF v2.0.0"
               println DEBUG "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
               current_epoch=$(getEpoch)
               println DEBUG "現在のエポック  : ${FG_LBLUE}${current_epoch}${NC}"
               println DEBUG "表示中のエポック : ${FG_LBLUE}${epoch_enter}${NC}\n"
               invalid_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='invalid';" 2>/dev/null)
               missed_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='missed';" 2>/dev/null)
               ghosted_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='ghosted';" 2>/dev/null)
               stolen_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='stolen';" 2>/dev/null)
               confirmed_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='confirmed';" 2>/dev/null)
               adopted_cnt=$(( $(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='adopted';" 2>/dev/null) + confirmed_cnt ))
               leader_cnt=$(( $(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='leader';" 2>/dev/null) + adopted_cnt + invalid_cnt + missed_cnt + ghosted_cnt + stolen_cnt ))
               IFS='|' && read -ra epoch_stats <<< "$(sqlite3 "${BLOCKLOG_DB}" "SELECT epoch_slots_ideal, max_performance FROM epochdata WHERE epoch=${epoch_enter};" 2>/dev/null)" && IFS=' '
               if [[ ${#epoch_stats[@]} -eq 0 ]]; then
                 epoch_stats=("-" "-")
               else
                 epoch_stats[1]="${epoch_stats[1]}%"
               fi
               [[ ${#epoch_stats[0]} -gt 5 ]] && ideal_len=${#epoch_stats[0]} || ideal_len=5
               [[ ${#epoch_stats[1]} -gt 4 ]] && luck_len=${#epoch_stats[1]} || luck_len=4
               printf '|' >&3; printf "%$((6+ideal_len+luck_len+7+9+6+7+6+7+24+2))s" | tr " " "=" >&3; printf '|\n' >&3
               printf "| %-6s | %-${ideal_len}s | %-${luck_len}s | ${FG_LBLUE}%-7s${NC} | ${FG_GREEN}%-9s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} |\n" "Leader" "Ideal" "Luck" "Adopted" "Confirmed" "Missed" "Ghosted" "Stolen" "Invalid" >&3
               printf '|' >&3; printf "%$((6+ideal_len+luck_len+7+9+6+7+6+7+24+2))s" | tr " " "=" >&3; printf '|\n' >&3
               printf "| ${FG_LGRAY}%-6s${NC} | ${FG_LGRAY}%-${ideal_len}s${NC} | ${FG_LGRAY}%-${luck_len}s${NC} | ${FG_LBLUE}%-7s${NC} | ${FG_GREEN}%-9s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} |\n" "${leader_cnt}" "${epoch_stats[0]}" "${epoch_stats[1]}" "${adopted_cnt}" "${confirmed_cnt}" "${missed_cnt}" "${ghosted_cnt}" "${stolen_cnt}" "${invalid_cnt}" >&3
               printf '|' >&3; printf "%$((6+ideal_len+luck_len+7+9+6+7+6+7+24+2))s" | tr " " "=" >&3; printf '|\n' >&3
               echo
               # print block table
               block_cnt=1
               status_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(status) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(status) DESC LIMIT 1;")
               [[ ${status_len} -lt 6 ]] && status_len=6
               block_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(block) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(slot) DESC LIMIT 1;")
               [[ ${block_len} -lt 5 ]] && block_len=5
               slot_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(slot) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(slot) DESC LIMIT 1;")
               [[ ${slot_len} -lt 4 ]] && slot_len=4
               slot_in_epoch_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(slot_in_epoch) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(slot_in_epoch) DESC LIMIT 1;")
               [[ ${slot_in_epoch_len} -lt 11 ]] && slot_in_epoch_len=11
               at_len=24
               size_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(size) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(size) DESC LIMIT 1;")
               [[ ${size_len} -lt 4 ]] && size_len=4
               hash_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(hash) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(hash) DESC LIMIT 1;")
               [[ ${hash_len} -lt 4 ]] && hash_len=4
               if [[ ${view} -eq 1 ]]; then
                 printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+17))s" | tr " " "=" >&3; printf '|\n' >&3
                 printf "| %-${#leader_cnt}s | %-${status_len}s | %-${block_len}s | %-${slot_len}s | %-${slot_in_epoch_len}s | %-${at_len}s |\n" "#" "Status" "Block" "Slot" "SlotInEpoch" "Scheduled At" >&3
                 printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+17))s" | tr " " "=" >&3; printf '|\n' >&3
                 while IFS='|' read -r status block slot slot_in_epoch at; do
                   at=$(TZ="${BLOCKLOG_TZ}" date '+%F %T %Z' --date="${at}")
                   [[ ${block} -eq 0 ]] && block="-"
                   printf "| ${FG_LGRAY}%-${#leader_cnt}s${NC} | ${FG_LGRAY}%-${status_len}s${NC} | ${FG_LGRAY}%-${block_len}s${NC} | ${FG_LGRAY}%-${slot_len}s${NC} | ${FG_LGRAY}%-${slot_in_epoch_len}s${NC} | ${FG_LGRAY}%-${at_len}s${NC} |\n" "${block_cnt}" "${status}" "${block}" "${slot}" "${slot_in_epoch}" "${at}" >&3
                   ((block_cnt++))
                 done < <(sqlite3 "${BLOCKLOG_DB}" "SELECT status, block, slot, slot_in_epoch, at FROM blocklog WHERE epoch=${epoch_enter} ORDER BY slot;" 2>/dev/null)
                 printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+17))s" | tr " " "=" >&3; printf '|\n' >&3
               elif [[ ${view} -eq 2 ]]; then
                 printf '|' >&3; printf "%$((${#leader_cnt}+status_len+slot_len+size_len+hash_len+14))s" | tr " " "=" >&3; printf '|\n' >&3
                 printf "| %-${#leader_cnt}s | %-${status_len}s | %-${slot_len}s | %-${size_len}s | %-${hash_len}s |\n" "#" "Status" "Slot" "Size" "Hash" >&3
                 printf '|' >&3; printf "%$((${#leader_cnt}+status_len+slot_len+size_len+hash_len+14))s" | tr " " "=" >&3; printf '|\n' >&3
                 while IFS='|' read -r status slot size hash; do
                   [[ ${size} -eq 0 ]] && size="-"
                   [[ -z ${hash} ]] && hash="-"
                   printf "| ${FG_LGRAY}%-${#leader_cnt}s${NC} | ${FG_LGRAY}%-${status_len}s${NC} | ${FG_LGRAY}%-${slot_len}s${NC} | ${FG_LGRAY}%-${size_len}s${NC} | ${FG_LGRAY}%-${hash_len}s${NC} |\n" "${block_cnt}" "${status}" "${slot}" "${size}" "${hash}" >&3
                   ((block_cnt++))
                 done < <(sqlite3 "${BLOCKLOG_DB}" "SELECT status, slot, size, hash FROM blocklog WHERE epoch=${epoch_enter} ORDER BY slot;" 2>/dev/null)
                 printf '|' >&3; printf "%$((${#leader_cnt}+status_len+slot_len+size_len+hash_len+14))s" | tr " " "=" >&3; printf '|\n' >&3
               elif [[ ${view} -eq 3 ]]; then
                 printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+size_len+hash_len+23))s" | tr " " "=" >&3; printf '|\n' >&3
                 printf "| %-${#leader_cnt}s | %-${status_len}s | %-${block_len}s | %-${slot_len}s | %-${slot_in_epoch_len}s | %-${at_len}s | %-${size_len}s | %-${hash_len}s |\n" "#" "Status" "Block" "Slot" "SlotInEpoch" "Scheduled At" "Size" "Hash" >&3
                 printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+size_len+hash_len+23))s" | tr " " "=" >&3; printf '|\n' >&3
                 while IFS='|' read -r status block slot slot_in_epoch at size hash; do
                   at=$(TZ="${BLOCKLOG_TZ}" date '+%F %T %Z' --date="${at}")
                   [[ ${block} -eq 0 ]] && block="-"
                   [[ ${size} -eq 0 ]] && size="-"
                   [[ -z ${hash} ]] && hash="-"
                   printf "| ${FG_LGRAY}%-${#leader_cnt}s${NC} | ${FG_LGRAY}%-${status_len}s${NC} | ${FG_LGRAY}%-${block_len}s${NC} | ${FG_LGRAY}%-${slot_len}s${NC} | ${FG_LGRAY}%-${slot_in_epoch_len}s${NC} | ${FG_LGRAY}%-${at_len}s${NC} | ${FG_LGRAY}%-${size_len}s${NC} | ${FG_LGRAY}%-${hash_len}s${NC} |\n" "${block_cnt}" "${status}" "${block}" "${slot}" "${slot_in_epoch}" "${at}" "${size}" "${hash}" >&3
                   ((block_cnt++))
                 done < <(sqlite3 "${BLOCKLOG_DB}" "SELECT status, block, slot, slot_in_epoch, at, size, hash FROM blocklog WHERE epoch=${epoch_enter} ORDER BY slot;" 2>/dev/null)
                 printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+size_len+hash_len+23))s" | tr " " "=" >&3; printf '|\n' >&3
               elif [[ ${view} -eq 4 ]]; then
                 println OFF "ブロックログ項目:\n"
                 println OFF "Leader    - 当エポックに割り当てられたスケジュール数"
                 println OFF "Ideal     - アクティブステーク（シグマ）に基づいて割り当てられたブロック数の期待値/理想値"
                 println OFF "Luck      - 期待値における実際に割り当てられたスロットリーダー数の割合"
                 println OFF "Adopted   - ブロック生成成功数"
                 println OFF "Confirmed - 生成したブロックのうちオンチェーン上で確認された数"
                 println OFF "Missed    - スロットでスケジュールされているが、 cncli DB には記録されておらず"
                 println OFF "            他のプールの生成実績も確認できない数"
                 println OFF "Ghosted   - ハイトバトルまたはブロック伝播遅延が発生し、他のプールによってブロックが生成された数"
                 println OFF "Stolen    - 他プールと同一スロットにスケジュールが重なりスロットバトルが発生し"
                 println OFF "            他のプールによってブロックが生成された数"
                 println OFF "Invalid   - プールで生成したブロックに問題が発生した数(KES更新ミスなど)"
                 println OFF "            [logmonitor]に表示されるコードで原因を調べることができます"
               fi
               echo
               println OFF "[h] ホーム | ${view_output} | [*] Refresh"
               read -rsn1 key
               case ${key} in
                 h ) continue 2 ;;
                 1 ) view=1; view_output="${FG_YELLOW}[1] 表示 1${NC} | [2] 表示 2 | [3] 表示 3 | [i] 情報" ;;
                 2 ) view=2; view_output="[1] 表示 1 | ${FG_YELLOW}[2] 表示 2${NC} | [3] 表示 3 | [i] 情報" ;;
                 3 ) view=3; view_output="[1] 表示 1 | [2] 表示 2 | ${FG_YELLOW}[3] 表示 3${NC} | [i] 情報" ;;
                 i ) view=4; view_output="[1] 表示 1 | [2] 表示 2 | [3] 表示 3 | ${FG_YELLOW}[i] 情報${NC}" ;;
                 * ) continue ;;
         esac
       done
       ;;
    2) myExit 0 "ブロックログ終了!" ;;
  esac

  waitForInput && continue


done # main loop
}

##############################################################

main "$@"
