# **エアギャップ環境セットアップ**

# Mac に Ubuntu 22.04 をインストールする

## Bootable USB で起動する

### USB を認識させる

USB を Mac に挿し「Option」キーを押しながら電源を入れる。

!!! info "Windows用キーボードを使用している場合"
    Optionキーはありませんので代わりに「Alt」キーを押してください

起動音が鳴り以下のような画面が表示されるまでキーを押したままにしてください。

![](../images/airgap/01-mac-boot.jpg)


### ブートデバイスを選択する

こちらの例ではハードディスクのようなアイコンが内蔵のHDDまたはSSDですので、オレンジ色のほうのUSBを選択しEnterキーを押します。

そうするとUSBから起動が始まります。

![](../images/airgap/02-mac-usb-boot.jpg)


### Ubuntu Server のインストールを開始する

以下のような画面が表示されますので、「Try or Install Ubuntu Server」を選択してEnterキーを押すとUbuntu Serverのインストーラーが起動します。

![](../images/airgap/03-install-ubuntu-server.jpg)



## Mac mini で WiFi を認識させる

### 1-1. 前提条件

Broadcomのチップであれば対応可能

- Apple Silicon (M1,M2,M3) Mac mini
    - ドライバがオープンにされていないため対応不可

### 1-2. 有線LAN でネットに接続する

ドライバをインストールするために有線でネットに繋いでください。


### 1-3. チップの型番を確認する

```bash
lspci -nn | grep -i network
```
以下のような戻り値があれば 1-3. に進む

> Broadcom Inc. and subsidiaries BCM4331


### 1-4. ドライバをインストールする

```bash
sudo apt update -y
```
```bash
sudo apt install bcmwl-kernel-source network-manager -y
```


### 1-5. 再起動する

```bash
sudo reboot
```


### 1-6. WiFi デバイス名を確認する
```bash
nmcli device
```

以下の戻り値の例では wlp2s0 が WiFi デバイスです
```
DEVICE    TYPE      STATE         CONNECTION 
wlp2s0    wifi      disconnected  --         
enp1s0f0  ethernet  unmanaged     --         
lo        loopback  unmanaged     --        
```


### 1-7. アクセスポイント一覧を取得する
```bash
nmcli device wifi list
```

```
IN-USE  BSSID              SSID             MODE   CHAN  RATE        SIGNAL  BARS  SECURITY  
        00:00:00:00:00:00  TP-Link_0000     Infra  40    540 Mbit/s  97      ▂▄▆█  WPA2      
        00:00:00:00:00:00  aterm-000af8-g   Infra  6     270 Mbit/s  79      ▂▄▆_  WPA2    
```


### 1-8. WiFi に接続する

`TP-Link_0000` にパスワード `01234567` で接続する場合

```bash
sudo nmcli device wifi connect "TP-Link_0000" password "01234567"
```

以上で次回起動時もWiFiに接続された状態になります。

---