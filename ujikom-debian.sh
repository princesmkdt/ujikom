echo "MODUL UJIKOM DEBIAN 11"
echo "auto eth0" >> /etc/network/interfaces
echo "iface eth0 inet dhcp"
nano /etc/network/interfaces
systemctl restart networking
nano /etc/resolv.conf | echo "nameserver 192.168.100.x nameserver 192.168.100.1 nameserver 8.8.8.8"
chattr +i /etc/resolv.conf
echo "anda harus ping google dulu"
echo "http://deb.debian.org/debian bullseye main contrib non-free"
apt update 
