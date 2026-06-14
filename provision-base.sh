#!/usr/bin/env bash
# Katman 1 — linux-lab taban provisioning (x86_64).
# Distro-bilen: Ubuntu 24.04 (apt) ve Rocky/Alma 9 (dnf) üzerinde çalışır.
# Idempotent: tekrar çalıştırmak güvenli. root ile çalıştır (sudo).
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Bu script root ile çalışmalı: sudo $0"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"

# --- distro tespiti ---
. /etc/os-release
case "${ID_LIKE:-$ID}" in
  *debian*|*ubuntu*) FAMILY=debian ;;
  *rhel*|*fedora*)   FAMILY=rhel ;;
  *) echo "Desteklenmeyen distro: $ID"; exit 1 ;;
esac
echo ">> Distro ailesi: $FAMILY ($PRETTY_NAME)"

# --- temel paketler ---
if [ "$FAMILY" = debian ]; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y --no-install-recommends \
    sudo procps iproute2 less nano ca-certificates curl git
  PKGCMD="/usr/bin/apt update"
else
  dnf -y install sudo procps-ng iproute less nano ca-certificates curl git
  dnf clean all || true
  PKGCMD="/usr/bin/dnf update"
fi

# --- hostname (marka) ---
echo 'staging-server-01' > /etc/hostname
hostnamectl set-hostname staging-server-01 2>/dev/null || true

# --- selin kullanıcısı + parolasız sudo (gözetimsiz kayıt için) ---
if ! id selin >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash selin
fi
echo 'selin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/selin
chmod 0440 /etc/sudoers.d/selin

# --- markalı prompt + locale (idempotent: işaretle-koru) ---
RC=/home/selin/.bashrc
if ! grep -q 'linux-lab recording profile' "$RC" 2>/dev/null; then
cat >> "$RC" <<'RCBLOCK'

# --- linux-lab recording profile ---
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
unset PROMPT_COMMAND
RCBLOCK
fi
chown selin:selin "$RC"

# --- auth log seed (distro-doğru yol) ---
if [ "$FAMILY" = debian ]; then
  LOG=/var/log/auth.log; LOGGRP=adm;  LOGMODE=0640
else
  LOG=/var/log/secure;   LOGGRP=root; LOGMODE=0600
fi
mkdir -p /var/log
cat > "$LOG" <<LOGSEED
Jun 14 08:58:03 staging-server-01 systemd-logind[211]: New seat seat0.
Jun 14 09:01:22 staging-server-01 sshd[812]: Accepted publickey for selin from 10.0.4.21 port 51844 ssh2: ED25519 SHA256:1b2C3d4E5f6G7h8I9j0KlMnOpQrStUvWx
Jun 14 09:01:22 staging-server-01 systemd-logind[211]: New session 3 of user selin.
Jun 14 09:03:47 staging-server-01 sudo:    selin : TTY=pts/0 ; PWD=/home/selin ; USER=root ; COMMAND=$PKGCMD
Jun 14 09:07:15 staging-server-01 sshd[844]: Failed password for invalid user admin from 203.0.113.66 port 60122 ssh2
LOGSEED
chown "root:$LOGGRP" "$LOG" 2>/dev/null || chown root:root "$LOG"
chmod "$LOGMODE" "$LOG"

# Not: /etc/shadow varsayılan olarak root:shadow 0640 (RHEL'de 0000/0600). selin
# shadow grubunda DEĞİL, dolayısıyla `cat /etc/shadow` -> Permission denied (Gün 1
# anı). Bunu gevşetme.

# --- çalıştırıcıları kur + profilleri/dersleri paketle (appliance kendine yeter) ---
install -d -m 0755 /opt/linux-lab/profiles /opt/linux-lab/lessons
install -m 0755 "$HERE/bin/lab-setup"    /usr/local/bin/lab-setup
install -m 0755 "$HERE/bin/lesson-setup" /usr/local/bin/lesson-setup
cp -r "$HERE/profiles/." /opt/linux-lab/profiles/ 2>/dev/null || true
cp -r "$HERE/lessons/."  /opt/linux-lab/lessons/  2>/dev/null || true

echo ">> Taban hazır. Doğrulama:  sudo bash $HERE/test/verify-base.sh"
