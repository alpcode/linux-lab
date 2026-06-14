#!/usr/bin/env bash
# Deterministic "is this image recording-ready for Day 1?" regression test.
# Asserts the TEACHING INVARIANTS, not byte-exact output. Run inside a fresh
# container as selin (see `make verify`).
set -uo pipefail
pass=0; fail=0
ok(){ printf '  \033[1;32mOK\033[0m  %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  \033[1;31mNO\033[0m  %s\n' "$1"; fail=$((fail+1)); }

echo "== Kimlik =="
[ "$(hostname)" = "staging-server-01" ] && ok "hostname = staging-server-01" || no "hostname yanlis: $(hostname)"
[ "$(whoami)" = "selin" ] && ok "kullanici = selin (non-root)" || no "kullanici root/yanlis: $(whoami)"

echo "== FHS koku =="
for d in etc var proc sys dev tmp; do
  [ -e "/$d" ] && ok "/$d var" || no "/$d yok"
done

echo "== /etc guvenlik ani =="
if cat /etc/shadow >/dev/null 2>&1; then
  no "/etc/shadow OKUNABILDI -- selin olarak calismiyorsun!"
else
  ok "/etc/shadow -> Permission denied (beklenen)"
fi
[ "$(cat /etc/hostname)" = "staging-server-01" ] && ok "cat /etc/hostname dogru" || no "/etc/hostname icerigi yanlis"

echo "== /var/log seed =="
if sudo -n tail -n 5 /var/log/auth.log >/dev/null 2>&1; then
  ok "sudo + auth.log calisiyor"
else
  no "sudo tail auth.log basarisiz"
fi
grep -q "selin" /var/log/auth.log 2>/dev/null && ok "auth.log seedlenmis (selin girdileri var)" || no "auth.log bos/seedlenmemis"

echo "== /proc canlilik =="
u1="$(cut -d' ' -f1 /proc/uptime)"; sleep 1.2; u2="$(cut -d' ' -f1 /proc/uptime)"
[ "$u1" != "$u2" ] && ok "uptime iki okumada degisiyor ($u1 -> $u2)" || no "uptime degismedi (canlilik gosterilemez)"

echo "== /sys =="
ls /sys/class/net 2>/dev/null | grep -qx "lo" && ok "/sys/class/net icinde lo var" || no "lo arayuzu yok"

echo "== /dev =="
{ [ -e /dev/null ] && [ -e /dev/urandom ]; } && ok "/dev/null ve /dev/urandom var" || no "ozel aygit dosyalari eksik"
if echo "kara delik testi" > /dev/null 2>&1; then ok "echo > /dev/null sessizce calisiyor"; else no "/dev/null yazilamadi"; fi

echo
echo "Sonuc: $pass gecti, $fail kaldi."
[ "$fail" -eq 0 ] || exit 1
