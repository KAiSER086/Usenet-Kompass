# 9.0 FAQ & Fehlerbehebung (Troubleshooting)

Dieses Kapitel behandelt die häufigsten Stolpersteine und Fehlermeldungen bei der Einrichtung des Stacks. Statt die Schritt-für-Schritt-Anleitung zu wiederholen, findest du hier konkrete Fehlerbilder, deren Ursachen und zielgerichtete Lösungen.

---

## 1. Speicher, Festplatten & Dateirechte

### Fehler: `Permission denied` oder Container können keine Dateien schreiben
* **Symptom:** Sonarr, Radarr oder SABnzbd melden im Log `Access to path is denied` oder stürzen beim Start ab.
* **Häufigste Ursache (Externe USB-Festplatten):** Die Festplatte ist mit einem Windows-Dateisystem (**NTFS** oder **exFAT**) formatiert. Diese Dateisysteme unterstützen keine nativen Linux-Dateiberechtigungen (`chown`, `chmod`) und ignorieren die in Docker gesetzten Parameter `PUID` und `PGID`.
* **Lösung A (Dauerhaft & Empfohlen):** Sichere vorhandene Daten und formatiere die Festplatte als natives Linux-Dateisystem (**ext4**):
  ```bash
  # Beispiel für Partition /dev/sdb1 (Vorsicht: Löscht alle Daten auf der Partition!)
  sudo mkfs.ext4 -L "Medien" /dev/sdb1
  ```
* **Lösung B (Ohne Formatierung via fstab-Mount-Optionen):** Wenn du NTFS/exFAT beibehalten musst, erzwinge die Besitzerrechte beim Einhängen in der Datei `/etc/fstab`:
  ```text
  # Beispiel für /etc/fstab bei NTFS:
  UUID=DEINE-UUID /mnt/daten ntfs-3g uid=1000,gid=1000,umask=022 0 0
  ```

---

### Problem: Downloads dauern ewig beim Importieren (Festplatte rödelt minutenlang)
* **Symptom:** Sobald SABnzbd/NZBGet einen Download beendet, dauert der Import in Sonarr oder Radarr sehr lange. Der freie Speicherplatz sinkt temporär drastisch.
* **Ursache:** Die Verzeichnisse wurden in der `docker-compose.yml` als getrennte Volumes gemountet (z. B. `- ./downloads:/downloads` und `- ./movies:/movies`). Für den Linux-Kernel sind das zwei unterschiedliche Dateisysteme. Ein blitzschneller Hardlink bzw. **Instant Atomic Move (`rename()`)** ist technisch unmöglich – die gesamte Datei (z. B. 30 GB) muss physisch blockweise neu geschrieben werden.
* **Lösung:** Verwende ausnahmslos das gemeinsame Hauptvolume nach TRaSH-Standard:
  ```yaml
  volumes:
    - ./data:/data # oder /mnt/daten/medien:/data
  ```
  Dadurch liegen `incomplete`, `complete`, `movies` und `tv` auf demselben Mount-Point und der Import geschieht in wenigen Millisekunden.

---

## 2. Netzwerk, VPN & Container-Kommunikation

### Problem: Webinterface von SABnzbd, Sonarr oder Radarr lädt nicht (Verbindung verweigert)
* **Symptom:** Du rufst `http://deine-server-ip:8080` oder `:8989` im Browser auf, aber die Seite ist nicht erreichbar.
* **Ursache:** Die Dienste laufen im VPN-Netzwerkmodus (`network_mode: "service:gluetun"`). Container in diesem Modus besitzen keinen eigenen Netzwerk-Stack und keine eigenen Ports.
* **Lösung:** Ports dürfen **nicht** in der Dienstdefinition von `sabnzbd`, `sonarr` etc. stehen, sondern müssen gebündelt in der Sektion von **`gluetun`** deklariert werden:
  ```yaml
  services:
    gluetun:
      ports:
        - "8080:8080" # SABnzbd
        - "8989:8989" # Sonarr
        - "7878:7878" # Radarr
        - "9696:9696" # Prowlarr
  ```

---

### Problem: Prowlarr oder Seerr können Sonarr/Radarr nicht erreichen
* **Symptom:** Beim Testen der Verbindung erscheint `Unable to connect to Sonarr` oder `Connection refused`.
* **Ursache & Lösung je nach Position der Dienste:**
  1. **Kommunikation innerhalb von Gluetun (z. B. Prowlarr -> Sonarr):**  
     Da beide Container den Netzwerk-Stack von Gluetun teilen, lauschen sie auf demselben Localhost.  
     * **URL:** `http://127.0.0.1:8989` (oder `http://localhost:8989`) eintragen, **nicht** den Containernamen.
  2. **Kommunikation von außen zu Gluetun (z. B. Seerr -> Sonarr):**  
     Seerr läuft außerhalb des VPNs im Docker-Bridge-Netzwerk.  
     * **URL:** `http://gluetun:8989` eintragen, da Gluetun die Ports für Sonarr bereitstellt.

---

### Problem: SABnzbd meldet "Access Denied" / Host-Header-Fehler (Tailscale / Fernzugriff)
* **Symptom:** Beim Aufruf über Tailscale (MagicDNS oder Tailscale-IP) verweigert SABnzbd den Zugriff mit einer Sicherheitswarnung.
* **Ursache:** SABnzbd besitzt einen standardmäßigen Schutz gegen DNS-Rebinding-Angriffe und blockiert fremde Hostnamen.
* **Lösung:** Öffne die Konfigurationsdatei `./config/sabnzbd/sabnzbd.ini` und setze:
  ```ini
  inet_exposure = 5
  ```
  Alternativ kannst du deine Tailscale-Domain (z. B. `mein-server.tailnet.ts.net`) unter `host_whitelist` kommagetrennt hinzufügen und SABnzbd neu starten (`docker compose restart sabnzbd`).

---

### Problem: Downloader startet vor dem VPN-Tunnel (Verbindungsfehler nach Neustart)
* **Symptom:** Nach einem Server-Neustart melden SABnzbd oder die Arr-Dienste Verbindungsprobleme zum Usenet bzw. zu Indexern.
* **Ursache:** Die Container starten zeitgleich mit Gluetun, noch bevor der WireGuard-Tunnel erfolgreich aufgebaut und initialisiert wurde (Race Condition).
* **Lösung:** Ergänze in der `docker-compose.yml` bei den abhängigen Diensten die Bedingung `condition: service_healthy`:
  ```yaml
  sabnzbd:
    depends_on:
      gluetun:
        condition: service_healthy
  ```

---

## 3. Streaming & Hardware-Transkodierung

### Problem: Transkodierung in Jellyfin schlägt fehl (Grünes Bild, Fehler oder 100 % CPU-Last)
* **Symptom:** Beim Abspielen von Videos mit Transkodierung bricht die Wiedergabe ab oder der Prozessor schlägt an den 100 %-Anschlag, obwohl Intel QuickSync oder VAAPI aktiv sein sollten.
* **Ursache:** Dem Jellyfin-Container fehlt der Zugriff auf die Render-Gerätedateien (`/dev/dri`) oder dem Container-Benutzer fehlen die Berechtigungen für die Host-Gruppe `render`.
* **Lösung:**
  1. Ermittle die Gruppen-ID von `render` auf deinem Host:
     ```bash
     getent group render | cut -d: -f3
     ```
  2. Trage das Gerät und die ermittelte Gruppen-ID (z. B. `107`) in der `docker-compose.yml` unter `jellyfin` ein:
     ```yaml
     jellyfin:
       devices:
         - /dev/dri:/dev/dri
       group_add:
         - "107" # GID der Gruppe render vom Host
     ```

---

### Problem: Video buffert oder ruckelt alle paar Sekunden

* **Symptom:** Das Video stoppt ständig zum Nachladen oder die Wiedergabe bricht ab.
* **Ursachen & Diagnose-Checkliste:**
  1. **Schritt 1: Ist es Direct Play oder Transcoding?**
     * Öffne während der Wiedergabe im Jellyfin-Player das Zahnrad und wähle **Wiedergabe-Informationen**.
     * **Falls Transcoding aktiv ist:** Jellyfin nennt dir den Grund:
       * *Grund „Untertitel werden eingebrannt“ (Subtitle Burn-In):* Du nutzt bildbasierte PGS- oder VOBSUB-Untertitel (typisch für Blu-ray/Remux). Schalte die Untertitel aus oder wechsle auf textbasierte **SRT-Untertitel**.
       * *Grund „Audio-Codec nicht unterstützt“:* Dein TV oder deine Soundbar unterstützt kein verlustfreies Dolby TrueHD oder DTS-HD. In Kombination mit Untertiteln führt das oft zum Volltranscode des Videos. Wähle im Player eine kompatible Tonspur (z. B. Dolby Digital 5.1 / AC3) oder nutze einen externen Player mit Passthrough an einen AV-Receiver.
       * *Grund „Video-Codec / Profil nicht unterstützt“:* Dein Abspielgerät kann das Format (z. B. 10-Bit H.264 / Hi10P, AV1 oder HEVC) nicht in Hardware decodieren. Nutze einen fähigen Client wie **Moonfin**, **Infuse**, **Wholphin** oder den **Jellyfin Media Player** statt der integrierten TV-App.
  2. **Schritt 2: Das Video läuft in „Direct Play“, buffert aber trotzdem?**
     * **Ursache (Die 100-Mbit/s-Falle):** Bei riesigen 4K Remux-Dateien (60–90 GB) übersteigen kurze Bitraten-Spitzen (Spikes bis 150 Mbit/s) die Bandbreite des 100-Mbit/s-Fast-Ethernet-Ports deines Smart-TVs.
     * **Lösung:** Wechsle am Fernseher auf schnelles 5-GHz-WLAN (oft 200–400 Mbit/s Durchsatz) oder setze in Radarr/Sonarr auf **4K WEB-DLs** (15–25 Mbit/s), die visuell hervorragend aussehen und jedes Netzwerk schonen.

---

## 4. Docker & System-Fehler

### Fehler: `bind: address already in use` beim Start
* **Symptom:** `docker compose up -d` bricht mit einem Port-Konflikt ab.
* **Ursache:** Ein Port (z. B. `8080` für SABnzbd oder `8096` für Jellyfin) wird bereits von einem anderen Dienst auf deinem Host-System (z. B. Webserver, Pi-hole) belegt.
* **Lösung:** Passe in der Datei `.env` lediglich den externen Port an (z. B. `PORT_SABNZBD=8085`), **niemals** den internen Container-Port:
  ```env
  PORT_SABNZBD=8085
  ```
  Docker leitet eingehende Anfragen auf Port `8085` nun automatisch an den internen Port `8080` weiter.

---

| Vorheriges Kapitel | Inhaltsverzeichnis | Nächstes Kapitel |
| :--- | :---: | ---: |
| [**8.0 Finaler Stack**](../Docker%20Compose%20Stack/Finaler%20Stack.md) | [**Inhaltsverzeichnis**](../README.md#inhaltsverzeichnis) | [**Glossar: Usenet-Lexikon**](../Lexikon/Lexikon.md) |
