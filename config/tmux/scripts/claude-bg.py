#!/usr/bin/env python3
"""Procesos en segundo plano de Claude Code, filtrados por proyecto.

  claude-bg.py [--cwd RUTA] [--watch SEGUNDOS] [--pick] [--todos]

Sin --todos se limita al proyecto de RUTA (o del directorio actual), incluidos
sus worktrees. En --watch redibuja en el sitio en vez de limpiar la pantalla:
un `clear` cada pocos segundos produce un parpadeo muy molesto en un pane fijo.
"""
import argparse
import glob
import json
import os
import sys
import time

AZUL = "\033[38;2;137;180;250m"
MALVA = "\033[38;2;203;166;247m"
VERDE = "\033[38;2;166;227;161m"
ROJO = "\033[38;2;243;139;168m"
AMARILLO = "\033[38;2;249;226;175m"
GRIS = "\033[38;2;108;112;134m"
TEXTO = "\033[38;2;205;214;244m"
RESET = "\033[0m"

INICIO = "\033[H"      # cursor arriba-izquierda
BORRA_LINEA = "\033[K"  # borra hasta fin de línea
BORRA_ABAJO = "\033[J"  # borra de aquí al final
OCULTA_CURSOR = "\033[?25l"
MUESTRA_CURSOR = "\033[?25h"


def slug(ruta):
    """Convierte una ruta en el nombre de carpeta que usa Claude Code."""
    return ruta.replace("/", "-").replace("_", "-").replace(".", "-")


def edad(ts):
    d = time.time() - ts
    if d < 60:
        return f"{int(d)}s"
    if d < 3600:
        return f"{int(d // 60)}m"
    if d < 86400:
        return f"{int(d // 3600)}h"
    return f"{int(d // 86400)}d"


def raices_tmp():
    """En macOS $TMPDIR es /var/folders/..., pero Claude Code usa /tmp."""
    uid = os.getuid()
    vistas, fuera = set(), []
    for base in (os.environ.get("TMPDIR", ""), "/tmp", "/private/tmp"):
        if not base:
            continue
        real = os.path.realpath(os.path.join(base.rstrip("/"), f"claude-{uid}"))
        if os.path.isdir(real) and real not in vistas:
            vistas.add(real)
            fuera.append(real)
    return fuera


def agentes(raiz_proyecto):
    fuera = []
    for est in glob.glob(os.path.expanduser("~/.claude/jobs/*/state.json")):
        try:
            with open(est, encoding="utf-8") as fh:
                d = json.load(fh)
        except Exception:
            continue
        cwd = d.get("cwd") or ""
        # Un agente cuenta si su cwd está dentro del proyecto (o es el proyecto)
        if raiz_proyecto and not (cwd == raiz_proyecto or cwd.startswith(raiz_proyecto + "/")):
            continue
        fuera.append({
            "id": os.path.basename(os.path.dirname(est)),
            "estado": d.get("state") or "?",
            "detalle": (d.get("detail") or "").split("\n")[0][:30],
            "intent": (d.get("intent") or "")[:30],
            "cwd": os.path.basename(cwd),
            "vuelo": (d.get("inFlight") or {}).get("tasks", 0),
            "ts": os.path.getmtime(est),
            "ruta": est,
        })
    return sorted(fuera, key=lambda x: x["ts"], reverse=True)


def tareas(raiz_proyecto):
    prefijo = slug(raiz_proyecto) if raiz_proyecto else None
    fuera = []
    for raiz in raices_tmp():
        for out in glob.glob(os.path.join(raiz, "*", "*", "tasks", "*.output")):
            carpeta = out.split(os.sep)[-4]
            # El proyecto exacto o cualquiera de sus worktrees (que van con sufijo)
            if prefijo and not carpeta.startswith(prefijo):
                continue
            try:
                st = os.stat(out)
            except OSError:
                continue
            fuera.append({
                "id": os.path.basename(out).replace(".output", ""),
                "proyecto": carpeta.lstrip("-").split("-")[-1][:26],
                "bytes": st.st_size,
                "ts": st.st_mtime,
                "ruta": out,
            })
    return sorted(fuera, key=lambda x: x["ts"], reverse=True)


def color_estado(e):
    return {"running": VERDE, "blocked": ROJO, "queued": AMARILLO}.get(e, GRIS)


def render(raiz_proyecto, ancho):
    ags, trs = agentes(raiz_proyecto), tareas(raiz_proyecto)
    L = []
    etiqueta = os.path.basename(raiz_proyecto) if raiz_proyecto else "todos los proyectos"
    L.append(f"{AZUL} {etiqueta[:ancho - 4]}{RESET}")
    L.append("")

    L.append(f"{MALVA}  Agentes{RESET}")
    if not ags:
        L.append(f"{GRIS}    ninguno aquí{RESET}")
    for a in ags[:6]:
        c = color_estado(a["estado"])
        L.append(f"  {c}●{RESET} {TEXTO}{a['id']}{RESET}")
        vuelo = f" · {a['vuelo']} en vuelo" if a["vuelo"] else ""
        L.append(f"    {c}{a['estado']}{RESET}{GRIS}{vuelo} · {edad(a['ts'])}{RESET}")
        etiq = a["detalle"] or a["intent"]
        if etiq:
            L.append(f"    {GRIS}{etiq}{RESET}")

    L.append("")
    L.append(f"{MALVA}  Procesos bash{RESET}")
    if not trs:
        L.append(f"{GRIS}    ninguno aquí{RESET}")
    for t in trs[:10]:
        activo = (time.time() - t["ts"]) < 30
        c = VERDE if activo else GRIS
        kb = t["bytes"] / 1024
        tam = f"{kb:.0f}K" if kb >= 1 else f"{t['bytes']}b"
        L.append(f"  {c}●{RESET} {TEXTO}{t['id'][:16]}{RESET} {GRIS}{tam} · {edad(t['ts'])}{RESET}")
    return L


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cwd", default=None)
    ap.add_argument("--watch", type=float, default=0)
    ap.add_argument("--pick", action="store_true")
    ap.add_argument("--todos", action="store_true")
    args = ap.parse_args()

    raiz = None if args.todos else os.path.realpath(args.cwd or os.getcwd())

    if args.pick:
        for a in agentes(raiz):
            print(f"{a['ruta']}\tagente  {a['id']}  {a['estado']}  {a['intent']}")
        for t in tareas(raiz)[:40]:
            print(f"{t['ruta']}\tbash    {t['id']}  {t['bytes']}b")
        return

    ancho = int(os.environ.get("COLUMNS") or 38)

    if not args.watch:
        print("\n".join(render(raiz, ancho)))
        return

    # Bucle con redibujo en el sitio: nada de `clear`, que es lo que parpadea.
    # Además solo se reescribe si el contenido cambió.
    previo = None
    sys.stdout.write(OCULTA_CURSOR)
    try:
        while True:
            actual = render(raiz, ancho)
            if actual != previo:
                sys.stdout.write(INICIO)
                sys.stdout.write("\n".join(l + BORRA_LINEA for l in actual))
                sys.stdout.write("\n" + BORRA_ABAJO)
                sys.stdout.flush()
                previo = actual
            time.sleep(args.watch)
    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write(MUESTRA_CURSOR)
        sys.stdout.flush()


if __name__ == "__main__":
    main()
