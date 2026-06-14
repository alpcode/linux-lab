# Katman 1 — VirtualBox taban appliance kurulumu (x86_64)

İki taban appliance: **Ubuntu 24.04** (Seviye 0/2a/2b/3 hattı) ve **Rocky 9**
(Seviye 1 / RHCSA). İki yol var: hızlı tekrarlanabilir build için **Vagrant**,
ya da GUI ile elle kurmak için **manuel**. İkisi de aynı `provision-base.sh`'i
çalıştırır → aynı `selin@staging-server-01` ortamı.

VirtualBox Windows / Linux / Intel-Mac'te çalışır. Apple Silicon değil — bu makine
Intel/AMD olduğu için doğru yer burası.

---

## Yol A — Vagrant (önerilen, tekrarlanabilir)

Gereken: VirtualBox + Vagrant kurulu.

```bash
cd linux-lab/appliances
vagrant up                 # ubuntu-s0 ve rocky-s1'i kurar + verify-base çalıştırır
```

`vagrant up` sonunda her iki makinenin de `verify-base.sh` çıktısında tüm
satırlar **OK** olmalı. Sonra:

```bash
vagrant ssh ubuntu-s0      # selin@staging-server-01 prompt'unda prova
```

Dağıtmak için bir "altın" appliance dışa aktar:

```bash
vagrant package --base linux-lab-ubuntu-s0 --output ubuntu-s0.box
# veya VirtualBox'tan: Dosya > Sanal Cihazı Dışa Aktar > .ova
```

> Vagrant Cloud'da `bento/ubuntu-24.04` ve `bento/rockylinux-9` kutularının güncel
> sürümlerini doğrula; ad değişmişse Vagrantfile'daki `m.vm.box` satırını güncelle.

---

## Yol B — Manuel VirtualBox kurulumu

### Ubuntu 24.04 taban

1. **ISO indir:** ubuntu.com/download/server → güncel **24.04 LTS** *Live Server*
   (x86_64). (Desktop değil; sunucu profili kayıt için daha temiz.)
2. **VM oluştur:** Yeni → Tür Linux, Sürüm Ubuntu (64-bit). Bellek **4096 MB**,
   CPU **2**, disk **25–30 GB** (VDI, dinamik).
3. **Kur:** ISO ile başlat, standart kurulum, "Install OpenSSH server"i işaretle.
   Kurulum kullanıcısını geçici aç (provisioning `selin`'i ayrıca kuracak).
4. **Repoyu VM'e al:** en kolayı VM içinde:
   ```bash
   sudo apt-get update && sudo apt-get install -y git
   git clone <repo-url> linux-lab    # ya da paylaşımlı klasör / scp
   cd linux-lab
   ```
5. **Provision et + doğrula:**
   ```bash
   sudo bash provision-base.sh
   sudo bash test/verify-base.sh     # hepsi OK olmalı
   ```
6. **Temiz snapshot al:** VirtualBox → Anlık Görüntüler → Al → "clean-base".
   (Her kayıt öncesi bu snapshot'a dönersin → determinizm.)
7. **(Opsiyonel) Dışa aktar:** Dosya → Sanal Cihazı Dışa Aktar → `ubuntu-s0.ova`.

### Rocky 9 taban

Aynı adımlar, şu farklarla:

- **ISO:** rockylinux.org/download → **Rocky 9** (x86_64, minimal yeterli).
- VM Sürüm: **Red Hat (64-bit)**.
- Repoyu al: `sudo dnf install -y git` sonra clone.
- `sudo bash provision-base.sh` distro'yu otomatik tanır (dnf kullanır,
  `/var/log/secure` seedler).

> **Seviye 1'e gelince (şimdi değil):** Rocky VM'ine **3 ek disk** ekle
> (Ayarlar → Depolama → SATA'ya 3 × ~2 GB VDI). LVM lab'ı (PV/VG/LV) bunları ister.
> Vagrant kullanıyorsan Vagrantfile'daki yorumlu disk bloğunu aç.

---

## Build vs. öğrenci: aynı script, iki rol

- **Sen (build + kayıt):** appliance'ı bir kez kurar, `clean-base` snapshot'ına
  dönerek kaydedersin. Saf-CLI dersleri için istersen konteyner zeminini de
  kullanabilirsin (otomasyon daha hızlı); systemd/disk/RHCSA için bu VM.
- **Öğrenci (tüketim):** ya `.ova`'yı içe aktarır, ya da resmî Ubuntu/Rocky'yi
  kurup **aynı** `provision-base.sh`'i çalıştırır. İkisinde de ortam birebir aynı.

İmaj dağıtacaksan **Drive değil** (popüler büyük dosyada kota duvarı): Cloudflare
R2 / Backblaze B2 / torrent kullan. Tercihen taban küçük kalsın, gerisi scriptle.

---

## Sırada ne var

- `lab-setup s0` **çalışır durumda** (Vim, tcpdump, python3+venv, ...). Diğer
  seviyeler (`s1…s3`) o seviyeye gelince doldurulur — bilerek stub.
- `lesson-setup L0-U1-D1` Gün 1 için boş (taban yeterli); ileriki derslerde gerçek
  fixture üretecek.
- Sonraki adım: Gün 1'i uçtan uca — manifest (`environment` + `fixtures` alanlı) +
  Gün 1 `.tape` + n8n akışı.
