# 6.0 Prowlarr, Sonarr und Radarr

## 6.1 Was ist der "Arr"-Stack?

Die **"Arr"-Apps** (Prowlarr, Radarr, Sonarr etc.) bilden das automatische Kontrollzentrum deines privaten Medienservers. Sie eliminieren das fehleranfällige manuelle Suchen, Herunterladen, Entpacken und Einsortieren von Medien:

* **Prowlarr:** Der zentrale Proxy und Indexer-Manager. Du hinterlegst deine Usenet-Indexer (z. B. *Treasure-Maps*, *NewzBay*, *NZBGeek*, *DrunkenSlug*) nur ein einziges Mal in Prowlarr. Die App testet die Schnittstellen, überwacht API-Limits und synchronisiert die Such- und RSS-Feeds vollautomatisch mit Sonarr und Radarr.
* **Radarr:** Der spezialisierte Film-Manager. Radarr überwacht Wunschlisten, sucht anhand konfigurierter Qualitäts- und Sprachprofile nach Veröffentlichungen, übergibt NZB-Dateien an den Downloader (SABnzbd oder NZBGet) und importiert den fertigen Film nach Abschluss strukturiert in deine Mediathek.
* **Sonarr:** Der Serien-Manager. Identisch im Konzept zu Radarr, aber optimiert für die komplexe Episoden- und Staffel-Logik von TV-Serien, Daily Shows und Anime (inkl. Staffelpakete, automatische Umbenennung und Qualitäts-Upgrades bei besseren Releases).

---

## 6.2 Docker-Konfiguration & TRaSH-Volume-Struktur

Füge die folgenden Dienste zu deiner bestehenden `docker-compose.yml`-Datei hinzu:

```yaml
services:
  gluetun:
    # ... Deine bestehende Gluetun-Konfiguration
    # Hier stehen deine gemappten Ports (8080, 6789, 7878, 8989, 9696)
    
  sabnzbd: # oder nzbget
    # ... Deine bestehende Downloader-Konfiguration
    
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=1000 # Deine Benutzer-ID (id -u)
      - PGID=1000 # Deine Gruppen-ID (id -g)
      - TZ=Europe/Berlin
    volumes:
      - ./config/prowlarr:/config
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    volumes:
      - ./config/sonarr:/config
      - ./data:/data
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - sabnzbd # oder nzbget
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    volumes:
      - ./config/radarr:/config
      - ./data:/data
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - sabnzbd # oder nzbget
    restart: unless-stopped
```

---

### Das TRaSH-Guides Speicherprinzip: Instant Atomic Moves statt Slow Copy

Die Dateistruktur ist das technische Fundament eines performanten Stacks. Wir setzen konsequent auf den **TRaSH-Guides Standard**:

```text
/data/
├── usenet/
│   ├── incomplete/       <-- Temporäre Download-Fragmente (SABnzbd / NZBGet)
│   └── complete/         <-- Fertig entpackte Downloads
│       ├── movies/       <-- Download-Kategorie "movies" (Radarr)
│       └── tv/           <-- Download-Kategorie "tv" (Sonarr)
└── media/
    ├── movies/           <-- Radarr Root Folder & Jellyfin Filme
    └── tv/               <-- Sonarr Root Folder & Jellyfin Serien
```

> [!IMPORTANT]
> **Warum getrennte Mounts (`/downloads` & `/movies`) die Performance zerstören:**
> Werden Downloads und Mediathek als getrennte Docker-Volumes eingebunden (z. B. `- ./downloads:/downloads` und `- ./movies:/movies`), behandelt der Linux-Kernel sie als zwei physikalisch voneinander isolierte Dateisysteme.
> * **Der I/O-Flaschenhals (Slow Copy):** Ein Import über Dateisystemgrenzen hinweg (`EXDEV: cross-device link not permitted`) zwingt das System dazu, jeden 30-GB-Film **vollständig von A nach B zu lesen, neu zu schreiben und die Quelle danach zu löschen**. Auf HDDs, NAS-Laufwerken oder einem Raspberry Pi führt das zu 100 % Festplattenauslastung, Systemrucklern und langen Verzögerungen.
> * **Die Lösung (Instant Atomic Move):** Durch das einheitliche Root-Volume `- ./data:/data` liegen Downloads und Mediathek auf **demselben Dateisystem**. Sonarr und Radarr verschieben fertige Dateien via `rename()` in **Bruchteilen einer Millisekunde** (`Instant Move`). Es werden lediglich Zeiger im Dateisystem aktualisiert – ohne Festplattenabnutzung, ohne Schreibzeit und ohne CPU-Last.
> * *Hinweis zu Hardlinks:* Solltest du neben dem Usenet auch Torrents betreiben (wo Quelldateien zum Seeden erhalten bleiben müssen), funktionieren auch Hardlinks technisch **ausschließlich** innerhalb desselben Dateisystem-Mounts (`/data`).

Falls du eine externe Festplatte oder ein NAS-Verzeichnis nutzt (z. B. gemountet unter `/mnt/medien`), binde dieses Verzeichnis einfach als Basis für `/data` ein:

```yaml
    volumes:
      - ./config/sonarr:/config
      - /mnt/medien:/data
```

### Dateiberechtigungen auf dem Host setzen

Damit alle Container reibungslos schreiben dürfen:

```bash
# Zeigt PUID und PGID deines Host-Benutzers
id

# Rechte rekursiv zuweisen (1000 durch deine tatsächliche PUID/PGID ersetzen)
sudo chown -R 1000:1000 ./data
sudo chmod -R 755 ./data
```

---

## 6.3 "Arr"-Apps konfigurieren

### 6.3.1 Prowlarr einrichten & DACH-Kategorien konfigurieren

Prowlarr fungiert als Schaltzentrale für alle Suchanfragen.

1. **Webinterface aufrufen:** Öffne `http://<deine-tailscale-ip>:9696` (oder deine Server-IP) im Browser und erstelle dein Admin-Konto.
2. **Download-Client verbinden:**
   * Gehe zu **Settings > Download Clients** und klicke auf **(+)**.
   * Wähle **SABnzbd** (Port `8080`) oder **NZBGet** (Port `6789`).
   * **Host:** `127.0.0.1` (da beide Apps im gemeinsamen Gluetun-Netzwerk laufen).
   * **API-Key:** Aus SABnzbd/NZBGet eintragen und speichern.
3. **Indexer hinzufügen:**
   * Navigiere zu **Indexers > (+)** und wähle deine Usenet-Indexer (z. B. *Treasure-Maps*, *NewzBay*, *NZBGeek*, *DrunkenSlug*).
   * Trage deine Zugangsdaten / API-Keys ein.

#### 🇩🇪 DACH-Spezifika: Newznab-Kategorien & Sync-Profile

Deutsche Indexer strukturieren Releases häufig über spezifische Newznab-Kategorie-IDs. Werden in den Sync-Profilen für Sonarr und Radarr nur englischsprachige Standard-Kategorien hinterlegt, ignorieren Sonarr und Radarr deutsche Releases bei automatischen Suchläufen und RSS-Feeds komplett!

| Medium / Typ | Standard-ID | DACH-spezifische IDs & Bedeutung | Relevanz für DACH-Setups |
| :--- | :---: | :--- | :--- |
| **Filme / HD** | `2040` | `2060` (German / Multi), `2000` (Allgemein Filme) | **Kritisch:** Viele DE-Indexer taggen 1080p German/DL hier. |
| **Filme / UHD (4K)** | `2045` | `2045` (4K / 2160p HDR/DV) | Standard für hochauflösende Film-Releases. |
| **Serien / HD** | `5040` | `5020` (Foreign/DE), `5000` (Allgemein TV) | **Kritisch:** Deutsche 720p/1080p Serienfolgen. |
| **Serien / UHD (4K)** | `5045` | `5045` (4K / 2160p) | 4K-Episoden moderner Streaming-Serien. |
| **Serien / Staffelpakete** | `5070` | `5070`, `5080` (Season Packs) | **Unerlässlich:** Ermöglicht den Download kompletter Staffeln. |
| **Serien / SD** | `5030` | `5030` (Standard Definition) | Wichtig für ältere Serienklassiker ohne HD-Remaster. |

**Sonarr- & Radarr-Synchronisation in Prowlarr einrichten:**
1. Gehe zu **Settings > Applications** und klicke auf **(+)**.
2. Wähle **Sonarr** bzw. **Radarr** aus:
   * **Prowlarr Server:** `http://127.0.0.1:9696`
   * **Sonarr/Radarr Server:** `http://127.0.0.1:8989` (Sonarr) bzw. `http://127.0.0.1:7878` (Radarr)
   * **API Key:** Aus der jeweiligen App unter *Settings > General > Security* kopieren.
3. **Sync Categories anpassen:**
   * **Für Radarr:** Stelle sicher, dass neben `2000`, `2040`, `2045` auch explizit **`2060`** (oder sonstige vom Indexer genutzte DE-Kategorien) ausgewählt sind.
   * **Für Sonarr:** Aktiviere neben `5000`, `5040`, `5045` unbedingt **`5020`**, **`5030`** sowie **`5070` / `5080`** (Season Packs).
4. **Speichern:** Prowlarr überträgt nun alle Indexer mitsamt der korrekten DACH-Kategorien an Sonarr und Radarr.

---

### 6.3.2 Sonarr & Radarr einrichten

* **Webinterfaces öffnen:**
  * **Sonarr:** `http://<deine-tailscale-ip>:8989`
  * **Radarr:** `http://<deine-tailscale-ip>:7878`

#### 1. Root-Ordner (Mediathek) hinterlegen
* Navigiere zu **Settings > Media Management**.
* Klicke ganz unten auf **Add Root Folder**:
  * In Sonarr: `/data/media/tv`
  * In Radarr: `/data/media/movies`

#### 2. Download-Client verbinden
* Gehe zu **Settings > Download Clients** und füge deinen Downloader hinzu:
  * **Typ:** SABnzbd (Port `8080`) oder NZBGet (Port `6789`).
  * **Host:** `127.0.0.1`
  * **API Key:** Deinen API-Key des Downloaders eintragen.
  * **Category:**
    * In Sonarr: **`tv`**
    * In Radarr: **`movies`**

> [!TIP]
> **Performance-Tipp für SABnzbd (Direct Unpack):**
> Aktiviere in SABnzbd unter **Einstellungen > Schalter** die Option **Direktes Entpacken (*Direct Unpack*)**.
> SABnzbd entpackt RAR-Archive dadurch bereits parallel während des Herunterladens, sobald die Segmente eintreffen. Wenn der Download fertiggestellt ist, ist die Datei sofort entpackt. Sonarr und Radarr können den Instant Move unmittelbar und ohne Wartezeit vollziehen.

> [!NOTE]
> **Warum du KEIN Remote Path Mapping brauchst:**
> In vielen veralteten Anleitungen wird das Einrichten von *Remote Path Mappings* beschrieben. Da in unserem Stack alle Container (SABnzbd, Sonarr, Radarr) denselben Mount `- ./data:/data` nutzen, stimmen die internen Pfade (`/data/usenet/complete/...`) zu 100 % überein.
> **Lass das Feld "Remote Path Mappings" leer!**
> 
> *Wann wird Remote Path Mapping überhaupt benötigt? (Troubleshooting/Fallback):*
> Nur dann, wenn dein Download-Client auf einem **externen physischen Server** oder einer externen Seedbox außerhalb deines Docker-Stacks läuft und Dateipfade zurückmeldet, die lokal an anderer Stelle eingehängt sind.

#### 3. Standardisierte TRaSH-Dateibenennung (*Media Management*)

Standardmäßig belassen Sonarr und Radarr die Dateinamen der Release-Gruppen oft unberührt. Das führt dazu, dass bei einem späteren Re-Scan oder Datenbank-Wiederherstellen essenzielle Metadaten (Audio-Codecs, HDR-Typen, Custom Formats) verloren gehen.

Aktiviere unter **Settings > Media Management**:
* **Rename Episodes / Rename Movies:** Auf `Yes` (Aktiviert) setzen.
* **Propers and Repacks:** Auf **`Do Not Prefer`** setzen *(Begründung: Repacks und Propers steuern wir gezielter und sauberer über Custom Formats)*.

**Empfohlene TRaSH-Benennungsformate hinterlegen:**

* **Radarr (Filme):**
  * **Standard Movie Format:**
    ```text
    {Movie CleanTitle} {(Release Year)} [imdbid-{ImdbId}] - [{Edition Tags} ]{[Custom Formats]}{[Quality Full]}{[MediaInfo VideoDynamicRangeType]}{[MediaInfo AudioCodec}{ MediaInfo AudioChannels}]{-Release Group}
    ```
  * **Movie Folder Format:**
    ```text
    {Movie CleanTitle} ({Release Year}) [imdbid-{ImdbId}]
    ```

* **Sonarr (Serien):**
  * **Standard Episode Format:**
    ```text
    {Series CleanTitle} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Custom Formats]}{[Quality Full]}{[MediaInfo VideoDynamicRangeType]}{[MediaInfo AudioCodec}{ MediaInfo AudioChannels}]{-Release Group}
    ```
  * **Series Folder Format:**
    ```text
    {Series CleanTitle} (tvdbid-{TvdbId})
    ```
  * **Season Folder Format:**
    ```text
    Season {season:00}
    ```

* **Ergebnis:**
  Dateien heißen danach z. B. strukturiert:
  `Dune Part Two (2024) [imdbid-tt15239678] - [German DL][Bluray-1080p][HDR][DTS-HD MA 5.1]-GROUP.mkv`.
  Damit wissen Jellyfin, Sonarr und Radarr zu jedem Zeitpunkt exakt, um welche Qualität, Edition und Tonspuren es sich handelt.

---

## 6.4 Deutsche Sprachprofile & Custom Formats (TRaSH Guides Scoring)

In der Vergangenheit wurden häufig statische Schlagwort-Filter genutzt (z. B. *„Must Contain: German“*). Dieser Ansatz ist heute veraltet und führt zu erheblichen Problemen:
* **Warum statische Tags schlecht sind:** Ein Release mit dem Tag `DL` (Dual Language), `Multi` oder `Ger.Dub` wird von einem simplen Wortfilter nach `German` oft übersehen oder verworfen.
* **Keine Flexibilität:** Du kannst keine Qualitätsabstufung vornehmen (z. B.: *„Nimm bevorzugt German DL. Falls nicht verfügbar, nimm reines Deutsch, und erst wenn gar nichts anderes existiert, den Originalton“*).

Die moderne Lösung sind **Custom Formats (CF)** mit punktebasierter Bewertung (*Scoring*) nach dem [TRaSH-Guides Standard](https://trash-guides.info/).

---

### Das empfohlene DACH-Scoring-Modell

Jedes gefundene Release wird von Sonarr/Radarr anhand seiner Metadaten und Release-Titel analysiert. Treffen Kriterien zu, werden Punkte addiert:

| Custom Format | Empfohlener Score | Zweck & Erklärung |
| :--- | :---: | :--- |
| **`German DL` (Dual Language)** | **`+1500`** | **Höchste Priorität:** Enthält deutsche Synchronisation UND englischen Originalton. Ermöglicht freie Sprachwahl im Player. |
| **`German` (Single Audio)** | **`+1000`** | **Solider Standard:** Reine deutsche Tonspur ohne Originalton. |
| **`German Forced` (Untertitel)** | **`+200`** | Bonus für erzwungene deutsche Untertitel bei fremdsprachigen Passagen (z. B. Klingonisch, Dothraki, Elbisch). |
| **Lossless Audio (DTS-HD / TrueHD / Atmos)** | **`+100`** | Bonus für hochwertige unkomprimierte Tonspuren bei Heimkino-Nutzung. |
| **x264 / AVC (für 1080p SDR)** | **`+50`** | Bevorzugt maximale Kompatibilität ohne Transkodierungsbedarf auf älteren Abspielgeräten. |
| **CAM / Telesync / Line-Dubbed** | **`-10000`** | **Ausschluss:** Schließt minderwertige Kinomitschnitte und Vorabveröffentlichungen garantiert aus. |

---

### Custom Formats in Sonarr & Radarr einbinden (Schritt für Schritt)

#### 1. Custom Formats importieren
1. Öffne in Sonarr bzw. Radarr **Settings > Custom Formats**.
2. Klicke auf das **Plus (+)** und wähle **Import**.
3. Kopiere die offiziellen JSON-Definitionen aus den TRaSH Guides:
   * **Radarr:** [TRaSH Guides Radarr Custom Formats](https://trash-guides.info/Radarr/Radarr-collection-of-custom-formats/#german)
   * **Sonarr:** [TRaSH Guides Sonarr Custom Formats](https://trash-guides.info/Sonarr/Sonarr-collection-of-custom-formats/#german)
4. Füge mindestens die Formate **`German DL`**, **`German`** und **`German Forced`** hinzu und speichere sie ab.

#### 2. Punkte (Scores) im Qualitätsprofil zuweisen
1. Navigiere zu **Settings > Profiles** und klicke auf dein gewünschtes Profil (z. B. `HD-1080p` oder erstelle ein neues Profil `1080p - German`).
2. Scrolle nach unten zum Bereich **Custom Formats**.
3. Trage die Punktzahlen gemäß der Tabelle oben ein:
   * `German DL` ➔ `1500`
   * `German` ➔ `1000`
   * `German Forced` ➔ `200`
4. **Upgrades & Schwellenwert einstellen:**
   * **Upgrades Allowed:** Haken setzen.
   * **Upgrade Until Custom Format Score:** Auf `1500` setzen (damit ein reines deutsches Release automatisch durch eine bessere Dual-Language-Fassung ersetzt wird, sobald eine erscheint).
   * **Minimum Custom Format Score:** Setze diesen Wert auf `1000`, wenn du **ausschließlich** deutschsprachige Medien zulassen willst. Setze ihn auf `0`, wenn englischsprachige Releases als Fallback heruntergeladen werden dürfen, falls keine deutsche Version existiert.
5. Klicke auf **Save**.

Ab sofort wählt der Stack bei jeder Suchanfrage vollautomatisch die für den deutschsprachigen Raum optimale Version aus – ganz ohne manuelle Kontrolle!