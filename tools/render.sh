#!/usr/bin/env bash
# linux-lab — bir dersi uçtan uca üret. Çıktılar out/<DERS-KODU>/ altına.
#
# durations.json VARSA (gen_tts.py ile üretilmiş): senkron tape -> VHS -> overlay -> mux (SESLİ final).
# YOKSA: yer tutucu tape -> VHS -> overlay (sessiz; önce gen_tts.py çalıştır).
#
# Ubuntu VM'in İÇİNDE, selin olarak:  tools/render.sh L0-U1-D1
set -euo pipefail

CODE="${1:?kullanım: tools/render.sh <DERS-KODU>   (örn. L0-U1-D1)}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LDIR="$ROOT/lessons/$CODE"
TAPE="$LDIR/$CODE-terminal.tape"
OUT="$ROOT/out/$CODE"
MANIFEST="$LDIR/manifest.json"

[ -f "$MANIFEST" ] || { echo "HATA: manifest yok: $MANIFEST" >&2; exit 1; }
mkdir -p "$OUT"

PRIMARY="$(python3 -c "import json;print(json.load(open('$MANIFEST'))['lesson'].get('narration_lang','tr'))")"
DUR="$ROOT/out/$CODE/audio/$PRIMARY/durations.json"

if [ -f "$DUR" ]; then
    echo ">> durations.json bulundu -> SESLE SENKRON üretim (dil: $PRIMARY)"
    python3 "$ROOT/tools/gen_tape.py" "$MANIFEST" "$DUR"
else
    echo ">> durations.json yok -> sessiz/yer tutucu üretim (sesli istiyorsan önce: tools/gen_tts.py)"
fi
[ -f "$TAPE" ] || { echo "HATA: tape yok: $TAPE" >&2; exit 1; }

echo ">> [1] VHS ile terminal kaydı   ->  out/$CODE/$CODE-terminal.mp4"
( cd "$OUT" && vhs "$TAPE" )
if [ ! -f "$OUT/$CODE-terminal.mp4" ] && [ -f "$LDIR/$CODE-terminal.mp4" ]; then
    mv "$LDIR/$CODE-terminal.mp4" "$OUT/$CODE-terminal.mp4"
fi
[ -f "$OUT/$CODE-terminal.mp4" ] || { echo "HATA: terminal.mp4 üretilemedi" >&2; exit 1; }

echo ">> [2] Overlay biniyor          ->  out/$CODE/$CODE-overlay.mp4"
python3 "$ROOT/tools/gen_overlays.py" "$OUT/$CODE-terminal.mp4" "$MANIFEST" "$OUT/$CODE-overlay.mp4"

if [ -f "$DUR" ]; then
    echo ">> [3] Ses muxlanıyor           ->  out/$CODE/$CODE-$PRIMARY-final.mp4"
    python3 "$ROOT/tools/mux.py" "$OUT/$CODE-overlay.mp4" "$MANIFEST" "$PRIMARY"
fi

echo ">> Bitti. Çıktılar:"
ls -la "$OUT"
