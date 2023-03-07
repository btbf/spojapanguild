# **エアギャップマシンの作成**

!!! summary "エアギャップマシンとは？"
    プール運営で使用するウォレットの秘密鍵やプール運営の秘密鍵をオフライン上で管理し、エアギャップオフラインマシンでCLIを起動しトランザクションファイルに署名する作業に使用します。
    
    * ウォレットの秘密鍵やプール運営の秘密鍵をプール運営のオンラインマシン上に保管すると、ハッキングなどの際に資金盗難のリスクがあります。

## Windowsの場合

!!! hint "貢献者"
    [[SA8] SMAN8](https://adapools.org/pool/ec736597797c68044b8fccd4e895929c0a842f2e9e0a9e221b0a3026) さんに導入手順を作成頂きました。ありがとうございます！

### インストール要件
**環境**

* Windows11 Home
* 実装RAM 8.00 GB

**ダウンロード/インストール**

* Ubuntu Desktop 20.04.4 LTS  
* VirtualBox-7.0.4  
---

### **1- OS Ubuntuの入手**
1-1.下の画像の赤い四角のところをタップしてダウンロードします。

- [Ubuntu20.04.4 LTSの入手](https://releases.ubuntu.com/20.04/)

![2-1](https://user-images.githubusercontent.com/80440848/184349563-06b3ad6d-5295-4225-bd7f-6cc880e3d174.png)

1-2.ダウンロードしたubuntu-20.04.4-desktop-amd64を作成したフォルダ(ここではTest_CNodeというフォルダ)に移動しておく。

![4-Ubuntu_download](https://user-images.githubusercontent.com/80440848/184369093-df29585b-bb75-44c4-a3e6-fb411046b7da.PNG)

### **2- VirtualBoxのダウンロード**
2-1. VirtualBoxのダウンロードサイトにアクセスし、`Windows hosts`をタップしダウンロードする。

 * [VirtualBoxの入手](https://www.virtualbox.org/wiki/Downloads)

### **3- VirtualBoxのインストール**

3-1.ダウンロードしたvirtualbox6.1.36のインストーラをダブルクリックで起動する。

| ファイル名 |
| ------------- |
|VirtualBox-7.0.4-154605-Win.exe|

![1virtualbox](../images/win/VirtualBoxubuntu-1.jpg)

3-2.ダウンロードが完了したら、左下の赤い四角のインストーラーをタップして起動する。

![2 virtualbox_setup](https://user-images.githubusercontent.com/80440848/184338728-9a1a783f-6ee5-4c8e-a5b2-9ccec5e1dbf0.PNG)

3-3.この画面になったら、`Next>`をタップ。

![3 virtualbox_setup](../images/win/VirtualBoxubuntu-3.jpg)

3-4.続けてそのまま`Next>`をタップし、画像の順番に進み最後に`Install`をクリックする。

![7 virtualbox_setup](../images/win/VirtualBoxubuntu-4.jpg)

3-5.Windowsセキュリティが作動し、デバイスのソフトウェアをインストールしますか？と聞かれたら`インストール(I)`をタップし、下の画像の赤い四角で囲まれた`Finish`をタップする。

![10 virtualbox_setup](../images/win/VirtualBoxubuntu-5.jpg)

3-6.VirtualBoxの管理画面が立ち上がり、インストールが完了しました。

![15](../images/win/VirtualBoxubuntu-6.jpg)


### **4- VirtualBoxの仮想マシンの作成**
4-1.マシンを作成する為に下の画像の赤い四角の`新規(N)`をクリックする。

![16](../images/win/VirtualBoxubuntu-7.jpg)

4-2.マシン設定  
名前・・・任意の仮想マシン名  
ISO Imagae・・・1でダウンロードしたUbuntu-ISOファイルを指定する  
「Skip Unattended Installation」にチェックして「次へ」をクリック。

![VirtualMashine-1](../images/win/VirtualBoxubuntu-8.jpg)

4-3.メインメモリを`4096MB`、Processorosを`2`に設定し「次へ」をクリック

![VirtualMashine-2](../images/win/VirtualBoxubuntu-9.jpg)

4-4.DiskSizeを`50.00GB`に設定し「次へ」をクリック

![VirtualMashine-3](../images/win/VirtualBoxubuntu-10.jpg)

4-5.バーチャルマシン作成概要の確認。「完了」をクリック

![VirtualMashine-4](../images/win/VirtualBoxubuntu-11.jpg)


### **5- VirtualBoxの仮想マシンの環境設定**

5-1.使用する仮想マシン(ここではAirGap)を選択し、「設定」アイコンをクリックする

![Setting_Mashine-1](../images/win/VirtualBoxubuntu-12.jpg)

**一般**
5-2.「一般」→「高度」タブからクリップボードの共有とドラッグ&ドロップを「双方向」に変更してOKをクリック

![Setting_Mashine-2](../images/win/VirtualBoxubuntu-13.jpg)

**システム**
5-3.「システム」→「マザーボード」タブの「フロッピー」のチェックを`外す`。チップセットを`ICH9`に変更してOKをクリック

![Setting_Mashine-3](../images/win/VirtualBoxubuntu-14.jpg)

**共有フォルダ設定**

5-4.WindowsとUbuntu間の共有フォルダ(Share)を作成する(ドキュメントフォルダなどの任意の場所)

![Setting_Mashine-4](../images/win/VirtualBoxubuntu-15.jpg)

5-5.共有フォルダーから新規追加アイコンをクリック  

* 「フォルダーのパス」に5-4で作成したフォルダを指定する  
* マウントポイントに`/media/share_win`を入力する  
* 「自動マウント」にチェックする

![Setting_Mashine-4](../images/win/VirtualBoxubuntu-16.jpg)


### **6- Ubuntuのインストール**

6-1.`起動`をクリック。

![install_ubuntu-1](../images/win/VirtualBoxubuntu-17.jpg)

6-2.下の画像のようにディスクが起動し始めます。

![install_ubuntu-3](https://user-images.githubusercontent.com/80440848/184519354-4a60ea8e-267c-4cda-952b-5fce4de835aa.png)

6-3.左の枠の中から`日本語`を選択し`Ubuntuをインストール`をクリックします。

![install_ubuntu-4](../images/win/VirtualBoxubuntu-18.jpg)

6-5.日本語キーボードの方は、両方とも「Japanese」を選択し、設定が完了したら「続ける」をクリックします。

>USキーボードの方は「キーボードレイアウト」→「キーボードレイアウトの検出」をクリックして設定してください。
※ 画面が見切れている場合の対処法：Alt＋F7を押すとマウスでウィンドウを移動できます)

![install_ubuntu-5](https://user-images.githubusercontent.com/80440848/184519500-d4cd960c-2773-4ffc-9845-9f32c7806190.png)

6-6.下の画像の状態のまま、`続ける`をクリック

![install_ubuntu-6](https://user-images.githubusercontent.com/80440848/184528936-4809b68b-75e9-413d-9ce8-f84efb28a45e.png)

6-7.下の画像の状態のまま、`インストール`をクリック。

![install_ubuntu-7](https://user-images.githubusercontent.com/80440848/184528995-44737e97-0bcd-4c64-9571-d3a20782a4b6.png)

6-8.`続ける`をクリック。

![install_ubuntu-8](https://user-images.githubusercontent.com/80440848/184529041-e35ff5d2-d244-45fd-965d-ae73e7c3f156.png)

6-9.お住まいの地域をクリックし、`続ける`をクリック。

![install_ubuntu-9](https://user-images.githubusercontent.com/80440848/184529073-b356baeb-6a27-4602-bca4-3afaf92a3631.png)

6-10.`あなたの名前`はマシン名を入れると、その下の`コンピューターの名前`、`ユーザー名の入力`にも自動で入力されます。そして、パスワードをご自身で決めて入力を済ませて下さい。終わりましたら、`続ける`をタップ。

![install_ubuntu-10](../images/win/VirtualBoxubuntu-19.jpg)

6-11.Ubuntuのインストールが始まりました。しばらくお待ちください。

![install_ubuntu-11](https://user-images.githubusercontent.com/80440848/184529318-1eb3cfd5-ab0d-4fbf-bedd-9749a714baa0.png)

6-12.インストール完了後、再起動を行って下さい

![install_ubuntu-12](../images/win/VirtualBoxubuntu-20.jpg)

6-13.ログインします

![install_ubuntu-13](../images/win/VirtualBoxubuntu-21.jpg)

6-14.オンラインアカウントの接続は、右上の`スキップ(S)`をクリック。

![install_ubuntu-14](../images/win/VirtualBoxubuntu-22.jpg)

6-15.`次へ`をタップします。

![install_ubuntu-15](../images/win/VirtualBoxubuntu-23.jpg)

6-16.そのまま、`次へ（N)`をタップ。

![install_ubuntu-16](https://user-images.githubusercontent.com/80440848/184529565-da681e94-671b-4f50-9e54-2ab38b18ff75.png)

6-17.`いいえ、送信しません`を選択し、右上の`次へ(N)`をタップします。

![install_ubuntu-17](https://user-images.githubusercontent.com/80440848/184529605-d90d782a-f16f-4844-b41e-d9801ab9b61f.png)

6-18.インストールが終わりました。`完了`をクリック。

![install_ubuntu-18](../images/win/VirtualBoxubuntu-24.jpg)

6-19.新バージョンは「アップグレードしない」をクリックします

![install_ubuntu20](../images/win/VirtualBoxubuntu-25.jpg)

6-20.`OK`をクリック。

![install_ubuntu21](../images/win/VirtualBoxubuntu-26.jpg)

6-21.`この操作を今すぐ実行`をクリック。

![install_ubuntu21](../images/win/VirtualBoxubuntu-27.jpg)

6-22.`インストール`をクリック。

![install_ubuntu21](../images/win/VirtualBoxubuntu-28.jpg)

6-23.`インストール`をクリック。

![install_ubuntu21](../images/win/VirtualBoxubuntu-29.jpg)

6-23.インストール完了後`全体に適用する`をクリックし閉じる

![install_ubuntu21](../images/win/VirtualBoxubuntu-30.jpg)


### **7- Guest Additionsのインストール**

アプリ一覧からターミナル(端末)を起動し以下コマンドを手動入力する。
```
sudo apt updata -y
sudo apt upgrade -y
sudo apt install gcc make perl -y
```
>まだコピーアンドペーストが利用できないため、タイプミスに留意してください。

7-1.ホストメイン画面上部の「Devices」タブから「Insert Guest Additions CD image...」⇒`OK`をクリックします。

![共有フォルダ_5](https://user-images.githubusercontent.com/80440848/184529831-1af5010c-3969-47c6-8dd4-5efa5e23d87c.PNG)

7-2.以下のメッセージが表示されたら`実行`をクリックした後、パスワードを入力します。

![共有フォルダ_6](../images/win/VirtualBoxubuntu-31.jpg)

7-3処理完了のメッセージが表示されましたら`Enter`キーをタップします。

![共有フォルダ_7](https://user-images.githubusercontent.com/80440848/184530144-5c95c10c-4197-4316-96e5-1b6cd8f78e4b.PNG)

7-4.ターミナル(端末)を起動しユーザーをグループ化するコマンドを実行。

```
sudo adduser $USER vboxsf
```
![共有フォルダ_6](../images/win/VirtualBoxubuntu-32.jpg)


7-5.フォルダに`shere_win`が表示されていれば、5の「共有フォルダ」で設定したローカルPCのフォルダと同期します。

![共有フォルダ_6](../images/win/VirtualBoxubuntu-33.jpg)

7-6.コピー＆ペーストできるかホストPCでコマンドを`コピー`してゲストOSの端末で右クリックして`貼り付け`してみる。問題なければ、これで終了です。お疲れ様でした！

![コピ＆ペイスト-7](https://user-images.githubusercontent.com/80440848/184537933-f3f645ed-1afe-48aa-9a0e-0cafb257a333.png)


7-7.「表示」→「Auto-resize　Guest　Display」にチェックが入っている事を確認します。

![共有フォルダ_6](../images/win/VirtualBoxubuntu-34.jpg)

---

上記手順を行なっても、「共有フォルダが表示されない」「共有フォルダ化されていない」場合は、一度VBox_GAs_6.1.36をアンマウントしてから再度挿入し、再起動すると共有フォルダは完了します。それでもダメなら[GUI操作でGuest Additionsがインストールできなかった場合](./#guiguest-additions)を試してください。

### 8- Swapファイルの作成  
8-1. 既存Swapファイルを削除  
```console
sudo swapoff /swapfile
```
```console
sudo rm /swapfile
```

---

8-2. 新規Swapファイルを作成  
```console
cd $HOME
sudo fallocate -l 6G /swapfile
```
```console
sudo chmod 600 /swapfile
```
```console
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show
```
```console
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
cat /proc/sys/vm/vfs_cache_pressure
cat /proc/sys/vm/swappiness
```

## Macの場合

!!! hint "貢献者"
    [[AKYO] AKYO](https://jp.cexplorer.io/pool/pool1jsxk3ymqv2gdc6mhqk52544g2aun4zhq5wgx6n32l5s3jlne70n) Akyoさんに導入手順を作成頂きました。ありがとうございます！

### インストール要件
**環境**
- macOS Ventura version13.0

**ダウンロード/インストール**
- VirtualBox バージョン 7.0.4
- Ubuntu Desktop 20.04.5 LTS (Focal Fossa)


---

### 1- Ubuntuイメージファイルのダウンロード

1-1. 以下のリンク先からISOイメージファイルをダウンロードします。

  - [Ubuntuを入手する](https://releases.ubuntu.com/20.04/)
※ ダウンロード完了まで少しかかるのでしばらくお待ちください

| ファイル名 | ubuntu-20.04.5-desktop-amd64.iso |
:---|:---

![UbuntuInstall-1](https://user-images.githubusercontent.com/80967103/203985883-cd707677-fdf5-44a5-9571-1f32197d7292.png)

---

### 2- VirtualBoxのダウンロード/インストール

2-1. 以下のリンク先からVirtualBoxをインストールします。

  - [VirtualBoxを入手する](https://www.virtualbox.org/wiki/Downloads)


| ファイル名 | VirtualBox-7.0.4-154605-OSX.dmg |
:---|:---

![VirtualBoxInstall-1](https://user-images.githubusercontent.com/80967103/199987719-48886644-846b-4748-95a7-65d6d12cf08c.png)

---

2-2. ダウンロードしたファイルをクリックし、インストールウィザードに従ってインストールします。
完了したら「閉じる」をクリックして終了します。


> macOS BigSur 以降では、インストールしたカーネル拡張をロードできるようにするために再起動が必要です。

![VirtualBoxInstall-2](https://user-images.githubusercontent.com/80967103/200001693-d02d64e2-a17c-4a35-ab42-3239b6e85ade.png)

---

### 3- VirtualBoxで仮想マシンを作成
> VirtualBoxのアイコンをクリックし、起動します。

3-1. VirtualBoxが起動したら「新規」をクリックします。

![UbuntuVMCreate-1](https://user-images.githubusercontent.com/80967103/199995540-8812988e-ae05-4f52-b40c-b1ac255cd6ef.png)

---

3-2. 以下の項目を設定し、「続き」をクリックします。
> ※ 名前はお好みで入力してください。
> ISO Imageは、「その他」を選択し、ダウンロードしたUbuntu-20.04.5のISOイメージファイルを選択します。  
タイプ、バージョンについては上記を選択すればデフォルトで設定されます。    
> `Skip Unattended Installation`にチェック


| 名前 | airGap |
:---|:---
| Folder | デフォルトでOK |


![UbuntuVMCreate-2](https://user-images.githubusercontent.com/80967103/200000228-a7333064-a9a7-43dd-bc24-91292d2af32a.png)

  ---

3-3. 仮想マシンに割当てるメモリサイズは「`4096`MB」、Processorsは「`2`」を選択し「次へ」をクリックします。

![UbuntuVMCreate-3](https://user-images.githubusercontent.com/80967103/200007711-1919c2b1-ca3a-4710-8f95-09506a444881.png)

---

3-4. Virtual Hard diskは「`50`GB」を入力し、「次へ」をクリックします。

![UbuntuVMCreate-7](https://user-images.githubusercontent.com/80967103/200004570-a7831dd0-971a-4a85-b442-386e9510321f.png)


3-5. 概要を確認して「完了」をクリックします。

![UbuntuVMCreate-7](https://user-images.githubusercontent.com/80967103/200163806-ebee3d0f-5caa-4b54-b07c-6569e9b8059f.png)


---

### 4- 仮想マシンの仕様設定

> 「完了」をクリックしたら「Oracle VM VirtualBox マネージャー」画面に遷移するので設定毎に「設定」をクリックしてください。

**一般**

4-1. 「設定」→「一般」→「高度」タブから、以下の設定を「双方向」にし、「OK」をクリックします。

![UbuntuSpecSettings-2](https://user-images.githubusercontent.com/80967103/200102482-958c0ece-9c96-40e7-854c-84eeb172fe39.png)

---

**システム**

4-2. 「マザーボード」タブを以下の設定にし、「OK」をクリックします。

| マザーボード |  |
:---|:---
| 起動順序 | 「フロッピー」のチェックマークを外す |
| チップセット | ICH9 |
| ポインティングデバイス | PS/2マウス |

![UbuntuSpecSettings-3](https://user-images.githubusercontent.com/80967103/200104121-58558676-f637-494d-897c-f5c6f7e2f905.png)

---

**ディスプレイ**

4-3. 「スクリーン」タブから以下の設定にし、「OK」をクリックします。

| ビデオメモリー | 128MB |
:---|:---
| 表示倍率 | 200% |
| グラフィックスコントローラー | VMSVGA |

![UbuntuSpecSettings-4](https://user-images.githubusercontent.com/80967103/200104321-b1805130-d1b9-4e7e-9883-ef9ca583b41c.png)

---

**共有フォルダー**

4-4. ホスト側で共有させたいフォルダを事前に作成しておきます。
- 例）「airGap」フォルダを作成後、配下に「share」フォルダを作成。

`Mac Terminal`
```console
mkdir -p $HOME/airGap/share
```

---

4-5. 共有フォルダを指定します。

![UbuntuSpecSettings-6](https://user-images.githubusercontent.com/80967103/200105091-1ab57c12-26b9-4f1e-92fd-e989ae76a3e1.png)

---

### 5- 仮想マシンにUbuntuをインストール

5-1. 仮想マシンを起動します。

![BootVirtualMachine-1](https://user-images.githubusercontent.com/80967103/200105774-017a584c-24ca-471b-8ce3-2c6bce299301.png)

> PCから権限許可を求められたら「セキュリティとプライバシー」にて必要な権限を許可し、VirtualBoxを再起動します。

---

5-2. 読み込み終了後、言語は「日本語」にし、「Install Ubuntu」をクリックします。

![BootVirtualMachine-2](https://user-images.githubusercontent.com/80967103/200107225-fab3855e-ffe1-4291-9337-2d2dd908ba18.png)

---

5-3. キーボード設定では、日本語キーボードの方は、両方とも「Japanese」を選択し、設定が完了したら「続ける」をクリックします。  
> USキーボードの方は「キーボードレイアウト」→「キーボードレイアウトの検出」をクリックして設定してください。  
※ 画面が見切れていた場合の対処法：Alt＋F7で移動できます)

---

5-4. 「アップデートと他のソフトウェア」の設定では、以下のように設定し、「続ける」をクリックします。

![BootVirtualMachine-3](https://user-images.githubusercontent.com/80967103/203983361-de583135-1f98-4578-819e-98ceef0ba661.png)

---

5-5. 「インストールの種類」の設定では「ディスクを削除してUbuntuをインストール」を選択し、「インストール」をクリックします。

![BootVirtualMachine-4](https://user-images.githubusercontent.com/80967103/159128589-0b0373ac-a342-45d6-b22c-0f14122a5f3d.png)

---

5-6. 「ディスクに変更を書き込みますか?」の設定では「続ける」をクリックします。

![BootVirtualMachine-5](https://user-images.githubusercontent.com/80967103/159128650-7cbc6a86-5fce-465b-b980-95d3f17f7e3e.png)

---

5-7. タイムゾーンの設定は、「Tokyo」を選択し、「続ける」をクリックします。

![BootVirtualMachine-6](https://user-images.githubusercontent.com/80967103/159128953-10f8e1d9-cd04-401e-905c-3b27cbdf89e6.png)

---

5-8. 必要な情報を入力し、「続ける」をクリックします。
> ※ 画像は一例ですのでお好みで設定してください。

![BootVirtualMachine-7](https://user-images.githubusercontent.com/80967103/200107672-1be7368a-aa1f-4590-9a36-cf3ad914aa04.png)

---

5-9. インストール開始。

![BootVirtualMachine-8](https://user-images.githubusercontent.com/80967103/159129325-84554dfb-4062-4c90-ab26-baa3422c2fd5.png)

---

5-10. インストール完了後、VMの再起動を求められるので「今すぐ再起動する」をクリックし、Enterキーを押下します。

![BootVirtualMachine-9](https://user-images.githubusercontent.com/80967103/200108019-76aad33a-f170-4538-94fc-e7aabafeb8d8.png)

---

5-11. 再起動後、ユーザー名をクリックし、パスワードを入力してログインします。

---

5-12. 「オンラインアカウントへの接続」の設定では右上の「スキップ」をクリックします。

![BootVirtualMachine-10](https://user-images.githubusercontent.com/80967103/200108172-78dbeb3e-3c06-4c51-84e6-e9ea906f80e1.png)

---

5-13. 「Livepatch」の設定では右上の「次へ」をクリックします。

![BootVirtualMachine-11](https://user-images.githubusercontent.com/80967103/200108232-edb1f8e4-ae79-4c8b-8245-df9349df33ca.png)

---

5-14. 「Ubuntuの改善を支援する」の設定では、「いいえ、送信しません」を選択後、右上の「次へ」をクリックします。

![BootVirtualMachine-12](https://user-images.githubusercontent.com/80967103/200108403-e4ce931d-4fac-43da-aca3-5bbadc4947b3.png)

---

5-15. 「プライバシー」の設定では右上の「次へ」をクリックします。

![BootVirtualMachine-13](https://user-images.githubusercontent.com/80967103/200108468-8109b5b6-1b2e-407e-936d-19703d0f7525.png)

---

5-16. 「準備完了」と表示されたら右上の「完了」をクリックします。

![BootVirtualMachine-14](https://user-images.githubusercontent.com/80967103/200108519-0226b6db-95b1-48c0-9bed-b9f746c3c310.png)

---

5-17. 「ソフトウェアの更新」を求められたら「アップグレードしない」をクリックし、その後「OK」をクリックします。

![BootVirtualMachine-14](https://user-images.githubusercontent.com/80967103/203997822-2d823615-395b-49e4-be07-aa36fa2153a3.png)

---

5-18. 「アップデート情報→不完全な言語サポート」が表示されたら「この操作を今すぐ実行する」→「インストール」をクリック後、認証を求められるのでパスワードを入力し、「システム全体に適用」をクリックします。

![BootVirtualMachine-14](https://user-images.githubusercontent.com/80967103/204000214-49e1af9b-780f-4cea-a90d-6dfc33c00f75.png)

---

### 6- Guest Additionsのインストール
6-1. ターミナルを開いて以下を実行します。
> Guest Additionsがインストールされていない状態なのでホストからゲストにコピーアンドペーストできません。タイプミスに留意してください。  
> また以下の手順を行なっても、共有フォルダがGUIで表示されない、共有フォルダ化されていない場合は、一度VBox_GAs_6.1.36をアンマウントしてから再度挿入し、再起動すると共有フォルダは完了します。  
> それでもダメなら[`GUI操作でGuest Additionsがインストールできなかった場合`](#guiguest-additions)を試してください。
```console
sudo apt update -y
sudo apt upgrade -y
sudo apt install gcc make perl -y
```

---

6-2. ホストメイン画面上部の「Devices」タブから「Insert Guest Additions CD image...」→「OK」をクリックします。

---

6-3. 以下のメッセージが表示されたら「実行」をクリックした後、パスワードを入力します。

![BootVirtualMachine-15](https://user-images.githubusercontent.com/80967103/200109416-73ade24b-33bf-4a74-aa6a-2f032254f8cd.png)

---

6-4. 処理完了のメッセージが表示されたらEnterキーを押下します。
> 画面が点滅した場合は、リサイズが行われているのでそのまま少し待っていると点滅しなくなるはずです。

![BootVirtualMachine-16](https://user-images.githubusercontent.com/80967103/159153823-eb6c79b5-a6d7-46e7-9ae9-a392ed33de8e.png)

---

6-5. ユーザーを`vboxsf`グループに追加して再起動します。
```console
sudo adduser $USER vboxsf
sudo reboot
```

---

6-6. 「View」→「Auto-resize　Guest　Display」にチェックが入っている事を確認します。  
> 確認後、右クリック→「取り出す」をクリックします。

![BootVirtualMachine-18](https://user-images.githubusercontent.com/80967103/200109672-4e4d6dde-23d9-408d-96ff-a9ab28c2039f.png)

---

6-7. テストファイル作成  
ターミナルを開いて以下を実行します。
> 共有フォルダにテストファイルを作成してホスト側で確認できたら成功です。

```console
touch /media/sf_share/test.txt
ls /media/sf_share/
```

実行結果としてVMとホストに`test.txt`が作成されていることを確認します。
![BootVirtualMachine-18](https://user-images.githubusercontent.com/80967103/200110310-c3f060e1-0184-4aa5-8bfd-7d7fea5eef3f.png)

---

### 6- Swapファイルの作成  
6-1. 既存Swapファイルを削除  
```console
sudo swapoff /swapfile
```
```console
sudo rm /swapfile
```

---

6-2. 新規Swapファイルを作成  
```console
cd $HOME
sudo fallocate -l 6G /swapfile
```
```console
sudo chmod 600 /swapfile
```
```console
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show
```
```console
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
cat /proc/sys/vm/vfs_cache_pressure
cat /proc/sys/vm/swappiness
```
---

## 補足

### 本番運用で使用する際の注意点

- 本番運用で使用される場合は必ず「ネットワークアダプターを有効化」のチェックを外してください。  
[2-8. エアギャップオフラインマシンの作成](https://docs.spojapanguild.net/setup/2-node-setup/#2-8)を終えた後に行ってください。

![BootVirtualMachine-21](https://user-images.githubusercontent.com/80967103/200110479-30bdd7ea-88b4-41f2-8642-b6653e45762a.png)

### GUI操作でGuest Additionsがインストールできなかった場合
Virtualbox guest addition packagesをインストールします。
> ターミナルを開いて以下のコマンドを実行してください。  
> Guest Additionsがインストールされていない状態なのでホストからゲストにコピーアンドペーストできません。タイプミスに留意してください。  
> 成功していれば再起動後、コピーアンドペーストできます。
```console
sudo apt update -y
sudo apt upgrade -y
sudo add-apt-repository multiverse
sudo apt install virtualbox-guest-dkms virtualbox-guest-x11 -y
```

ユーザーを`vboxsf`グループに追加して再起動します。
```console
sudo adduser $USER vboxsf
sudo reboot
```

共有フォルダが追加されているか確認
```console
df
```
> `share`          488245288 203122832 285122456  42% `/media/sf_share`

共有フォルダのグループを確認
```console
ls -l /media
```
> drwxrwx--- 1 root `vboxsf` 96  x月 xx xx:xx sf_share

テストファイル作成  
> 共有フォルダにテストファイルを作成してホスト側で確認できたら成功です。

```console
touch /media/sf_share/test.txt
ls /media/sf_share/
```

実行結果としてVMとホストに`test.txt`が作成されていることを確認します。
![BootVirtualMachine-18](https://user-images.githubusercontent.com/80967103/200110310-c3f060e1-0184-4aa5-8bfd-7d7fea5eef3f.png)