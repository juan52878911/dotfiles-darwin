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


def envolver(texto, ancho, sangria):
    """Parte el texto en líneas que quepan, sin cortar palabras a media.

    El panel es estrecho (38 columnas): sin esto los títulos se salían del pane
    y tmux los cortaba en seco a mitad de palabra.
    """
    import textwrap
    disponible = max(8, ancho - sangria - 2)
    return textwrap.wrap(texto, width=disponible) or [""]


def dur(seg):
    seg = max(0, int(seg))
    if seg < 60:
        return f"{seg}s"
    if seg < 3600:
        return f"{seg // 60}m"
    return f"{seg // 3600}h {(seg % 3600) // 60:02d}m"


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


def _primera_linea(ruta):
    with open(ruta, "rb") as fh:
        return fh.readline()


def _ultimas_lineas(ruta, cuantas=25, cola=200000):
    """Lee solo el final del fichero: estos JSONL pasan del medio mega."""
    with open(ruta, "rb") as fh:
        fh.seek(0, os.SEEK_END)
        fin = fh.tell()
        fh.seek(max(0, fin - cola))
        trozo = fh.read()
    lineas = [l for l in trozo.split(b"\n") if l.strip()]
    return lineas[-cuantas:]


def _tokens(lineas):
    """El último registro no siempre trae `usage`; se busca hacia atrás.

    Se suma cache_read + output porque es lo que refleja el tamaño real del
    contexto que ha manejado el agente, que es lo que muestra la app.
    """
    for cruda in reversed(lineas):
        try:
            d = json.loads(cruda)
        except Exception:
            continue
        u = ((d.get("message") or {}).get("usage") or {})
        if u:
            return u.get("cache_read_input_tokens", 0) + u.get("output_tokens", 0)
    return 0


_CACHE_DESC = {}   # jsonl_padre -> (mtime, {agentId: descripcion})


def _mapa_descripciones(jsonl_padre):
    """Escanea el JSONL padre UNA vez y cachea por mtime.

    Sin esto se recorría el fichero entero por cada agente: con 5 agentes eran
    5 pasadas completas y el panel pasaba de 0.1 s a 0.4 s por refresco.
    """
    try:
        mt = os.path.getmtime(jsonl_padre)
    except OSError:
        return {}
    guardado = _CACHE_DESC.get(jsonl_padre)
    if guardado and guardado[0] == mt:
        return guardado[1]

    por_uso, por_agente, pendientes = {}, {}, []
    try:
        with open(jsonl_padre, encoding="utf-8", errors="ignore") as fh:
            for linea in fh:
                if '"Agent"' not in linea and '"agentId"' not in linea:
                    continue
                try:
                    d = json.loads(linea)
                except Exception:
                    continue
                c = (d.get("message") or {}).get("content")
                if not isinstance(c, list):
                    continue
                for b in c:
                    if not isinstance(b, dict):
                        continue
                    if b.get("type") == "tool_use" and b.get("name") == "Agent":
                        por_uso[b.get("id")] = (b.get("input") or {}).get("description", "")
                    elif b.get("type") == "tool_result":
                        pendientes.append((b.get("tool_use_id"), linea))
    except OSError:
        return {}

    for id_uso, linea in pendientes:
        desc = por_uso.get(id_uso)
        if not desc:
            continue
        # El agentId aparece en el texto del resultado
        import re
        for m in re.finditer(r'"agentId":"([a-z0-9]+)"', linea):
            por_agente[m.group(1)] = desc
        for m in re.finditer(r'\b(a[0-9a-f]{16})\b', linea):
            por_agente.setdefault(m.group(1), desc)

    _CACHE_DESC[jsonl_padre] = (mt, por_agente)
    return por_agente


def _descripcion_padre(jsonl_padre, agent_id):
    """La descripción real de la tarea vive en la sesión PADRE.

    Enlace: el subagente tiene `agentId`; en el padre, el registro que lo menciona
    lleva un bloque tool_result con `tool_use_id`, y el tool_use de Agent con ese
    mismo id trae el campo `description` — que es justo lo que enseña la app.
    """
    return _mapa_descripciones(jsonl_padre).get(agent_id, "")


def _titulo(cruda):
    try:
        d = json.loads(cruda)
    except Exception:
        return ""
    m = d.get("message") or {}
    c = m.get("content")
    txt = c if isinstance(c, str) else (c[0].get("text", "") if isinstance(c, list) and c else "")
    # La primera frase con sentido sirve de título
    for linea in txt.split("\n"):
        linea = linea.strip()
        if len(linea) > 12:
            return linea
    return txt


def sesiones_bg(raiz_proyecto):
    """Sesiones en segundo plano, de ~/.claude/sessions/<pid>.json con kind=="bg".

    Esta es la fuente BUENA: trae el nombre real de la tarea, el `status` en vivo
    y el jobId. Se actualiza por eventos (statusUpdatedAt), no por sondeo.
    Se descartó hablar por el socket de `messagingSocketPath` porque su protocolo
    es de mensajería entre sesiones (`notify_when_idle` / `peer_idle_notice`), no
    de telemetría: no da tokens ni usos de herramienta, y suscribirse tocaría
    sesiones que están trabajando.
    """
    fuera = []
    for f in glob.glob(os.path.expanduser("~/.claude/sessions/*.json")):
        try:
            with open(f, encoding="utf-8") as fh:
                d = json.load(fh)
        except Exception:
            continue
        if d.get("kind") != "bg":
            continue
        cwd = d.get("cwd") or ""
        if raiz_proyecto and not (cwd == raiz_proyecto or cwd.startswith(raiz_proyecto + "/")):
            continue
        pid = d.get("pid")
        try:
            os.kill(int(pid), 0)
            vivo = True
        except Exception:
            vivo = False
        if not vivo:
            continue          # proceso muerto: el fichero quedó huérfano
        fuera.append({
            "id": str(d.get("jobId") or pid),
            "titulo": d.get("name") or str(pid),
            "estado": d.get("status") or "?",
            "transcurrido": time.time() - (d.get("startedAt", 0) / 1000),
            "ts": (d.get("statusUpdatedAt") or d.get("updatedAt") or 0) / 1000,
        })
    return sorted(fuera, key=lambda x: x["ts"], reverse=True)


def agentes(raiz_proyecto):
    """Subagentes, de ~/.claude/projects/<proy>/<ses>/subagents/agent-*.jsonl

    No hay campo de estado: se considera EN CURSO si el fichero se tocó hace poco.
    Claude Desktop muestra lo mismo con más metadatos porque habla con el proceso;
    desde disco esto es lo más fiel que se puede inferir.
    """
    patron = os.path.expanduser("~/.claude/projects/*/*/subagents/agent-*.jsonl")
    fuera = []
    ahora = time.time()
    for ruta in glob.glob(patron):
        proyecto = ruta.split(os.sep)[-4]
        if raiz_proyecto and not proyecto.startswith(slug(raiz_proyecto)):
            continue
        try:
            st = os.stat(ruta)
        except OSError:
            continue
        # Ventana de 24 h: un agente largo puede pasar horas sin escribir (esperando
        # una herramienta lenta) y la app lo sigue dando por "En ejecución".
        if ahora - st.st_mtime > 24 * 3600:
            continue
        try:
            prim = json.loads(_primera_linea(ruta))
            colas = _ultimas_lineas(ruta)
        except Exception:
            continue
        tokens = _tokens(colas)
        inicio = prim.get("timestamp", "")
        try:
            import calendar
            t0 = calendar.timegm(time.strptime(inicio[:19], "%Y-%m-%dT%H:%M:%S"))
            transcurrido = st.st_mtime - t0
        except Exception:
            transcurrido = 0
        fuera.append({
            "id": os.path.basename(ruta)[6:14],
            "titulo": (_descripcion_padre(os.sep.join(ruta.split(os.sep)[:-2]) + ".jsonl",
                                          os.path.basename(ruta)[6:-6])
                       or _titulo(_primera_linea(ruta))),
            "tokens": tokens,
            "activo": (ahora - st.st_mtime) < 300,
            "transcurrido": transcurrido,
            "ts": st.st_mtime,
            "ruta": ruta,
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


def _visible(linea):
    """Longitud sin contar los códigos de color."""
    import re
    return len(re.sub(r"\033\[[0-9;]*m", "", linea))


def _recortar(linea, ancho):
    if _visible(linea) <= ancho:
        return linea
    import re
    fuera, usado = [], 0
    for trozo in re.split(r"(\033\[[0-9;]*m)", linea):
        if trozo.startswith("\033"):
            fuera.append(trozo)
            continue
        queda = ancho - usado - 1
        if queda <= 0:
            break
        fuera.append(trozo[:queda])
        usado += len(trozo[:queda])
    return "".join(fuera) + "…" + RESET


def render(raiz_proyecto, ancho):
    ags = agentes(raiz_proyecto)
    # La salida de un subagente también cae en tasks/: sin esto sale dos veces
    ids_agente = {a["id"] for a in ags}
    trs = [t for t in tareas(raiz_proyecto) if not any(t["id"].startswith(i) for i in ids_agente)]
    L = []
    etiqueta = os.path.basename(raiz_proyecto) if raiz_proyecto else "todos los proyectos"
    L.append(f"{AZUL} {etiqueta[:ancho - 4]}{RESET}")
    L.append("")

    bgs = sesiones_bg(raiz_proyecto)
    if bgs:
        L.append(f"{MALVA}  Sesiones en background{RESET}")
        for b in bgs[:4]:
            c = VERDE if b["estado"] in ("running", "busy") else AMARILLO
            trozos = envolver(b["titulo"], ancho, 4)
            L.append(f"  {c}●{RESET} {TEXTO}{trozos[0]}{RESET}")
            for extra in trozos[1:2]:
                L.append(f"    {TEXTO}{extra}{RESET}")
            L.append(f"    {c}{b['estado']}{RESET}{GRIS} · {dur(b['transcurrido'])}{RESET}")
        L.append("")

    L.append(f"{MALVA}  Agentes{RESET}")
    if not ags:
        L.append(f"{GRIS}    ninguno aquí{RESET}")
    for a in ags[:5]:
        c = VERDE if a["activo"] else GRIS
        estado = "en curso" if a["activo"] else "inactivo"
        trozos = envolver(a["titulo"], ancho, 4)
        L.append(f"  {c}●{RESET} {TEXTO}{trozos[0]}{RESET}")
        for extra in trozos[1:3]:            # como mucho tres líneas de título
            L.append(f"    {TEXTO}{extra}{RESET}")
        tk = f"{a['tokens']/1000:.0f}k" if a["tokens"] >= 1000 else str(a["tokens"])
        L.append(f"    {c}{estado}{RESET}{GRIS} · {dur(a['transcurrido'])} · {tk} tok{RESET}")

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
    return [_recortar(l, ancho) for l in L]


def _mapa_padres():
    import subprocess
    out = subprocess.run(["ps", "-Ao", "pid=,ppid="], capture_output=True, text=True).stdout
    m = {}
    for l in out.splitlines():
        c = l.split()
        if len(c) == 2:
            m[int(c[0])] = int(c[1])
    return m


def _mapa_panes():
    import subprocess
    out = subprocess.run(
        ["tmux", "list-panes", "-a", "-F", "#{pane_pid}\t#{session_name}:#{window_index}.#{pane_index}"],
        capture_output=True, text=True).stdout
    m = {}
    for l in out.splitlines():
        c = l.split("\t")
        if len(c) == 2:
            m[int(c[0])] = c[1]
    return m


def pane_de(pid, padres, panes):
    """Sube por el árbol de procesos hasta dar con un pane de tmux."""
    cur, saltos = int(pid), 0
    while cur > 1 and saltos < 12:
        if cur in panes:
            return panes[cur]
        cur = padres.get(cur, 0)
        saltos += 1
    return ""


def lista(raiz_proyecto, pane_actual):
    """Filas para fzf:  ruta_transcripcion \t destino_tmux \t etiqueta"""
    padres, panes = _mapa_padres(), _mapa_panes()
    filas = []

    for f in glob.glob(os.path.expanduser("~/.claude/sessions/*.json")):
        try:
            with open(f, encoding="utf-8") as fh:
                d = json.load(fh)
        except Exception:
            continue
        pid = d.get("pid")
        try:
            os.kill(int(pid), 0)
        except Exception:
            continue
        cwd = d.get("cwd") or ""
        if raiz_proyecto and not (cwd == raiz_proyecto or cwd.startswith(raiz_proyecto + "/")):
            continue
        destino = pane_de(pid, padres, panes)
        # La transcripción de la sesión vive en projects/<slug>/<sessionId>.jsonl
        tr = os.path.expanduser(f"~/.claude/projects/{slug(cwd)}/{d.get('sessionId')}.jsonl")
        aqui = "▶ " if destino and destino == pane_actual else "  "
        tipo = "bg " if d.get("kind") == "bg" else "ses"
        est = d.get("status") or d.get("kind") or ""
        nombre = (d.get("name") or str(pid))[:30]
        donde = destino or "(app)"
        filas.append(f"{tr}\t{destino}\t{aqui}{tipo} {nombre}  ·{est}· {donde}")

    for a in agentes(raiz_proyecto):
        marca = "en curso" if a["activo"] else "inactivo"
        filas.append(f"{a['ruta']}\t\t   ag  {a['titulo'][:30]}  ·{marca}· {dur(a['transcurrido'])}")
    return filas


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cwd", default=None)
    ap.add_argument("--watch", type=float, default=0)
    ap.add_argument("--pick", action="store_true")
    ap.add_argument("--todos", action="store_true")
    ap.add_argument("--lista", action="store_true")
    ap.add_argument("--pane", default="")
    args = ap.parse_args()

    raiz = None if args.todos else os.path.realpath(args.cwd or os.getcwd())

    if args.lista:
        for f in lista(raiz, args.pane):
            print(f)
        return

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
