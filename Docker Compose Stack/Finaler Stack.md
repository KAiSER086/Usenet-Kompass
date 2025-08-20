# 8.0 Der komplette Docker-Stack

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
      - VPN_SERVICE_PROVIDER=dein-vpn-provider
      - VPN_TYPE=openvpn
      - OPENVPN_USER=dein-benutzername
      - OPENVPN_PASSWORD=dein-passwort
      - SERVER_COUNTRIES=Netherlands
      - TZ=Europe/Berlin
      - PUID=1000
      - PGID=1000
    ports:
      - 8080:8080 # Sabnzbd
      - 6789:6789 # NZBGet
      - 7878:7878 # Radarr
      - 8989:8989 # Sonarr
      - 9696:9696 # Prowlarr
    volumes:
      - ./gluetun-config:/gluetun
    restart: unless-stopped

  # Wähle EINEN Downloader aus und kommentiere den anderen aus oder entferne ihn.

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
      - 8096:8096
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
      - 5055:5055
    depends_on:
      - radarr
      - sonarr
    restart: unless-stopped
```
