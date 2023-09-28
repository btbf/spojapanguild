#2023/09/28 v1.9.5 @btbf

from watchdog.events import RegexMatchingEventHandler
from watchdog.observers import Observer
from concurrent.futures import ThreadPoolExecutor
import os
import time
import datetime
import sqlite3
import requests
import slackweb
import subprocess
import random
from pytz import timezone
from dateutil import parser
from discordwebhook import Discord
from dotenv import load_dotenv

# .envファイルの内容を読み込みます
load_dotenv()

# 環境変数を読み込む
home = os.environ["NODE_HOME"]
ticker = os.environ["ticker"]
line_notify_token = os.environ["line_notify_token"]
dc_notify_url = os.environ["dc_notify_url"]
b_timezone = os.environ["b_timezone"]
bNotify = os.environ["bNotify"]
bNotify_st = os.environ["bNotify_st"]
slack_notify_url = os.environ["slack_notify_url"]
teleg_token = os.environ["teleg_token"]
teleg_id = os.environ["teleg_id"]
auto_leader = os.environ["auto_leader"]
#s_No = 1
prev_block = 0
sendStream = 'if [ ! -e "send.txt" ]; then send=0; echo $send | tee send.txt; else cat send.txt; fi'
send = (subprocess.Popen(sendStream, stdout=subprocess.PIPE,
                                shell=True).communicate()[0]).decode('utf-8')
send = int(send.strip())
line_leader_str_list = []

#print(send)

#通知基準 全て=0 confirm以外全て=1 Missedとivaildのみ=2
if bNotify_st == "0":
    notStatus = ['adopted','leader']
elif bNotify_st == "1":
    notStatus = ['adopted','leader','confirmed']
elif bNotify_st == "2":
    notStatus = ['adopted','leader','confirmed','ghosted','stolen']
else:
    print("通知基準を正しく設定してください")


def getAllRows(timing):
    try:
        global prev_block
        connection = sqlite3.connect(home + '/guild-db/blocklog/blocklog.db')
        cursor = connection.cursor()
        print("Connected to SQLite")

        sqlite_select_query = """SELECT * FROM blocklog WHERE status NOT IN ("adopted","leader") order by at desc limit 1;"""
        cursor.execute(sqlite_select_query)
        records = cursor.fetchall()
        
        print("Total rows are:  ", len(records))
        print("Printing each row")
        for row in records:
            #print("Id: ", row[0])
            print("slot: ", row[1])
        # print("at: ", row[2])
            at_string = row[2]
            btime = parser.parse(at_string).astimezone(timezone(b_timezone)).strftime('%Y-%m-%d %H:%M:%S')
            print("at: ", btime)
            print("epoch: ", row[3])
            print("block: ", row[4])
            print("slot_in_epoch: ", row[5])
        #print("hash: ", row[6])
        #print("size: ", row[7])
            print("status: ", row[8])
            print("prevblock", prev_block)
            print("\n")           
            #スケジュール番号計算
            scheduleNo, total_schedule = getNo(row[5],row[3])

            sqlite_next_leader = f"SELECT * FROM blocklog WHERE slot >= {row[1]} order by slot asc limit 1 offset 1;"
            cursor.execute(sqlite_next_leader)
            next_leader_records = cursor.fetchall()
            print(f"タイムゾーン：{b_timezone}")
            print("SQL:", next_leader_records)
            if next_leader_records:
                for next_leader_row in next_leader_records:
                    print("Next_slot: ", next_leader_row[1])
                    at_next_string = next_leader_row[2]
                    next_btime = parser.parse(at_next_string).astimezone(timezone(b_timezone))
                    print("Next_at: ", next_btime)
                    print(f"スケジュール取得:{random_slot_num}\n")
                    p_next_btime = str(next_btime)

            else:
                p_next_btime = "次エポックのスケジュールを取得してください"
                print("Next_at: ", p_next_btime)

            if row[4] != "0":
                blockUrl=f"https://pooltool.io/realtime/{row[4]}\r\n"
                
            if timing == 'modified':
                if prev_block != row[4] and row[8] not in notStatus:
                    #LINE通知内容
                    b_message = '\r\n' + ticker + 'ブロック生成結果('+str(row[3])+')\r\n'\
                        + '\r\n'\
                        + '📍'+str(scheduleNo)+' / '+str(total_schedule)+' > '+ str(row[8])+'\r\n'\
                        + '⏰'+str(btime)+'\r\n'\
                        + '\r\n'\
                        + '📦ブロックNo：'+str(row[4])+'\r\n'\
                        + '⏱スロットNo：'+str(row[1])+' (e:'+str(row[5])+')\r\n'\
                        + blockUrl\
                        + '\r\n'\
                        + '次のスケジュール >>\r\n'\
                        + p_next_btime+'\r\n'\

                    sendMessage(b_message)
                    #通知先 LINE=0 Discord=1 Slack=2 Telegram=3 ※複数通知は不可

                else:
                    break
            else:
                prev_block = row[4]
                print("prevblock", prev_block)

        if len(records) > 0:
            if row[8] not in ['adopted','leader']:
                prev_block = row[4]

        cursor.close()

    except sqlite3.Error as error:
        print("Failed to read data from table", error)
    finally:
        if connection:
            connection.close()
            print("The Sqlite connection is closed\n")
            if timing == 'start':
                print(f"スケジュール取得:{random_slot_num}\n")
                print("Guild-db monitoring started\n")                
                start_message = '\r\n[' + ticker + '] ブロック生成ステータス通知を起動しました🟢\r\n'\
                    + 'スケジュール取得は'+ str(random_slot_num) + 'スロットです\r\n'\
                    
                sendMessage(start_message)

def sendMessage(b_message):
    #通知先 LINE=0 Discord=1 Slack=2 Telegram=3 ※複数通知は不可
    if bNotify == "0":
        d_line_notify(b_message)
    elif bNotify == "1":
        discord = Discord(url=dc_notify_url)
        discord.post(content=b_message)
    elif bNotify == "2":
        slack = slackweb.Slack(url=slack_notify_url)
        slack.notify(text=b_message)
    else:
        send_text = 'https://api.telegram.org/bot' + teleg_token + '/sendMessage?chat_id=' + teleg_id + '&parse_mode=Markdown&text=' + b_message
        response = requests.get(send_text)
        response.json()


def getNo(slotEpoch,epochNo):
    ssNo = 0
    try:
        connection = sqlite3.connect(home + '/guild-db/blocklog/blocklog.db')
        cursor = connection.cursor()
        print("Connected to SQLite")
        getEpoch()
        sqlite_select_query = f"SELECT * FROM blocklog WHERE epoch=={epochNo} order by slot asc;"
        cursor.execute(sqlite_select_query)
        epoch_records = cursor.fetchall()
        print("総スケジュール:  ", len(epoch_records))
        for i, row in enumerate(epoch_records, 1):
            if slotEpoch == row[5]:
                ssNo = i
                break
            #else:
                #ssNo = 0

        cursor.close()

    except sqlite3.Error as error:
        print("Failed to read data from table", error)
    finally:
        if connection:
            connection.close()
            print("The Sqlite connection is closed\n")
            return ssNo, len(epoch_records)

def d_line_notify(line_message):

    line_notify_api = 'https://notify-api.line.me/api/notify'

    payload = {'message': line_message}
    headers = {'Authorization': 'Bearer ' + line_notify_token}  # 発行したトークン
    line_notify = requests.post(line_notify_api, data=payload, headers=headers)

def getEpoch():
    #subprocess.call('curl -s localhost:12798/metrics | grep epoch')
    bepochNo = 0
    while True:
        cmd = 'curl -s localhost:12798/metrics | grep epoch'
        process = (subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                shell=True).communicate()[0]).decode('utf-8')
        checkepoch = len(process)
        if checkepoch == 0:
            print ("ノード同期までお待ちください")

        else:
            bepochNo = process.replace('cardano_node_metrics_epoch_int ', '')
            print ("epoch:", bepochNo)
            break
        time.sleep(30)
    return bepochNo

def randomSlot():
    random_slot=random.randrange(303300, 317700, 120)
    return random_slot
    
def getScheduleSlot():
    line_leader_str_list = []
    leader_str = ""
    slotComm = os.popen('curl -s localhost:12798/metrics | grep slotIn | grep -o [0-9]*')
    slotn = slotComm.read()
    slotn = int(slotn.strip())
    global send
    #print(random_slot_num)
    #slotn = 303000
    if (slotn >= random_slot_num):
        if send == 0:
            currentEpoch = getEpoch()
            nextEpoch = int(currentEpoch) + 1
            if auto_leader == "1":
                subprocess.Popen("tmux send-keys -t leaderlog '$NODE_HOME/scripts/cncli.sh leaderlog' C-m" , shell=True)
                b_message = '\r\n[' + ticker + '] お知らせ📣\r\n'\
                    + str(nextEpoch)+'エポックスケジュールの自動取得を開始します！\r\n'\
                    + '数分後に取得結果を通知します'\
                        
            else:
                b_message = '\r\n[' + ticker + '] お知らせ📣\r\n'\
                    + str(currentEpoch.strip())+'エポック'+ str(slotn)+'スロットを過ぎました\r\n'\
                    + str(nextEpoch)+'エポックのスケジュールを取得できます！'\

            sendMessage(b_message)
            #print ("スケジュールが取得できます")
            send = 1
            stream = os.popen(f'send={send}; echo $send > send.txt')
        elif send >= 1 and send <= 5: #スケジュール結果送信
            currentEpoch = getEpoch()
            nextEpoch = int(currentEpoch) + 1
            try:
                connection = sqlite3.connect(home + '/guild-db/blocklog/blocklog.db')
                cursor = connection.cursor()
                print("Connected to SQLite")
                
                sqlite_epochdata_query = f"select * from epochdata where epoch = {nextEpoch} LIMIT 1;"
                cursor.execute(sqlite_epochdata_query)
                fetch_epoch_records = cursor.fetchall()
                next_epoch_records = len(fetch_epoch_records)
                
                if (next_epoch_records == 1 and send == 5):
                    for fetch_epoch_row in fetch_epoch_records:
                        luck = fetch_epoch_row[7]
                        ideal = fetch_epoch_row[6]
                        
                    #print("エポックレコードあり")
                    next_epoch_leader = f"select * from blocklog where epoch = {nextEpoch} order by slot asc;"
                    cursor.execute(next_epoch_leader)
                    fetch_leader_records = cursor.fetchall()
                    if (len(fetch_leader_records) != 0):
                        line_count = 1
                        line_leader_str = ""
                        for x, next_epoch_leader_row in enumerate(fetch_leader_records, 1):
                            
                            at_leader_string = next_epoch_leader_row[2]
                            leader_btime = parser.parse(at_leader_string).astimezone(timezone(b_timezone)).strftime('%Y-%m-%d %H:%M:%S')
                            #LINE対策 20スケジュールごとに分割
                            if bNotify == "0" and x >= 21:
                                if line_count <= 20:
                                    
                                    line_leader_str += f"{x}) {next_epoch_leader_row[5]} / {leader_btime}\n"
                                    line_count += 1
                                    if line_count == 21 or x == len(fetch_leader_records):
                                        line_leader_str_list.append(line_leader_str)
                                        line_leader_str = ""
                                        line_count = 1
                                    
                            else:        
                                leader_str += f"{x}) {next_epoch_leader_row[5]} / {leader_btime}\n"
                           
                            p_leader_btime = str(leader_btime)
                            
                        b_message = '\r\n\r\n[' + ticker + '] ' + str(nextEpoch) + 'エポックスケジュール詳細\r\n'\
                            + '📈期待値(Ideal)    : '+ str(ideal) + '\r\n'\
                            + '💎割当て確率(Luck) : '+ str(luck) + '%\r\n'\
                            + '📋割当てブロック数  : '+ str(len(fetch_leader_records))+'\r\n'\
                            + '\r\n'\
                            + leader_str + '\r\n'\
                                
                    else:
                        b_message = '\r\n[' + ticker + '] ' + str(nextEpoch) + 'エポックスケジュール詳細\r\n'\
                            + 'スケジュールはありませんでした\r\n'\
                                
                    sendMessage(b_message)

                    #LINE対応
                    line_index = 0
                    len_line_list = len(line_leader_str_list)
                    
                    if bNotify == "0":
                        while line_index < len_line_list:
                            b_message = '\r\n' + line_leader_str_list[line_index] + '\r\n'\
                                
                            sendMessage(b_message)
                            line_index += 1
                        
                    send += 1
                    stream = os.popen(f'send={send}; echo $send > send.txt')
                elif (next_epoch_records == 1 and send < 5):
                    send += 1
                    stream = os.popen(f'send={send}; echo $send > send.txt')
                else:
                    pass
                
                cursor.close()

            except sqlite3.Error as error:
                print("Failed to read data from table", error)
            finally:
                if connection:
                    connection.close()
                    print("The Sqlite connection is closed\n")
                    
        else:
            pass
            #print(send)
             
    else:
        if send >= 1:
            send = 0
            stream = os.popen(f'send={send}; echo $send > send.txt')
    

class MyFileWatchHandler(RegexMatchingEventHandler):

    def __init__(self, regexes):
        super().__init__(regexes=regexes)

    # ファイル変更時の動作
    def on_modified(self, event):
        filepath = event.src_path
        filename = os.path.basename(filepath)
        dt_now = datetime.datetime.now()
        fsize = os.path.getsize(filepath)
        if filename.startswith('block'):
            print(f"{dt_now} {filename}")
            print(f"-- size: {fsize}")
            timing = 'modified'
            getAllRows(timing)


random_slot_num=randomSlot()

if __name__ == "__main__":

    # 対象ディレクトリ
    DIR_WATCH = './'
    # 対象ファイルパスのパターン
    PATTERNS = [r'^.\/blocklog.*\.db$']

    def on_modified(event):
        filepath = event.src_path
        filename = os.path.basename(filepath)
        print('%s changed' % filename)

    if bNotify >= "4" or bNotify == "":
        print("通知先フラグを正しく設定してください")
    else:
        if bNotify == "0" and line_notify_token == "":
            print("LINE通知用アクセストークンを正しく設定してください")
        elif bNotify == "1" and dc_notify_url == "":
            print("WebhookURLを正しく設定してください")
        elif bNotify == "2" and slack_notify_url == "":
            print("WebhookURLを正しく設定してください")
        elif bNotify == "3" and teleg_token == "":
            print("テレグラム通知用トークンを正しく設定してください")
        else:
            event_handler = MyFileWatchHandler(PATTERNS)

            observer = Observer()
            observer.schedule(event_handler, DIR_WATCH, recursive=True)
            observer.start()
            timing = 'start'
            
            getAllRows(timing)
            timeslot = 1
            try:
                while True:
                    time.sleep(1)
                    if timeslot == 5:
                        getScheduleSlot()
                        timeslot = 0
                    timeslot += 1

            except KeyboardInterrupt:
                observer.stop()
            observer.join()