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
import shutil
import subprocess
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

# Candidati per lrelease (compilatore traduzioni Qt).
# lrelease non è incluso in QGIS; installarlo con:
#   winget install --id=TheQtCompany.QtOnlineInstaller  (poi Qt > Tools > Qt Linguist)
# oppure scaricare QtTools standalone da https://download.qt.io/official_releases/qt/
LRELEASE_CANDIDATES = [
    "lrelease",
    r"C:\Qt\6.7.0\mingw_64\bin\lrelease.exe",
    r"C:\Qt\5.15.2\msvc2019_64\bin\lrelease.exe",
    r"C:\Program Files\QGIS 3.40.7\apps\qt5\bin\lrelease.exe",
    r"C:\OSGeo4W\apps\Qt5\bin\lrelease.exe",
]


def find_lrelease() -> str | None:
    for candidate in LRELEASE_CANDIDATES:
        if shutil.which(candidate):
            return candidate
        if pathlib.Path(candidate).is_file():
            return candidate
    return None


def compile_translations(base: pathlib.Path) -> None:
    i18n_dir = base / "i18n"
    ts_files = list(i18n_dir.glob("*.ts")) if i18n_dir.exists() else []
    if not ts_files:
        return

    lrelease = find_lrelease()
    if not lrelease:
        print("  [ATTENZIONE] lrelease non trovato: le traduzioni .ts non verranno compilate.")
        print("               Installa Qt Tools o aggiungi lrelease al PATH.")
        return

    for ts in ts_files:
        qm = ts.with_suffix(".qm")
        result = subprocess.run([lrelease, str(ts), "-qm", str(qm)],
                                capture_output=True, text=True)
        if result.returncode == 0:
            print(f"  compilato: {qm.relative_to(base).as_posix()}")
        else:
            print(f"  [ERRORE] lrelease su {ts.name}: {result.stderr.strip()}")


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
            if any(part in EXCLUDE for part in rel.parts):
                continue
            # Esclude i sorgenti di traduzione (si distribuiscono i .qm compilati)
            if item.suffix == ".ts":
                continue
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

    # Compila le traduzioni .ts → .qm prima di creare lo ZIP
    compile_translations(PLUGIN_DIR)

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
