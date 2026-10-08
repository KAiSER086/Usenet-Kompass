# 5.0 Usenet Downloader: SABnzbd vs. NZBGet

Nachdem dein sicheres Netzwerk mit Gluetun und Tailscale steht, geht es an das Herzstück deines Setups: den Usenet-Downloader. Wir stellen dir hier die beiden führenden Optionen vor – **SABnzbd** (unsere Standard-Empfehlung) und **NZBGet** (die leichtgewichtige Alternative für speicherarme Systeme).

---

## SABnzbd vs. NZBGet: Moderne Performance-Analyse & Mythen-Check

Lange Zeit hielt sich in der Usenet-Community das Vorurteil: *„Python-basierte Downloader wie SABnzbd sind zu schwerfällig für sparsame Hardware wie den Raspberry Pi – wer Gigabit will, muss zwingend das in C++ geschriebene NZBGet nutzen.“*

**Unsere aktuellen Hardware-Benchmarks widerlegen diesen Mythos eindeutig.**

Moderne Versionen von SABnzbd nutzen Python mit **`sabctools`** – nativen, hochoptimierten C-Erweiterungen mit Hardware-SIMD-Unterstützung (**ARM NEON** auf dem Raspberry Pi 5 und **AVX2** auf x86-Systemen). Damit wird die CPU-intensive yEnc-Dekodierung und CRC32-Prüfsummenberechnung direkt auf Hardware-Ebene ausgeführt.

| Kriterium | SABnzbd *(⭐ Standard-Empfehlung)* | NZBGet *(Leichtgewicht)* |
| :--- | :--- | :--- |
| **Architektur** | Python mit nativen C-Erweiterungen (**`sabctools`** mit ARM NEON & AVX2 SIMD). | Natives, Multi-Threaded C++. |
| **Max. Durchsatz (Raspberry Pi 5)** | **Volles Leitungs-Maximum (59,3+ MB/s Netto bei 500 Mbit/s / 115+ MB/s bei Gigabit)**. 1 GB Testdateien in ~18 s. | **Volles Leitungs-Maximum (59,3+ MB/s Netto bei 500 Mbit/s / 115+ MB/s bei Gigabit)**. 1 GB Testdateien in ~20 s. |
| **Cloud VPS (2 vCPU / AMD EPYC)** | **Hervorragend (64 MB/s)** bei 10–20 Verbindungen dank dynamischem TCP-Window-Scaling. | **39–47 MB/s** bei 10–20 Verbindungen. |
| **Arbeitsspeicher (RAM)** | ~350 MB bis 1,2 GB (je nach konfiguriertem RAM-Schreibcache). | **Extrem genügsam** (~40–60 MB im Leerlauf, ~150–250 MB unter Vollast). |
| **Prozessorlast** | Sehr moderat dank SIMD-Hardwarebeschleunigung. | Minimal (< 15 % CPU-Auslastung bei Gigabit). |
| **Direct Unpack** | **Nativ integriert**: Entpackt RAR-Archive parallel während des Downloads (*Einstellungen > Schalter*). | **Nativ integriert**: Entpackt RAR-Archive parallel während des Downloads (*Settings > UNPACK > DirectUnpack*). |
| **Weboberfläche & UX** | Modern, intuitiv, responsive und mit erstklassiger Warteschlangenverwaltung. | Funktional und schlank, optisch jedoch etwas in die Jahre gekommen. |

---

### 💾 Der wahre Flaschenhals: I/O-Architektur & Festplatten-Thrashing

Wenn ein Usenet-Download auf einem Server oder Raspberry Pi unerwartet bei 20–30 MB/s einbricht, liegt die Ursache in 99 % der Fälle **nicht an der Prozessorleistung**, sondern an der Festplatten-Architektur:

Usenet-Downloads bestehen aus tausenden winzigen Segmenten (Artikeln), die parallel aus dem Netzwerk eintreffen. Werden diese Fragmente direkt und unzusammenhängend auf eine langsame mechanische Festplatte (HDD) geschrieben, tritt massives **Head-Thrashing** auf – die Lese-/Schreibköpfe der Festplatte springen ununterbrochen hin und her, wodurch der I/O-Durchsatz der HDD auf unter 30 MB/s zusammenbricht.

> [!TIP]
> #### ⚡ Die goldene I/O-Regel für maximale Download-Geschwindigkeit:
> 1. **Schneller Zwischenspeicher:** Der temporäre Ordner (`/data/usenet/incomplete`) muss zwingend auf einer schnellen **SSD oder NVMe** liegen (350+ MB/s Schreibdurchsatz).
> 2. **RAM-Schreibcache in SABnzbd aktivieren:** Stelle in SABnzbd unter **Einstellungen > Allgemein > Cache-Begrenzung** (`cache_limit`) einen Puffer von **`1G`** (oder mindestens `512M`) ein. Dadurch puffert SABnzbd ankommende Segmente im Arbeitsspeicher und schreibt sie in großen, sequenziellen Blöcken auf die SSD – die I/O-Last sinkt drastisch.
> 3. **Instant Atomic Move:** Nach Abschluss verschieben Sonarr und Radarr die Datei in Millisekunden per Hardlink/Atomic Move in dein Medienverzeichnis (`/data/media`), ohne Daten auf der Festplatte zeitaufwendig kopieren zu müssen.

---

### 🔌 Der Verbindungs-Sweet-Spot: Wie viele Verbindungen sind optimal?

Ein weit verbreiteter Irrglaube lautet: *„Je mehr Verbindungen ich im Downloader eintrage, desto schneller wird der Download.“*

Unsere Messungen zeigen, wie stark Hardware-Dimensionierung und Netzwerk-Modus das Optimum beeinflussen:
* **Der Alltags-Sweet-Spot liegt bei 15 bis 20 Verbindungen:**
  * **Bei WireGuard-VPN (Gluetun):** Hier ist bei 16–20 Verbindungen die volle VPN-Bandbreite (~750–800 Mbit/s Netto) erreicht. Mehr Verbindungen belasten lediglich die CPU und bringen keinen Geschwindigkeitszuwachs.
  * **Auf kleinen Servern (2 vCPU):** Mehr als 20 Verbindungen führen zu **Context-Switch-Thrashing** – die Downloadrate brach im Test von 64 MB/s auf 46,8 MB/s ein (-27 %).
* **High-Speed No-VPN (SSL Port 563 auf 6+ vCPUs):**
  * Stehen ausreichend CPU-Kerne zur Verfügung und wird die Verbindung direkt per SSL (ohne zwischengeschalteten VPN-Tunnel) aufgebaut, skaliert SABnzbd dank C-Erweiterungen (`sabctools`) fast linear nach oben: Bei 30 Verbindungen werden über **330 MB/s** (~2,7 Gbit/s) erreicht, bei 50 Verbindungen sogar **363 MB/s** – bei einer CPU-Auslastung von unter 30 %.
* **Praxis-Empfehlung:**
  * Im **VPN-Betrieb:** Fest auf **16 bis 20 Verbindungen** einstellen.
  * Im **Direkt-Betrieb (SSL):** Starte mit **20 Verbindungen** (~230 MB/s). Bei extrem schnellen Leitungen (> 2,5 Gbit/s) und starker CPU schrittweise auf 30 erhöhen.

---

### 🎯 Entscheidungshilfe: Welcher Downloader für dich?

* **Wähle SABnzbd (Empfohlen):**
  * Du nutzt einen **Raspberry Pi 5 (4 GB oder 8 GB)**, einen **Intel N100 / x86-Homeserver** oder einen Cloud-VPS mit mindestens 2 GB RAM.
  * Du bevorzugst ein modernes, komfortables Webinterface mit exzellenter Fehlerdiagnose, detaillierter Historie und flexibler Warteschlangenverwaltung.
  * Du möchtest einen großen RAM-Schreibcache (z. B. 1 GB) nutzen, um I/O-Zugriffe auf die SSD maximal zu bündeln.
* **Wähle NZBGet:**
  * Du betreibst ein extrem sparsames System mit **unter 2 GB RAM** (z. B. Raspberry Pi 3, 1-GB-VPS oder ein altes NAS).
  * Du suchst minimale RAM-Auslastung (< 60 MB im Leerlauf, < 250 MB unter Volllast) bei voller nativer C++-Effizienz – ohne auf Features wie Direct Unpack verzichten zu müssen.

---

<details>
<summary><b>📊 Reale Hardware-Benchmark-Ergebnisse ansehen (RPi 5 vs. 2-vCPU vs. 6-vCPU Server)</b></summary>

### 1. Testumgebung & Messmethodik
* **Raspberry Pi 5:** Broadcom BCM2712 (4x Cortex-A76 @ 2.4 GHz), 8 GB RAM, NVMe SSD, 500 Mbit/s via WireGuard-VPN.
* **Cloud VPS (2 vCPU):** 2 vCPUs (AMD EPYC), 4 GB RAM, Enterprise NVMe, 1 Gbit/s Uplink via WireGuard-VPN.
* **Cloud VPS (6 vCPU):** 6 vCPUs (AMD EPYC), 8 GB RAM, Enterprise NVMe, Multi-Gigabit Uplink – getestet mit und ohne WireGuard-VPN (Gluetun).
* **Test-Payload:** Offizielles 1.000 MB SABnzbd-Testarchiv über Eweka SSL/TLS (Port 563).

### 2. Durchsatz & Downloadzeit (1 GB Testdatei)

#### A. Vergleich: Kleine Systeme vs. 2-vCPU VPS (WireGuard-VPN)
| Server & Setup | Downloader | Verbindungen | Durchsatz | Downloadzeit | CPU-Auslastung |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **RPi 5 (NVMe + 1G Cache)** | **SABnzbd** | **20** | **59,3 MB/s (100 % Leitung)** | **18,0 s** | ~35–45 % |
| **RPi 5 (NVMe)** | **NZBGet** | **20** | **59,3 MB/s (100 % Leitung)** | **20,0 s** | ~15–20 % |
| **Cloud VPS (2 vCPU AMD)** | **SABnzbd** | **10** | **64,0 MB/s** | **15,6 s** | ~40 % |
| **Cloud VPS (2 vCPU AMD)** | **SABnzbd** | **20** | **63,8 MB/s** | **15,7 s** | ~55 % |
| **Cloud VPS (2 vCPU AMD)** | **SABnzbd** | **30** | **46,8 MB/s (-27 % Einbruch)** | **21,4 s** | ~85 % (Thread Overload) |

#### B. Skalierter Cloud VPS (6 vCPU / 8 GB RAM): No-VPN Direkt vs. Gluetun VPN
| Modus | Downloader | Verbindungen | Netto-Durchsatz | Downloadzeit | CPU-Auslastung | Besonderheit |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Gluetun (WireGuard)** | SABnzbd | 8 | 55,6 MB/s | 17,0 s | ~36 % | VPN dämpft Single-Stream |
| **Gluetun (WireGuard)** | SABnzbd | 12 | 80,4 MB/s | 12,0 s | ~46 % | Gute Steigerung |
| **Gluetun (WireGuard)** | SABnzbd | **16–20** | **92,3–93,0 MB/s** | **10,0 s** | **~52 %** | ⭐ **VPN Sweet-Spot (~750 Mbit/s)** |
| **Gluetun (WireGuard)** | SABnzbd | 30–40 | 90,0–97,6 MB/s | 10,0 s | ~54 % | VPN-Server-Plateau |
| **Direkt (No-VPN SSL)** | SABnzbd | 8 | 73,5 MB/s | 13,0 s | ~19 % | Ungesättigt |
| **Direkt (No-VPN SSL)** | SABnzbd | 16 | 190,6 MB/s | 5,0 s | ~29 % | Schneller als 1,5 Gbit/s |
| **Direkt (No-VPN SSL)** | SABnzbd | **20** | **233,1 MB/s** | **4,0 s** | **~29 %** | ⭐ **Alltags-Sweet-Spot (~1,8 Gbit/s)** |
| **Direkt (No-VPN SSL)** | SABnzbd | 30 | 331,8 MB/s | 2,0 s | ~29 % | Extremer Durchsatz (~2,7 Gbit/s) |
| **Direkt (No-VPN SSL)** | SABnzbd | 50 | 363,3 MB/s | 2,0 s | ~29 % | Absolutes Maximum (~3 Gbit/s) |

### 3. Zentrale Erkenntnisse
1. **CPU-Flaschenhals eliminiert:** Auf 6 vCPUs bricht der Durchsatz bei 30+ Verbindungen nicht mehr ein. Die CPU bleibt dank Python-SIMD (`sabctools`) selbst bei 360 MB/s unter 30 % Last.
2. **Der VPN-Flaschenhals:** Über WireGuard liegt der Sweet-Spot bei 16–20 Verbindungen (~93 MB/s). Mehr Verbindungen erhöhen nur die CPU-Kryptolast, überwinden aber nicht das Durchsatz-Limit des VPN-Tunnels.
3. **Direkt-Modus (SSL Port 563):** Wer den VPN-Tunnel weglässt und auf die providerseitige SSL-Verschlüsselung setzt, spart die Hälfte an CPU-Ressourcen und erreicht bei schnellen Server-Anbindungen bis zu 360 MB/s (1 GB in 2 Sekunden).

</details>

---

## 5.1 Downloader zur docker-compose.yml hinzufügen

Wir zeigen dir hier die Konfiguration für beide Downloader. In unserem Standard-Setup kommt **SABnzbd** zum Einsatz.

### Konfigurations- und Datenordner erstellen

Führe diese Befehle im Projektverzeichnis aus:

```bash
mkdir -p config/sabnzbd config/nzbget
mkdir -p data/usenet/complete/movies data/usenet/complete/tv
mkdir -p data/usenet/incomplete
mkdir -p data/media/movies data/media/tv
```

#### Wichtiger Hinweis zu Speicherpfaden (TRaSH-Guides Standard)

Wir binden den gesamten Datenordner als ein einziges Volume (`./data:/data`) ein. Dadurch können Sonarr und Radarr später fertige Downloads über **Instant Atomic Moves** in Millisekunden in deine Mediathek verschieben, ohne die Festplatte durch zeitaufwendiges Kopieren zu belasten.

Wenn du deine Daten auf einer externen Festplatte ablegen möchtest (z. B. gemountet unter `/mnt/daten/medien`), passe die `volumes`-Sektion entsprechend an:

```yaml
volumes:
  - ./config/sabnzbd:/config 
  - /mnt/daten/medien:/data
```

Stelle sicher, dass der angegebene Ordner auf deinem Host-System existiert und der Benutzer, unter dem die Container laufen (`PUID`), die notwendigen Schreibrechte besitzt.

---

### Option A: SABnzbd hinzufügen (Standard-Empfehlung)

```yaml
  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    environment:
      - PUID=1000 # Ersetze mit deiner PUID
      - PGID=1000 # Ersetze mit deiner PGID
      - TZ=Europe/Berlin
    volumes:
      - ./config/sabnzbd:/config
      - ./data:/data
    restart: unless-stopped
    depends_on:
      - gluetun
    network_mode: "service:gluetun"
```

---

### Option B: NZBGet hinzufügen (Leichtgewicht)

```yaml
  nzbget:
    image: lscr.io/linuxserver/nzbget:latest
    container_name: nzbget
    environment:
      - PUID=1000 # Ersetze mit deiner PUID
      - PGID=1000 # Ersetze mit deiner PGID
      - TZ=Europe/Berlin
    volumes:
      - ./config/nzbget:/config
      - ./data:/data
    restart: unless-stopped
    depends_on:
      - gluetun
    network_mode: "service:gluetun"
```

> **Wichtiger Hinweis:** Die Zeile `network_mode: "service:gluetun"` leitet den gesamten Datenverkehr des Downloaders über den sicheren VPN-Tunnel.

#### Dienst starten und Webinterface aufrufen

Starte den Stack mit:

```bash
docker compose up -d
```

Anschließend erreichst du das Webinterface:

* **SABnzbd:** `http://deine-server-ip:8080` oder `http://<tailscale-ip>:8080`
  * *Tipp:* Wenn du SABnzbd über Tailscale aufrufst und eine Host-Header-Sicherheitsmeldung erhältst, kannst du in der Datei `./config/sabnzbd/sabnzbd.ini` die Option `inet_exposure = 5` setzen.
* **NZBGet:** `http://deine-server-ip:6789` oder `http://<tailscale-ip>:6789`

---

## 5.2 Downloader konfigurieren: Usenet-Provider & Server-Prioritäten

### 💡 Wichtig: Haupt-Provider vs. Backup-Blockaccount richtig einrichten

Wenn du neben deiner Flatrate (z. B. Eweka) einen Block-Account (z. B. NewsgroupDirect) als Backup nutzt, musst du **Prioritäten** vergeben, damit dein bezahltes Datenvolumen nicht unnötig verbraucht wird:

* **Haupt-Provider (Flatrate):** Priorität auf **`0`** setzen.
* **Block-Account (Backup):** Priorität auf **`1`** (oder höher) setzen bzw. als **„Backup-Server“ / „Optional Server“** markieren.
* *Effekt:* Der Downloader lädt 100 % der Daten vom Hauptprovider. Nur wenn dort ein Segment durch DMCA gelöscht wurde, holt er genau diesen fehlenden Teil vom Backup-Blockaccount.

---

### SABnzbd: Usenet-Provider & Performance einrichten

1. **Einstellungen öffnen:** Klicke oben rechts auf das **Zahnrad-Symbol ⚙️**.
2. **Server hinzufügen:** Wähle links **"Server"** und klicke auf **"Server hinzufügen"**.
   * **Hostname:** Die News-Server-Adresse deines Providers (z. B. `news.eweka.nl`).
   * **Port:** **`563`** (oder `443`) für verschlüsseltes SSL/TLS.
   * **SSL:** Haken bei **"SSL verwenden"** aktivieren.
   * **Benutzername & Passwort:** Deine Zugangsdaten vom Provider.
   * **Verbindungen:** Starte mit **`15–20`** Verbindungen (Sweet-Spot für maximale Bandbreite bei minimaler Systemlast).
   * **Priorität:** `0` für Hauptserver, `1` für Backup-Blockaccounts.
3. **Pfade anpassen:** Unter **Einstellungen > Ordner**:
   * **Ordner für fertige Downloads:** `/data/usenet/complete`
   * **Temporärer Download-Ordner:** `/data/usenet/incomplete` *(auf schneller SSD/NVMe)*
4. **Kategorien für *arr anlegen:** Unter **Einstellungen > Kategorien**:
   * **`movies`**: Ordner/Pfad `movies` (ergibt `/data/usenet/complete/movies`)
   * **`tv`**: Ordner/Pfad `tv` (ergibt `/data/usenet/complete/tv`)
5. **Direct Unpack aktivieren (Empfohlen):**
   * Unter **Einstellungen > Schalter** die Option **Direktes Entpacken** (*Direct Unpack*) aktivieren.
   * *Effekt:* Archive werden bereits während des Herunterladens parallel entpackt. Die Wartezeit nach Download-Ende schrumpft auf wenige Sekunden.
6. **RAM-Schreibcache konfigurieren:**
   * Unter **Einstellungen > Allgemein > Tuning** die **Cache-Begrenzung** (`cache_limit`) auf **`1G`** (bei mindestens 4 GB System-RAM) oder `512M` setzen.
   * *Effekt:* Schützt Festplatten vor I/O-Spitzen und garantiert stabile Höchstgeschwindigkeiten.
7. **Testen & Speichern:** Klicke auf **"Server testen"** und speichere die Konfiguration.

![Sabnzbd-Provider](sabnzbd-provider.gif)

---

### NZBGet: Usenet-Provider & Performance einrichten

1. **Einstellungen öffnen:** Klicke im Menü auf **"Settings"**.
2. **News-Server:** Wähle in der linken Leiste **"NEWS-SERVERS"**.
3. **Server-Daten eintragen:**
   * **Name:** Z. B. `Eweka`.
   * **Host:** Die Server-Adresse des Anbieters.
   * **Port:** **`563`**.
   * **Encryption:** Auf **`yes`** (SSL aktivieren) setzen.
   * **User & Password:** Deine Anmeldedaten.
   * **Connections:** Starte mit **`15–20`** Verbindungen.
   * **Level:** Setze `0` für den Hauptserver und `1` für Blockaccounts.
4. **Pfade & Kategorien anpassen:**
   * Unter **Settings > Paths** überprüfe bzw. setze **DestDir** auf `/data/usenet/complete` und **InterDir** auf `/data/usenet/incomplete`.
   * Unter **Settings > Categories** die Kategorien `movies` und `tv` mit den jeweiligen Unterverzeichnissen anlegen.
5. **Direct Unpack aktivieren (Empfohlen):**
   * Gehe in den Einstellungen auf **"UNPACK"**.
   * Setze die Option **DirectUnpack** auf **`yes`**.
   * *Effekt:* NZBGet entpackt RAR-Archive parallel während des Herunterladens. Sobald der Download beendet ist, steht die fertige Mediendatei unmittelbar für Sonarr/Radarr bereit.
6. **Speichern:** Klicke auf **"Save all changes"** (und ggf. **"Reload NZBGet"**) und teste mit **"Test Connection"**.

![NZBGet-Provider](nzbget-provider.gif)

---

| ⬅️ Vorheriges Kapitel | 🧭 Inhaltsverzeichnis | ➡️ Nächstes Kapitel |
| :--- | :---: | ---: |
| ⬅️ [**4.0 VPNs & Netzwerk**](../Docker%20Compose%20Stack/VPNs.md) | [**Inhaltsverzeichnis**](../README.md#inhaltsverzeichnis) | [**6.0 Arr-Stack**](../Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md) ➔ |