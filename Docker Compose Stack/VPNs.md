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

```yaml
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

```yaml
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

```yaml
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

### 3.6 Tailscale-Mesh erstellen

Damit dein Tailscale-Dienst funktionieren kann, musst du dich zuerst auf der **Tailscale-Website** registrieren und den Container anschließend mit deinem Konto verknüpfen.

#### Schritt 1: Tailscale-Konto erstellen

1. Öffne die [Tailscale-Website](https://tailscale.com/) in deinem Browser.
2. Klicke auf **"Sign up"** oder **"Get started"**.
3. Registriere dich mit deinem bevorzugten Konto (Google, Microsoft, GitHub oder E-Mail).

Nach der Anmeldung befindest du dich in der Tailscale Admin Console. Dein Mesh-Netzwerk ist jetzt erstellt, hat aber noch keine verbundenen Geräte.

#### Schritt 2: Authentifizierungsschlüssel erstellen

Jetzt musst du einen speziellen Schlüssel erstellen, damit dein Docker-Container sich automatisch mit deinem neuen Netzwerk verbinden kann.

1. Gehe in der Admin Console zu **Settings > Auth keys**.
2. Erstelle einen neuen Schlüssel. Ein **"one-time key"** ist für diesen Zweck die sicherste und beste Option.
3. Kopiere den generierten Schlüssel.

#### Schritt 3: Container mit dem Netzwerk verbinden

Führe den folgenden Befehl im Terminal in deinem Docker-Verzeichnis aus, um den Tailscale-Client im Container zu starten und ihn mit deinem Mesh-Netzwerk zu verbinden. Ersetze dabei `<dein-auth-key>` mit dem Schlüssel, den du in Schritt 2 kopiert hast.

```bash
docker exec tailscale tailscale up --authkey <dein-auth-key> --accept-dns=false
```

Sobald das erledigt ist, kannst du deine Endgeräte in das Netzwerk einbinden.

### 3.7 Verbindung zum Mesh-VPN herstellen

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

Sobald du angemeldet bist, stellt die App automatisch eine sichere, verschlüsselte Verbindung zu deinem Mesh-Netzwerk her. Dein Gerät kann nun über die private Tailscale-IP-Adresse direkt auf die Dienste auf deinem Server zugreifen.
