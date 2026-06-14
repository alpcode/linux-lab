#!/usr/bin/env bash
# Taban appliance doğrulaması (distro-bilen). Tercihen root ile çalıştır.
set -uo pipefail
pass=0; fail=0
ok(){ printf '  \033[1;32mOK\033[0m  %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  \033[1;31mNO\033[0m  %s\n' "$1"; fail=$((fail+1)); }
. /etc/os-release
case "${ID_LIKE:-$ID}" in *debian*|*ubuntu*) LOG=/var/log/auth.log;; *) LOG=/var/log/secure;; esac

echo "== Kimlik =="
[ "$(hostname)" = "staging-server-01" ] && ok "hostname = staging-server-01" || no "hostname: $(hostname)"
id selin >/dev/null 2>&1 && ok "selin kullanicisi var" || no "selin yok"

echo "== Marka / prompt =="
grep -q 'linux-lab recording profile' /home/selin/.bashrc 2>/dev/null && ok "markali .bashrc" || no ".bashrc profili yok"

echo "== Guvenlik ani (shadow) =="
if sudo -u selin cat /etc/shadow >/dev/null 2>&1; then no "selin shadow'u OKUYABILDI"; else ok "selin -> /etc/shadow Permission denied"; fi

echo "== Log seed =="
{ [ -f "$LOG" ] && grep -q selin "$LOG"; } && ok "seedli log: $LOG" || no "log seed yok: $LOG"

echo "== /proc canlilik =="
u1="$(cut -d' ' -f1 /proc/uptime)"; sleep 1.2; u2="$(cut -d' ' -f1 /proc/uptime)"
[ "$u1" != "$u2" ] && ok "uptime canli ($u1 -> $u2)" || no "uptime sabit"

echo "== /sys, /dev =="
ls /sys/class/net 2>/dev/null | grep -qx lo && ok "/sys/class/net icinde lo" || no "lo yok"
{ [ -e /dev/null ] && [ -e /dev/urandom ]; } && ok "/dev/null + /dev/urandom" || no "/dev eksik"

echo "== Calistiricilar =="
command -v lab-setup >/dev/null 2>&1 && ok "lab-setup kurulu" || no "lab-setup yok"
command -v lesson-setup >/dev/null 2>&1 && ok "lesson-setup kurulu" || no "lesson-setup yok"

echo; echo "Sonuc: $pass gecti, $fail kaldi."
[ "$fail" -eq 0 ] || exit 1
