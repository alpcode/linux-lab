#!/usr/bin/env bash
# Seviye 0 profili: erken derslerin araçları (Vim, ağ gözlemi, Python köprüsü).
# Idempotent, distro-bilen. lab-setup tarafından çağrılır.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "sudo gerekli: sudo lab-setup s0"; exit 1; }
. /etc/os-release
case "${ID_LIKE:-$ID}" in *debian*|*ubuntu*) F=debian;; *rhel*|*fedora*) F=rhel;; *) echo "distro?"; exit 1;; esac

if [ "$F" = debian ]; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y --no-install-recommends \
    vim tmux tree tcpdump dnsutils net-tools iputils-ping \
    python3 python3-venv python3-pip shellcheck
else
  dnf -y install vim tmux tree tcpdump bind-utils net-tools iputils \
    python3 python3-pip || true
  dnf -y install epel-release 2>/dev/null && dnf -y install ShellCheck 2>/dev/null || true
fi
echo "Seviye 0 araçları kuruldu (vim, tcpdump, python3+venv+pip, ...)."
