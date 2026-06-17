#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""overlay'li terminal videosu + terminal anlatım sesi -> sesli final klip.

durations.json'daki TERMINAL beat'lerini (intro + duraklar + closing) sırayla
birleştirip overlay'li videonun üstüne ses olarak bindirir. Ses, videoya göre
sessizlikle doldurulur (apad) ki video uzunluğu belirleyici olsun.

NOT: Bu yalnızca TERMINAL segmentinin klibidir. Tam ders = 9 segmentin (yüz/Manim/
kart + terminal) birleşimi; diğer segmentlerin görselleri ayrı üretilir.

Çıktı: out/<kod>/<kod>-<dil>-final.mp4

Kullanım:
    python3 tools/mux.py <overlay.mp4> <manifest.json> [dil] [output.mp4]
Gerekli: ffmpeg, ffprobe
"""
import json, sys, pathlib, subprocess

overlay = pathlib.Path(sys.argv[1])
manifest_path = pathlib.Path(sys.argv[2])
m = json.loads(manifest_path.read_text(encoding="utf-8"))
code = m["lesson"]["code"]
primary = m["lesson"].get("narration_lang", "tr")
lang = sys.argv[3] if len(sys.argv) > 3 else primary


def _repo_root(mp):
    p = mp.resolve()
    for anc in p.parents:
        if anc.name == "lessons":
            return anc.parent
        if (anc / ".git").exists() or (anc / "tools").is_dir():
            return anc
    return p.parent


root = _repo_root(manifest_path)
audio_dir = root / "out" / code / "audio" / lang
dj_path = audio_dir / "durations.json"
if not dj_path.exists():
    sys.exit(f"durations.json yok: {dj_path}\n  Önce gen_tts.py çalıştır (gerçek ya da --mock).")

dj = json.loads(dj_path.read_text(encoding="utf-8"))
term_beats = [b for b in dj["beats"] if b["kind"] in ("term_intro", "term_stop", "term_closing")]
if not term_beats:
    sys.exit("durations.json'da terminal anlatım beat'i yok")

# concat listesi (mutlak yollar)
listf = audio_dir / "_terminal_concat.txt"
listf.write_text("".join(f"file '{(audio_dir / b['file']).resolve()}'\n" for b in term_beats),
                 encoding="utf-8")

out = pathlib.Path(sys.argv[4]) if len(sys.argv) > 4 else root / "out" / code / f"{code}-{lang}-final.mp4"
out.parent.mkdir(parents=True, exist_ok=True)

cmd = ["ffmpeg", "-y",
       "-f", "concat", "-safe", "0", "-i", str(listf),   # 0: birleşik anlatım sesi
       "-i", str(overlay),                                # 1: overlay'li video
       "-filter_complex", "[0:a]apad[a]",                 # sesi sessizlikle doldur
       "-map", "1:v:0", "-map", "[a]", "-shortest",       # video uzunluğu belirleyici
       "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", str(out)]
print(f"mux: {len(term_beats)} terminal beat -> {out.name}")
subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def dur(p):
    return float(subprocess.check_output(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(p)]).strip())


audio_total = sum(b["duration_sec"] for b in term_beats)
print(f"video: {dur(overlay):.1f}s · anlatım: {audio_total:.1f}s · final: {dur(out):.1f}s")
print("Yazıldı:", out)
