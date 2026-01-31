#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Tentukan target user (bekerja bila dijalankan langsung atau via sudo)
if [ -n "${SUDO_USER-}" ] && [ "${SUDO_USER}" != "root" ]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="${USER:-$(whoami)}"
fi

# Cari home directory target user
HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)
HOME_DIR=${HOME_DIR:-/home/"$TARGET_USER"}

# Helper: jalankan perintah dengan sudo bila perlu
run() {
  if [ "$(id -u)" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}

echo "Menjalankan untuk user: $TARGET_USER (home: $HOME_DIR)"

# Paket yang dibutuhkan (sesuaikan dengan modul)
PKGS=(bind9 dnsutils proftpd ftp mariadb-server php php-fpm nginx w3m postfix courier-imap roundcube zip)

run apt update
run apt install -y "${PKGS[@]}"

echo "Selesai install paket yang diperlukan."

# Hapus apache2 bila terpasang untuk menghindari bentrok dengan nginx
if dpkg -s apache2 >/dev/null 2>&1; then
  run apt remove -y apache2
  run apt autoremove -y
  echo "apache2 dihapus"
fi

# Pastikan direktori /etc/bind dan file zona ada
run mkdir -p /etc/bind
run touch /etc/bind/conf_domain /etc/bind/conf_ip
run chmod 644 /etc/bind/conf_domain /etc/bind/conf_ip

# Direktori sumber konfigurasi di repo user (sesuaikan dengan modul)
SRC_DIR="$HOME_DIR/ujikom"

if [ -d "$SRC_DIR" ]; then
  # fungsi bantu untuk cari nama file alternatif (tanpa/ dengan .txt)
  copy_if_exists() {
    local src_base="$1" dst="$2"
    if [ -f "$SRC_DIR/$src_base" ]; then
      run cp -f "$SRC_DIR/$src_base" "$dst"
      return 0
    elif [ -f "$SRC_DIR/$src_base.txt" ]; then
      run cp -f "$SRC_DIR/$src_base.txt" "$dst"
      return 0
    fi
    return 1
  }

  if copy_if_exists "conf_ip" /etc/bind/conf_ip; then
    echo "copied conf_ip"
  else
    echo "peringatan: $SRC_DIR/conf_ip{,.txt} tidak ditemukan"
  fi

  if copy_if_exists "conf_domain" /etc/bind/conf_domain; then
    echo "copied conf_domain"
  else
    echo "peringatan: $SRC_DIR/conf_domain{,.txt} tidak ditemukan"
  fi

  if copy_if_exists "webgw" /etc/nginx/sites-available/webgw; then
    run chmod 644 /etc/nginx/sites-available/webgw
    if [ ! -L /etc/nginx/sites-enabled/webgw ]; then
      run ln -s /etc/nginx/sites-available/webgw /etc/nginx/sites-enabled/webgw
    fi
    echo "copied & enabled webgw nginx site"
  else
    echo "peringatan: $SRC_DIR/webgw{,.txt} tidak ditemukan"
  fi

  if copy_if_exists "proftp" /etc/proftpd/proftpd.conf; then
    run chmod 644 /etc/proftpd/proftpd.conf
    echo "copied proftpd config"
  else
    echo "peringatan: $SRC_DIR/proftp{,.txt} tidak ditemukan"
  fi
else
  echo "peringatan: sumber konfigurasi $SRC_DIR tidak ditemukan. Buat folder $SRC_DIR berisi conf_domain, conf_ip, webgw, proftp (boleh pakai ekstensi .txt)."
fi

# Buat public_html di home user untuk upload web (aman untuk root atau non-root)
PUBLIC_HTML="$HOME_DIR/public_html"
if [ ! -d "$PUBLIC_HTML" ]; then
  if [ "$(id -u)" -eq 0 ]; then
    mkdir -p "$PUBLIC_HTML"
    chown "$TARGET_USER":"$TARGET_USER" "$PUBLIC_HTML"
  else
    mkdir -p "$PUBLIC_HTML"
  fi
  echo "Direktori $PUBLIC_HTML dibuat"
fi

# Set kepemilikan hanya pada direktori yang dibuat oleh skrip
if [ -d "$SRC_DIR" ]; then
  if [ "$(id -u)" -eq 0 ]; then
    chown -R "$TARGET_USER":"$TARGET_USER" "$SRC_DIR" || true
  fi
fi
if [ "$(id -u)" -eq 0 ]; then
  chown -R "$TARGET_USER":"$TARGET_USER" "$PUBLIC_HTML" || true
fi
chmod -R 750 "$PUBLIC_HTML" || true

# Restart layanan yang relevan (tidak exit bila salah satu gagal)
run systemctl restart bind9 || echo "gagal restart bind9 (cek konfigurasi)"
run systemctl restart proftpd || echo "gagal restart proftpd"
run systemctl restart nginx || echo "gagal restart nginx"

# Petunjuk singkat untuk README GitHub
cat <<EOF

Selesai. Beberapa catatan untuk modul / README:
- File konfigurasi BIND: /etc/bind/named.conf.local (tambahkan include jika perlu)
- Zona: /etc/bind/conf_domain (domain) dan /etc/bind/conf_ip (reverse)
- FTP: /etc/proftpd/proftpd.conf
- Web: /etc/nginx/sites-available/* (enable dengan ln -s ke sites-enabled)
- Upload web ke: $PUBLIC_HTML (gunakan FTP client)
- Buat database MySQL: mysql -u root -p  -> CREATE DATABASE wp;
- Tambah user FTP: sudo adduser <nama_user>

Simpan repository Anda termasuk folder 'ujikom' berisi conf_domain, conf_ip, webgw, proftp (boleh .txt) agar skrip dapat otomatis menyalin konfigurasi.

EOF
```// filepath: /home/princeannakhla/Coding/ujikom-debian2.sh
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Tentukan target user (bekerja bila dijalankan langsung atau via sudo)
if [ -n "${SUDO_USER-}" ] && [ "${SUDO_USER}" != "root" ]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="${USER:-$(whoami)}"
fi

# Cari home directory target user
HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)
HOME_DIR=${HOME_DIR:-/home/"$TARGET_USER"}

# Helper: jalankan perintah dengan sudo bila perlu
run() {
  if [ "$(id -u)" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}

echo "Menjalankan untuk user: $TARGET_USER (home: $HOME_DIR)"

# Paket yang dibutuhkan (sesuaikan dengan modul)
PKGS=(bind9 dnsutils proftpd ftp mariadb-server php php-fpm nginx w3m postfix courier-imap roundcube zip)

run apt update
run apt install -y "${PKGS[@]}"

echo "Selesai install paket yang diperlukan."

# Hapus apache2 bila terpasang untuk menghindari bentrok dengan nginx
if dpkg -s apache2 >/dev/null 2>&1; then
  run apt remove -y apache2
  run apt autoremove -y
  echo "apache2 dihapus"
fi

# Pastikan direktori /etc/bind dan file zona ada
run mkdir -p /etc/bind
run touch /etc/bind/conf_domain /etc/bind/conf_ip
run chmod 644 /etc/bind/conf_domain /etc/bind/conf_ip

# Direktori sumber konfigurasi di repo user (sesuaikan dengan modul)
SRC_DIR="$HOME_DIR/ujikom"

if [ -d "$SRC_DIR" ]; then
  # fungsi bantu untuk cari nama file alternatif (tanpa/ dengan .txt)
  copy_if_exists() {
    local src_base="$1" dst="$2"
    if [ -f "$SRC_DIR/$src_base" ]; then
      run cp -f "$SRC_DIR/$src_base" "$dst"
      return 0
    elif [ -f "$SRC_DIR/$src_base.txt" ]; then
      run cp -f "$SRC_DIR/$src_base.txt" "$dst"
      return 0
    fi
    return 1
  }

  if copy_if_exists "conf_ip" /etc/bind/conf_ip; then
    echo "copied conf_ip"
  else
    echo "peringatan: $SRC_DIR/conf_ip{,.txt} tidak ditemukan"
  fi

  if copy_if_exists "conf_domain" /etc/bind/conf_domain; then
    echo "copied conf_domain"
  else
    echo "peringatan: $SRC_DIR/conf_domain{,.txt} tidak ditemukan"
  fi

  if copy_if_exists "webgw" /etc/nginx/sites-available/webgw; then
    run chmod 644 /etc/nginx/sites-available/webgw
    if [ ! -L /etc/nginx/sites-enabled/webgw ]; then
      run ln -s /etc/nginx/sites-available/webgw /etc/nginx/sites-enabled/webgw
    fi
    echo "copied & enabled webgw nginx site"
  else
    echo "peringatan: $SRC_DIR/webgw{,.txt} tidak ditemukan"
  fi

  if copy_if_exists "proftp" /etc/proftpd/proftpd.conf; then
    run chmod 644 /etc/proftpd/proftpd.conf
    echo "copied proftpd config"
  else
    echo "peringatan: $SRC_DIR/proftp{,.txt} tidak ditemukan"
  fi
else
  echo "peringatan: sumber konfigurasi $SRC_DIR tidak ditemukan. Buat folder $SRC_DIR berisi conf_domain, conf_ip, webgw, proftp (boleh pakai ekstensi .txt)."
fi

# Buat public_html di home user untuk upload web (aman untuk root atau non-root)
PUBLIC_HTML="$HOME_DIR/public_html"
if [ ! -d "$PUBLIC_HTML" ]; then
  if [ "$(id -u)" -eq 0 ]; then
    mkdir -p "$PUBLIC_HTML"
    chown "$TARGET_USER":"$TARGET_USER" "$PUBLIC_HTML"
  else
    mkdir -p "$PUBLIC_HTML"
  fi
  echo "Direktori $PUBLIC_HTML dibuat"
fi

# Set kepemilikan hanya pada direktori yang dibuat oleh skrip
if [ -d "$SRC_DIR" ]; then
  if [ "$(id -u)" -eq 0 ]; then
    chown -R "$TARGET_USER":"$TARGET_USER" "$SRC_DIR" || true
  fi
fi
if [ "$(id -u)" -eq 0 ]; then
  chown -R "$TARGET_USER":"$TARGET_USER" "$PUBLIC_HTML" || true
fi
chmod -R 750 "$PUBLIC_HTML" || true

# Restart layanan yang relevan (tidak exit bila salah satu gagal)
run systemctl restart bind9 || echo "gagal restart bind9 (cek konfigurasi)"
run systemctl restart proftpd || echo "gagal restart proftpd"
run systemctl restart nginx || echo "gagal restart nginx"

# Petunjuk singkat untuk README GitHub
cat <<EOF

Selesai. Beberapa catatan untuk modul / README:
- File konfigurasi BIND: /etc/bind/named.conf.local (tambahkan include jika perlu)
- Zona: /etc/bind/conf_domain (domain) dan /etc/bind/conf_ip (reverse)
- FTP: /etc/proftpd/proftpd.conf
- Web: /etc/nginx/sites-available/* (enable dengan ln -s ke sites-enabled)
- Upload web ke: $PUBLIC_HTML (gunakan FTP client)
- Buat database MySQL: mysql -u root -p  -> CREATE DATABASE wp;
- Tambah user FTP: sudo adduser <nama_user>

Simpan repository Anda termasuk folder 'ujikom' berisi conf_domain, conf_ip, webgw, proftp (boleh .txt) agar skrip dapat otomatis menyalin konfigurasi.

EOF