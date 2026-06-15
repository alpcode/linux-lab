# L0-U1-D1 — Lab · FHS Turu (6 durak)  (25:00–58:00)
# Manifest'ten OTOMATİK üretildi: manifest.json. Elle düzenleme; manifest'i değiştir.
# Ubuntu VM'in İÇİNDE, selin olarak çalıştır:  vhs L0-U1-D1-terminal.tape
#
Output L0-U1-D1-terminal.mp4

Set Shell "bash"
Set FontFamily "JetBrains Mono"
Set FontSize 22
Set Width 1280
Set Height 720
Set Padding 20
Set TypingSpeed 60ms

# --- Temiz başlangıç (gizli): markalı prompt + ana dizin + temizle ---
Hide
Type "source ~/.bashrc 2>/dev/null; cd ~; clear"
Enter
Sleep 500ms
Show

# === Intro · Lab · FHS Turu (6 durak) ===
Type@60ms "cd /"
Enter
Sleep 1s
Type@60ms "ls"
Enter
Sleep 3s

# === Durak · /etc — Yapılandırmanın evi ===
Type "cd /etc"
Enter
Sleep 1s
Type "ls"
Enter
Sleep 2s
Type "cat /etc/hostname"
Enter
Sleep 2s
Type "cat /etc/shadow"
Enter
Sleep 3s

# === Durak · /var — Değişen verinin evi ===
Type "cd /var/log"
Enter
Sleep 1s
Type "ls"
Enter
Sleep 2s
Type "sudo tail -n 5 /var/log/auth.log"
Enter
Sleep 3s

# === Durak · /proc — Diskte olmayan dizin (canlı) ===
Type "cd /proc"
Enter
Sleep 1s
Type "ls"
Enter
Sleep 2s
Type "cat /proc/cpuinfo | head -n 20"
Enter
Sleep 3s
Type "cat /proc/uptime"
Enter
Sleep 3s
Type "cat /proc/uptime"
Enter
Sleep 2s

# === Durak · /sys — Donanımın aynası ===
Type "ls /sys/class/net"
Enter
Sleep 3s
Type "cat /sys/class/net/lo/mtu"
Enter
Sleep 2s

# === Durak · /dev — 'Her şey dosyadır' felsefesi ===
Type "cd /dev"
Enter
Sleep 1s
Type "ls"
Enter
Sleep 2s
Type 'echo "bu yazi kaybolacak" > /dev/null'
Enter
Sleep 2s

# === Durak · /tmp — Geçicinin evi ===
Type "cd /tmp"
Enter
Sleep 1s
Type "ls -la"
Enter
Sleep 2s
Type "df -h /tmp"
Enter
Sleep 3s

# --- Kapanış nefesi (overlay/anlatım sonradan biner) ---
Sleep 2s

