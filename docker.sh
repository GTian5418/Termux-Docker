#!/data/data/com.termux/files/usr/bin/bash

# 创建必要的目录
sudo mkdir -p /data/docker/run
sudo mkdir -p /var/run

# 重新挂载根目录为可写
sudo mount -o remount,rw /

# 如果 cgroup 未挂载，则挂载
if ! mountpoint -q /sys/fs/cgroup; then
    sudo mount -t tmpfs -o mode=755 tmpfs /sys/fs/cgroup
fi

# 确保 devices cgroup 存在并挂载
if [ ! -d "/sys/fs/cgroup/devices" ]; then
    sudo mkdir -p /sys/fs/cgroup/devices
fi
if ! mountpoint -q /sys/fs/cgroup/devices; then
    sudo mount -t cgroup -o devices cgroup /sys/fs/cgroup/devices
fi

# 创建并挂载 run 目录
DIRECTORY=/var/run/
if [ ! -d "$DIRECTORY" ]; then
    mkdir -p /var/run/
fi
sudo mount --bind /data/docker/run/ /var/run/

# 启动 dockerd
sudo dockerd --cgroup-parent=/docker