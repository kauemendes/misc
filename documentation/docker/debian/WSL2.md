# How to Configure docker CLI into DEBIAN WSL2

If you run Debian try:
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy

ensure that /etc/sysctl.conf includes:
net.ipv4.ip_forward = 1

Third guess: Are you using openvpn?
If so, create the bridge yourself:
```
$ sudo apt-get install bridge-utils

$ sudo brctl addbr docker0

$ sudo ip addr add 10.1.0.1/24 dev docker0

$ sudo ip link set dev docker0 up

$ ip addr show docker0

$ sudo systemctl restart docker

$ sudo iptables -t nat -L -n
```
