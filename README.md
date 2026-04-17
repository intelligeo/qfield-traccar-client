# QField Traccar Client

App-wide plugin per [QField](https://qfield.org/) che invia la posizione GPS del dispositivo a un server [Traccar](https://www.traccar.org/) usando il protocollo HTTP OsmAnd.

## Funzionalità

- Invio periodico della posizione GPS (latitudine, longitudine, altitudine, velocità, direzione, accuratezza)
- Intervallo di invio configurabile
- Pannello di configurazione integrato nell'interfaccia QField
- Log degli eventi in tempo reale (fino a 20 voci, ispirato a *StatusActivity* del client Android Traccar)
- Impostazioni persistenti tra le sessioni (URL server, Device ID, intervallo, stato tracking)

## Protocollo

```
GET http://<server>:<porta>?id=<deviceId>&timestamp=<unix>&lat=<lat>&lon=<lon>&speed=<speed>&bearing=<bearing>&altitude=<alt>&accuracy=<acc>
```

Compatibile con la porta OsmAnd di Traccar (default: `5055`).

## Installazione

1. Scaricare il file ZIP dalla [pagina Releases](https://github.com/intelligeo/qfield-traccar-client/releases)
2. In QField aprire **Impostazioni → Plugin**
3. Toccare **Installa plugin da URL** e incollare l'URL del file ZIP  
   oppure caricare il file ZIP direttamente dal dispositivo

## Configurazione

Dopo l'installazione toccare il pulsante ![icona cloud upload](icon.svg) nella toolbar di QField per aprire il pannello:

| Campo | Descrizione | Default |
|---|---|---|
| Server URL | Indirizzo del server Traccar | `http://traccar.intelligeo.net:5055` |
| Device ID | Identificativo univoco del dispositivo | `qfield-device-1` |
| Intervallo | Secondi tra un invio e l'altro | `10` |

## Packaging

Lo script `package.py` crea il file ZIP pronto per il deploy:

```bash
python package.py
# oppure specificando la cartella di output:
python package.py --output /percorso/output
```

Il file ZIP viene generato in `dist/` con il nome `qfield-traccar-client-v<version>.zip`.  
La versione è letta automaticamente da `metadata.txt`.

## File del plugin

| File | Descrizione |
|---|---|
| `main.qml` | Logica e UI del plugin (QML/JS) |
| `metadata.txt` | Nome, versione, autore, icona |
| `icon.svg` | Icona del plugin |

## Requisiti

- QField ≥ 3.x (con supporto app-wide plugin)
- Server Traccar ≥ 5.x

## Licenza

[GPL-2.0](LICENSE)

## Autore

INTELLIGEO.ch — Dr. Sara Lanini-Maggi
