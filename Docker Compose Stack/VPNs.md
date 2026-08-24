# 4.0 VPN- und Mesh-Konfiguration

Nachdem wir die zentralen Konzepte verstanden und Docker Compose eingerichtet haben, beginnen wir mit der grundlegenden Netzwerkkonfiguration deines Stacks. Hierbei konzentrieren wir uns auf die Absicherung deiner Downloads und den sicheren Fernzugriff.

## Was ist ein VPN und warum ist es für Usenet wichtig?

Ein **VPN (Virtual Private Network)** ist eine Technologie, die eine sichere und verschlüsselte Verbindung zwischen deinem Computer und einem Server im Internet herstellt. Stell dir vor, du leitest deinen gesamten Internetverkehr durch einen sicheren, privaten Tunnel.

Für Usenet-Downloads ist ein VPN aus folgenden Gründen nützlich:

* **Anonymität:** Deine tatsächliche IP-Adresse wird verborgen, da der gesamte Traffic über die IP-Adresse des VPN-Servers läuft. Das schützt deine Privatsphäre.
* **Sicherheit:** Die Daten werden verschlüsselt, sodass dein Internetanbieter (oder andere Dritte) nicht einsehen können, welche Server du kontaktierst.

## Was ist ein Mesh-VPN und warum nutzen wir Tailscale?

Ein **Mesh-VPN**, wie es von Tailscale verwendet wird, ist eine moderne Form des VPN. Während ein herkömmliches VPN all deinen Traffic über einen einzigen zentralen Server leitet, um ihn zu verschleiern, ermöglicht ein Mesh-VPN eine direkte, verschlüsselte Kommunikation zwischen all deinen Geräten – egal wo sie sich befinden.

Stell dir vor, deine Geräte (z. B. dein Heimserver, dein Laptop und dein Smartphone) sind Teil eines privaten, sicheren Netzwerks. Mit Tailscale kannst du von unterwegs direkt und sicher auf die Benutzeroberflächen deiner Docker-Dienste auf deinem Server zugreifen, ohne Ports am Router öffnen zu müssen. Es ist die optimale Lösung für einen sicheren Fernzugriff auf deinen Usenet-Stack.

---

## 4.1 Das Netzwerk sichern mit Gluetun

Um deine Privatsphäre zu schützen und deine Downloads abzusichern, leiten wir den Datenverkehr des Downloaders und der Arr-Apps über ein VPN. Gluetun ist ein schlanker, leistungsstarker Docker-Container, der dies extrem einfach macht.

Bevor wir den Dienst in der `docker-compose.yml` definieren, erstellen wir einen Ordner auf deinem Host-System, in dem die Container ihre Konfigurationsdateien ablegen:

```bash
mkdir docker
cd docker
```

Wir ermitteln zunächst die `PUID` und `PGID` deines System-Benutzers:

```bash
# PUID und PGID notieren
id

# docker-compose.yml erstellen
nano docker-compose.yml
```

Dort fügen wir folgenden Code ein:

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
      - VPN_TYPE=openvpn # oder wireguard, je nach Anbieter
      - OPENVPN_USER=dein-benutzername
      - OPENVPN_PASSWORD=dein-passwort
      - SERVER_COUNTRIES=Netherlands # Oder ein Land deiner Wahl
      - TZ=Europe/Berlin
      - PUID=1000 # durch deine PUID ersetzen
      - PGID=1000 # durch deine PGID ersetzen
    ports:
      # Port-Mappings für alle Dienste, die über Gluetun getunnelt werden
      - 8080:8080   # SABnzbd
      - 6789:6789   # NZBGet
      - 7878:7878   # Radarr
      - 8989:8989   # Sonarr
      - 9696:9696   # Prowlarr
    volumes:
      - ./config/gluetun:/gluetun
    restart: unless-stopped
```

Folgende VPN-Anbieter haben volle OVPN-Integration in Gluetun:

```text
AirVPN, Cyberghost, ExpressVPN, FastestVPN, Giganews, HideMyAss, IPVanish, IVPN, Mullvad, NordVPN, Perfect Privacy, Privado, Private Internet Access, PrivateVPN, ProtonVPN, PureVPN, SlickVPN, Surfshark, TorGuard, VPNSecure.me, VPNUnlimited, Vyprvpn, WeVPN, Windscribe
```

Jetzt überprüfen wir, ob die Verbindung erfolgreich aufgebaut wird:

```bash
# Container starten
docker compose up -d

# Shell des Gluetun-Containers öffnen
docker exec -it gluetun sh

# Öffentliche VPN-IP-Adresse abfragen
curl ipinfo.io/ip
```

Die angezeigte IP-Adresse sollte mit der IP deines VPN-Servers übereinstimmen.

---

## 4.2 Tailscale-Dienst auf dem Host-System hinzufügen

Nachdem das VPN-Fundament steht, richten wir den sicheren Fernzugriff ein. Tailscale installieren wir direkt auf dem Host-System. So kannst du zuverlässig auf den Server zugreifen, ohne dass es zu Routing-Konflikten mit Docker oder Gluetun kommt.

**Tailscale installieren:** Öffne ein Terminal auf deinem Host-System und führe folgenden Befehl aus:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Dieses Skript erkennt deine Linux-Distribution automatisch und installiert die notwendigen Pakete.

**Tailscale starten und authentifizieren:** Gib anschließend den folgenden Befehl ein, um den Tailscale-Dienst zu starten und ihn mit deinem Konto zu verknüpfen:

```bash
sudo tailscale up
```

In der Terminal-Ausgabe wird ein Authentifizierungs-Link angezeigt. Öffne diesen in deinem Webbrowser, um das Gerät in deinem Tailscale-Konto freizugeben.

### Verbindung zum Mesh-VPN herstellen

Nachdem dein Server Teil des Mesh-VPNs ist, verbindest du deine Endgeräte (Smartphone, Tablet, Laptop):

1. **Tailscale-App installieren:** Lade die offizielle Tailscale-App aus dem App Store / Google Play Store oder von der [Tailscale-Website](https://tailscale.com/download) herunter.
2. **Anmelden:** Öffne die App und melde dich mit demselben Konto an.

Sobald du verbunden bist, kannst du über die private **Tailscale-IP-Adresse** deines Servers jederzeit von überall sicher auf deine Webinterfaces (SABnzbd, Sonarr, Radarr, Jellyfin etc.) zugreifen.