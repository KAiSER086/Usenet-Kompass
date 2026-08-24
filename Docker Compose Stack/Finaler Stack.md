# 8.0 Der komplette Docker-Stack

Hier ist die vollständige, harmonisierte `docker-compose.yml` für deinen gesamten Usenet- und Medienserver-Stack.

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_SERVICE_PROVIDER=dein-vpn-provider # z. B. nordvpn, mullvad, expressvpn, custom
      - VPN_TYPE=openvpn # oder wireguard
      - OPENVPN_USER=dein-benutzername
      - OPENVPN_PASSWORD=dein-passwort
      - SERVER_COUNTRIES=Netherlands
      - TZ=Europe/Berlin
      - PUID=1000 # Deine PUID
      - PGID=1000 # Deine PGID
    ports:
      - "8080:8080" # SABnzbd WebUI
      - "6789:6789" # NZBGet WebUI (falls genutzt)
      - "7878:7878" # Radarr WebUI & API
      - "8989:8989" # Sonarr WebUI & API
      - "9696:9696" # Prowlarr WebUI & API
    volumes:
      - ./config/gluetun:/gluetun
    restart: unless-stopped

  # --- Usenet Downloader (Wähle SABnzbd ODER NZBGet) ---

  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    volumes:
      - ./config/sabnzbd:/config
      - ./downloads:/downloads
      - ./incomplete-downloads:/incomplete-downloads
    restart: unless-stopped
    depends_on:
      - gluetun
    network_mode: "service:gluetun"

  # nzbget:
  #   image: lscr.io/linuxserver/nzbget:latest
  #   container_name: nzbget
  #   environment:
  #     - PUID=1000
  #     - PGID=1000
  #     - TZ=Europe/Berlin
  #   volumes:
  #     - ./config/nzbget:/config
  #     - ./downloads:/downloads
  #     - ./incomplete-downloads:/incomplete-downloads
  #   restart: unless-stopped
  #   depends_on:
  #     - gluetun
  #   network_mode: "service:gluetun"

  # --- Arr-Stack (Automatisierung & Indexer-Management) ---

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
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
      - ./downloads:/downloads
      - ./tvshows:/tvshows
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
      - ./downloads:/downloads
      - ./movies:/movies
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - sabnzbd # oder nzbget
    restart: unless-stopped

  # --- Frontend (Streaming & Media Requests) ---

  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
    volumes:
      - ./config/jellyfin:/config
      - ./movies:/movies
      - ./tvshows:/tvshows
    ports:
      - "8096:8096"
    restart: unless-stopped

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
      - "5055:5055"
    depends_on:
      - radarr
      - sonarr
      - gluetun
    restart: unless-stopped
```

> 📌 **Hinweis zur internen Kommunikation:**
> Da `sabnzbd`, `prowlarr`, `sonarr` und `radarr` über das Gluetun-Netzwerk laufen (`network_mode: "service:gluetun"`), können sie untereinander per `127.0.0.1` (localhost) kommunizieren.
> Dienste außerhalb des VPNs wie `jellyseerr` erreichen Sonarr und Radarr innerhalb des Docker-Netzwerks über den Hostnamen **`gluetun`** (z. B. `http://gluetun:7878` und `http://gluetun:8989`).