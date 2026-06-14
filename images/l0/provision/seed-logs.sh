#!/usr/bin/env bash
# Seed a deterministic /var/log/auth.log. A fresh container has no syslog and no
# logins, so the /var/log stop would otherwise be empty. Fixed timestamps keep
# every recording identical.
set -euo pipefail

mkdir -p /var/log
cat > /var/log/auth.log <<'LOG'
Jun 14 08:58:03 staging-server-01 systemd-logind[211]: New seat seat0.
Jun 14 09:01:22 staging-server-01 sshd[812]: Accepted publickey for selin from 10.0.4.21 port 51844 ssh2: ED25519 SHA256:1b2C3d4E5f6G7h8I9j0KlMnOpQrStUvWx
Jun 14 09:01:22 staging-server-01 systemd-logind[211]: New session 3 of user selin.
Jun 14 09:03:47 staging-server-01 sudo:    selin : TTY=pts/0 ; PWD=/home/selin ; USER=root ; COMMAND=/usr/bin/apt update
Jun 14 09:07:15 staging-server-01 sshd[844]: Failed password for invalid user admin from 203.0.113.66 port 60122 ssh2
Jun 14 09:09:02 staging-server-01 sudo:    selin : TTY=pts/0 ; PWD=/home/selin ; USER=root ; COMMAND=/usr/bin/systemctl restart nginx
LOG

chown root:adm /var/log/auth.log 2>/dev/null || chown root:root /var/log/auth.log
chmod 0640 /var/log/auth.log
