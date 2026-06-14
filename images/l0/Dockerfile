# syntax=docker/dockerfile:1
# Level 0 recording image — Selin / TechLabs, branded selin@staging-server-01.
# Deterministic substrate for the FHS / command lessons and the VHS recording pipeline.
FROM ubuntu:24.04

# English, deterministic system messages (so "Permission denied" etc. match the
# lesson verbatim) while staying UTF-8 capable for Turkish content.
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

# Minimal tool set the Level 0 / Day 1 FHS tour relies on.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      sudo procps iproute2 less nano ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Branded identity shown by `cat /etc/hostname`. The container is also run with
# --hostname staging-server-01 (see Makefile) so the prompt and `hostname` agree.
RUN echo 'staging-server-01' > /etc/hostname

# Provisioning scripts. Copy the same pattern into images/l1, l2, ... per level.
COPY provision/ /opt/provision/
RUN chmod +x /opt/provision/*.sh \
 && /opt/provision/setup-user.sh \
 && /opt/provision/seed-logs.sh \
 && /opt/provision/setup-shell.sh

# Record AS the non-root student. This is what makes `cat /etc/shadow` ->
# "Permission denied" and what makes `sudo` meaningful in the lesson.
USER selin
WORKDIR /home/selin
CMD ["bash"]
