# 3.3 VPN- und Mesh-Konfiguration

Nachdem wir die zentralen Konzepte verstanden und Docker Compose eingerichtet haben, beginnen wir mit der grundlegenden Netzwerkkonfiguration deines Stacks. Hierbei konzentrieren wir uns auf die Absicherung deiner Downloads und den sicheren Fernzugriff.

## Was ist ein VPN und warum ist es für Usenet wichtig?

Ein **VPN (Virtual Private Network)** ist eine Technologie, die eine sichere und verschlüsselte Verbindung zwischen deinem Computer und einem Server im Internet herstellt. Stell dir vor, du leitest deinen gesamten Internetverkehr durch einen sicheren, privaten Tunnel.

Für Usenet-Downloads ist ein VPN aus folgenden Gründen essenziell:

* **Anonymität:** Deine tatsächliche IP-Adresse wird verborgen, da der gesamte Traffic über die IP-Adresse des VPN-Servers läuft. Das schützt deine Privatsphäre.
* **Sicherheit:** Die Daten werden verschlüsselt, sodass dein Internetanbieter (oder andere Dritte) nicht einsehen können, welche Dateien du herunterlädst.

## Was ist ein Mesh-VPN und warum nutzen wir Tailscale?

Ein **Mesh-VPN**, wie es von Tailscale verwendet wird, ist eine moderne Form des VPN. Während ein herkömmliches VPN all deinen Traffic über einen einzigen zentralen Server leitet, ermöglicht ein Mesh-VPN eine direkte, verschlüsselte Kommunikation zwischen all deinen Geräten – egal wo sie sich befinden.

Stell dir vor, deine Geräte (z. B. dein Heimserver, dein Laptop und dein Handy) sind Teil eines privaten, sicheren Netzwerks. Mit Tailscale kannst du von deinem Handy aus direkt und sicher auf die Benutzeroberflächen deiner Docker-Dienste auf deinem Server zugreifen, ohne dass deine Daten über einen unsicheren Weg übertragen werden. Es ist die optimale Lösung für einen sicheren Fernzugriff auf deinen Usenet-Stack.

---

## 3.4 Das Netzwerk sichern mit Gluetun

Um deine Privatsphäre zu schützen und deine Downloads abzusichern, leiten wir den gesamten Datenverkehr über ein VPN. Gluetun ist ein leistungsstarker Docker-Container, der dies extrem einfach macht.

Bevor wir den Dienst in der `docker-compose.yml` definieren, erstellen wir einen Ordner auf deinem Host-System, in dem die Container ihre Konfigurationsdateien ablegen werden. Dies ist wichtig, damit deine Einstellungen auch nach einem Neustart des Containers erhalten bleiben.

Führe die folgendenden Befehle im Hauptverzeichnis deines Systems aus:

```bash
mkdir docker
cd docker
```

Da wir das Verzeichnis jetzt erstellt haben, können wir mit der `docker-compose.yml` beginnen, wir benötigen aber noch die PUID und die PGID deines Benutzers:

```bash
# PUID und PGID notieren
id

# docker-compose.yml erstellen
nano docker-compose.yml
```

Dort fügen wir folgenden Code ein:

```bash
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    environment:
      - VPN_SERVICE_PROVIDER=dein-vpn-provider # z.B. nordvpn, mullvad, expressvpn
      - VPN_TYPE=ovpn # oder wireguard, je nach Anbieter
      - VPN_USER=dein-benutzername
      - VPN_PASSWORD=dein-passwort
      - SERVER_COUNTRIES=Netherlands # Oder ein Land deiner Wahl
      - TZ=Europe/Berlin
      - PUID=1000 # durch deine PUID ersetzen
      - PGID=1000 # durch deine PGID ersetzen
    volumes:
      - ./gluetun-config:/gluetun
    ports:
      # Hier werden Ports für andere Dienste gemappt, die über das VPN laufen sollen.
      # Jellyfin, Jellyseer und Tailscale werden nicht getunnelt.
      - 8080:8080 # SABNZBd
      - 6789:6789 # NZBGET
      - 8989:8989 # Sonarr
      - 7878:7878 # Radarr
      - 9696:9696 # Prowlarr
    restart: unless-stopped
```

Folgende VPN Anbieter haben volle OVPN Integration:

```bash
AirVPN, Cyberghost, ExpressVPN, FastestVPN, Giganews, HideMyAss, IPVanish, IVPN, Mullvad, NordVPN, Perfect Privacy, Privado, Private Internet Access, PrivateVPN, ProtonVPN, PureVPN, SlickVPN, Surfshark, TorGuard, VPNSecure.me, VPNUnlimited, Vyprvpn, WeVPN, Windscribe
```

Jetzt überprüfen wir ob die Verbindung erfolgreich war:

```bash
# Im Docker Verzeichnis
docker compose up -d

# Shell des Gluetun-Containers öffnen
docker exec -it gluetun sh

# IP-Adresse abfragen
curl ipinfo.io/ip
```

---

## 3.5 Tailscale-Dienst hinzufügen

Nachdem das VPN-Fundament steht, richten wir den sicheren Fernzugriff ein. Tailscale ist dafür die beste Lösung, da es einen sicheren, verschlüsselten Tunnel zwischen deinen Geräten und deinem Server schafft.

Füge diesen Dienst zu deiner bestehenden `docker-compose.yml`hinzu:

```bash
services:
  gluetun:
    # ... der Gluetun-Dienst steht hier
  
  tailscale:
    container_name: tailscale
    image: tailscale/tailscale:latest
    hostname: dein-servername # nur Kleinbuchstaben und - statt Leerzeichen
    volumes:
      - ./tailscale-data:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun # Zugriff auf das TUN-Gerät des Hosts
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

Es ist wichtig auf die korrekte YAML-Einrückung zu achten, das vemeidet spätere Fehlermeldungen:

```bash
services:        # <- Hauptabschnitt (Ebene 0)
  gluetun:       # <- Ein Dienst innerhalb von services (Ebene 1, 2 Leerzeichen Einrückung)
    image: ...   # <- Konfiguration des Dienstes (Ebene 2, 4 Leerzeichen Einrückung)
    ports:       # <- Eine Liste innerhalb der Konfiguration (Ebene 2, 4 Leerzeichen Einrückung)
      - "8080:8080" # <- Ein Element der Liste (Ebene 3, 6 Leerzeichen Einrückung)
  
  tailscale:     # <- Ein Dienst innerhalb von services (Ebene 1, 2 Leerzeichen Einrückung)
    image: ...   # <- Konfiguration des Dienstes (Ebene 2, 4 Leerzeichen Einrückung)
    volumes:     # <- Eine Liste innerhalb der Konfiguration (Ebene 2, 4 Leerzeichen Einrückung)
      - ...      # <- Ein Element der Liste (Ebene 3, 6 Leerzeichen Einrückung)

  sabnzbd
    image: ...
    volumes:
      - ....
```

Nachdem wir den Tailscale Block hinzugefügt haben, starten wir den Dienst:

```bash
docker compose up -d
```
