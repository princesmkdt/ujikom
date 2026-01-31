# ...existing code...
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Tentukan user target (bekerja baik bila dijalankan langsung atau via sudo)
if [ -n "${SUDO_USER-}" ] && [ "${SUDO_USER}" != "root" ]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="${USER:-$(whoami)}"
fi

# Cari home directory target user
HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)
HOME_DIR=${HOME_DIR:-/home/"$TARGET_USER"}

# Gunakan sudo bila bukan root
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

echo "Menjalankan untuk user: $TARGET_USER (home: $HOME_DIR)"

# Paket yang dibutuhkan (sesuaikan dengan modul)
PKGS=(bind9 dnsutils proftpd ftp mariadb-server php php-fpm nginx w3m postfix courier-imap roundcube zip)

$SUDO apt update
$SUDO apt install -y "${PKGS[@]}"

echo "Selesai install paket yang diperlukan."

# Hapus apache2 bila terpasang untuk menghindari bentrok dengan nginx
if dpkg -s apache2 >/dev/null 2>&1; then
  $SUDO apt remove -y apache2
  $SUDO apt autoremove -y
  echo "apache2 dihapus"
fi

# Pastikan file zona dan direktori ada
$SUDO mkdir -p /etc/bind
$SUDO touch /etc/bind/conf_domain /etc/bind/conf_ip
$SUDO chmod 644 /etc/bind/conf_domain /etc/bind/conf_ip

# Direktori sumber konfigurasi di repo user (sesuaikan dengan modul)
SRC_DIR="$HOME_DIR/ujikom"

if [ -d "$SRC_DIR" ]; then
  # Salin file jika ada
  if [ -f "$SRC_DIR/conf_ip.txt" ]; then
    $SUDO cp -f "$SRC_DIR/conf_ip.txt" /etc/bind/conf_ip
    echo "copied conf_ip"
  else
    echo "peringatan: $SRC_DIR/conf_ip.txt tidak ditemukan"
  fi

  if [ -f "$SRC_DIR/conf_domain.txt" ]; then
    $SUDO cp -f "$SRC_DIR/conf_domain.txt" /etc/bind/conf_domain
    echo "copied conf_domain"
  else
    echo "peringatan: $SRC_DIR/conf_domain.txt tidak ditemukan"
  fi

  if [ -f "$SRC_DIR/webgw.txt" ]; then
    $SUDO cp -f "$SRC_DIR/webgw.txt" /etc/nginx/sites-available/webgw
    $SUDO chmod 644 /etc/nginx/sites-available/webgw
    if [ ! -L /etc/nginx/sites-enabled/webgw ]; then
      $SUDO ln -s /etc/nginx/sites-available/webgw /etc/nginx/sites-enabled/webgw
    fi
    echo "copied & enabled webgw nginx site"
  else
    echo "peringatan: $SRC_DIR/webgw.txt tidak ditemukan"
  fi

  if [ -f "$SRC_DIR/proftp.txt" ]; then
    $SUDO cp -f "$SRC_DIR/proftp.txt" /etc/proftpd/proftpd.conf
    $SUDO chmod 644 /etc/proftpd/proftpd.conf
    echo "copied proftpd config"
  else
    echo "peringatan: $SRC_DIR/proftp.txt tidak ditemukan"
  fi
else
  echo "peringatan: sumber konfigurasi $SRC_DIR tidak ditemukan. Buat folder $SRC_DIR berisi conf_ip.txt, conf_domain.txt, webgw.txt, proftp.txt"
fi

# Buat public_html di home user untuk upload web
PUBLIC_HTML="$HOME_DIR/public_html"
if [ ! -d "$PUBLIC_HTML" ]; then
  $SUDO -u "$TARGET_USER" mkdir -p "$PUBLIC_HTML"
  echo "Direktori $PUBLIC_HTML dibuat"
fi

# Set kepemilikan agar user dapat mengelola file tersebut
$SUDO chown -R "$TARGET_USER":"$TARGET_USER" "$HOME_DIR" || true
$SUDO chmod -R 750 "$PUBLIC_HTML" || true

# Restart layanan yang relevan (jangan exit bila gagal restart satu service)
$SUDO systemctl restart bind9 || echo "gagal restart bind9 (cek konfigurasi)"
$SUDO systemctl restart proftpd || echo "gagal restart proftpd"
$SUDO systemctl restart nginx || echo "gagal restart nginx"

# Petunjuk singkat untuk modul (siap dipublish ke GitHub)
cat <<EOF

Selesai. Beberapa catatan untuk modul / README:
- File konfigurasi BIND: /etc/bind/named.conf.local (tambahkan include jika perlu)
- Zona: /etc/bind/conf_domain (domain) dan /etc/bind/conf_ip (reverse)
- FTP: /etc/proftpd/proftpd.conf
- Web: /etc/nginx/sites-available/* (enable dengan ln -s ke sites-enabled)
- Upload web ke: $PUBLIC_HTML (gunakan FTP client)
- Buat database MySQL: mysql -u root -p  -> CREATE DATABASE wp;
- Tambah user FTP: sudo adduser <nama_user>

Simpan repository Anda termasuk folder 'ujikom' berisi conf_domain.txt, conf_ip.txt, webgw.txt, proftp.txt agar skrip dapat otomatis menyalin konfigurasi.

EOF
# ...existing code...