# Usenet-Kompass

Der deutsche Guide zur vollständigen Usenet-Automatisierung als Docker Compose Stack, inklusive detaillierter Anleitungen für Gluetun, Sonarr, Radarr, Prowlarr, SABnzbd, NZBGet, Jellyfin, Jellyseerr und Tailscale.

---

## Inhaltsverzeichnis

* 1.0 **[Grundlagen](Grundlagen/Grundlagen.md#10-grundlagen)**
  * 1.1 [Was ist Usenet?](Grundlagen/Grundlagen.md#11-was-ist-usenet)
  * 1.2 [Systemvoraussetzungen & Hardware-Wahl](Grundlagen/Grundlagen.md#12-systemvoraussetzungen--hardware-wahl)

* 2.0 **[Provider und Indexer](Provider%20%26%20Indexer/Provider%20%26%20Indexer.md#20-provider-und-indexer)**
  * 2.1 [Usenet-Provider wählen](Provider%20%26%20Indexer/Provider%20%26%20Indexer.md#21-usenet-provider-wählen)
  * 2.2 [Indexer finden](Provider%20%26%20Indexer/Provider%20%26%20Indexer.md#22-indexer-finden)

* 3.0 **[Der Docker-Compose Stack](Docker%20Compose%20Stack/Docker%20Compose%20Stack.md#30-der-docker-compose-stack)**
  * 3.1 [Das System vorbereiten](Docker%20Compose%20Stack/Docker%20Compose%20Stack.md#31-das-system-vorbereiten)

* 4.0 **[VPN- und Mesh-Konfiguration](Docker%20Compose%20Stack/VPNs.md#40-vpn--und-mesh-konfiguration)**
  * 4.1 [Das Netzwerk sichern mit Gluetun](Docker%20Compose%20Stack/VPNs.md#41-das-netzwerk-sichern-mit-gluetun)
  * 4.2 [Tailscale-Dienst auf dem Host-System hinzufügen](Docker%20Compose%20Stack/VPNs.md#42-tailscale-dienst-auf-dem-host-system-hinzufügen)

* 5.0 **[Usenet Downloader](Downloader/Sabnzbd%20vs%20NZBGet.md#50-usenet-downloader-sabnzbd-vs-nzbget)**
  * 5.1 [SABnzbd vs. NZBGet: Der Vergleich](Downloader/Sabnzbd%20vs%20NZBGet.md#sabnzbd-vs-nzbget-der-vergleich)
  * 5.2 [Downloader zur docker-compose.yml hinzufügen](Downloader/Sabnzbd%20vs%20NZBGet.md#51-downloader-zur-docker-composeyml-hinzufügen)
  * 5.3 [Downloader konfigurieren: Usenet-Provider](Downloader/Sabnzbd%20vs%20NZBGet.md#52-downloader-konfigurieren-usenet-provider)

* 6.0 **[Prowlarr, Sonarr und Radarr](Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md#60-prowlarr-sonarr-und-radarr)**
  * 6.1 [Was ist der "Arr"-Stack?](Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md#61-was-ist-der-arr-stack)
  * 6.2 ["Arr"-Apps installieren](Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md#62-arr-apps-installieren)
  * 6.3 ["Arr"-Apps konfigurieren](Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md#63-arr-apps-konfigurieren)

* 7.0 **[Jellyfin & Jellyseerr: Das Frontend deiner Mediathek](Frontend/Jellyfin%20und%20Jellyseer.md#70-jellyfin--jellyseerr-das-frontend-deiner-mediathek)**
  * 7.1 [Jellyfin zum Docker-Stack hinzufügen](Frontend/Jellyfin%20und%20Jellyseer.md#71-jellyfin-zum-docker-stack-hinzufügen)
  * 7.2 [Jellyseerr zum Docker-Stack hinzufügen](Frontend/Jellyfin%20und%20Jellyseer.md#72-jellyseerr-zum-docker-stack-hinzufügen)

* 8.0 **[Der finale Stack](Docker%20Compose%20Stack/Finaler%20Stack.md#80-der-komplette-docker-stack)**

---

### Lexikon

* [Usenet Lexikon](Lexikon/Lexikon.md#usenet-lexikon)