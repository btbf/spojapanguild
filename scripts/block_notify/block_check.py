#2022/12/05 v1.7 @btbf

from watchdog.events import RegexMatchingEventHandler
from watchdog.observers import Observer
import os
import time
import datetime
import sqlite3
import requests
import slackweb
import subprocess
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
s_No = 1
prev_block = 0

#通知基準 全て=0 confirm以外全て=1 Missedとivaildのみ=2
if bNotify_st == "0":
    notStatus = ['adopted','leader']
elif bNotify_st == "1":
    notStatus = ['adopted','leader','confirmed']
elif bNotify_st == "2":
    notStatus = ['adopted','leader','confirmed','ghosted','stolen']
else:
    print("通知基準を正しく設定してください")

if bNotify >= "4":
    print("通知先を正しく設定してください")

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
            btime = parser.parse(at_string).astimezone(timezone(b_timezone))
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
            scheduleNo, total_schedule = getNo(row[5], s_No)

            sqlite_next_leader = f"SELECT * FROM blocklog WHERE slot >= {row[1]} order by slot asc limit 1 offset 1;"
            cursor.execute(sqlite_next_leader)
            next_leader_records = cursor.fetchall()
            print("SQL:", next_leader_records)
            if next_leader_records:
                for next_leader_row in next_leader_records:
                    print("Next_slot: ", next_leader_row[1])
                    at_next_string = next_leader_row[2]
                    next_btime = parser.parse(at_next_string).astimezone(timezone(b_timezone))
                    print("Next_at: ", next_btime)
                    p_next_btime = str(next_btime)

            else:
                p_next_btime = "次エポックのスケジュールを取得してください"
                print("Next_at: ", p_next_btime)

            if row[4] != "0":
                blockUrl=f"https://pooltool.io/realtime/{row[4]}\r\n"
                
            if timing == 'modified':
                if prev_block != row[4] and row[8] not in notStatus:
                    #LINE通知内容
                    b_message = ticker + 'ブロック生成結果('+str(row[3])+')\r\n'\
                        + '\r\n'\
                        + '■ブロックNo:'+str(row[4])+'\r\n'\
                        + str(btime)+'\r\n'\
                        + str(scheduleNo)+'/ '+str(total_schedule)+' > '+ str(row[8])+'\r\n'\
                        + blockUrl\
                        + '\r\n'\
                        + '次のスケジュール>>\r\n'\
                        + p_next_btime+'\r\n'\


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
                print("Guild-db monitoring started\n")


def getNo(slotEpoch,ssNo):
    try:
        connection = sqlite3.connect(home + '/guild-db/blocklog/blocklog.db')
        cursor = connection.cursor()
        print("Connected to SQLite")
        epochNo = getEpoch()
        sqlite_select_query = f"SELECT * FROM blocklog WHERE epoch=={epochNo};"
        cursor.execute(sqlite_select_query)
        epoch_records = cursor.fetchall()
        print("総スケジュール:  ", len(epoch_records))
        for row in epoch_records:
            if slotEpoch == row[5]:
                break
            else:
                ssNo += 1

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




if __name__ == "__main__":

    # 対象ディレクトリ
    DIR_WATCH = './'
    # 対象ファイルパスのパターン
    PATTERNS = [r'^.\/blocklog.*\.db$']

    def on_modified(event):
        filepath = event.src_path
        filename = os.path.basename(filepath)
        print('%s changed' % filename)

    event_handler = MyFileWatchHandler(PATTERNS)

    observer = Observer()
    observer.schedule(event_handler, DIR_WATCH, recursive=True)
    observer.start()
    timing = 'start'
    getAllRows(timing)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
