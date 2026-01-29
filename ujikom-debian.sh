#!/usr/bin/env bash
set -e pipefail 
echo "Kebutuhan Install ujikom selain itu anda config filenya sendiri :)"
apt install bind9 dnsutils proftpd ftp mariadb-server php php-fpm nginx w3m postfix courier-imap roundcube
echo "Selesai Install Kebutuhan Ujikom"
echo "file konfigurasi web atau www ada di folder config /etc/bind/named.conf.local"
echo "Silahkan di edit sesuai kebutuhan"
echo "tambahkan file conf_domain untuk domain dan conf_ip untuk ipnya"
echo "file ftp ada di /etc/proftpd/proftpd.conf"
echo "silahkan di edit sendiri :))"
echo "saya akan meremove apache agar tidak bentrok dengan nginx"
apt remove apache2 -y
echo "Selesai menghapus apache2"
apt autoremove -y
echo "file web ada di /etc/nginx/sites-available"
echo "filenya sudah ada di repository saya"
echo "silahkan di edit sesuai kebutuhan"
echo "jika sudah selesai silahkan di enable dengan perintah ln -s dan restart nginx"
echo "Buka filezilla dan koneksikan FTP Server
- Masuk ke direktory public_html dan ganti nama index.php menjadi index_1.php
- Download file wordpress dari situs resmi dan upload direktory utama FTP (pastikan klik
tanda /. Jangan ditaruh di dalam public_html)."
apt install zip 
echo "anda harus menambah database dengan sql dengan perintah mysql dan create database wp;"
echo "jangan lupa tambahkan ftp user di linux anda dengan adduser"
IFS=$'\n\t'