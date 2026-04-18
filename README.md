# QField Traccar Client

App-wide plugin for [QField](https://qfield.org/) that sends the device GPS position to a [Traccar](https://www.traccar.org/) server using the OsmAnd HTTP protocol.

## Features

- Periodic GPS position reporting (latitude, longitude, altitude, speed, bearing, accuracy)
- Configurable reporting interval
- Settings panel integrated directly in the QField UI
- Real-time event log (up to 20 entries, inspired by the *StatusActivity* of the Traccar Android client)
- Persistent settings across sessions (server URL, device ID, interval, tracking state)

## Protocol

```
GET http://<server>:<port>?id=<deviceId>&timestamp=<unix>&lat=<lat>&lon=<lon>&speed=<speed>&bearing=<bearing>&altitude=<alt>&accuracy=<acc>
```

Compatible with the Traccar OsmAnd port (default: `5055`).

## Installation

1. Download the ZIP file from the [Releases page](https://github.com/intelligeo/qfield-traccar-client/releases)
2. In QField open **Settings → Plugins**
3. Tap **Install plugin from URL** and paste the ZIP file URL,  
   or load the ZIP file directly from the device

## Configuration

After installation, tap the ![cloud upload icon](icon.svg) button in the QField toolbar to open the settings panel:

| Field | Description | Default |
|---|---|---|
| Server URL | Traccar server address | `http://traccar.intelligeo.net:5055` |
| Device ID | Unique device identifier | `qfield-device-1` |
| Interval | Seconds between each position report | `10` |

## Packaging

The `package.py` script builds a deploy-ready ZIP file:

```bash
python package.py
# or specifying a custom output folder:
python package.py --output /path/to/output
```

The ZIP is generated in `dist/` with the name `qfield-traccar-client-v<version>.zip`.  
The version is read automatically from `metadata.txt`.  
If `lrelease` (Qt Linguist tool) is on `PATH` or in one of the well-known Qt installation paths, `.ts` translation files are compiled to `.qm` automatically before the ZIP is created.

> **Note:** `lrelease` is **not** bundled with QGIS. Install it via the [Qt Online Installer](https://www.qt.io/download-qt-installer) (Qt → Tools → Qt Linguist), then add `<Qt>/bin` to your `PATH`.

## Translations

All UI strings are wrapped in `qsTr()`. Translation files live in `i18n/`:

| File | Language |
|---|---|
| `i18n/traccar-client_en.ts` | English (en_US) |
| `i18n/traccar-client_it.ts` | Italian (it_IT) |
| `i18n/traccar-client_fr.ts` | French (fr_FR) |
| `i18n/traccar-client_de.ts` | German (de_CH) |

To add a new language, copy `traccar-client_it.ts`, rename it to `traccar-client_<locale>.ts` and translate the `<translation>` elements.  
Compile with `lrelease i18n/traccar-client_<locale>.ts`.

## Plugin files

| File | Description |
|---|---|
| `main.qml` | Plugin logic and UI (QML/JS) |
| `metadata.txt` | Name, version, author, icon |
| `icon.svg` | Plugin icon |

## Requirements

- QField ≥ 3.x (with app-wide plugin support)
- Traccar server ≥ 5.x

## License

[GPL-2.0](LICENSE)

## Author

INTELLIGEO.ch — Dr. Sara Lanini-Maggi
