# 8.0 Der komplette Docker-Stack

Hier findest du die vollständigen, harmonisierten `docker-compose.yml`-Vorlagen für deinen gesamten Usenet- und Medienserver-Stack. Du kannst frei wählen, ob du den Stack abgesichert über ein VPN oder als schlanke Direktanbindung ohne VPN betreiben möchtest.

> [!TIP]
> **Ausfallsicherheit & Saubere Konfiguration:**
> * **Integrierte Log-Rotation:** Alle Vorlagen nutzen einen wiederverwendbaren Logging-Block (`max-size: 10m`, `max-file: 3`), damit Docker-Logs deine Festplatte oder microSD-Karte niemals unbemerkt füllen können.
> * **Umgebungsvariablen (`.env`):** Du kannst die Vorlage `.env.example` nach `.env` kopieren (`cp .env.example .env`), um Benutzer-IDs (`PUID`/`PGID`), Pfade (`CONFIG_DIR`/`DATA_DIR`) oder VPN-Keys zentral und sicher auszulagern.

### Schnellstart mit `.env`
```bash
# 1. Umgebungsvariablen anlegen und anpassen
cp .env.example .env
nano .env

# 2. Gewünschte Vorlage kopieren & Stack starten
cp docker-compose.example.yml docker-compose.yml       # Mit VPN (Gluetun)
# ODER: cp docker-compose.novpn.example.yml docker-compose.yml  # Ohne VPN (Direktmodus)
docker compose up -d
```

---

## Variante A: Mit VPN (Gluetun-Tunneling via WireGuard / OpenVPN)

Diese Variante leitet den gesamten Datenverkehr von SABnzbd/NZBGet und Prowlarr über den VPN-Tunnel von Gluetun.

```yaml
# Wiederverwendbarer Logging-Block gegen unbegrenzt volllaufende Festplatten
x-logging: &default-logging
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"

services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    <<: *default-logging
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      # --- VPN Konfiguration ---
      - VPN_SERVICE_PROVIDER=${VPN_SERVICE_PROVIDER:-mullvad} # z. B. mullvad, protonvpn, ivpn, custom
      - VPN_TYPE=${VPN_TYPE:-wireguard} # wireguard oder openvpn
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY:-dein-wireguard-private-key}
      - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES:-10.64.0.1/32} # Deine WireGuard-IP
      - SERVER_COUNTRIES=${SERVER_COUNTRIES:-Netherlands,Germany}
      - FIREWALL_OUTBOUND_SUBNETS=${FIREWALL_OUTBOUND_SUBNETS:-192.168.178.0/24,100.64.0.0/10} # Erlaube Zugriff aus dem lokalen Heimnetz & Tailscale (anpassen!)
      - TZ=${TZ:-Europe/Berlin}
      - PUID=${PUID:-1000} # Deine PUID
      - PGID=${PGID:-1000} # Deine PGID
    ports:
      - "8080:8080" # SABnzbd WebUI
      - "6789:6789" # NZBGet WebUI (falls genutzt)
      - "7878:7878" # Radarr WebUI & API
      - "8989:8989" # Sonarr WebUI & API
      - "9696:9696" # Prowlarr WebUI & API
    volumes:
      - ${CONFIG_DIR:-./config}/gluetun:/gluetun
    restart: unless-stopped

  # --- Usenet Downloader (Wähle SABnzbd ODER NZBGet) ---

  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/sabnzbd:/config
      - ${DATA_DIR:-./data}:/data
    restart: unless-stopped
    depends_on:
      - gluetun
    network_mode: "service:gluetun"

  # nzbget:
  #   image: lscr.io/linuxserver/nzbget:latest
  #   container_name: nzbget
  #   <<: *default-logging
  #   environment:
  #     - PUID=${PUID:-1000}
  #     - PGID=${PGID:-1000}
  #     - TZ=${TZ:-Europe/Berlin}
  #   volumes:
  #     - ${CONFIG_DIR:-./config}/nzbget:/config
  #     - ${DATA_DIR:-./data}:/data
  #   restart: unless-stopped
  #   depends_on:
  #     - gluetun
  #   network_mode: "service:gluetun"

  # --- Arr-Stack (Automatisierung & Indexer-Management) ---

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/prowlarr:/config
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/sonarr:/config
      - ${DATA_DIR:-./data}:/data
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - sabnzbd # oder nzbget
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/radarr:/config
      - ${DATA_DIR:-./data}:/data
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - sabnzbd # oder nzbget
    restart: unless-stopped

  # --- Frontend (Streaming & Media Requests) ---

  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/jellyfin:/config
      - ${DATA_DIR:-./data}/media:/data/media
    # Optional für Intel QuickSync Hardware-Transcoding:
    # devices:
    #   - /dev/dri:/dev/dri
    # group_add:
    #   - "107" # GID der Gruppe 'render' auf dem Host (getent group render | cut -d: -f3)
    ports:
      - "8096:8096"
    restart: unless-stopped

  seerr:
    image: ghcr.io/seerr-team/seerr:latest
    container_name: seerr
    <<: *default-logging
    init: true
    environment:
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/seerr:/app/config
    ports:
      - "5055:5055"
    depends_on:
      - radarr
      - sonarr
      - gluetun
    restart: unless-stopped
```

---

## Variante B: Ohne VPN (Direkte Verbindung via SSL/TLS)

Diese Variante verzichtet komplett auf Gluetun. Alle Downloads erfolgen direkt und nativ über Port 563 (SSL/TLS Ende-zu-Ende verschlüsselt). Jeder Dienst bindet seine Ports direkt an das Hostsystem.

```yaml
# Wiederverwendbarer Logging-Block gegen unbegrenzt volllaufende Festplatten
x-logging: &default-logging
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"

services:
  # --- Usenet Downloader (Wähle SABnzbd ODER NZBGet) ---

  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/sabnzbd:/config
      - ${DATA_DIR:-./data}:/data
    ports:
      - "8080:8080"
    restart: unless-stopped

  # nzbget:
  #   image: lscr.io/linuxserver/nzbget:latest
  #   container_name: nzbget
  #   <<: *default-logging
  #   environment:
  #     - PUID=${PUID:-1000}
  #     - PGID=${PGID:-1000}
  #     - TZ=${TZ:-Europe/Berlin}
  #   volumes:
  #     - ${CONFIG_DIR:-./config}/nzbget:/config
  #     - ${DATA_DIR:-./data}:/data
  #   ports:
  #     - "6789:6789"
  #   restart: unless-stopped

  # --- Arr-Stack (Automatisierung & Indexer-Management) ---

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/prowlarr:/config
    ports:
      - "9696:9696"
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/sonarr:/config
      - ${DATA_DIR:-./data}:/data
    ports:
      - "8989:8989"
    depends_on:
      - sabnzbd # oder nzbget
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/radarr:/config
      - ${DATA_DIR:-./data}:/data
    ports:
      - "7878:7878"
    depends_on:
      - sabnzbd # oder nzbget
    restart: unless-stopped

  # --- Frontend (Streaming & Media Requests) ---

  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    <<: *default-logging
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/jellyfin:/config
      - ${DATA_DIR:-./data}/media:/data/media
    # Optional für Intel QuickSync Hardware-Transcoding:
    # devices:
    #   - /dev/dri:/dev/dri
    # group_add:
    #   - "107" # GID der Gruppe 'render' auf dem Host
    ports:
      - "8096:8096"
    restart: unless-stopped

  seerr:
    image: ghcr.io/seerr-team/seerr:latest
    container_name: seerr
    <<: *default-logging
    init: true
    environment:
      - TZ=${TZ:-Europe/Berlin}
    volumes:
      - ${CONFIG_DIR:-./config}/seerr:/app/config
    ports:
      - "5055:5055"
    depends_on:
      - radarr
      - sonarr
    restart: unless-stopped
```

---

> 📁 **Hinweis zur TRaSH-Guides Speicherstruktur (`/data`):**
> Durch das einheitliche Mapping von `./data:/data` (bzw. deiner externen Festplatte nach `/data`) nutzen Downloader und Medien-Apps dasselbe Dateisystem.
> * **Downloads:** SABnzbd/NZBGet legt fertige Dateien unter `/data/usenet/complete` ab (temporär: `/data/usenet/incomplete`).
> * **Medien:** Sonarr importiert Serien nach `/data/media/tv`, Radarr Filme nach `/data/media/movies`, und Jellyfin streamt aus `/data/media`.
> * **Der entscheidende Vorteil:** Sonarr und Radarr verschieben fertige Dateien per **Instant Atomic Move (`rename()`) in Millisekunden** – komplett ohne doppelte Schreiblast oder lange Wartezeiten auf der Festplatte.

> 📌 **Hinweis zur internen Kommunikation:**
> * **In Variante A (Mit Gluetun):** Da `sabnzbd`, `prowlarr`, `sonarr` und `radarr` über das Gluetun-Netzwerk laufen (`network_mode: "service:gluetun"`), kommunizieren sie untereinander per `127.0.0.1` (localhost). Dienste außerhalb wie `seerr` erreichen Sonarr und Radarr über den Hostnamen **`gluetun`** (z. B. `http://gluetun:7878`).
> * **In Variante B (Ohne VPN):** Alle Dienste laufen im gemeinsamen Docker-Bridge-Netzwerk und erreichen sich direkt über ihre Containernamen (z. B. `http://sonarr:8989`, `http://radarr:7878`, `http://prowlarr:9696`, `http://sabnzbd:8080`).