# **SFTPソフト設定**

!!! info 
    本手順は、MacOSで実施してます。Windowsの方は読み替えて実施してください。

## 1. FileZillaのダウンロード

次のリンクの遷移先から[FileZilla Client](https://filezilla-project.org/)をダウンロードします。

| OS | ファイル名 |
:---|:---
| MacOS | FileZilla_X.XX.X_macosx-x86.app.tar.bz2 |
| Windows | FileZilla_X.XX.X_win64-setup.exe |

1. 「`Quick download links`」配下の「`Download Filezilla Client`」をクリック
![FileZilla-1](https://user-images.githubusercontent.com/80967103/167054304-2be2102e-fa65-49fb-a0e8-c4b9cfafee58.png)
2. 「`More download options`」配下の「`Show additional download options`」をクリック
![FileZilla-2](https://user-images.githubusercontent.com/80967103/167054657-d3a0e819-babc-4268-a2cf-ac89bbbb396a.png)
3. 「`Download FileZilla Client`」から対象OSを選択します。  
ダウンロード後に解凍します。Macの方はDownloadsフォルダからApplicationフォルダへ移動してください。
![FileZilla-3](https://user-images.githubusercontent.com/80967103/167055110-ffb6d7f4-b558-4f0e-8358-8640bdfb5002.png)
4. ポップアップメッセージが表示されたら以下の画像のように進めてFileZillaを起動します。
![FileZilla-4](https://user-images.githubusercontent.com/80967103/167059324-6e8b3a81-7e27-4649-97d5-23effe9be3d1.png)
![FileZilla-5](https://user-images.githubusercontent.com/80967103/167056869-3a42a555-9f4f-425c-acaf-74bee800f950.png)


## 2. SFTP設定
サイトマネージャーでの各種設定

| 項目 | 設定値 |
:---|:---
| **`プロトコル`** | SFTP |
| **`ホスト`** | サーバーIP |
| **`ポート`** | 設定したsshポート番号 |
| **`ログオンタイプ`** | インタラクティブ |
| **`ユーザー`** | ユーザー名 |

1. メニューバーから「`FileZilla`」→「`設定`」へと進みます。
![FileZilla-6](https://user-images.githubusercontent.com/80967103/167063614-9391fe44-f539-4e99-8f00-a1e60449a3e6.png)
2. 秘密鍵を指定します。
![FileZilla-7](https://user-images.githubusercontent.com/80967103/167064529-afa0cd78-f1a9-438a-92ac-4f9ef9a29853.png)
3. 接続先の作成と設定をします。
![FileZilla-8](https://user-images.githubusercontent.com/80967103/167065561-4cb28293-6f1b-4019-9d93-47e967d5b1bc.png)
> Google2段階認証を設定していて、うまく接続できなかった場合は、ログオンタイプを一度`鍵ファイル`にして秘密鍵を指定後、接続を試み、その後ログオンタイプを`インタラクティブ`にしてGoogle認証での6桁の数字を入力してみてください。

---