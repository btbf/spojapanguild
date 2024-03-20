#!/usr/bin/env bash
python_version_check=$(python3 -V | grep "3.12")
python_version=$(python3 -V)

if [[ -z ${python_version_check} ]]; then
    echo
    echo "現在のPythonバージョンは${python_version}です"
    echo "3.12へアップデートする場合は何かキーを押してください"
    read
    echo "システムアップデートを実施します"
    sudo apt update && sudo apt upgrade -y

    echo "システムアップデートが完了しました"
    echo "python3.12.xへアップデートします"
    sleep 3

    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:deadsnakes/ppa -y

    sudo apt update

    echo
    echo "python3.12をインストールします"
    echo
    sudo apt install python3.12 -y
    echo
    echo "python3.12をインストールしました"
    echo
    sleep 1

    echo "python3.12.x依存関係をインストールします"
    sleep 2
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
    python3 -V

    #sudo update-alternatives --config python3

    sudo apt remove --purge python3-apt -y
    sudo apt autoclean

    sudo apt install python3-apt -y

    sudo apt install python3.12-distutils -y
    cd

    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo python3.12 get-pip.py

    sudo apt install -y build-essential libssl-dev libffi-dev python3-dev python3-pip python3-testresources
    pip3 install --upgrade setuptools six urllib3
    echo
    python_version=$(python3 -V)
    echo "途中の黄色いメッセージは無視してください"
    echo "${python_version}をインストールしました"
else
    echo "すでにPython 3.12シリーズがインストールされています"
fi
