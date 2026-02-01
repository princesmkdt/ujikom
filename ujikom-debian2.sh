#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# INSTALL APA YANG DI PERLUKAN
adduser prince
cd /home/prince/
apt install bind9 dnsutils proftpd ftp mariadb-server php php-fpm nginx w3m zip postfix courier-imap roundcube
apt remove --purge apache2
apt autoremove
# Untuk Konfig Domain
cp /home/prince/ujikom/conf_domain /etc/bind/conf_domain && cp /home/prince/ujikom/conf_ip /etc/bind/conf_domain
cp /home/prince/ujikom/proftpd.conf /etc/proftpd/proftpd.conf && cp /home/prince/ujikom/webgw /etc/nginx/sites-available/webgw
ln -s /etc/nginx/sites-available/webgw /etc/nginx/sites-enabled
rm -r /etc/nginx/sites-enabled/default
cp /home/prince/ujikom/main.cf /etc/postfix/main.cf && maildirmake /etc/skel/maildir
cp /home/prince/ujikom/config.inc.php /etc/roundcube/config.inc.php
cp /home/prince/ujikom/mailgw /etc/nginx/sites/available/mailgw
cp /home/prince/ujikom/mailgw /etc/nginx/sites-enabled/mailgw
ln -s /etc/nginx/sites-available/mailgw /etc/nginx/sites-enabled/
systemctl restart bind9
systemctl restart proftpd
systemctl restart nginx
adduser pengguna
mkdir /home/pengguna/public_html_baru1 && chmod 775 /home/pengguna/public_html_baru1 -R
chown pengguna:www-data /home/pengguna/public_html-baru1 -R
echo "Untuk Perintah mysql ada di file sqlcommand"
touch sqlcommand && echo "untuk buat database = create database wp;"
echo "berikan akses ke database yang baru di buat dengan = grant all on wp.* to userdata identified by 'Moshing3!';"
