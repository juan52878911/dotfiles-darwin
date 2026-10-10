"""Etiquetas de Finder para las carpetas de cada organización/entorno de ws.

Lee ws.toml y marca la raíz de cada grupo y la carpeta de cada proyecto con una
etiqueta de color: se ve en Finder y se busca con Spotlight (tag:<Organización>).
En el grupo: `etiqueta` (nombre o false para no poner ninguna) y `color`; por
defecto, su nombre y un color por orden. Respeta las etiquetas que pongas tú.

Es cosa de este Mac, no de ws: lo lanza el agente ws-etiquetas (darwin/home.nix)
al iniciar sesión y cada vez que cambia ws.toml.
"""
import os
import plistlib
import subprocess
import sys
import tomllib
from pathlib import Path

COLORES = {"ninguno": 0, "gris": 1, "verde": 2, "morado": 3, "azul": 4,
           "amarillo": 5, "rojo": 6, "naranja": 7}
POR_DEFECTO = ["azul", "verde", "morado", "naranja", "amarillo", "rojo", "gris"]
ATRIBUTO = "com.apple.metadata:_kMDItemUserTags"


def expandir(ruta):
    return Path(os.path.expanduser(ruta)) if ruta else None


def grupos(cfg):
    for seccion in ("organizaciones", "entornos"):
        for clave, datos in cfg.get(seccion, {}).items():
            yield clave, datos


def marcas(cfg):
    res = {}
    for i, (clave, g) in enumerate(grupos(cfg)):
        if g.get("etiqueta") is False:
            continue
        color = g.get("color", POR_DEFECTO[i % len(POR_DEFECTO)])
        res[clave] = (g.get("etiqueta") or g.get("nombre") or clave, COLORES.get(color, 0))
    return res


def leer(ruta):
    r = subprocess.run(["/usr/bin/xattr", "-px", ATRIBUTO, str(ruta)], capture_output=True, text=True)
    if r.returncode != 0:
        return []
    try:
        return plistlib.loads(bytes.fromhex(r.stdout.replace(" ", "").replace("\n", "")))
    except Exception:
        return []


def etiquetar(ruta, etiqueta, nombres_ws):
    """Pone la etiqueta del grupo y quita las de otros grupos; respeta las tuyas."""
    if not ruta or not ruta.exists():
        return
    actuales = leer(ruta)
    nuevas = [t for t in actuales if t.split("\n")[0] not in nombres_ws]
    nuevas.append(f"{etiqueta[0]}\n{etiqueta[1]}")
    if nuevas != actuales:
        datos = plistlib.dumps(nuevas, fmt=plistlib.FMT_BINARY).hex()
        subprocess.run(["/usr/bin/xattr", "-wx", ATRIBUTO, datos, str(ruta)], capture_output=True)


def main():
    config = Path(sys.argv[1] if len(sys.argv) > 1 else "~/.config/ws/ws.toml").expanduser()
    if not config.exists():
        return
    with open(config, "rb") as f:
        cfg = tomllib.load(f)
    m = marcas(cfg)
    nombres_ws = {n for n, _ in m.values()}
    for clave, g in grupos(cfg):
        if clave in m and g.get("raiz"):
            etiquetar(expandir(g["raiz"]), m[clave], nombres_ws)
    for clave, p in cfg.get("proyectos", {}).items():
        grupo = clave.split("/")[0]
        if grupo in m and p.get("ruta"):
            etiquetar(expandir(p["ruta"]), m[grupo], nombres_ws)


if __name__ == "__main__":
    main()
