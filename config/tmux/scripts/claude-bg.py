#!/usr/bin/env python3
"""Lista los procesos en segundo plano de Claude Code.

Modos:
  (sin args)  render para el panel de tmux
  --pick      formato plano para fzf: <ruta>\t<etiqueta>
"""
import json
import os
import sys
import time
import glob

AZUL, MALVA, VERDE, ROJO = "\033[38;2;137;180;250m", "\033[38;2;203;166;247m", "\033[38;2;166;227;161m", "\033[38;2;243;139;168m"
GRIS, TEXTO, AMARILLO, RESET = "\033[38;2;108;112;134m", "\033[38;2;205;214;244m", "\033[38;2;249;226;175m", "\033[0m"

def edad(ts):
    d = time.time() - ts
    if d < 60:   return f"{int(d)}s"
    if d < 3600: return f"{int(d//60)}m"
    if d < 86400:return f"{int(d//3600)}h"
    return f"{int(d//86400)}d"

def raices_tmp():
    """Dónde deja Claude Code la salida de los procesos en background.

    En macOS $TMPDIR apunta a /var/folders/..., pero Claude Code usa /tmp
    (que el sistema resuelve a /private/tmp). Se prueban las tres.
    """
    uid = os.getuid()
    vistas, fuera = set(), []
    for base in (os.environ.get("TMPDIR", ""), "/tmp", "/private/tmp"):
        if not base:
            continue
        ruta = os.path.join(base.rstrip("/"), f"claude-{uid}")
        real = os.path.realpath(ruta)
        if os.path.isdir(real) and real not in vistas:
            vistas.add(real)
            fuera.append(real)
    return fuera

def agentes():
    """Sesiones de agente en background, de ~/.claude/jobs/*/state.json"""
    fuera = []
    for est in glob.glob(os.path.expanduser("~/.claude/jobs/*/state.json")):
        try:
            with open(est, encoding="utf-8") as fh:
                d = json.load(fh)
        except Exception:
            continue
        fuera.append({
            "id": os.path.basename(os.path.dirname(est)),
            "estado": d.get("state") or "?",
            "detalle": (d.get("detail") or "").split("\n")[0][:30],
            "intent": (d.get("intent") or "")[:30],
            "cwd": os.path.basename(d.get("cwd") or ""),
            "vuelo": (d.get("inFlight") or {}).get("tasks", 0),
            "ts": os.path.getmtime(est),
            "ruta": est,
        })
    return sorted(fuera, key=lambda x: x["ts"], reverse=True)

def tareas():
    """Salidas de bash en background del proyecto actual y recientes."""
    fuera = []
    patrones = [os.path.join(r, "*", "*", "tasks", "*.output") for r in raices_tmp()]
    for out in (p for pat in patrones for p in glob.glob(pat)):
        try:
            st = os.stat(out)
        except OSError:
            continue
        partes = out.split(os.sep)
        fuera.append({
            "id": os.path.basename(out).replace(".output", ""),
            "proyecto": partes[-4].lstrip("-").replace("-", "/").split("/")[-1][:30],
            "bytes": st.st_size,
            "ts": st.st_mtime,
            "ruta": out,
        })
    return sorted(fuera, key=lambda x: x["ts"], reverse=True)

def color_estado(e):
    return {"running": VERDE, "blocked": ROJO, "queued": AMARILLO}.get(e, GRIS)

def main():
    ags, trs = agentes(), tareas()

    if "--pick" in sys.argv:
        for a in ags:
            print(f"{a['ruta']}\tagente  {a['id']}  {a['estado']}  {a['intent']}")
        for t in trs[:40]:
            print(f"{t['ruta']}\tbash    {t['id']}  {t['bytes']}b  {t['proyecto']}")
        return

    print(f"{MALVA}  Agentes{RESET}")
    if not ags:
        print(f"{GRIS}    ninguno{RESET}")
    for a in ags[:6]:
        c = color_estado(a["estado"])
        print(f"  {c}●{RESET} {TEXTO}{a['id']}{RESET} {GRIS}{a['cwd']}{RESET}")
        etiq = a["detalle"] or a["intent"]
        vuelo = f" · {a['vuelo']} en vuelo" if a["vuelo"] else ""
        print(f"    {c}{a['estado']}{RESET}{GRIS}{vuelo} · {edad(a['ts'])}{RESET}")
        if etiq:
            print(f"    {GRIS}{etiq}{RESET}")

    print()
    print(f"{MALVA}  Procesos bash{RESET}")
    if not trs:
        print(f"{GRIS}    ninguno{RESET}")
    for t in trs[:8]:
        # Modificado hace poco = probablemente sigue escribiendo
        activo = (time.time() - t["ts"]) < 30
        c = VERDE if activo else GRIS
        kb = t["bytes"] / 1024
        tam = f"{kb:.0f}K" if kb >= 1 else f"{t['bytes']}b"
        print(f"  {c}●{RESET} {TEXTO}{t['id']}{RESET} {GRIS}{tam} · {edad(t['ts'])}{RESET}")
        print(f"    {GRIS}{t['proyecto']}{RESET}")

if __name__ == "__main__":
    main()
