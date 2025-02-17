#!/data/data/com.termux/files/usr/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" != "0" ]; then
    echo "错误: 需要 root 权限"
    echo "请先执行 'tsu' 获取 root 权限，然后再运行 'lxcs' 命令"
    exit 1
fi

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 清理 cgroup
clean_cgroup() {
    log "清理 cgroup 挂载点..."
    # 保留 docker 使用的 cgroup
    for i in $(mount | grep cgroup | grep -v "devices" | awk '{print $3}' | sort -r); do
        umount $i 2>/dev/null || true
    done

    log "清理 cgroup 目录..."
    # 不要完全清理 cgroup 目录
    for cg in blkio cpu cpuacct cpuset freezer memory; do
        if [ -d "/sys/fs/cgroup/${cg}" ]; then
            umount "/sys/fs/cgroup/${cg}" 2>/dev/null || true
        fi
    done
}
# 配置网络
setup_network() {
    log "配置网络..."
    sysctl -w net.ipv4.ip_forward=1

    # 清理防火墙规则
    iptables -t filter -F
    iptables -t filter -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t raw -F
    iptables -t raw -X
    iptables -t mangle -F
    iptables -t mangle -X

    # 配置路由规则
    ip rule add pref 1 from all lookup main 2>/dev/null || true
    ip rule add pref 2 from all lookup default 2>/dev/null || true
    ip route add default via 10.0.0.1 dev wlan0 2>/dev/null || true
    ip rule add from all lookup main pref 30000 2>/dev/null || true

    # 添加 NAT 规则
    iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
}

# 主函数
main() {
    log "开始启动 LXC 容器..."

    # 清理和重新挂载 cgroup
    clean_cgroup

    log "重新挂载 cgroup..."
    lxc-setup-cgroups

    # 设置网络
    setup_network

    # 启动容器
    log "启动 debian 容器..."
    lxc-start -n debian -d

    log "容器启动完成！"
    lxc-ls -f
}

# 处理参数
case "$1" in
    "stop")
        log "停止容器..."
        lxc-stop -n debian -k
        ;;
    "start")
        main
        ;;
    *)
        main
        ;;
esac