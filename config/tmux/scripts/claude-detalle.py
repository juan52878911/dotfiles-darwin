#!/usr/bin/env python3
"""Detalle en vivo de una sesión o agente de Claude Code.

  claude-detalle.py <ruta.jsonl> [--seguir]

Traduce el JSONL de la transcripción a algo legible: qué herramienta usa, qué
responde, cuántos tokens lleva. Con --seguir se queda leyendo el final del
fichero, así que el panel lo muestra en tiempo real.
"""
import json
import os
import sys
import time

MALVA = "\033[38;2;203;166;247m"
VERDE = "\033[38;2;166;227;161m"
AZUL = "\033[38;2;137;180;250m"
AMARILLO = "\033[38;2;249;226;175m"
GRIS = "\033[38;2;108;112;134m"
TEXTO = "\033[38;2;205;214;244m"
RESET = "\033[0m"


def hora(iso):
    try:
        return iso[11:19]
    except Exception:
        return "--:--:--"


# Bloques que son fontanería interna, no lo que el agente está haciendo.
RUIDO = (
    "<task-notification>", "<tool-use-id>", "<output-file>", "<task-id>",
    "<local-command-caveat>", "<system-reminder>", "<command-name>",
    "Async agent launched successfully", "This tool result is internal metadata",
    "Caveat: The messages below were generated",
)


def _es_ruido(txt):
    return any(m in txt for m in RUIDO)


def resumir(cruda):
    """Convierte un registro del JSONL en una línea legible, o None si no aporta."""
    try:
        d = json.loads(cruda)
    except Exception:
        return None
    t = hora(d.get("timestamp", ""))
    m = d.get("message") or {}
    contenido = m.get("content")

    if isinstance(contenido, str):
        txt = " ".join(contenido.split())
        if not txt or _es_ruido(txt):
            return None
        rol = m.get("role", d.get("type", ""))
        col = AZUL if rol == "user" else TEXTO
        return f"{GRIS}{t}{RESET} {col}{txt[:150]}{RESET}"

    if not isinstance(contenido, list):
        return None

    partes = []
    for b in contenido:
        if not isinstance(b, dict):
            continue
        tipo = b.get("type")
        if tipo == "text":
            txt = " ".join((b.get("text") or "").split())
            if txt and not _es_ruido(txt):
                partes.append(f"{TEXTO}{txt[:220]}{RESET}")
        elif tipo == "tool_use":
            nombre = b.get("name", "?")
            ent = b.get("input") or {}
            pista = ent.get("command") or ent.get("file_path") or ent.get("pattern") or ent.get("description") or ""
            pista = " ".join(str(pista).split())[:80]
            partes.append(f"{AMARILLO}󰊕 {nombre}{RESET} {GRIS}{pista}{RESET}")
        elif tipo == "tool_result":
            cont = b.get("content")
            if isinstance(cont, list):
                cont = " ".join(str(x.get("text", "")) for x in cont if isinstance(x, dict))
            cont = " ".join(str(cont or "").split())
            if _es_ruido(cont):
                continue
            estado = ROJO_ERR if b.get("is_error") else VERDE
            partes.append(f"{estado}   ↳{RESET} {GRIS}{cont[:110]}{RESET}")
    if not partes:
        return None
    return f"{GRIS}{t}{RESET} " + "\n".join(partes) if len(partes) == 1 else \
           f"{GRIS}{t}{RESET} " + ("\n" + " " * 9).join(partes)


ROJO_ERR = "\033[38;2;243;139;168m"


def cabecera(ruta):
    nombre = os.path.basename(ruta)
    if nombre.startswith("agent-"):
        return f"{MALVA}  agente {nombre[6:14]}{RESET}"
    return f"{MALVA}  sesión {nombre[:8]}{RESET}"


def ultimas(ruta, n=40, cola=400000):
    with open(ruta, "rb") as fh:
        fh.seek(0, os.SEEK_END)
        fin = fh.tell()
        fh.seek(max(0, fin - cola))
        trozo = fh.read()
    return [l for l in trozo.split(b"\n") if l.strip()][-n:], fin


def visor(ruta):
    """Visor tipo log: pinta el final y se queda siguiendo el fichero.

    Se hace a mano en vez de con `less -R +F` o `fzf` por dos motivos:
      · `less` no puede atar esc a "salir" (allí esc es prefijo de secuencias).
      · `fzf --tac` espera el EOF de la entrada, y un tail infinito no lo da:
        la ventana salía vacía y no cerraba.
    Al imprimir sin más, el terminal desplaza solo, así que SIEMPRE se ve lo
    último — que es de lo que se trata.
    """
    import termios
    import threading
    import tty

    print(cabecera(ruta))
    print()
    lineas, pos = ultimas(ruta, n=200)
    for l in lineas:
        r = resumir(l)
        if r:
            print(r)
    sys.stdout.flush()

    if not sys.stdin.isatty():
        return

    # Lectura de teclas en un hilo con read BLOQUEANTE.
    # Con select() sobre sys.stdin la tecla no llegaba a verse (el envoltorio de
    # texto de Python se interpone); un read bloqueante en su propio hilo no tiene
    # esa sutileza.
    salir = threading.Event()

    def escuchar():
        while not salir.is_set():
            try:
                k = os.read(sys.stdin.fileno(), 1)
            except OSError:
                break
            if not k or k in (b"\x1b", b"q", b"Q"):
                salir.set()
                break

    viejo = termios.tcgetattr(sys.stdin)
    try:
        tty.setcbreak(sys.stdin.fileno())
        hilo = threading.Thread(target=escuchar, daemon=True)
        hilo.start()
        fh = open(ruta, "rb")
        fh.seek(pos)
        while not salir.is_set():
            linea = fh.readline()
            if not linea:
                salir.wait(0.4)
                continue
            r = resumir(linea)
            if r:
                print(r)
                sys.stdout.flush()
    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, viejo)


def main():
    if len(sys.argv) < 2:
        print("uso: claude-detalle.py <ruta.jsonl> [--seguir]")
        return
    ruta = sys.argv[1]
    seguir = "--seguir" in sys.argv
    if "--visor" in sys.argv:
        if not os.path.exists(ruta):
            print(f"{GRIS}  sin transcripción todavía{RESET}")
            return
        visor(ruta)
        return
    if not os.path.exists(ruta):
        print(f"{GRIS}  sin transcripción todavía{RESET}")
        return

    print(cabecera(ruta))
    print()
    lineas, pos = ultimas(ruta)
    for l in lineas:
        r = resumir(l)
        if r:
            print(r)
    sys.stdout.flush()

    if not seguir:
        return

    # Seguir el fichero: solo lo nuevo, sin repintar nada de lo anterior
    with open(ruta, "rb") as fh:
        fh.seek(pos)
        while True:
            linea = fh.readline()
            if not linea:
                time.sleep(0.7)
                continue
            r = resumir(linea)
            if r:
                print(r)
                sys.stdout.flush()


if __name__ == "__main__":
    main()
