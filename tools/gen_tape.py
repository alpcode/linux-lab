#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Manifest (+ opsiyonel durations.json) -> VHS .tape üreticisi.

'terminal' segmentini VHS .tape'e çevirir. durations.json verilirse her bölüm
(intro / her durak / closing) o bölümün ANLATIM süresine eşitlenir: komutlar
yazılır, sonra terminal anlatım bitene kadar TUTULUR -> kayıt sesle senkron.
durations.json yoksa manifest'teki sleep_after_sec kullanılır (yer tutucu tempo).

Kural: .tape ELLE düzenlenmez; kaynak manifest + durations.json'dır.

Kullanım:
    python3 tools/gen_tape.py lessons/L0-U1-D1/manifest.json
    python3 tools/gen_tape.py lessons/L0-U1-D1/manifest.json out/L0-U1-D1/audio/tr/durations.json
"""
import json, sys, pathlib

mpath = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "lessons/L0-U1-D1/manifest.json")
durations_path = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else None

m = json.loads(mpath.read_text(encoding="utf-8"))
code = m["lesson"]["code"]
lesson_dir = mpath.parent

term = next((s for s in m["segments"] if s["type"] == "terminal"), None)
if term is None:
    sys.exit("Bu manifestte 'terminal' tipli segment yok.")

# --- opsiyonel: anlatım süreleri (durations.json) ---
dur, synced = {}, False
if durations_path and durations_path.exists():
    dj = json.loads(durations_path.read_text(encoding="utf-8"))
    for b in dj.get("beats", []):
        if b["kind"] == "term_intro":
            dur["intro"] = b["duration_sec"]
        elif b["kind"] == "term_closing":
            dur["closing"] = b["duration_sec"]
        elif b["kind"] == "term_stop" and b.get("dir"):
            dur[b["dir"]] = b["duration_sec"]
    synced = bool(dur)


def vhs_type(cmd, typing_ms=None):
    delim = "'" if '"' in cmd else '"'
    prefix = f"Type@{typing_ms}ms " if typing_ms else "Type "
    return f"{prefix}{delim}{cmd}{delim}"


def cmd_used(cmds, default_typing=60):
    """VHS'in komutları yazma + sleep_after_sec için kabaca harcadığı süre."""
    t = 0.0
    for c in cmds:
        t += len(c["cmd"]) * (c.get("typing_ms") or default_typing) / 1000.0
        t += c.get("sleep_after_sec", 2)
    return t


L = []
add = L.append
add(f"# {code} — {term['title']}  ({term.get('time_band','')})")
add(f"# Manifest'ten OTOMATİK üretildi: {mpath.name}"
    + (f" + {durations_path.name} (SESLE SENKRON)" if synced else " (yer tutucu tempo)"))
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


def emit(cmds, target=None):
    for c in cmds:
        add(vhs_type(c["cmd"], c.get("typing_ms")))
        add("Enter")
        add(f"Sleep {c.get('sleep_after_sec', 2)}s")
    if target is not None:
        hold = max(0.5, target - cmd_used(cmds))
        add(f"Sleep {hold:.1f}s    # anlatim tutmasi (bolum ~ {target:.1f}s)")


intro = term.get("intro")
if intro:
    add(f"# === Intro · {term['title']} ===")
    emit(intro["commands"], dur.get("intro"))
    add("")

for st in term.get("stops", []):
    add(f"# === Durak · {st['dir']} — {st.get('label','')} ===")
    emit(st["commands"], dur.get(st["dir"]))
    add("")

closing = term.get("closing")
add("# === Kapanis (anlatim + geri cagirma; overlay sonradan biner) ===")
if closing and "closing" in dur:
    emit([], dur["closing"])          # komut yok: anlatim suresi kadar tut
else:
    add("Sleep 2s")
add("")

out = lesson_dir / f"{code}-terminal.tape"
out.write_text("\n".join(L) + "\n", encoding="utf-8")

n = len(intro["commands"]) + sum(len(st["commands"]) for st in term.get("stops", []))
print("Yazildi:", out, "(SESLE SENKRON)" if synced else "(yer tutucu tempo)")
print("Toplam komut:", n)
if synced:
    print(f"Hedef terminal suresi: ~{sum(dur.values()):.0f}s ({len(dur)} bolum)")
