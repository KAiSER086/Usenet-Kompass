# 7.0 Jellyfin & Jellyseerr: Das Frontend deiner Mediathek

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

#### ⚡ Optional: Hardware-Transcoding mit Intel QuickSync (QSV) aktivieren

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

## Was ist Jellyseerr?

**Jellyseerr** ist ein modernes Medien-Anfrageportal mit schicker Netflix-ähnlicher Oberfläche. Es dient als Schnittstelle zwischen deinen Nutzern und deinem Download-Stack.

Anstatt manuell nach Film- oder Serientiteln gefragt zu werden, können Mitnutzer direkt in Jellyseerr suchen, Trailer ansehen und mit einem Klick auf **„Anfragen“** den Download auslösen.

* **Automatisierung:** Neue Anfragen werden automatisch an Radarr (Filme) oder Sonarr (Serien) weitergereicht.
* **Statusanzeige:** Nutzer sehen direkt, ob ein Titel bereits vorhanden, angefragt oder gerade im Download ist.

---

## 7.2 Jellyseerr zum Docker-Stack hinzufügen

Füge Jellyseerr zu deiner `docker-compose.yml` hinzu:

```yaml
  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    volumes:
      - ./config/jellyseerr:/app/config
    ports:
      - 5055:5055
    depends_on:
      - radarr
      - sonarr
      - gluetun
    restart: unless-stopped
```

Stack aktualisieren:

```bash
docker compose up -d
```

---

### Jellyseerr konfigurieren

Öffne `http://<deine-tailscale-ip>:5055` im Browser und folge dem Einrichtungsassistenten:

1. **Mit Jellyfin verbinden:**
   * Melde dich mit deinem Jellyfin-Konto an.
   * **Jellyfin-URL:** `http://jellyfin:8096` (oder `http://<deine-server-ip>:8096`).
   * Wähle die zu synchronisierenden Mediatheken aus.

2. **Radarr & Sonarr verbinden:**
   > ⚠️ **Wichtig für das Docker-Netzwerk:** Da Radarr und Sonarr über das Netzwerk von `gluetun` laufen, erreichst du sie innerhalb des Docker-Netzwerks über den Hostnamen **`gluetun`** (oder alternativ über die IP deines Servers).

   * **Radarr (Filme):**
     * **Hostname / IP:** `gluetun` (oder deine Server-IP)
     * **Port:** **`7878`**
     * **API Key:** Aus Radarr unter *Einstellungen > Allgemein > Sicherheit*.
   * **Sonarr (Serien):**
     * **Hostname / IP:** `gluetun` (oder deine Server-IP)
     * **Port:** **`8989`**
     * **API Key:** Aus Sonarr unter *Einstellungen > Allgemein > Sicherheit*.

3. **Fertigstellen:** Nun ist dein automatisierter Medien-Workflow komplett einsatzbereit!