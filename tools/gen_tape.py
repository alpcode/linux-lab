#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Manifest -> VHS .tape üreticisi.
Bir dersin manifest'indeki 'terminal' segmentini okuyup VHS .tape dosyasına çevirir.
.tape, Ubuntu VM'in İÇİNDE `vhs <dosya>` ile çalıştırılıp MP4 üretir.
Kural: .tape ELLE düzenlenmez; kaynak manifest'tir, değişiklik orada yapılır.

Kullanım:
    python3 tools/gen_tape.py [lessons/L0-U1-D1/manifest.json]
"""
import json, sys, pathlib

mpath = pathlib.Path(sys.argv[1] if len(sys.argv) > 1
                     else "lessons/L0-U1-D1/manifest.json")
m = json.loads(mpath.read_text(encoding="utf-8"))
code = m["lesson"]["code"]
lesson_dir = mpath.parent

term = next((s for s in m["segments"] if s["type"] == "terminal"), None)
if term is None:
    sys.exit("Bu manifestte 'terminal' tipli segment yok.")


def vhs_type(cmd, typing_ms=None):
    # Komutta " varsa VHS string'ini ' ile sar (kaçışla uğraşma).
    delim = "'" if '"' in cmd else '"'
    prefix = f"Type@{typing_ms}ms " if typing_ms else "Type "
    return f"{prefix}{delim}{cmd}{delim}"


L = []
add = L.append
add(f"# {code} — {term['title']}  ({term.get('time_band','')})")
add(f"# Manifest'ten OTOMATİK üretildi: {mpath.name}. Elle düzenleme; manifest'i değiştir.")
add(f"# Ubuntu VM'in İÇİNDE, selin olarak çalıştır:  vhs {code}-terminal.tape")
add("#")
add(f"Output {code}-terminal.mp4")
add("")
add('Set Shell "bash"')
add('Set FontFamily "JetBrains Mono"')
add("Set FontSize 22")
add("Set Width 1280")
add("Set Height 720")
add("Set Padding 20")
add("Set TypingSpeed 60ms")
add("")
add("# --- Temiz başlangıç (gizli): markalı prompt + ana dizin + temizle ---")
add("Hide")
add('Type "source ~/.bashrc 2>/dev/null; cd ~; clear"')
add("Enter")
add("Sleep 500ms")
add("Show")
add("")


def emit(cmds):
    for c in cmds:
        add(vhs_type(c["cmd"], c.get("typing_ms")))
        add("Enter")
        add(f"Sleep {c.get('sleep_after_sec', 2)}s")


intro = term.get("intro")
if intro:
    add(f"# === Intro · {term['title']} ===")
    emit(intro["commands"])
    add("")

for st in term.get("stops", []):
    add(f"# === Durak · {st['dir']} — {st.get('label','')} ===")
    emit(st["commands"])
    add("")

add("# --- Kapanış nefesi (overlay/anlatım sonradan biner) ---")
add("Sleep 2s")
add("")

out = lesson_dir / f"{code}-terminal.tape"
out.write_text("\n".join(L) + "\n", encoding="utf-8")

n = len(intro["commands"]) + sum(len(st["commands"]) for st in term.get("stops", []))
print("Yazıldı:", out)
print("Toplam komut:", n)
