getway=$(ip route get 8.8.8.8 | grep -oP '(?<=via )[^ ]*')
sudo ip route add default via $getway dev wlan0
sudo ip rule add from all lookup main pref 30000
sudo ip rule add pref 1 from all lookup main
sudo ip rule add pref 2 from all lookup default


