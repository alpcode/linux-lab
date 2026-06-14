# linux-lab — Katman 1 (taban appliance) + 3 katmanlı ortam sistemi

x86_64 (Intel/AMD) + VirtualBox için. Öğrenci ortamı = VM; provisioning =
sürüm-kontrollü script. Hepsi `selin@staging-server-01` kimliğinden.

## Üç katman ve ritimleri

| Katman | Ne | Ne zaman | Nasıl |
|---|---|---|---|
| **1. Taban appliance (2)** | Ubuntu 24.04 + Rocky 9; selin, marka, temel araç, çalıştırıcılar | Bir kez, şimdi | `provision-base.sh` |
| **2. Seviye profili (5)** | `lab-setup s0…s3` — o seviyenin araçları | s0 şimdi; gerisi seviyeye gelince | `sudo lab-setup s2b` |
| **3. Ders fixture'ı (ders başına)** | `lesson-setup <kod>` — o dersin senaryo dosyaları | Her ders yazılırken | `lesson-setup L0-U1-D1` |

Mantık: büyük şeyler (taban + seviye araçları) bir kez kurulur; her derse özel
şeyler küçük scriptlerle akar. Senaryo dosyaları **mutlaka** Katman 3'ten gelir —
tek imaj 350 dersin fixture'ını şişmeden ve ileriki dersleri ifşa etmeden taşıyamaz.

## Hızlı başlangıç

```bash
# Yol A: Vagrant (tekrarlanabilir)
cd appliances && vagrant up

# Yol B: manuel VirtualBox -> appliances/build-virtualbox.md
# VM içinde:
sudo bash provision-base.sh
sudo bash test/verify-base.sh        # hepsi OK -> taban kayıta hazır
```

Sonra ortamı kullan:

```bash
sudo lab-setup s0                    # Seviye 0 araçları (çalışır)
lesson-setup L0-U1-D1                # Gün 1 fixture (boş — taban yeterli)
```

## Çalıştırıcılar nasıl çalışır

- `lab-setup <profil>` → `/opt/linux-lab/profiles/<profil>.sh` çalıştırır.
  Yerelde yoksa ve `LINUX_LAB_REPO` tanımlıysa repodan çeker.
- `lesson-setup <kod>` → `/opt/linux-lab/lessons/<kod>/setup.sh` çalıştırır
  ('Ü' otomatik 'U'). Fixture yoksa "boş olabilir" deyip temiz çıkar.

Uzaktan güncelleme istersen appliance içinde:
```bash
export LINUX_LAB_REPO="https://raw.githubusercontent.com/<sen>/linux-lab/main"
```

## Determinizm

Her kayıt öncesi VM'i **`clean-base` snapshot'ına döndür** (VirtualBox) ya da
`vagrant snapshot restore`. Böylece her ders aynı durumdan başlar.

## Dizin

```
linux-lab/
├── provision-base.sh          # Katman 1: distro-bilen taban (apt/dnf)
├── bin/
│   ├── lab-setup              # Katman 2 dağıtıcı
│   └── lesson-setup           # Katman 3 dağıtıcı
├── profiles/
│   ├── s0.sh                  # ÇALIŞIR (Vim, tcpdump, python3+venv, ...)
│   └── s1/s2a/s2b/s3.sh       # stub — seviyeye gelince doldurulacak
├── lessons/
│   └── L0-U1-D1/setup.sh      # Gün 1 (boş — taban yeterli)
├── appliances/
│   ├── Vagrantfile            # Vagrant + VirtualBox (iki makine)
│   └── build-virtualbox.md    # manuel kurulum tarifi
└── test/verify-base.sh        # taban doğrulaması (distro-bilen)
```

> Daha önce kurduğumuz konteyner Dockerfile'ları (varsa repoda `images/`) hâlâ
> işe yarar: saf-CLI derslerinin **otomatik kaydı** için. Öğrenci substratı ise VM.
