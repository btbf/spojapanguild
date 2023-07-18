!!! summary "概要"
    このマニュアルは、プールのpayment.addrを有権者登録する方法です。  
    payment.addrの資金をVotingパワーに使用でき、Catalyst投票が可能になります。

## 依存関係インストール
必要なバイナリ

| bech32  | cardano-signer | catalyst-toolbox |
| :---------- | :---------- | :---------- |
| v1.1.3 | v1.13.0 | v0.5.0 |

### **Bech32インストール**

ダウンロード
```bash
cd $HOME/git
wget https://github.com/input-output-hk/bech32/archive/refs/tags/$(curl -s https://api.github.com/repos/input-output-hk/bech32/releases/latest | jq -r .tag_name).tar.gz
tar -xf $(curl -s https://api.github.com/repos/input-output-hk/bech32/releases/latest | jq -r .tag_name).tar.gz
mv bech32-$(curl -s https://api.github.com/repos/input-output-hk/bech32/releases/latest | jq -r .tag_name | tr -d v) bech32
rm $(curl -s https://api.github.com/repos/input-output-hk/bech32/releases/latest | jq -r .tag_name).tar.gz
```

ビルド
```bash
cd bech32
cabal update
cabal build bech32
```

binディレクトリへコピー
```bash
sudo cp $(find $HOME/git/bech32/dist-newstyle/build -type f -name "bech32") /usr/local/bin/bech32
```

バージョン確認
```bash
bech32 -v
```
> 戻り値 1.1.3


### **cardano-signerインストール**
```bash
cd $HOME/git
wget https://github.com/gitmachtl/cardano-signer/releases/download/$(curl -s https://api.github.com/repos/gitmachtl/cardano-signer/releases/latest | jq -r .tag_name)/cardano-signer-$(curl -s https://api.github.com/repos/gitmachtl/cardano-signer/releases/latest | jq -r .tag_name | tr -d v)_linux-x64.tar.gz
tar -xf cardano-signer-$(curl -s https://api.github.com/repos/gitmachtl/cardano-signer/releases/latest | jq -r .tag_name | tr -d v)_linux-x64.tar.gz
```

binディレクトリへコピー
```
sudo cp $HOME/git/cardano-signer /usr/local/bin/cardano-signer
```

バージョン確認
```
cardano-signer help | grep -m 1 "cardano-signer"
```
> cardano-signer 1.13.0

### **catalyst-toolboxインストール**

```
cd $HOME/git
git clone https://github.com/input-output-hk/catalyst-toolbox.git
cd catalyst-toolbox
git checkout 6c3ebb7
```

Rustパッケージアップデート
```
rustup update
```

インストール
```
cd catalyst-toolbox
cargo install --path . --force
```

バージョン確認
```
catalyst-toolbox --version
```
> catalyst-toolbox 0.5.0
