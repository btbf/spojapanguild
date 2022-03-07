# ノードに関するよくある質問

## BPノードが再起動を繰り返します

** 1. Swap設定確認 **
```
free -h
```
!!! example "戻り値"
    * Mem:Total⇒`15Gi`以下 
    * Swap:Total⇒`8.0Gi`以下

=== "Mem:Total⇒ 15Gi 以下の場合"
    サーバーメモリを16GB以上にスケールアップするか、16GBスペックを再契約し再構築する

=== "Swap:Total⇒ 8.0Gi 以下の場合"
    ** 既存のスワップファイルを削除する **
    ```
    sudo swapoff /swapfile
    rm /swapfile
    ```
    ** 新しいスワップファイルを設定する **
    ```
    cd $HOME
    sudo fallocate -l 8G /swapfile

    sudo chmod 600 /swapfile

    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo swapon --show

    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    cat /proc/sys/vm/vfs_cache_pressure
    cat /proc/sys/vm/swappiness
    ```
    サーバー再起動
    ```
    sudo systemctl stop cardano-node
    sudo reboot
    ```