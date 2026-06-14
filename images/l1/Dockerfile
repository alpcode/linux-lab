# syntax=docker/dockerfile:1
# Level 1 builds ON the Level 0 image: identical selin@staging-server-01 identity
# and seeded state, plus the tools Level 1 lessons introduce. Same pattern for l2, l3.
FROM linux-lab:l0

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      vim grep sed gawk tree htop \
 && rm -rf /var/lib/apt/lists/*

# Add Level 1 provisioning here as needed (extra seeded files, practice users, ...).
# COPY provision/ /opt/provision-l1/
# RUN chmod +x /opt/provision-l1/*.sh && for s in /opt/provision-l1/*.sh; do "$s"; done

USER selin
WORKDIR /home/selin
CMD ["bash"]
