# **カルダノステークプール構築手順**

<!--!!! summary "概要"
    このマニュアルは、[X Stake Pool](https://xstakepool.com)オペレータの[BTBF](https://twitter.com/btbfpark)が[CoinCashew](https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node#9-register-your-stakepool)より許可を得て、日本語翻訳しております。
-->

!!! info "情報"
    このマニュアルは、カルダノノードv1.35.3に対応しています。  
    最終更新日：2022年8月25日の時点guide version 12.3.1

!!! tip "サポート"
    サポートが必要な場合は、[SPO JAPAN GUILDコミュニティ](https://discord.gg/U3gU54c)で現役のSPOに質問できます


## **0-1.SPOの必須スキル**

カルダノステークプールを運営するには、以下のスキルを必要とします。

* カルダノノードを継続的にセットアップ、実行、維持する運用スキル
* ノードを24時間年中無休で維持するというコミット
* システム運用スキル
* サーバ管理スキル \(運用および保守\)
* 開発と運用経験 \(DevOps\)
* サーバ強化とセキュリティに関する知識


## **0-2.サーバースペック要件**

=== "最小構成"
    | 項目      | 要件                          |
    | :---------- | :----------------------------------- |
    | **サーバー**      | BP用1台  リレー用1台  エアギャップマシン1台  |
    | **OS**       | 64-bit Linux \(Ubuntu 20.04 LTS\) |
    | **CPU**   | 2Ghz以上 2コアのIntelまたはAMD x86プロセッサー|
    | **メモリ**    | 16GB |
    | **ストレージ**    | 150GB |
    | **ネットワーク**    | 10Mbps |
    | **帯域**    | 1時間あたり1GBの帯域 |
    | **電力**    | 24時間365日安定供給 |
    | **ADA**    | 600ADA |


=== "推奨構成"
    | 項目      | 要件                          |
    | :---------- | :----------------------------------- |
    | **サーバー**      | BP用1台  リレー用2台  エアギャップマシン1台  |
    | **OS**       | 64-bit Linux \(Ubuntu 20.04 LTS\) |
    | **CPU**   | 2Ghz以上 4コアのIntelまたはAMD x86プロセッサー|
    | **メモリ**    | 16GB over |
    | **ストレージ**    | 256GB以上 |
    | **ネットワーク**    | 100Mbps |
    | **帯域**    | 無制限 |
    | **電力**    | 24時間365日安定供給 |
    | **ADA**    | 無制限 |

### **プール構成のイメージ**

**最小構成**
``` mermaid
    flowchart BT
        a2[リレー1] <-- 開放FW --> a4[カルダノネットワーク]
        subgraph ide1[プール]
            subgraph リレーIP指定FW
                a1[BP]
            end
        a1[BP] <--> a2[リレー1]
        end
        c1[PC] --> ide1
        c1[PC] --> エアギャップ
```

**推奨構成**
``` mermaid
    flowchart BT
        a2[リレー1] & a3[リレー2] <-- 開放FW --> a4[カルダノネットワーク]
        subgraph ide1[プール]
            subgraph リレーIP指定FW
                a1[BP]
            end
                a1[BP] <--> a2[リレー1] & a3[リレー2]
        end
        c1[PC] --> ide1
        c1[PC] --> エアギャップ
```


## **0-3.お試しノード起動**

!!! hint ""
    * Linuxサーバのコマンドや、ノード起動などお試しテストでやってみたい方は、手元のパソコンでエアギャップ環境を構築し左メニューの1，2をやってみましょう！
    * この項目はブロックチェーンには直接的に影響がないので、たとえ間違ったコマンドを送信してもネットワークには問題ございません。

## **0-4.エアギャップマシンの作成**

!!! summary "エアギャップマシンとは？"
    プール運営で使用するウォレットの秘密鍵やプール運営の秘密鍵をオフライン上で管理し、エアギャップオフラインマシンでCLIを起動しトランザクションファイルに署名する作業に使用します。
    
    * ウォレットの秘密鍵やプール運営の秘密鍵をプール運営のオンラインマシン上に保管すると、ハッキングなどの際に資金盗難のリスクがあります。

### Windowsの場合

!!! hint "貢献者"
    [[SA8] SMAN8](https://adapools.org/pool/ec736597797c68044b8fccd4e895929c0a842f2e9e0a9e221b0a3026) さんに導入手順を作成頂きました。ありがとうございます！


**環境**

* Windows10/11 Home (Intel(R) Core(TM) i5-8250U CPU @ 1.60GHz   1.80 GHz)  
* 実装RAM 8.00 GB (7.90 GB 使用可能)  
* 64 ビット オペレーティング システム、x64 ベース プロセッサ  

**ダウンロード/インストール**

* Ubuntu Desktop 20.04.4 LTS  
* VirtualBox-6.1.36  
---


#### **1- VirtualBoxのダウンロード**
1-1. VirtualBoxのダウンロードサイトにアクセスし、`VirtualBox 6.1.36 platform packages`の`Windows hosts`をタップしダウンロードする。

 * [VirtualBoxの入手](https://www.virtualbox.org/wiki/Downloads)

#### **2- VirtualBoxのインストール**

2-1.ダウンロードしたvirtualbox6.1.36のインストーラをダブルクリックで起動する。

| ファイル名 |
| ------------- |
|VirtualBox-6.1.36-152435-Win.exe|

![1virtualbox](https://user-images.githubusercontent.com/80440848/184325406-c8453b6f-0912-467f-bad3-f0b2466066f3.png)

2-2.ダウンロードが完了したら、左下の赤い四角のインストーラーをタップして起動する。

![2 virtualbox_setup](https://user-images.githubusercontent.com/80440848/184338728-9a1a783f-6ee5-4c8e-a5b2-9ccec5e1dbf0.PNG)

2-3.この画面になったら、`Next>`をタップ。

![3 virtualbox_setup](https://user-images.githubusercontent.com/80440848/184339305-fc9e9dab-6314-46a7-afc7-630209297b1f.PNG)

2-4.続けてそのまま`Next>`をタップし、下の画面になったら`Install`をタップする。

![7 virtualbox_setup](https://user-images.githubusercontent.com/80440848/184339928-0b689ef2-4bb2-4c23-b2f4-151a4f2e44ce.PNG)

2-5.Windowsセキュリティが作動し、デバイスのソフトウェアをインストールしますか？と聞かれたら`インストール(I)`をタップし、下の画像の赤い四角で囲まれた`Finish`をタップする。

![10 virtualbox_setup](https://user-images.githubusercontent.com/80440848/184340436-fca6347b-ff73-4d00-8593-033da52aad5e.PNG)

2-6.VirtualBoxの管理画面が立ち上がり、インストールが完了しました。

![15](https://user-images.githubusercontent.com/80440848/184341211-b58971af-5abc-4d32-8d44-788810e07f2b.PNG)

#### **3- OS Ubuntuの入手**
3-1.下の画像の赤い四角のところをタップしてダウンロードします。

- [Ubuntu20.04.4 LTSの入手](https://releases.ubuntu.com/20.04.4/?_ga=2.145106481.424434523.1659109603-1752942665.1659109603)

![2-1](https://user-images.githubusercontent.com/80440848/184349563-06b3ad6d-5295-4225-bd7f-6cc880e3d174.png)

3-2.ダウンロードしたubuntu-20.04.4-desktop-amd64を作成したフォルダ(ここではTest_CNodeというフォルダ)に移動しておく。

![4-Ubuntu_download](https://user-images.githubusercontent.com/80440848/184369093-df29585b-bb75-44c4-a3e6-fb411046b7da.PNG)


#### **4- VirtualBoxのインストール後の環境設定**
4-1.マシンを作成する為に下の画像の赤い四角の`新規(N)`をタップする。

![15](https://user-images.githubusercontent.com/80440848/184372736-01258bc7-1d91-441d-9551-1945dac351d9.PNG)

4-2.名前とオペレーティングシステムの画面になったら、①マシンの名前、②マシンのフォルダーパス指定、③Linux、④Linux(64bit)を選択する。

![VirtualMashine-1](https://user-images.githubusercontent.com/80440848/184377673-e74f5eec-4398-4c26-903f-fe08dc551ec0.PNG)

4-3.メモリサイズは、4GB(4000MB)に変更する。

![VirtualMashine-2](https://user-images.githubusercontent.com/80440848/184456824-af083067-728d-499a-ac2a-7d2129fbc9c9.png)

4-4.下の画像の状態で「仮想ハードディスクを作成する(C)」を選択した状態のまま下の`作成`をタップ。

![VirtualMashine-3](https://user-images.githubusercontent.com/80440848/184457064-512963cb-5144-4dff-92c7-b5c20c9460f5.png)

4-5.「VDI(VirtualBox Disc Image)」の状態のまま、`次へ(N)`をタップ。

![VirtualMashine-4](https://user-images.githubusercontent.com/80440848/184457609-bbbb30ca-8532-4dfc-88e3-68e461c8c14c.png)

4-6.「可変サイズ(D)」の状態のまま`次へ(N)`をタップ。

![VirtualMashine-5](https://user-images.githubusercontent.com/80440848/184457983-b7fd39f8-b760-4d67-8e14-5f65cc0183e0.png)

4-7.ハードディスクのサイズを50GBに変更し`作成`をタップ。

![VirtualMashine-6](https://user-images.githubusercontent.com/80440848/184458184-e63329cc-4265-4fd5-a6b0-85fbcb2507b7.png)

4-8.おめでとうございます！仮想マシンが作成されました。

![VirtualMashine-7](https://user-images.githubusercontent.com/80440848/184459602-b88ad8ae-7a94-41e2-bb40-4a44aac4f238.PNG)

#### **5- VirtualBoxの仮想マシンの作成**

5-1.VirtualBoxが終了している状態から、下の画像の四角をダブルクリックして、VirtualBoxを起動する。

![Setting_Mashine-1](https://user-images.githubusercontent.com/80440848/184461165-f5690181-46ac-4501-beb6-9d91f2bab20a.PNG)

5-2.ファイル > `環境設定(P)...`をタップ。

![Setting_Mashine-2](https://user-images.githubusercontent.com/80440848/184461509-39b2f551-7094-40ab-acda-c54d90d52e9f.PNG)

5-3.一般 > デフォルトの仮想マシンフォルダー(M)の 下の画像の赤い四角をタップし`その他`を選択。

![Setting_Mashine-3](https://user-images.githubusercontent.com/80440848/184462645-502725ab-e9f8-4413-89cc-c92d74fa983a.PNG)

5-4.仮想マシンの関連ファイル等の置き場所を決める為、フォルダ(ここではTest_CNodeフォルダ)を選択し、`OK`をタップし環境設定を完了する。

![Setting_Mashine-4](https://user-images.githubusercontent.com/80440848/184462980-4acdccd3-214f-4771-9336-35e0e1b97733.PNG)


#### **6- VirtualBoxの仮想マシンの環境設定**

6-1.対象の仮想マシンを選択したまま、赤い四角の線に囲まれた`設定`をタップ。

![Setting_Mashine-1](https://user-images.githubusercontent.com/80440848/184465981-d70cd0cb-a06f-4d53-87a0-63f2369da05f.PNG)

6-2.一般 > 高度(A)へと移動し、クリップボードの共有とドラック&ドロップを`無効`から`双方向`へ変更する。

![Setting_Mashine-2](https://user-images.githubusercontent.com/80440848/184466214-f00c4119-04f6-4beb-b9c1-5a9946e16c5c.PNG)

6-3.次に、システム > マザーボード(M)へ移動し、起動順序の`フロッピー`のチェックマークを外し、`ネットワーク`にチェックマークを入れる。その他は、デフォルトのままで良い。

![Setting_Mashine-3](https://user-images.githubusercontent.com/80440848/184466552-1c02f7f2-cf4e-4b4f-b0c5-70a6f1a2bc14.PNG)

6-4.システム > プロセッサー(P)に移動し、プロセッサー数(P)を`2`に変更する。※ディスクを起動してUbuntuのインストールの際にKernelPanicで先に進めない状況になるので、ご自身のPC状況に応じて2以上に設定して下さい。

![Setting_Mashine-4](https://user-images.githubusercontent.com/80440848/184466800-bcc15b4f-fa88-4319-b601-83ae5b690f28.PNG)

6-5.ストレージに移動し、赤い四角の`空`を選択したまま、右の赤い四角のディスクのようなマークが表示されるので、そのディスクマークをタップする。

![Setting_Mashine5](https://user-images.githubusercontent.com/80440848/184466892-c17b8f39-5255-4ec4-a2f9-644ddac9c1e2.png)

6-6.ディスクマークをタップしたら、`ディスクファイルを選択...`を選択。

![Setting_Mashine-6](https://user-images.githubusercontent.com/80440848/184467440-65ab8f20-a3b5-4260-a445-4741770447d8.PNG)

6-7.3-2で移動したフォルダを選択して、Ubuntu-20.04.4-desktop-amd64を選択する。

![Setting_Mashine-7](https://user-images.githubusercontent.com/80440848/184467480-91534242-b20c-4485-beca-7481caf1ab53.PNG)

![Setting_Mashine-8](https://user-images.githubusercontent.com/80440848/184467707-ad80d336-138c-441b-a720-902b2a26bfdb.PNG)

6-8.ネットワークのアダプター1の`ネットワークアダプターを有効化(E)`にチェックを入れておく。**※全てのセッティングが終わった後、セキュリティを堅牢にする為、チェックマークを外したままKESの更新作業等を行う。**

![Setting_Mashine-9](https://user-images.githubusercontent.com/80440848/184467931-80da9d62-98d0-4e6b-b336-d76e1957f307.png)

6-9.**共有フォルダの設定** です。メニュー > 共有フォルダーをタップ。

![共有フォルダ_1](https://user-images.githubusercontent.com/80440848/184518168-a7e59e32-23ea-4ac1-be42-1618267045a8.PNG)

6-10.下の画像のように、フォルダのパスから「その他」を選択し、**ホストPCにある共有するフォルダ名**を選択する。

![共有フォルダ_2-1](https://user-images.githubusercontent.com/80440848/184518243-ef50b2cc-8bb7-4647-8a00-3accf0c584ac.png)

※ホスト側でのフォルダを追加して作成する事も可能です。

6-11.フォルダーのパスのところには、ホストPCに用意してある共有フォルダを選択する。すると自動で下のスペースの`フォルダ名`にも追加される。そして、自動マウントにチェックを入れる。

![共有フォルダ_3](https://user-images.githubusercontent.com/80440848/184518546-593cc394-2583-45c2-8d0b-96b3ced50c1b.png)

6-12.`OK`すると下の画像のようになる。

![共有フォルダ_4](https://user-images.githubusercontent.com/80440848/184518719-56b691c2-82f8-4383-871d-40b3a0f7382c.PNG)

**※共有フォルダの機能が有効になる為には他の設定が必要になります。とりあえず、仮想マシンの環境設定を完了してます。**


#### **7- Ubuntuのインストール**

7-1.`起動`をタップ。

![install_ubuntu-1](https://user-images.githubusercontent.com/80440848/184519159-4dc7e22d-b97d-4561-ad71-58f48697025e.PNG)

7-2.VirtualBoxの環境設定や仮想マシンのストレージの設定により下の画像がスキップされることがある。もし、下の画像の表示があれば3-2のディスクを選択し、`起動`をタップ。

![install_ubuntu-2](https://user-images.githubusercontent.com/80440848/184519224-d27eaa1b-40c3-4138-836b-15a93aebdb53.png)

7-3.下の画像のようにディスクが起動し始めます。

![install_ubuntu-3](https://user-images.githubusercontent.com/80440848/184519354-4a60ea8e-267c-4cda-952b-5fce4de835aa.png)

7-4.左の枠の中から`日本語`を選択し`Ubuntuをインストール`をタップします。

![install_ubuntu-4](https://user-images.githubusercontent.com/80440848/184519425-07bb4035-2db2-4488-aeaa-166ad6afe889.png)

7-5.そのまま`続ける`をタップ。

![install_ubuntu-5](https://user-images.githubusercontent.com/80440848/184519500-d4cd960c-2773-4ffc-9845-9f32c7806190.png)

7-6.下の画像の状態のまま、`続ける`をタップ

![install_ubuntu-6](https://user-images.githubusercontent.com/80440848/184528936-4809b68b-75e9-413d-9ce8-f84efb28a45e.png)

7-7.下の画像の状態のまま、`インストール`をタップ。

![install_ubuntu-7](https://user-images.githubusercontent.com/80440848/184528995-44737e97-0bcd-4c64-9571-d3a20782a4b6.png)

7-8.`続ける`をタップします。

![install_ubuntu-8](https://user-images.githubusercontent.com/80440848/184529041-e35ff5d2-d244-45fd-965d-ae73e7c3f156.png)

7-9.下の画像の状態のまま、`続ける`をタップします。

![install_ubuntu-9](https://user-images.githubusercontent.com/80440848/184529073-b356baeb-6a27-4602-bca4-3afaf92a3631.png)

7-10.`あなたの名前`はマシン名を入れると、その下の`コンピューターの名前`、`ユーザー名の入力`にも自動で入力されます。そして、パスワードをご自身で決めて入力を済ませて下さい。終わりましたら、`続ける`をタップ。

![install_ubuntu-10](https://user-images.githubusercontent.com/80440848/184529128-0285558b-b30d-43c1-87eb-3af228d931ac.png)

7-11.Ubuntuのインストールが始まりました。しばらくお待ちください。

![install_ubuntu-11](https://user-images.githubusercontent.com/80440848/184529318-1eb3cfd5-ab0d-4fbf-bedd-9749a714baa0.png)

7-12.しばらく、お待ちください。

![install_ubuntu-12](https://user-images.githubusercontent.com/80440848/184529346-8647772e-7cc7-4ab7-9b8d-88d35a0ee789.png)

7-13.画面が切り替わります。

![install_ubuntu-13](https://user-images.githubusercontent.com/80440848/184529400-840e64dc-c7e4-4ac3-9f09-2a5256b6ab8c.png)

7-14.この画像になりましたら、右上の`スキップ(S)`をタップします。

![install_ubuntu-14](https://user-images.githubusercontent.com/80440848/184529444-ac73d9bb-9a10-457b-9301-d1f2d530b057.png)

7-15.`次へ`をタップします。

![install_ubuntu-15](https://user-images.githubusercontent.com/80440848/184529489-6e26c7a0-1afc-4429-8618-1ce80a98b160.png)

7-16.そのまま、`次へ（N)`をタップ。

![install_ubuntu-16](https://user-images.githubusercontent.com/80440848/184529565-da681e94-671b-4f50-9e54-2ab38b18ff75.png)

7-17.`いいえ、送信しません`を選択し、右上の`次へ(N)`をタップします。

![install_ubuntu-17](https://user-images.githubusercontent.com/80440848/184529605-d90d782a-f16f-4844-b41e-d9801ab9b61f.png)

7-18.インストールが終わりました。`今すぐ再起動する`をタップして下さい。

![install_ubuntu-18](https://user-images.githubusercontent.com/80440848/184529664-a2ccb0e8-ce6b-496f-9b1b-3a3380223f77.png)

7-19.再起動後、ソフトウェアの更新案内があるので、`今すぐインストールする`をタップ。

![install_ubuntu20](https://user-images.githubusercontent.com/80440848/184534669-9db15ca6-8304-4a6f-b940-a9746a2ab97d.png)

7-20.ソフトウェアの更新が完了したら、`すぐに再起動`する。

![install_ubuntu21](https://user-images.githubusercontent.com/80440848/184534823-ccb8769c-6477-40e6-afc2-35998cd1b24a.png)

7-21.Ubuntu画面でマウスを右クリックして、`端末を開く`をタップし、下のコマンドを実行する。

```
sudo apt updata -y
sudo apt upgrade -y
sudo apt install gcc make perl -y
```

#### **8- Guest Additionsのインストール**

8-1.ホストメイン画面上部の「Devices」タブから「Insert Guest Additions CD image...」⇒`OK`をクリックします。

![共有フォルダ_5](https://user-images.githubusercontent.com/80440848/184529831-1af5010c-3969-47c6-8dd4-5efa5e23d87c.PNG)

8-2.以下のメッセージが表示されたら`実行`をクリックした後、パスワードを入力します。

![共有フォルダ_6](https://user-images.githubusercontent.com/80440848/184529906-0a2fc427-786a-40f0-b433-a7d38f72b6ab.PNG)

8-3処理完了のメッセージが表示されましたら`Enter`キーをタップします。

![共有フォルダ_7](https://user-images.githubusercontent.com/80440848/184530144-5c95c10c-4197-4316-96e5-1b6cd8f78e4b.PNG)

8-4.ユーザーをグループ化するコマンドを実行。

```
sudo adduser <ユーザー名> vboxsf
```

8-5.共有フォルダが作成できたか下の画像のように表示されていればOK、コピー＆ペーストできるかホストPCでコマンドを`コピー`してゲストOSの端末で右クリックして`貼り付け`してみる。問題なければ、これで終了です。お疲れ様でした！

![共有フォルダ_6](https://user-images.githubusercontent.com/80440848/184537923-5b153aa4-889c-43ff-8b39-2840c50e664f.png)

![コピ＆ペイスト-7](https://user-images.githubusercontent.com/80440848/184537933-f3f645ed-1afe-48aa-9a0e-0cafb257a333.png)

---





### Macの場合

!!! hint "貢献者"
    [[WYAM] WYAM-StakePool](https://adapools.org/pool/940d6893606290dc6b7705a8aa56a857793a8ae0a3906d4e2afd2119) Akyoさんに導入手順を作成頂きました。ありがとうございます！


**環境**  

* MacBook Pro (13-inch, 2019, Two Thunderbolt 3 ports)
* Monterey 12.5

**ダウンロード/インストール**  

* Ubuntu Desktop 20.04.4 LTS
* VirtualBox 6.1.14

---

#### **1- Ubuntuイメージファイルのダウンロード**

1-1. 以下のリンク先からISOイメージファイルをダウンロードします。

  - [Ubuntuを入手する](https://releases.ubuntu.com/20.04.4/?_ga=2.145106481.424434523.1659109603-1752942665.1659109603)  
※ ダウンロード完了まで少しかかるのでしばらくお待ちください

| ファイル名 |
| ------------- |
|ubuntu-20.04.4-desktop-amd64.iso|

![UbuntuInstall-1](../images/mac/158050737-e653351a-063b-4a39-b7c4-3047b6f2d5c7.png)

---

#### **2- VirtualBoxのダウンロード/インストール**

2-1. 以下のリンク先からVirtualBoxをインストールします。

  - [VirtualBoxを入手する](https://www.virtualbox.org/wiki/Downloads)

| ファイル名 |
|-------------|
|VirtualBox-6.1.36-152435-OSX.dmg|

![VirtualBoxInstall-1](../images/mac/158052058-ab11df3f-3372-46e0-b438-f2bc63ed974a.png)

---

2-2. ダウンロードしたファイルをクリックし、インストールウィザードに従ってインストールします。完了したら「閉じる」をクリックして終了します。


> macOS BigSur 以降では、インストールしたカーネル拡張をロードできるようにするために再起動が必要です。

![VirtualBoxInstall-2](../images/mac/158053289-ab1efca1-f989-4025-96e4-d79e56e49b1b.png)

---

#### **3- VirtualBoxで仮想マシンを作成**
> VirtualBoxのアイコンをクリックし、起動します。  

3-1. VirtualBoxが起動したら「新規」をクリックします。

![UbuntuVMCreate-1](../images/mac/158601180-168b2c80-54fc-4ea7-b7a3-c795822b9cc0.png)

---

3-2. 以下の項目を設定し、「続き」をクリックします。  
> ※ 名前はお好みで入力してください。

| 名前 | Air-Gap-Machine |
|:-------------|:------------|
| マシンフォルダー | デフォルトでOK |
| タイプ | Linux |
| バージョン | Ubuntu（64-bit） |

![UbuntuVMCreate-2](../images/mac/158602639-d642c913-9c3a-4e76-ad95-7e639f03fd6e.png)

  ---

3-3. 仮想マシンに割当てるメモリサイズは「`4096`MB」とし、「続き」をクリックします。

![UbuntuVMCreate-3](../images/mac/159216570-ab997522-b8ea-42d6-a47a-86f5729c641d.png)

---

3-4. 「仮想ハードディスクを作成する」にチェックを入れ、「作成」をクリックします。

![UbuntuVMCreate-4](../images/mac/158603719-0c8488a9-27e0-4d2a-9324-4c37b4d6ded2.png)

---

3-5. 「VDI（VirtualBox Disk Image）」にチェックを入れ、「続き」をクリックします。

![UbuntuVMCreate-5](../images/mac/158604211-49605724-3e9f-4ed4-b728-974a0a39ffe0.png)

---

3-6. 「固定サイズ」にチェックを入れ、「続き」をクリックします。

![UbuntuVMCreate-6](../images/mac/158604563-9f0d291d-9596-4d04-a3ac-723d8cdf5504.png)

---

3-7. 仮想HDDファイルは「`50`GB」を入力し、「作成」をクリックします。

![UbuntuVMCreate-7](../images/mac/158605301-1aed9543-40ae-43ef-9ec0-d58904a689d4.png)

---

#### **4- 仮想マシンの仕様設定**

> 「OK」をクリックしたら「Oracle VM VirtualBox マネージャー」画面に遷移するので設定毎に「設定」をクリックしてください。

<br><br>
<span style="font-size: 200%;"><u>一般</u></span>

4-1. 歯車マークの「設定」をクリックします。

![UbuntuSpecSettings-1](../images/mac/159109074-94571ed6-ec42-4c64-9fab-14eb8f1c72ba.png)

---

4-2. 「高度」タブから、以下の設定を「双方向」にし、「OK」をクリックします。

![UbuntuSpecSettings-2](../images/mac/159109569-30d3557b-047f-4bfb-ac49-5ef66d7534c7.png)

---

<span style="font-size: 200%;"><u>システム</u></span>

4-3. 「マザーボード」タブと「プロセッサー」タブを以下の設定にし、「OK」をクリックします。

| マザーボード |  |
|:-------------|:------------|
| 起動順序 | 「フロッピー」のチェックマークを外す |
| チップセット | ICH9 |
| ポインティングデバイス | PS/2マウス |

| プロセッサー |  |
|:-------------|:------------|
| プロセッサー数 | 4 |

![UbuntuSpecSettings-3](../images/mac/159111094-fbe3b0f6-b6ea-4d30-8c91-d86c1fb28791.png)

---

<span style="font-size: 200%;"><u>ディスプレイ</u></span>

4-4. 「スクリーン」タブから以下の設定にし、「OK」をクリックします。

| ビデオメモリー | 128MB |
|:-------------|:------------|
| 表示倍率 | 200% |
| グラフィックスコントローラー | VMSVGA |
| アクセラレーション | 「3Dアクセラレーションを有効化」にチェック |

![UbuntuSpecSettings-4](../images/mac/159127356-0a509093-8739-479d-ab24-7c711e43a599.png)

---
<span style="font-size: 200%;"><u>ストレージ</u></span>

> イメージファイルはダウンロードフォルダにあると思いますので、そちらを選択するかお好きなフォルダに移動させてください。

4-5. 「ストレージデバイス」の「空」にUbuntuのイメージを指定し、「OK」をクリックします。

![UbuntuSpecSettings-5](../images/mac/159216844-a5ceddfe-e04e-4338-be5d-d12d61f66c27.png)

---

<span style="font-size: 200%;"><u>共有フォルダ</u></span>

4-6. ホスト側で共有させたいフォルダを事前に作成しておきます。  
例）「AirGap」フォルダを作成後、配下に「share」フォルダを作成。

`Mac Terminal`
```
mkdir -p $HOME/AirGap/share
```

---

4-7. 共有フォルダを指定します。

![UbuntuSpecSettings-6](../images/mac/159114384-1ec0efb2-69a3-4c87-85d4-aa33ae3c550c.png)

---

#### **5- 仮想マシンにUbuntuをインストール**

5-1. 仮想マシンを起動します。

![BootVirtualMachine-1](../images/mac/159123352-9d054193-2ba6-4717-ac2a-1978c2d1ffc4.png)

> PCから権限許可を求められたら「セキュリティとプライバシー」にて必要な権限を許可し、VirtualBoxを再起動します。

---

5-2. 読み込み終了後、言語は「日本語」にし、「Install Ubuntu」をクリックします。

![BootVirtualMachine-2](../images/mac/159124610-ae485412-085c-42e2-94e2-f75b9f556066.png)

---

5-3. キーボード設定では、日本語キーボードの方は、両方とも「Japanese」を選択し、設定が完了したら「続ける」をクリックします。  
> USキーボードの方は「キーボードレイアウト」→「キーボードレイアウトの検出」をクリックして設定してください。  
※ 画面が見切れていた場合の対処法：Alt＋F7で移動できます)

---

5-4. 「アップデートと他のソフトウェア」の設定では、以下のように設定し、「続ける」をクリックします。

![BootVirtualMachine-3](../images/mac/159128238-53def4ff-7699-45c0-85e4-c5e1115c87cb.png)

---

5-5. 「インストールの種類」の設定では「ディスクを削除してUbuntuをインストール」を選択し、「インストール」をクリックします。

![BootVirtualMachine-4](../images/mac/159128589-0b0373ac-a342-45d6-b22c-0f14122a5f3d.png)

---

5-6. 「ディスクに変更を書き込みますか?」の設定では「続ける」をクリックします。

![BootVirtualMachine-5](../images/mac/159128650-7cbc6a86-5fce-465b-b980-95d3f17f7e3e.png)

---

5-7. タイムゾーンの設定は、「Tokyo」を選択し、「続ける」をクリックします。

![BootVirtualMachine-6](../images/mac/159128953-10f8e1d9-cd04-401e-905c-3b27cbdf89e6.png)

---

5-8. 必要な情報を入力し、「続ける」をクリックします。  
> ※ 画像は一例ですのでお好みで設定してください。

![BootVirtualMachine-7](../images/mac/159129148-b99c85e4-4747-427a-b4e0-9c1842716682.png)

---

5-9. インストール開始。

![BootVirtualMachine-8](../images/mac/159129325-84554dfb-4062-4c90-ab26-baa3422c2fd5.png)

---

5-10. インストール完了後、再起動を求められるので「今すぐ再起動する」をクリックし、Enterキーを押下します。

![BootVirtualMachine-9](../images/mac/159130124-bf8953ae-bde1-4b4e-8d52-e34c026b59cc.png)

---

5-11. 再起動後、ユーザー名をクリックし、パスワードを入力してログインします。

---

5-12. 「オンラインアカウントへの接続」の設定では右上の「スキップ」をクリックします。

![BootVirtualMachine-10](../images/mac/159129733-65cc86f5-1e84-4bdd-a8be-d425f1d609d9.png)

---

5-13. 「Livepatch」の設定では右上の「次へ」をクリックします。

![BootVirtualMachine-11](../images/mac/159129954-9a75c0d4-1c99-4eb7-b7c4-0fa0f44654c8.png)

---

5-14. 「Ubuntuの改善を支援する」の設定では、「いいえ、送信しません」を選択後、右上の「次へ」をクリックします。

![BootVirtualMachine-12](../images/mac/159130038-77933811-e25d-4a48-84e7-0d77eb261aef.png)

---

5-15. 「プライバシー」の設定では右上の「次へ」をクリックします。

![BootVirtualMachine-13](../images/mac/159130272-c25ae943-20bc-41b0-a32d-a1bd63644181.png)

---

5-16. 「準備完了」と表示されたら右上の「完了」をクリックします。

![BootVirtualMachine-14](../images/mac/159130355-84b05b70-2269-4569-8793-9967a53642ba.png)

---

#### **6- Guest Additionsのインストール**

6-1. ターミナルを開いて以下を実行します。

>Guest Additionsがインストールされていない状態なのでホストからゲストにコピーアンドペーストできません。タイプミスに留意してください。
また以下の手順を行なっても、共有フォルダがGUIで表示されない、共有フォルダ化されていない場合は、一度VBox_GAs_6.1.36をアンマウントしてから再度挿入し、再起動すると共有フォルダは完了します。 それでもダメなら[GUI操作でGuest Additionsがインストールできなかった場合](./0-start-guide.md#guiguest-additions)を試してください。

```
sudo apt update -y
sudo apt upgrade -y
sudo apt install gcc make perl -y
```

---

6-2. ホストメイン画面上部の「Devices」タブから「Insert Guest Additions CD image...」→「OK」をクリックします。

---

6-2. 以下のメッセージが表示されたら「実行」をクリックした後、パスワードを入力します。

![BootVirtualMachine-15](../images/mac/159217595-93ffe2a5-ed89-4924-a3da-ece4791fbe25.png)

---

6-3. 処理完了のメッセージが表示されたらEnterキーを押下します。

![BootVirtualMachine-16](../images/mac/159153823-eb6c79b5-a6d8-46e8-9ae9-a392ed33de8e.png)

---
6-4. 処理完了のメッセージが表示されたらEnterキーを押下します。

![BootVirtualMachine-17](../images/mac/159153843-49688be7-1537-407b-b3af-c11751b2bf91.png)

---

6-4. 仮想マシンを再起動し、「View」→「Auto-resize　Guest　Display」にチェックが入っている事を確認します。

---

6-5. ユーザーをvboxsfグループに追加して再起動します。

```
sudo adduser $USER vboxsf
sudo reboot
```

6-6. 「View」→「Auto-resize　Guest　Display」にチェックが入っている事を確認します。
>確認後、右クリック→「取り出す」をクリックします。

![BootVirtualMachine-18](../images/mac/159217747-5601d4d0-2c97-4464-b270-a5ae61ef29ee.png)

---

6-7. テストファイル作成
ターミナルを開いて以下を実行します。
>共有フォルダにテストファイルを作成してホスト側で確認できたら成功です。

```
touch /media/sf_share/test
```


### 共通補足

#### GUI操作でGuest Additionsがインストールできなかった場合

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
touch /media/sf_share/test
```

---

#### Swapファイルの設定時のエラーについて

- 「テキストファイルがビジー状態です」と表示されたら以下を実行します。
```
sudo swapoff /swapfile
rm /swapfile
```

- [Swap領域設定](https://docs.spojapanguild.net/setup/1-ubuntu-setup/#1-7swap)

---

#### 本番運用で使用する際の注意点

- 本番運用で使用される場合は必ず「ネットワークアダプターを有効化」のチェックを外してください。

![BootVirtualMachine-20](../images/mac/159157103-500edf69-5ed1-48c9-aa67-bea37647c395.png)