# 5.0 Usenet Downloader: SABnzbd vs. NZBGet

Nachdem dein sicheres Netzwerk mit Gluetun und Tailscale steht, geht es an das Herzstück deines Setups: den Usenet-Downloader. Wir stellen dir hier die beiden beliebtesten Optionen vor, **SABnzbd** und **NZBGet**, damit du die passende Wahl für dein System treffen kannst.

---

## SABnzbd vs. NZBGet: Der Vergleich

| | SABnzbd | NZBGet |
| :--- | :--- | :--- |
| **Codebasis** | **Interpretiert (Python)**. Sehr modern, aktiv gepflegt und modular. | **Kompiliert (C++)**. Extrem performant und ressourcenschonend. |
| **Vorteile** | - Sehr benutzerfreundliche, moderne Oberfläche.  <br>- Riesige, aktive Community & regelmäßige Updates.  <br>- Exzellente Automatisierungs- und Reparaturfunktionen (PAR2). | - Extrem niedrige CPU- und RAM-Auslastung.  <br>- Ideal für stromsparende Single-Board-Computer.  <br>- Sehr hoher Durchsatz bei minimalem Overhead. |
| **Nachteile** | - Bei extrem hohen Gigabit-Raten etwas höhere CPU-Last. | - Webinterface funktional, aber etwas altbackener.  <br>- Konfiguration erfordert etwas mehr technisches Verständnis. |

**Empfehlung:** Beide Downloader eignen sich hervorragend für den Betrieb auf einem **Raspberry Pi 5**. Wenn du Wert auf die modernste Oberfläche und den größten Funktionsumfang legst, ist **SABnzbd** die Standardempfehlung. Suchst du maximale Ressourceneffizienz, ist **NZBGet** eine erstklassige Wahl.

---

## 5.1 Downloader zur docker-compose.yml hinzufügen

Wir zeigen dir hier die Konfiguration für beide Downloader. Du solltest dich für einen der beiden entscheiden und den nicht benötigten Teil auskommentieren oder weglassen.

### Konfigurations- und Downloadordner erstellen

Führe diese Befehle im Docker-Verzeichnis aus, um die Ordner für Konfiguration und Downloads anzulegen:

```bash
mkdir -p config/sabnzbd config/nzbget
mkdir -p downloads incomplete-downloads
```

#### Wichtiger Hinweis zu Speicherpfaden

Wenn du deine Downloads auf einer externen Festplatte ablegen möchtest (z. B. gemountet unter `/mnt/name-der-festplatte/medien`), passe die `volumes`-Sektion entsprechend an:

```yaml
volumes:
  - ./config/sabnzbd:/config 
  - /mnt/name-der-festplatte/medien/downloads:/downloads
  - /mnt/name-der-festplatte/medien/incomplete-downloads:/incomplete-downloads
```

Stelle sicher, dass der angegebene Ordner auf deinem Host-System existiert und der Benutzer, unter dem die Container laufen (`PUID`), die notwendigen Schreibrechte besitzt.

---

### Option A: SABnzbd hinzufügen

Füge den folgenden Block zu deiner `docker-compose.yml` hinzu:

```yaml
  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    environment:
      - PUID=1000 # Ersetze mit deiner PUID
      - PGID=1000 # Ersetze mit deiner PGID
      - TZ=Europe/Berlin
    volumes:
      - ./config/sabnzbd:/config # Speichert die Konfiguration
      - ./downloads:/downloads # Ordner für fertige Downloads
      - ./incomplete-downloads:/incomplete-downloads # Ordner für laufende Downloads
    restart: unless-stopped
    depends_on:
      - gluetun
    network_mode: "service:gluetun"
```

---

### Option B: NZBGet hinzufügen

```yaml
  nzbget:
    image: lscr.io/linuxserver/nzbget:latest
    container_name: nzbget
    environment:
      - PUID=1000 # Ersetze mit deiner PUID
      - PGID=1000 # Ersetze mit deiner PGID
      - TZ=Europe/Berlin
    volumes:
      - ./config/nzbget:/config # Speichert die Konfiguration
      - ./downloads:/downloads # Ordner für Downloads
      - ./incomplete-downloads:/incomplete-downloads # Ordner für laufende Downloads
    restart: unless-stopped
    depends_on:
      - gluetun
    network_mode: "service:gluetun"
```

> **Wichtiger Hinweis:** Die Zeile `network_mode: "service:gluetun"` leitet den gesamten Datenverkehr des Downloaders über den VPN-Tunnel.

#### Dienst starten und Webinterface aufrufen

Starte den Stack mit:

```bash
docker compose up -d
```

Anschließend erreichst du das Webinterface:

* **SABnzbd:** `http://deine-server-ip:8080` oder `http://<tailscale-ip>:8080`
  * *Tipp:* Wenn du SABnzbd über Tailscale aufrufst und eine Zugriffsmeldung erhältst, kannst du in der Datei `./config/sabnzbd/sabnzbd.ini` die Option `inet_exposure = 5` setzen oder deine Tailscale-IP als Host eintragen.
* **NZBGet:** `http://deine-server-ip:6789` oder `http://<tailscale-ip>:6789`

---

## 5.2 Downloader konfigurieren: Usenet-Provider

Nach dem ersten Start verbindest du deinen Downloader mit deinem Usenet-Provider-Account.

### SABnzbd: Usenet-Provider einrichten

1. **Einstellungen öffnen:** Klicke oben rechts auf das **Zahnrad-Symbol ⚙️**.
2. **Server-Menü:** Wähle links **"Server"** und klicke auf **"Server hinzufügen"**.
3. **Provider-Details eintragen:**
   * **Hostname:** Die News-Server-Adresse (z. B. `news.eweka.nl`).
   * **Port:** **`563`** (oder `443`) für verschlüsseltes SSL/TLS.
   * **SSL:** Haken bei **"SSL verwenden"** setzen.
   * **Benutzername & Passwort:** Deine Zugangsdaten vom Provider.
   * **Verbindungen:** Starte mit **`15–25`** Verbindungen. (Mehr Verbindungen sind nicht immer schneller und belasten die CPU unnötig).
4. **Testen & Speichern:** Klicke auf **"Server testen"** und danach auf **"Änderungen speichern"**.

![Sabnzbd-Provider](sabnzbd-provider.gif)

---

### NZBGet: Usenet-Provider einrichten

1. **Einstellungen öffnen:** Klicke im Menü auf **"Settings"**.
2. **News-Server:** Wähle in der linken Leiste **"NEWS-SERVERS"**.
3. **Server-Daten eintragen:**
   * **Name:** Z. B. `Eweka`.
   * **Host:** Die Server-Adresse des Anbieters.
   * **Port:** **`563`**.
   * **Encryption:** Auf **`yes`** (SSL aktivieren) setzen.
   * **User & Password:** Deine Anmeldedaten.
   * **Connections:** Starte mit ca. **`20`** Verbindungen.
4. **Pfade anpassen:** Unter **Settings > Paths** überprüfe, dass **DestDir** auf `/downloads` und **InterDir** auf `/incomplete-downloads` eingestellt ist.
5. **Speichern:** Klicke auf **"Save all changes"** und teste mit **"Test Connection"**.

![NZBGet-Provider](nzbget-provider.gif)