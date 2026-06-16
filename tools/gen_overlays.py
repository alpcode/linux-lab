#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Manifest + terminal MP4 -> overlay'li MP4.

Manifest'in 'terminal' segmentinden zamanlamayı hesaplar, cue sembollerini
renkli emoji rozetleri (PNG) olarak basar ve ffmpeg ile videoya bindirir:
  - kalıcı ORTAM etiketi (sağ alt)
  - intro BANDI "Çıktın farklı olabilir" (üst orta, intro süresince)
  - her DURAKTA: başlık "/etc · ..." (sol alt) + sembol rozetleri (sağ üst)

Zamanlama manifest'ten TAHMİN edilir (yazma süresi + sleep), sonra GERÇEK video
süresine ÖLÇEKLENİR (ffprobe) — böylece VHS'in sistematik zamanlama farkı düzeltilir.

Kullanım:
    python3 tools/gen_overlays.py <input.mp4> [manifest.json] [output.mp4]
Gerekli: ffmpeg, Pillow, fonts-dejavu-core, fonts-noto-color-emoji
"""
import json, sys, subprocess, pathlib
from PIL import Image, ImageDraw, ImageFont

inp = pathlib.Path(sys.argv[1])
manifest_path = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else inp.parent / "manifest.json"

DEJAVU = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
NOTO   = "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"
for f, pkg in [(DEJAVU, "fonts-dejavu-core"), (NOTO, "fonts-noto-color-emoji")]:
    if not pathlib.Path(f).exists():
        sys.exit(f"Font yok: {f}\n  Kur: sudo apt install -y {pkg}")

m = json.loads(manifest_path.read_text(encoding="utf-8"))
code = m["lesson"]["code"]
os_blk = m["lesson"].get("on_screen", {})   # ekran metni: İngilizce (dublajlarda ortak)

def _repo_root(mp):
    """manifest .../lessons/<kod>/manifest.json -> repo kökü"""
    p = mp.resolve()
    for anc in p.parents:
        if anc.name == "lessons":
            return anc.parent
        if (anc / ".git").exists() or (anc / "tools").is_dir():
            return anc
    return p.parent

# çıktı: 3. argüman verilmişse o; yoksa out/<kod>/<kod>-overlay.mp4
if len(sys.argv) > 3:
    out = pathlib.Path(sys.argv[3])
else:
    out = _repo_root(manifest_path) / "out" / code / f"{code}-overlay.mp4"
out.parent.mkdir(parents=True, exist_ok=True)
W, H = 1280, 720
term = next((s for s in m["segments"] if s["type"] == "terminal"), None)
if not term:
    sys.exit("manifestte 'terminal' segmenti yok")

# ---- zaman çizelgesi (tahmin) ----
def cmd_time(c):
    return len(c["cmd"]) * (c.get("typing_ms", 60)) / 1000.0 + c.get("sleep_after_sec", 2)

t = 0.0
intro = term.get("intro")
intro_win = None
if intro:
    s = t
    for c in intro["commands"]:
        t += cmd_time(c)
    intro_win = [s, t]
windows = []
for st in term.get("stops", []):
    s = t
    for c in st["commands"]:
        t += cmd_time(c)
    windows.append([st, s, t])
est_total = t or 1.0

# ---- gerçek süreye ölçekle ----
real = float(subprocess.check_output(
    ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
     "-of", "csv=p=0", str(inp)]).strip())
scale = real / est_total
sc = lambda x: round(x * scale, 2)
if intro_win:
    intro_win = [sc(intro_win[0]), sc(intro_win[1])]
for w in windows:
    w[1], w[2] = sc(w[1]), sc(w[2])

print(f"Gerçek süre: {real:.1f}s · tahmin: {est_total:.1f}s · ölçek: {scale:.2f}")
for st, s, e in windows:
    print(f"  {s:6.1f}–{e:6.1f}s  {st['dir']}")

# ---- emoji rozetleri ----
assets = out.parent / ".overlay_assets"
assets.mkdir(exist_ok=True)
STRIKE = 109
emo_font = ImageFont.truetype(NOTO, size=STRIKE)
_badge = {}
def badge(emoji, h=60):
    if emoji in _badge:
        return _badge[emoji]
    big = Image.new("RGBA", (STRIKE * 2, STRIKE * 2), (0, 0, 0, 0))
    ImageDraw.Draw(big).text((0, 0), emoji, font=emo_font, embedded_color=True)
    bb = big.getbbox()
    if bb:
        big = big.crop(bb)
    w, hh = big.size
    big = big.resize((max(1, int(w * h / hh)), h), Image.LANCZOS)
    p = assets / f"badge_{ord(emoji[0]):x}.png"
    big.save(p)
    _badge[emoji] = (p, big.size)
    return _badge[emoji]

def is_emoji(s):
    return any(ord(ch) > 0x2000 for ch in s)

def textfile(name, txt):
    p = assets / f"txt_{name}.txt"
    p.write_text(txt, encoding="utf-8")
    return p

# ---- PNG overlay girdileri (durak sembolleri, sağ üst) ----
png_inputs = []  # (path, x, y, start, end)
for st, s, e in windows:
    bx = W - 20
    for emoji in [x for x in st.get("symbols", []) if is_emoji(x)]:
        p, (bw, bh) = badge(emoji, 60)
        bx -= bw
        png_inputs.append((p, bx, 20, s, e))
        bx -= 12

# ---- ffmpeg girdileri + overlay zinciri ----
inputs = ["-i", str(inp)]
ov_chain = []
last = "[0:v]"
for i, (p, x, y, s, e) in enumerate(png_inputs, start=1):
    inputs += ["-i", str(p)]
    ov_chain.append(f"{last}[{i}:v]overlay=x={int(x)}:y={int(y)}:enable='between(t,{s},{e})'[v{i}]")
    last = f"[v{i}]"

# ---- drawtext'ler ----
def DT(tf, size, x, y, enable=None, boxcolor="black@0.6", color="white"):
    en = f":enable='between(t,{enable[0]},{enable[1]})'" if enable else ""
    return (f"drawtext=fontfile={DEJAVU}:textfile={tf}:fontcolor={color}:fontsize={size}"
            f":x={x}:y={y}:box=1:boxcolor={boxcolor}:boxborderw=12{en}")

dt = []
banner = os_blk.get("intro_banner")
if intro and intro_win and banner:
    dt.append(DT(textfile("intro", banner), 28, "(w-tw)/2", "40",
                 enable=intro_win, boxcolor="#1c1c4e@0.8"))
for i, (st, s, e) in enumerate(windows):
    title = st.get("on_screen") or st.get("label", "")   # EN ekran başlığı
    label = f"{st['dir']} · {title}".strip(" ·")
    dt.append(DT(textfile(f"stop{i}", label), 30, "24", "h-th-24", enable=[s, e]))

# ---- filtergraph birleştir ----
fc = ";".join(ov_chain)
fc = (fc + ";" if fc else "") + last + ",".join(dt) + "[outv]"

cmd = ["ffmpeg", "-y", *inputs, "-filter_complex", fc,
       "-map", "[outv]", "-map", "0:a?", "-c:a", "copy", str(out)]
print("ffmpeg çalışıyor...")
subprocess.run(cmd, check=True)
print("Yazıldı:", out)
