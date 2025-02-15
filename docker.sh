sudo mount -o remount,rw /
sudo mount -t tmpfs -o mode=755 tmpfs /sys/fs/cgroup
sudo mkdir -p /sys/fs/cgroup/devices
sudo mount -t cgroup -o devices cgroup /sys/fs/cgroup/devices
DIRECTORY=/var/run/
if [ ! -d "$DIRECTORY" ]; then
  mkdir -p /var/run/
fi
sudo mount --bind /data/docker/run/ /var/run/
sudo dockerd # --iptables=false
