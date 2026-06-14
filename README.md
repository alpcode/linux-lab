# linux-lab — Selin / TechLabs ders ortamı (kayıt zemini)

Linux & Cloud-Native müfredatının video kayıtları için **deterministik, markalı**
(`selin@staging-server-01`) ders ortamı. n8n + VHS otomasyon hattının zeminidir:
her kayıt birebir aynı durumdan başlar, ortam git'te sürümlenir.

## Substrat kararı (önce bunu oku)

İki katman, ikisi de **aynı** `selin@staging-server-01` kimliğinden ve aynı
provisioning mantığından doğar:

- **Konteyner (Docker/Podman) — varsayılan kaydedici.** L0 ve komut/dosya-sistemi
  merkezli dersler + hızlı deterministik kayıt için. Saniyede sıfırlanır, n8n'den
  çağrılması kolaydır. Bu repodaki `images/`.
- **Gerçek VM (cloud-init / multipass) — gerektiğinde.** Konteynerin paylaşılan
  kernel + minimal `/dev` nedeniyle gösteremediği konular için. `vm/` altında.

Hangi konu nerede:

| Konu | Konteyner | VM |
|------|:---:|:---:|
| FHS, komutlar, dosya/izin, metin işleme, paket yönetimi | ✓ | ✓ |
| systemd / servis / journald | ✗ | ✓ |
| disk / partition / LVM / mount | ✗ | ✓ |
| boot / target / kernel modülü | ✗ | ✓ |
| çok arayüzlü ağ / firewalld | kısıtlı | ✓ |
| RHCSA (Rocky) | komut düzeyi | tam: VM |

Pratik kural: **Day 1'in FHS turu dahil Level 0'ın büyük kısmı konteynerde
kaydedilebilir.** Level 1+ kernel/servis/disk konularına geldiğinde aynı kimlikle
VM'e geçersin.

## Hızlı başlangıç (konteyner)

```bash
make build     # Level 0 imajını kur
make verify    # Gün 1 öğretim değişmezlerini taze konteynerde test et
make shell     # taze konteynerde elle prova
```

`make verify` çıktısı tüm satırlarda `OK` veriyorsa imaj Gün 1 için kayıta hazırdır.

## Gün 1 neden bu imajda deterministik

Kayıt sırasında dersin "anlarının" her seferinde aynı tetiklenmesi için ortam
özellikle hazırlandı:

- **non-root `selin` olarak çalışır** → `cat /etc/shadow` = `Permission denied`,
  ve `sudo` anlamlı. (root olsaydı shadow okunur, ders anı kaybolurdu.)
- **`/var/log/auth.log` seedli** → `/var` durağı her kayıtta dolu ve gerçekçi
  (sabit zaman damgaları, gerçek görünümlü ssh + sudo girdileri). RHEL ailesinde
  karşılığı `/var/log/secure` (bkz. `images/rocky`).
- **`--tmpfs /tmp`** (Makefile'da) → `df -h /tmp` tutarlı şekilde `tmpfs` gösterir.
- **`/proc/uptime` canlıdır** → iki okuma farklı çıkar → "kalıcı vs canlı" anı çalışır.
- **`--hostname staging-server-01` + `/etc/hostname`** → prompt ve `hostname` uyumlu.
- **`LANG=C.UTF-8`** → sistem mesajları İngilizce ve deterministik
  (`Permission denied`, yerelleştirilmiş değil), Türkçe içerik yine UTF-8.
- **NOPASSWD sudo** → gözetimsiz kayıt parola isteminde takılmaz.

## Katmanlama (L0 → L3)

Her seviye bir öncekinin üstüne biner; kimlik ve seed aynı kalır:

```dockerfile
FROM linux-lab:l0        # images/l1/Dockerfile
# ... o seviyenin araçları + provisioning
```

`images/l1/Dockerfile` bu deseni gösterir. L2/L3 için kopyala. RHCSA için
`images/rocky/Dockerfile` (dnf, `/var/log/secure`).

## VM yolu

`vm/cloud-init/user-data` — multipass ile aynı kimlikte gerçek VM:

```bash
multipass launch --name staging-server-01 --cloud-init vm/cloud-init/user-data 24.04
multipass shell staging-server-01
```

systemd/disk/boot derslerini ve RHCSA'yı burada kaydedersin (VHS'i SSH üzerinden
VM'e sokarak ya da asciinema/OBS ile).

## Sıradaki adım: kayıt (seçenek a)

`make record` şu an placeholder. Bir sonraki adımda buraya gelecek:

1. **Manifest şeması** — ders `.docx`'inden çıkarılan JSON (komut · beklenen çıktı ·
   anlatım · sembol · sayaç).
2. **Gün 1 `.tape`** — VHS bu imaja `docker exec` ile girer; `Hide`/`Show` ile
   `docker` komutları gizlenir, ekranda yalnız temiz `selin@staging-server-01`
   oturumu kaydedilir.
3. **n8n akışı** — konteyneri başlat → VHS kaydı → ffmpeg birleştir → (onay kapısı) → yayın.

VHS entegrasyon deseni (kayıt plumbing'i gizli):

```
n8n: docker run -d --name rec --hostname staging-server-01 --tmpfs /tmp linux-lab:l0 sleep infinity
n8n: vhs tapes/l0-d1.tape        # tape içinde: Hide; docker exec -it rec bash; Show; <ders komutları>
n8n: docker rm -f rec
```

## Dizin yapısı

```
linux-lab/
├── README.md
├── Makefile                      # build / verify / shell / record
├── images/
│   ├── l0/                       # Level 0 kayıt imajı (Ubuntu 24.04)
│   │   ├── Dockerfile
│   │   └── provision/            # setup-user · seed-logs · setup-shell
│   ├── l1/Dockerfile             # FROM l0 (örnek katman)
│   └── rocky/Dockerfile          # RHCSA (Rocky 9, /var/log/secure)
├── vm/cloud-init/user-data       # gerçek VM (multipass), aynı kimlik
└── test/verify-day1.sh           # Gün 1 deterministik değişmez testi
```
