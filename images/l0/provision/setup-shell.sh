#!/usr/bin/env bash
# Branded, deterministic prompt: selin@staging-server-01.
set -euo pipefail

cat >> /home/selin/.bashrc <<'RC'

# --- linux-lab recording profile ---
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
# Green user@host, blue path -- matches the on-screen brand in every video.
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
# Keep recordings clean (no window-title / multiline escapes).
unset PROMPT_COMMAND
RC

chown selin:selin /home/selin/.bashrc
