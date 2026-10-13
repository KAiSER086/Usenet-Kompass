# 7.0 Jellyfin & Seerr: Das Frontend deiner Mediathek

## Jellyfin vs. Plex vs. Emby: Warum diese Wahl?

Als Medienserver gibt es drei bekannte Hauptlösungen: das weit verbreitete **Plex**, das quelloffene **Jellyfin** und das Freemium-Modell **Emby**. Für unser privates, selbstgehostetes Setup ist Jellyfin die beste Wahl:

* **100 % Open Source & kostenlos:** Alle Funktionen (Hardware-Transkodierung, Apps, Multi-User) sind ohne Paywall oder Abonnement frei verfügbar.
* **Volle Privatsphäre & Kontrolle:** Keine Abhängigkeit von externen Servern oder Cloud-Authentifizierungen.
* **Perfekt für Tailscale:** Jellyfin streamt direkt über deinen privaten Tailscale-Tunnel auf deine mobilen Endgeräte – ganz ohne Portweiterleitungen am Heimrouter.

---

## 7.1 Jellyfin zum Docker-Stack hinzufügen

Füge den folgenden Codeblock in deine `docker-compose.yml` ein:

```yaml
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    volumes:
      - ./config/jellyfin:/config
      - ./data/media:/data/media
    # Optional für Intel QuickSync Hardware-Transcoding:
    # devices:
    #   - /dev/dri:/dev/dri
    # group_add:
    #   - "107" # GID der Gruppe 'render' auf dem Host (siehe Anleitung unten)
    ports:
      - 8096:8096
    restart: unless-stopped
```

> **Wichtiger Hinweis zu den Pfaden (TRaSH-Guides):** Wir binden `./data/media:/data/media` ein. Damit greift Jellyfin direkt auf die von Sonarr und Radarr einsortierten Filme (`/data/media/movies`) und Serien (`/data/media/tv`) zu.

#### Optional: Hardware-Transcoding mit Intel QuickSync (QSV) aktivieren

Wenn du einen Mini-PC mit Intel-Prozessor (z. B. Intel N100 oder Core-i) nutzt, kann Jellyfin Videos extrem stromsparend über die integrierte Grafikeinheit transkodieren. Damit der Container mit deinem Benutzer (`PUID=1000`) auf die GPU zugreifen darf, benötigt er Zugriff auf die Gruppe `render`:

1. **Gruppen-ID (GID) auf deinem Host ermitteln:**
   ```bash
   getent group render | cut -d: -f3
   # Falls 'render' keine Ausgabe liefert, alternativ 'video' prüfen:
   getent group video | cut -d: -f3
   ```
2. Trage die ausgegebene Zahl (z. B. `107`) bei `group_add` ein und aktiviere `devices` sowie `group_add` in der `docker-compose.yml`.
3. In Jellyfin unter **Dashboard > Wiedergabe > Transkodierung** wählst du als Hardwarebeschleunigung **Intel QuickSync (QSV)** aus.

---

### Jellyfin konfigurieren

1. **Webinterface aufrufen:** Öffne `http://<deine-tailscale-ip>:8096` oder `http://deine-server-ip:8096` im Browser.
2. **Einrichtungsassistent:** Erstelle deinen Admin-Benutzer und wähle die Sprache.
3. **Mediatheken anlegen:**
   * **Filme:** Ordner `/data/media/movies` auswählen.
   * **Serien:** Ordner `/data/media/tv` auswählen.
4. **Fertig:** Jellyfin lädt nun automatisch Filmplakate, Beschreibungen und Metadaten herunter.

---

### 7.1.1 Die besten Jellyfin-Clients & Playback-Tipps (Direct Play garantieren)

Die Wahl des richtigen Abspiel-Clients entscheidet maßgeblich darüber, ob dein Server entspannt im **Direct Play** läuft oder unter Volllast transkodieren muss. Integrierte Smart-TV-Apps (LG webOS, Samsung Tizen) sind oft durch limitierte TV-Chipsätze eingeschränkt. Mit den richtigen dedizierten Clients holst du das Maximum heraus:

| Plattform | Empfohlene Clients | Besonderheiten |
| :--- | :--- | :--- |
| **Plattformübergreifend (iOS, Android, TV, Desktop)** | **[Moonfin](https://moonfin.io)** *(Design-Tipp)* | Äußerst schicker, moderner Open-Source-Client mit moderner UI, dynamischen Layouts, Multi-Server-Support und nativer Seerr-Anfrage-Integration. Verfügbar für Android, Android TV/Fire TV, iOS, Smart-TVs und Desktop. |
| **Apple (Apple TV 4K, iPad, iPhone)** | **[Infuse](https://firecore.com/infuse)**, **Swiftfin** | Eigene Rendering-Engine, spielt fast jedes Dolby Vision Profil, PGS-Untertitel und TrueHD/DTS nativ in Direct Play ohne Transcoding ab. **Swiftfin** ist der moderne, native Open-Source-Client. |
| **Android TV / Fire TV Stick** | **[Wholphin](https://github.com/damontecres/Wholphin)**, offizielle TV-App | **Wholphin** ist ein extrem schneller, moderner Community-Client mit ExoPlayer/LibVLC-Engine, der native Untertitel und Direct Play hervorragend meistert. Die offizielle TV-App ist im Play Store und Amazon Appstore verfügbar. |
| **Android (Smartphone & Tablet)** | **[Findroid](https://github.com/jarnedemeulemeester/findroid)**, offizielle App | Nativer Kotlin-Client mit integriertem MPV-Player für butterweiches Abspielen aller Codecs. |
| **LG webOS & Samsung Tizen** | Offizielle Jellyfin-Apps, **[Moonfin](https://moonfin.io)** | Die offiziellen Apps sind in den jeweiligen TV-Stores verfügbar. Moonfin bietet eine optisch ansprechende Alternative. |
| **PC / Laptop (Windows, macOS, Linux)** | **[Jellyfin Media Player (JMP)](https://github.com/jellyfin/jellyfin-media-player)** | Nutzt den legendären `mpv`-Videoplayer im Hintergrund. Spielt ausnahmslos jede Datei, jeden Codec und jeden Untertitel direkt ab. |

> [!TIP]
> **Wiedergabe-Informationen prüfen (Der Live-Check):**
> Klicke während der Wiedergabe im Jellyfin-Player auf das **Zahnrad > Wiedergabe-Informationen** (oder Playback Data).
> * **Direct Play:** Alles perfekt – 0 % CPU-Last auf dem Server.
> * **Transkodierung:** Jellyfin zeigt dir hier den **exakten Grund** an (z. B. `Audio-Codec nicht unterstützt`, `Bitrate zu hoch` oder `Untertitel-Format erfordert Einbrennen`). So weißt du sofort, an welcher Stellschraube du drehen musst!

---

## Was ist Seerr?

**Seerr** (der moderne Nachfolger aus der Fusion von Overseerr und Jellyseerr) ist ein komfortables Medien-Anfrageportal mit schicker Netflix-ähnlicher Oberfläche. Es dient als Schnittstelle zwischen deinen Nutzern und deinem Download-Stack.

Anstatt manuell nach Film- oder Serientiteln gefragt zu werden, können Mitnutzer direkt in Seerr suchen, Trailer ansehen und mit einem Klick auf **„Anfragen“** den Download auslösen.

* **Automatisierung:** Neue Anfragen werden automatisch an Radarr (Filme) oder Sonarr (Serien) weitergereicht.
* **Statusanzeige:** Nutzer sehen direkt, ob ein Titel bereits vorhanden, angefragt oder gerade im Download ist.

---

## 7.2 Seerr zum Docker-Stack hinzufügen

Füge Seerr zu deiner `docker-compose.yml` hinzu:

```yaml
  seerr:
    image: ghcr.io/seerr-team/seerr:latest
    container_name: seerr
    init: true
    environment:
      - TZ=Europe/Berlin
    volumes:
      - ./config/seerr:/app/config
    ports:
      - "5055:5055"
    depends_on:
      - radarr
      - sonarr
      # - gluetun # Nur einkommentieren, falls du das VPN-Setup mit Gluetun nutzt
    restart: unless-stopped
```

Stack aktualisieren:

```bash
docker compose up -d
```

---

### Seerr konfigurieren

Öffne `http://<deine-tailscale-ip>:5055` (oder `http://<deine-server-ip>:5055`) im Browser und folge dem Einrichtungsassistenten:

#### Schritt 1: Mit Jellyfin verbinden
* Melde dich mit deinem Jellyfin-Konto an.
* **Jellyfin-URL:** `http://jellyfin:8096` (oder `http://<deine-server-ip>:8096`).
* Wähle die zu synchronisierenden Mediatheken aus und klicke auf **Weiter**.

#### Schritt 2: Radarr & Sonarr verbinden

> [!NOTE]
> **Wichtig für das Docker-Netzwerk (je nach gewähltem Modus):**
> * **Ohne VPN (Direkt-Modus / Standard):** Alle Dienste laufen im regulären Docker-Bridge-Netzwerk. Seerr erreicht die Apps direkt und sauber über deren Dienstnamen:
>   * Hostname für Radarr: **`radarr`**
>   * Hostname für Sonarr: **`sonarr`**
> * **Mit VPN (Gluetun-Tunneling):** Radarr und Sonarr teilen sich den Netzwerk-Stack von Gluetun (`network_mode: "service:gluetun"`). Externe Container im Docker-Netzwerk (wie Seerr) erreichen sie über den Hostnamen des VPN-Containers:
>   * Hostname für Radarr & Sonarr: **`gluetun`** (oder alternativ deine Server-IP)

Navigiere in Seerr zu **Einstellungen > Dienste** und füge deine Server hinzu:

* **Radarr (Filme):**
  * **Standardserver:** Aktivieren
  * **Servername:** `Radarr`
  * **Hostname / IP:** **`radarr`** *(ohne VPN)* bzw. **`gluetun`** *(mit VPN)* – oder deine Server-IP
  * **Port:** **`7878`**
  * **API Key:** Aus Radarr unter *Einstellungen > Allgemein > Sicherheit*.
  * **Stammordner:** `/data/media/movies`

* **Sonarr (Serien):**
  * **Standardserver:** Aktivieren
  * **Servername:** `Sonarr`
  * **Hostname / IP:** **`sonarr`** *(ohne VPN)* bzw. **`gluetun`** *(mit VPN)* – oder deine Server-IP
  * **Port:** **`8989`**
  * **API Key:** Aus Sonarr unter *Einstellungen > Allgemein > Sicherheit*.
  * **Stammordner:** `/data/media/tv`

#### Schritt 3: Fertigstellen
Klicke bei beiden Servern auf **„Verbindung testen“** und anschließend auf **„Speichern“**. Nun ist dein automatisierter Medien-Workflow komplett einsatzbereit!

---

| Vorheriges Kapitel | Inhaltsverzeichnis | Nächstes Kapitel |
| :--- | :---: | ---: |
| [**6.0 Arr-Stack**](../Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md) | [**Inhaltsverzeichnis**](../README.md#inhaltsverzeichnis) | [**8.0 Finaler Stack**](../Docker%20Compose%20Stack/Finaler%20Stack.md) |