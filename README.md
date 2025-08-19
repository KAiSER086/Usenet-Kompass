# Usenet-Kompass

Der deutsche Guide zur vollständigen Usenet-Automatisierung als Docker Compose Stack, inklusive detaillierter Anleitungen für Gluetun, Sonarr, Radarr, Prowlarr, SABnzbd, NZBGet, Jellyseerr und (quasi) Tailscale.

---

## Inhaltsverzeichnis

### Inhaltsverzeichnis

* 1.0 **[Grundlagen](#10-grundlagen)**
  * 1.1 [Was ist Usenet?](#11-was-ist-usenet)
  * 1.2 [Systemvoraussetzungen & Hardware-Wahl](#12-systemvoraussetzungen--hardware-wahl)

* 2.0 **[Provider und Indexer](#20-provider-und-indexer)**
  * 2.1 [Usenet-Provider wählen](#21-usenet-provider-wählen)
  * 2.2 [Indexer finden](#22-indexer-finden)

* 3.0 **[Der Docker-Compose Stack](#30-der-docker-compose-stack)**
  * 3.1 [Das System vorbereiten](#31-das-system-vorbereiten)

* 4.0 **[VPN- und Mesh-Konfiguration](#40-vpn-und-mesh-konfiguration)**
  * 4.1 [Das Netzwerk sichern mit Gluetun](#41-das-netzwerk-sichern-mit-gluetun)
  * 4.2 [Tailscale-Dienst auf dem Host-System hinzufügen](#42-tailscale-dienst-auf-dem-host-system-hinzufügen)

* 5.0 **[Usenet Downloader](#50-usenet-downloader-sabnzbd-vs-nzbget)**
  * 5.1 [SABnzbd vs. NZBGet: Der Vergleich](#sabnzbd-vs-nzbget-der-vergleich)
  * 5.2 [Downloader konfigurieren: Usenet-Provider](#52-downloader-konfigurieren-usenet-provider)

* 6.0 **[Prowlarr, Sonarr und Radarr](#60-prowlarr-sonarr-und-radarr)**
  * 6.1 [Was ist der "Arr"-Stack?](#61-was-ist-der-arr-stack)
  * 6.2 ["Arr"-Apps installieren](#62-arr-apps-installieren)
  * 6.3 ["Arr"-Apps konfigurieren](#63-arr-apps-konfigurieren)

* 7.0 **[Jellyfin & Jellyseerr: Das Frontend deiner Mediathek](#70-jellyfin--jellyseerr-das-frontend-deiner-mediathek)**
  * 7.1 [Jellyfin zum Docker-Stack hinzufügen](#71-jellyfin-zum-docker-stack-hinzufügen)
  * 7.2 [Jellyseerr zum Docker-Stack hinzufügen](#72-jellyseerr-zum-docker-stack-hinzufügen)

* 8.0 **[Der finale Stack](#der-finale-stack)**

---

### Lexikon

* [Usenet Lexikon](#usenet-lexikon)
