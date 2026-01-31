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
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [ -n "${SUDO_USER-}" ] && [ "${SUDO_USER}" != "root" ]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="${USER:-$(whoami)}"
fi

HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)
HOME_DIR=${HOME_DIR:-/home/"$TARGET_USER"}

run() {
  if [ "$(id -u)" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}

PKGS=(bind9 dnsutils proftpd ftp mariadb-server php php-fpm nginx w3m postfix courier-imap roundcube zip)

run apt update
run apt install -y "${PKGS[@]}"

if dpkg -s apache2 >/dev/null 2>&1; then
  run apt remove -y apache2
  run apt autoremove -y
fi

run mkdir -p /etc/bind
run touch /etc/bind/conf_domain /etc/bind/conf_ip
run chmod 644 /etc/bind/conf_domain /etc/bind/conf_ip

SRC_DIR="$HOME_DIR/ujikom"

if [ -d "$SRC_DIR" ]; then
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

  copy_if_exists "conf_ip" /etc/bind/conf_ip || true
  copy_if_exists "conf_domain" /etc/bind/conf_domain || true
  if copy_if_exists "webgw" /etc/nginx/sites-available/webgw; then
    run chmod 644 /etc/nginx/sites-available/webgw
    [ -L /etc/nginx/sites-enabled/webgw ] || run ln -s /etc/nginx/sites-available/webgw /etc/nginx/sites-enabled/webgw
  fi
  copy_if_exists "proftp" /etc/proftpd/proftpd.conf || true
fi

PUBLIC_HTML="$HOME_DIR/public_html"
if [ ! -d "$PUBLIC_HTML" ]; then
  if [ "$(id -u)" -eq 0 ]; then
    mkdir -p "$PUBLIC_HTML"
    chown "$TARGET_USER":"$TARGET_USER" "$PUBLIC_HTML"
  else
    mkdir -p "$PUBLIC_HTML"
  fi
fi

if [ -d "$SRC_DIR" ] && [ "$(id -u)" -eq 0 ]; then
  chown -R "$TARGET_USER":"$TARGET_USER" "$SRC_DIR" || true
fi
if [ "$(id -u)" -eq 0 ]; then
  chown -R "$TARGET_USER":"$TARGET_USER" "$PUBLIC_HTML" || true
fi
chmod -R 750 "$PUBLIC_HTML" || true

run systemctl restart bind9 || true
run systemctl restart proftpd || true
run systemctl restart nginx || true
