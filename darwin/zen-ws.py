"""Abre URLs en Zen, en el contenedor de la organización de ws.

    zen-ws [--contenedor NOMBRE] URL...

Sin --contenedor, la organización sale del contexto de ws: WS_CONTEXTO (lo pone
el shim de gh/claude, y el navegador lo hereda) o `ws contexto` de la carpeta o
la sesión de tmux. El contenedor se llama como la organización (`nombre`) y
lleva el color de su etiqueta de Finder. Sin contexto, Zen sin contenedor.

Zen no sabe abrir una URL en un contenedor desde fuera: lo hace la extensión
"Open external links in a container" con enlaces ext+container:, y crea el
contenedor si no existe. Es cosa de este Mac, no de ws: lo usa [navegadores]
del ws.toml privado.
"""
import importlib.util
import json
import os
import subprocess
import sys
import tomllib
from pathlib import Path
from urllib.parse import quote

CONFIG = Path("~/.config/ws/ws.toml").expanduser()
WS = f"/etc/profiles/per-user/{os.environ.get('USER', '')}/bin/ws"
# Colores de las etiquetas de Finder → colores de los contenedores de Firefox/Zen
COLOR_ZEN = {1: "toolbar", 2: "green", 3: "purple", 4: "blue", 5: "yellow", 6: "red", 7: "orange"}

_spec = importlib.util.spec_from_file_location("ws_etiquetas", Path(__file__).with_name("ws-etiquetas.py"))
etiquetas = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(etiquetas)


def grupo_actual():
    contexto = os.environ.get("WS_CONTEXTO")
    if contexto:
        return contexto.split("/")[0]
    try:
        r = subprocess.run([WS, "contexto", "--json"], capture_output=True, text=True, timeout=5)
        return json.loads(r.stdout or "{}").get("grupo")
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return None


def contenedor(cfg, grupo):
    """(nombre, color, icono) del contenedor del grupo, o None."""
    for seccion, icono in (("organizaciones", "briefcase"), ("entornos", "circle")):
        g = cfg.get(seccion, {}).get(grupo)
        if g:
            _, color = etiquetas.marcas(cfg).get(grupo, (None, 0))
            return g.get("nombre") or grupo, COLOR_ZEN.get(color, "toolbar"), icono
    return None


def main():
    args = sys.argv[1:]
    nombre = None
    if args[:1] == ["--contenedor"]:
        nombre, args = args[1], args[2:]
    cfg = tomllib.loads(CONFIG.read_text()) if CONFIG.exists() else {}
    destino = None
    if nombre:
        destino = (nombre, "toolbar", "briefcase")
        for seccion in ("organizaciones", "entornos"):
            for clave, g in cfg.get(seccion, {}).items():
                if (g.get("nombre") or clave) == nombre:
                    destino = contenedor(cfg, clave)
    elif (grupo := grupo_actual()):
        destino = contenedor(cfg, grupo)
    for url in args:
        if destino:
            n, color, icono = destino
            url = (f"ext+container:name={quote(n)}&color={color}&icon={icono}"
                   f"&url={quote(url, safe='')}")
        subprocess.run(["/usr/bin/open", "-a", "Zen", url])


if __name__ == "__main__":
    main()
