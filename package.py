#!/usr/bin/env python3
"""
Pacchettizza il plugin QField in uno ZIP pronto per il deploy.

Regole (da https://api.qfield.org/):
  - main.qml deve risiedere alla radice dello ZIP
  - il nome dello ZIP deve rispecchiare il nome della cartella del plugin
  - il suffisso versione ha la forma  <plugin-folder>-v<version>.zip

Utilizzo:
    python package.py              # crea lo zip nella cartella padre
    python package.py --output .   # specifica la cartella di output
"""

import argparse
import configparser
import pathlib
import sys
import zipfile

PLUGIN_DIR = pathlib.Path(__file__).parent.resolve()

# File/cartelle da escludere dallo ZIP
EXCLUDE = {
    pathlib.Path(__file__).name,   # questo script
    "__pycache__",
    ".git",
    ".gitignore",
    "dist",
}


def read_version(metadata_path: pathlib.Path) -> str:
    cfg = configparser.ConfigParser()
    cfg.read(metadata_path, encoding="utf-8")
    try:
        return cfg["general"]["version"].strip()
    except KeyError:
        print("ERRORE: 'version' non trovata in metadata.txt", file=sys.stderr)
        sys.exit(1)


def collect_files(base: pathlib.Path) -> list[pathlib.Path]:
    """Restituisce tutti i file da includere nello ZIP (percorsi relativi)."""
    files = []
    for item in sorted(base.rglob("*")):
        if item.is_file():
            rel = item.relative_to(base)
            # Esclude se una delle parti del percorso è nella lista EXCLUDE
            if not any(part in EXCLUDE for part in rel.parts):
                files.append(rel)
    return files


def build_zip(output_dir: pathlib.Path) -> pathlib.Path:
    metadata_path = PLUGIN_DIR / "metadata.txt"
    if not metadata_path.exists():
        print("ERRORE: metadata.txt non trovato.", file=sys.stderr)
        sys.exit(1)

    version = read_version(metadata_path)
    plugin_name = PLUGIN_DIR.name           # es. "qfield-traccar-client"
    zip_name = f"{plugin_name}-v{version}.zip"
    zip_path = output_dir / zip_name

    files = collect_files(PLUGIN_DIR)
    if not files:
        print("ERRORE: nessun file trovato da pacchettizzare.", file=sys.stderr)
        sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for rel in files:
            zf.write(PLUGIN_DIR / rel, arcname=rel.as_posix())
            print(f"  aggiunto: {rel.as_posix()}")

    return zip_path


def main():
    parser = argparse.ArgumentParser(description="Pacchettizza il plugin QField.")
    parser.add_argument(
        "--output", "-o",
        default=str(PLUGIN_DIR / "dist"),
        help="Cartella di output per lo ZIP (default: dist/ nella cartella del plugin)",
    )
    args = parser.parse_args()

    output_dir = pathlib.Path(args.output).resolve()
    print(f"Plugin dir : {PLUGIN_DIR}")
    print(f"Output dir : {output_dir}")

    zip_path = build_zip(output_dir)
    print(f"\nZIP creato : {zip_path}")


if __name__ == "__main__":
    main()
