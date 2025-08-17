# 4.0 VPN- und Mesh-Konfiguration

Nachdem wir die zentralen Konzepte verstanden und Docker Compose eingerichtet haben, beginnen wir mit der grundlegenden Netzwerkkonfiguration deines Stacks. Hierbei konzentrieren wir uns auf die Absicherung deiner Downloads und den sicheren Fernzugriff.

## Was ist ein VPN und warum ist es für Usenet wichtig?

Ein **VPN (Virtual Private Network)** ist eine Technologie, die eine sichere und verschlüsselte Verbindung zwischen deinem Computer und einem Server im Internet herstellt. Stell dir vor, du leitest deinen gesamten Internetverkehr durch einen sicheren, privaten Tunnel.

Für Usenet-Downloads ist ein VPN aus folgenden Gründen essenziell:

* **Anonymität:** Deine tatsächliche IP-Adresse wird verborgen, da der gesamte Traffic über die IP-Adresse des VPN-Servers läuft. Das schützt deine Privatsphäre.
* **Sicherheit:** Die Daten werden verschlüsselt, sodass dein Internetanbieter (oder andere Dritte) nicht einsehen können, welche Dateien du herunterlädst.

## Was ist ein Mesh-VPN und warum nutzen wir Tailscale?

Ein **Mesh-VPN**, wie es von Tailscale verwendet wird, ist eine moderne Form des VPN. Während ein herkömmliches VPN all deinen Traffic über einen einzigen zentralen Server leitet, um ihn zu verschleiern, ermöglicht ein Mesh-VPN eine direkte, verschlüsselte Kommunikation zwischen all deinen Geräten – egal wo sie sich befinden.

Stell dir vor, deine Geräte (z. B. dein Heimserver, dein Laptop und dein Handy) sind Teil eines privaten, sicheren Netzwerks. Mit Tailscale kannst du von deinem Handy aus direkt und sicher auf die Benutzeroberflächen deiner Docker-Dienste auf deinem Server zugreifen, ohne dass deine Daten über einen unsicheren Weg übertragen werden. Es ist die optimale Lösung für einen sicheren Fernzugriff auf deinen Usenet-Stack.

---

## 4.1 Das Netzwerk sichern mit Gluetun

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

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    environment:
      - VPN_SERVICE_PROVIDER=dein-vpn-provider # z.B. nordvpn, mullvad, expressvpn
      - VPN_TYPE=openvpn # oder wireguard, je nach Anbieter
      - OPENVPN_USER=dein-benutzername
      - OPENVPN_PASSWORD=dein-passwort
      - SERVER_COUNTRIES=Netherlands # Oder ein Land deiner Wahl
      - TZ=Europe/Berlin
      - PUID=1000 # durch deine PUID ersetzen
      - PGID=1000 # durch deine PGID ersetzen
    ports:
      # Port-Mappings für die Dienste, die über Gluetun erreichbar sein sollen
      - 8080:8080   # Sabnzbd
      - 6789:6789   # NZBGet
      - 8686:8686   # Radarr
      - 8989:8989   # Sonarr
      - 9696:9696   # Prowlarr
    volumes:
      - ./gluetun-config:/gluetun
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

Die angezeigte IP-Adresse sollte mit der eures OVPN-Server übereinstimmen.

---

## 4.2 Tailscale-Dienst auf dem Host-System hinzufügen

Nachdem wir das VPN-Fundament mit Docker Compose und Gluetun geschaffen haben, richten wir den sicheren Fernzugriff ein. Tailscale ist dafür die beste Lösung, da es einen sicheren, verschlüsselten Tunnel zwischen deinen Geräten und deinem Server schafft. Anstatt es in einem Docker-Container laufen zu lassen (um Subnet-Routing zu vermeiden, da wir Einsteigerfreundlich bleiben wollen), installieren wir Tailscale direkt auf dem Host-System. So können wir zuverlässig auf den Server zugreifen, ohne dass es zu Konflikten mit Docker oder Gluetun kommt.

**Tailscale installieren:** Öffne ein Terminal auf deinem System und führe diesen Befehl aus, um Tailscale zu installieren:

```bash
curl -fsSL [https://tailscale.com/install.sh](https://tailscale.com/install.sh) | sh
```

Dieses Skript erkennt dein System und installiert die notwendigen Pakete.

**Tailscale starten und authentifizieren:** Gib anschließend den folgenden Befehl ein, um den Tailscale-Dienst auf deinem System zu starten und ihn mit deinem Tailscale-Konto zu verknüpfen.

```bash
sudo tailscale up
```

Der Terminal-Ausgabe wird ein Link angezeigt. Kopiere diesen Link und öffne ihn in deinem Webbrowser, um dich bei deinem Tailscale-Konto anzumelden und das Gerät zu autorisieren.

### Verbindung zum Mesh-VPN herstellen

Nachdem dein Server nun Teil deines Mesh-VPNs ist, musst du deine Endgeräte (Smartphone, Tablet, PC etc.) mit dem Netzwerk verbinden.

Der große Vorteil von **Tailscale** ist, dass es native Anwendungen für alle gängigen Betriebssysteme bietet. Die Installation und Einrichtung ist sehr einfach und erfordert keine komplexe manuelle Konfiguration.

#### So verbindest du deine Geräte

1. **Tailscale-App installieren:** Lade die offizielle Tailscale-App aus dem jeweiligen App Store oder von der [Tailscale-Website](https://tailscale.com/download) herunter. Die App ist für folgende Systeme verfügbar:
    * iOS und iPadOS
    * Android
    * Windows
    * macOS
    * Linux
2. **Mit deinem Konto anmelden:** Öffne die App auf deinem Gerät und melde dich mit demselben Konto an, das du für die Registrierung deines Servers verwendet hast.

Sobald du angemeldet bist, stellt die App automatisch eine sichere, verschlüsselte Verbindung zu deinem Mesh-Netzwerk her. Dein Gerät kann nun über die private **Tailscale-IP-Adresse** deines Servers direkt auf die Dienste zugreifen. Du findest diese IP-Adresse in der Tailscale-Admin-Konsole unter der Geräteliste.
