# syntax=docker/dockerfile:1
# RHEL-family substrate for the RHCSA unit. dnf instead of apt, same identity.
#
# NOTE: RHCSA covers systemd, services, disks/LVM, boot targets and firewalld --
# topics a container CANNOT fully demonstrate (shared kernel, minimal /dev, no
# real init). Use this image for command/FS-level RHCSA practice + recording;
# use the VM path (see ../../vm/) for systemctl, partitioning and boot lessons.
FROM rockylinux:9

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=xterm-256color

RUN dnf -y install sudo procps-ng iproute less nano && dnf clean all

RUN echo 'staging-server-01' > /etc/hostname \
 && useradd -m -s /bin/bash selin \
 && echo 'selin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/selin \
 && chmod 0440 /etc/sudoers.d/selin

# On the RHEL family the auth log lives at /var/log/secure (the Day 1 lesson
# explicitly notes this). Seed a deterministic baseline.
RUN printf '%s\n' \
 'Jun 14 09:01:22 staging-server-01 sshd[812]: Accepted publickey for selin from 10.0.4.21 port 51844 ssh2' \
 'Jun 14 09:03:47 staging-server-01 sudo:    selin : TTY=pts/0 ; PWD=/home/selin ; USER=root ; COMMAND=/usr/bin/dnf update' \
 > /var/log/secure \
 && chmod 0600 /var/log/secure

USER selin
WORKDIR /home/selin
CMD ["bash"]
