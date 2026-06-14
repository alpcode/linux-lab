#!/usr/bin/env bash
# Create the student user 'selin' with passwordless sudo.
# NOPASSWD is required so unattended recordings never stall on a password prompt.
set -euo pipefail

if ! id selin >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash selin
fi

echo 'selin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/selin
chmod 0440 /etc/sudoers.d/selin

# /etc/shadow stays root:shadow 0640. selin is NOT in the shadow group, so
# `cat /etc/shadow` as selin -> Permission denied (the Day 1 moment).
# Do not loosen this.
chmod 0640 /etc/shadow || true
