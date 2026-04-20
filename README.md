# QField Traccar Client

App-wide plugin for [QField](https://qfield.org/) that sends the device GPS position to a [Traccar](https://www.traccar.org/) server using the OsmAnd HTTP protocol.

## Features

- Periodic GPS position reporting (latitude, longitude, altitude, speed, bearing, accuracy)
- Configurable reporting interval
- Settings panel integrated directly in the QField UI
- Real-time event log (up to 20 entries, inspired by the *StatusActivity* of the Traccar Android client)
- Persistent settings across sessions (server URL, device ID, interval, tracking state)

## Screenshots

| Load | Seek | Connected | Some error |
|---|---|---|---|
|<img src="screenshots/1_open.jpg" width="200"/>|<img src="screenshots/2_seek.jpg" width="200"/>|<img src="screenshots/3_connect.jpg" width="200"/>|<img src="screenshots/4_error.jpg" width="200"/>|

## Use Cases

Real-time GPS tracking adds clear value in a wide range of field survey scenarios:

- **Utility & infrastructure inspection** — track inspection crews across large pipeline, powerline or road networks; supervisors can monitor progress in real time and re-deploy teams without radio calls.
- **Environmental monitoring campaigns** — log the exact path followed during vegetation, water quality or soil sampling transects so samples can later be correlated with the surveyor's exact trajectory.
- **Search & rescue coordination** — deploy QField-equipped teams in rugged terrain and monitor their positions live on the Traccar map to coordinate search grids and ensure no area is missed.
- **Archaeological or geological survey** — record the walked track alongside point features collected in QField, producing a complete audit trail of "where was the geologist/archaeologist at every moment".
- **Forestry and land management** — verify that all parcels in a large concession have actually been visited during inspection rounds, using the stored track as legal evidence of compliance.
- **Disaster response & damage assessment** — dispatch multiple field teams after an earthquake or flood; HQ can see instantly which zones have been assessed and which still need coverage.
- **Construction site supervision** — confirm that quality-control inspectors have walked every section of a worksite, and flag if a team stays static for too long (possible incident alert).
- **Multi-team topographic campaigns** — when several surveyors work in parallel, the project manager can prevent duplicate coverage and dynamically assign new areas as zones are completed.
- **Remote lone-worker safety** — satisfy duty-of-care requirements by proving a field technician working alone in an isolated area is moving normally; trigger an alert if the device stops reporting.
- **Wildlife or biodiversity transects** — register the surveyor's exact path so species observations collected in QField can be spatially joined to the walked transect for density-estimation analyses.

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

After installation, tap the plugin's button in the QField toolbar to open the settings panel:

| Field | Description | Default |
|---|---|---|
| Server URL | Traccar server address | `http://demo3.traccar.org:5055` |
| Device ID | Unique device identifier | `qfield-device-1` |
| Interval | Seconds between each position report | `10` |

## Requirements

- QField ≥ 3.x (with app-wide plugin support)
- Traccar server ≥ 5.x

## License

[GPL-2.0](LICENSE)

## Author

INTELLIGEO.ch — Dr. Sara Lanini-Maggi
