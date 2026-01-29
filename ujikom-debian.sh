
echo "http://deb.debian.org/debian bullseye main contrib non-free"
apt update 
sudo apt install bind9 dnsutils -y 
nano /etc/bind/named.conf.local | echo 
'zone “tkjsmkdt.org”{
file “/etc/bind/conf_domain”;
Type master;
};

zone “100.168.192.in-addr.arpa” {
type master;
file “/etc/bind/conf_ip”;
};'
