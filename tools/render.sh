#!/usr/bin/env bash
# linux-lab — bir dersi uçtan uca üret: VHS (terminal katmanı) + overlay.
# Repo içinde nereden çağrılırsa çağrılsın çalışır; TÜM çıktılar out/<DERS-KODU>/ altına düşer.
#
# Ubuntu VM'in İÇİNDE, selin olarak çalıştır:
#     tools/render.sh L0-U1-D1
#
# Gerekli: vhs, ffmpeg, python3 + Pillow, fonts-dejavu-core, fonts-noto-color-emoji
set -euo pipefail

CODE="${1:?kullanım: tools/render.sh <DERS-KODU>   (örn. L0-U1-D1)}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LDIR="$ROOT/lessons/$CODE"
TAPE="$LDIR/$CODE-terminal.tape"
OUT="$ROOT/out/$CODE"

[ -f "$LDIR/manifest.json" ] || { echo "HATA: manifest yok: $LDIR/manifest.json" >&2; exit 1; }
[ -f "$TAPE" ]               || { echo "HATA: tape yok: $TAPE" >&2; exit 1; }
mkdir -p "$OUT"

echo ">> [1/2] VHS ile terminal kaydı  ->  out/$CODE/$CODE-terminal.mp4"
( cd "$OUT" && vhs "$TAPE" )
# Bazı VHS sürümleri Output'u tape'in yanına yazabilir; garanti altına al:
if [ ! -f "$OUT/$CODE-terminal.mp4" ] && [ -f "$LDIR/$CODE-terminal.mp4" ]; then
    mv "$LDIR/$CODE-terminal.mp4" "$OUT/$CODE-terminal.mp4"
fi
[ -f "$OUT/$CODE-terminal.mp4" ] || { echo "HATA: terminal.mp4 üretilemedi" >&2; exit 1; }

echo ">> [2/2] Overlay biniyor         ->  out/$CODE/$CODE-overlay.mp4"
python3 "$ROOT/tools/gen_overlays.py" \
        "$OUT/$CODE-terminal.mp4" "$LDIR/manifest.json" "$OUT/$CODE-overlay.mp4"

echo ">> Bitti. Çıktılar:"
ls -la "$OUT"
