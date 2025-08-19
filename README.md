# Usenet-Kompass

Der deutsche Guide zur vollständigen Usenet-Automatisierung als Docker Compose Stack, inklusive detaillierter Anleitungen für Gluetun, Sonarr, Radarr, Prowlarr, SABnzbd, NZBGet, Jellyseerr und (quasi) Tailscale.

---

## Inhaltsverzeichnis

* 1.0 **[Grundlagen](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Grundlagen/Grundlagen.md#10-grundlagen)**
  * 1.1 [Was ist Usenet?]([#11-was-ist-usenet](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Grundlagen/Grundlagen.md#10-grundlagen))
  * 1.2 [Systemvoraussetzungen & Hardware-Wahl]([#12-systemvoraussetzungen--hardware-wahl](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Grundlagen/Grundlagen.md#12-systemvoraussetzungen--hardware-wahl))

* 2.0 **[Provider und Indexer]([#20-provider-und-indexer](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Provider%20%26%20Indexer/Provider%20%26%20Indexer.md#20-provider-und-indexer))**
  * 2.1 [Usenet-Provider wählen]([#21-usenet-provider-wählen](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Provider%20%26%20Indexer/Provider%20%26%20Indexer.md#21-usenet-provider-w%C3%A4hlen))
  * 2.2 [Indexer finden]([#22-indexer-finden](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Provider%20%26%20Indexer/Provider%20%26%20Indexer.md#22-indexer-finden))

* 3.0 **[Der Docker-Compose Stack]([#30-der-docker-compose-stack](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Docker%20Compose%20Stack/Docker%20Compose%20Stack.md#30-der-docker-compose-stack))**
  * 3.1 [Das System vorbereiten]([#31-das-system-vorbereiten](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Docker%20Compose%20Stack/Docker%20Compose%20Stack.md#31-das-system-vorbereiten))

* 4.0 **[VPN- und Mesh-Konfiguration]([#40-vpn-und-mesh-konfiguration](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Docker%20Compose%20Stack/VPNs.md#40-vpn--und-mesh-konfiguration))**
  * 4.1 [Das Netzwerk sichern mit Gluetun]([#41-das-netzwerk-sichern-mit-gluetun](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Docker%20Compose%20Stack/VPNs.md#41-das-netzwerk-sichern-mit-gluetun))
  * 4.2 [Tailscale-Dienst auf dem Host-System hinzufügen]([#42-tailscale-dienst-auf-dem-host-system-hinzufügen](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Docker%20Compose%20Stack/VPNs.md#42-tailscale-dienst-auf-dem-host-system-hinzuf%C3%BCgen))

* 5.0 **[Usenet Downloader]([#50-usenet-downloader-sabnzbd-vs-nzbget](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Downloader/Sabnzbd%20vs%20NZBGet.md#50-usenet-downloader-sabnzbd-vs-nzbget))**
  * 5.1 [SABnzbd vs. NZBGet: Der Vergleich]([#sabnzbd-vs-nzbget-der-vergleich](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Downloader/Sabnzbd%20vs%20NZBGet.md#51-downloader-zur-docker-composeyml-hinzuf%C3%BCgen))
  * 5.2 [Downloader konfigurieren: Usenet-Provider]([#52-downloader-konfigurieren-usenet-provider](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Downloader/Sabnzbd%20vs%20NZBGet.md#52-downloader-konfigurieren-usenet-provider))

* 6.0 **[Prowlarr, Sonarr und Radarr]([#60-prowlarr-sonarr-und-radarr](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md#60-prowlarr-sonarr-und-radarr))**
  * 6.1 [Was ist der "Arr"-Stack?]([#61-was-ist-der-arr-stack](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md#61-was-ist-der-arr-stack))
  * 6.2 ["Arr"-Apps installieren]([#62-arr-apps-installieren](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md#62-arr-apps-installieren))
  * 6.3 ["Arr"-Apps konfigurieren]([#63-arr-apps-konfigurieren](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Arr-Stack/Prowlarr%2C%20Sonarr%2C%20Radarr.md#63-arr-apps-konfigurieren))

* 7.0 **[Jellyfin & Jellyseerr: Das Frontend deiner Mediathek]([#70-jellyfin--jellyseerr-das-frontend-deiner-mediathek](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Frontend/Jellyfin%20und%20Jellyseer.md#70-jellyfin--jellyseerr-das-frontend-deiner-mediathek))**
  * 7.1 [Jellyfin zum Docker-Stack hinzufügen]([#71-jellyfin-zum-docker-stack-hinzufügen](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Frontend/Jellyfin%20und%20Jellyseer.md#71-jellyfin-zum-docker-stack-hinzuf%C3%BCgen))
  * 7.2 [Jellyseerr zum Docker-Stack hinzufügen]([#72-jellyseerr-zum-docker-stack-hinzufügen](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Frontend/Jellyfin%20und%20Jellyseer.md#72-jellyseer-zum-docker-stack-hinzuf%C3%BCgen))

* 8.0 **[Der finale Stack]([#der-finale-stack](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Docker%20Compose%20Stack/Finaler%20Stack.md#80-der-komplette-docker-stack))**

---

### Lexikon

* [Usenet Lexikon]([#usenet-lexikon](https://github.com/KAiSER086/Usenet-Kompass/blob/main/Lexikon/Lexikon.md#xx-usenet-lexikon))

