# 4.0 Netzwerk- und VPN-Konfiguration

Nachdem wir die zentralen Konzepte verstanden und Docker Compose eingerichtet haben, widmen wir uns der Netzwerkarchitektur deines Stacks. Hierbei hast du die freie Wahl zwischen zwei bewährten Ansätzen: **Direktanbindung ohne VPN** oder **zusätzliches VPN-Tunneling mit Gluetun**. Anschließend richten wir den sicheren Fernzugriff via **Tailscale** ein.

---

## 4.1 Die Wahl der Netzwerkarchitektur: Direktanbindung vs. VPN

Usenet-Verbindungen werden standardmäßig über **SSL/TLS (Port 563)** aufgebaut und sind somit auf Transportebene vollständig verschlüsselt. Ob du zusätzlich ein VPN zwischenschaltest, liegt in deinem eigenen Ermessen:

| Kriterium | Direktanbindung (Ohne VPN) | Mit VPN (Gluetun-Tunneling) |
| :--- | :--- | :--- |
| **Verschlüsselung** | **SSL/TLS (Port 563)** direkt zum Usenet-Server. | Doppelte Verschlüsselung: **WireGuard/OpenVPN** + SSL/TLS. |
| **Download-Performance** | **100 % native Leitungsgeschwindigkeit**, keine MTU-Reduktion (1500), 0 % CPU-Overhead für Tunnel-Kryptographie. | Bis zu 100 % bei WireGuard; mögliche Einbußen bei vielen parallelen Verbindungen oder schwachen Kernen. |
| **Kosten** | **0 €** (kein VPN-Abonnement erforderlich). | Kosten für einen VPN-Anbieter (z. B. Mullvad, ProtonVPN). |
| **Sichtbarkeit gegenüber ISP** | ISP sieht Datenaustausch mit News-Server-IP (Inhalte & Dateinamen bleiben unsichtbar). | ISP sieht ausschließlich verschlüsselten UDP-Traffic zum VPN-Server. |
| **Schutz vor ISP-Drosselung** | Abhängig vom ISP; einige Anbieter drosseln Usenet-Traffic in Stoßzeiten. | Wirksam: ISP kann Usenet-Pakete nicht identifizieren oder drosseln. |
| **Indexer-Anfragen (Prowlarr)** | Laufen über deine reguläre Heim-IP. | Laufen über die externe VPN-IP. |

---

### Welcher Weg ist der richtige für dich?

* **Wähle Direktanbindung (Ohne VPN), wenn:**
  * Du maximale Übertragungsraten und minimale Systemkomplexität anstrebst.
  * Dein Internetanbieter keine gezielten Drosselungen für Usenet-Ports vornimmt.
  * Du auf ein zusätzliches monatliches VPN-Abonnement verzichten möchtest.
  * *Hinweis:* Du kannst in diesem Fall direkt mit **[Kapitel 4.3: Tailscale für sicheren Fernzugriff](#43-tailscale-dienst-auf-dem-host-system-hinzufügen)** fortfahren und den Gluetun-Schritt überspringen!

* **Wähle VPN (Gluetun), wenn:**
  * Du deinen gesamten Usenet- und Indexer-Traffic gegenüber deinem Provider vollständig maskieren möchtest.
  * Du restriktives ISP-Traffic-Shaping zuverlässig umgehen willst.
  * Du den integrierten DNS- und Kill-Switch-Schutz von Gluetun nutzen möchtest.

---

## 4.2 Optional: Das Netzwerk sichern mit Gluetun

Wenn du dich für den Betrieb mit VPN entschieden hast, binden wir den Container **Gluetun** ein. Gluetun ist ein spezialisierter, extrem schlanker VPN-Client für Docker mit integriertem Kill-Switch.

### WireGuard vs. OpenVPN im Vergleich
* **WireGuard:** Direkt in den Linux-Kernel integriert. Bietet hohen Durchsatz bei minimaler Prozessorlast, besonders empfehlenswert für sparsame Hardware wie den Raspberry Pi 5 oder Mini-PCs.
* **OpenVPN:** Klassisches, weit verbreitetes Protokoll im Userspace. Erzeugt bei hohen Bandbreiten (ab 200–300 Mbit/s) spürbare CPU-Last.

---

### Gluetun-Verzeichnis vorbereiten

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

---

### Gluetun mit WireGuard einrichten

Füge folgenden Block in deine `docker-compose.yml` ein. Ersetze die Zugangsdaten durch die WireGuard-Konfigurationsdaten deines VPN-Anbieters (z. B. Mullvad, ProtonVPN, IVPN, NordVPN, Custom):

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
      - VPN_SERVICE_PROVIDER=mullvad # z. B. mullvad, protonvpn, ivpn, custom
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=dein-wireguard-private-key
      - WIREGUARD_ADDRESSES=10.64.0.1/32 # Deine zugewiesene WireGuard-IP
      - SERVER_COUNTRIES=Netherlands # Server-Standort
      - FIREWALL_OUTBOUND_SUBNETS=192.168.178.0/24 # Erlaube Zugriff aus dem lokalen Heimnetz (an dein Subnetz anpassen)
      - TZ=Europe/Berlin
      - PUID=1000 # durch deine PUID ersetzen
      - PGID=1000 # durch deine PGID ersetzen
    ports:
      # Port-Mappings für alle Dienste, die über Gluetun getunnelt werden
      - 8080:8080   # SABnzbd WebUI
      - 6789:6789   # NZBGet WebUI
      - 7878:7878   # Radarr WebUI & API
      - 8989:8989   # Sonarr WebUI & API
      - 9696:9696   # Prowlarr WebUI & API
    volumes:
      - ./config/gluetun:/gluetun
    restart: unless-stopped
```

> [!TIP]
> **Tipp – Zugangsdaten in `.env` auslagern:**
> Anstatt sensible Schlüssel wie `WIREGUARD_PRIVATE_KEY` direkt in die `docker-compose.yml` zu schreiben, kannst du diese sicher in der `.env`-Datei definieren (siehe [3.2 Konfigurationsverwaltung](Docker%20Compose%20Stack.md#32-konfigurationsverwaltung-env--log-rotation) und `.env.example`). In der Compose-Datei nutzt du dann einfach `- WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}`.

> 💡 **Wichtig für den lokalen LAN-Zugriff:**
> Gluetun blockiert standardmäßig durch seine integrierte Firewall alle Verbindungen außerhalb des Docker-Netzwerks. Mit `FIREWALL_OUTBOUND_SUBNETS=192.168.178.0/24` erlaubst du deinem lokalen Heimnetzwerk (z. B. PC oder Laptop im WLAN deiner Fritz!Box), direkt über die lokale IP des Servers auf die Webinterfaces zuzugreifen. Falls dein Heimnetz einen anderen IP-Bereich nutzt (z. B. `192.168.1.0/24` oder `10.0.0.0/24`), passe diesen Wert entsprechend an.

<details>
<summary><b>Fallback: Du möchtest trotzdem den "alten Onkel" OpenVPN nutzen? (Klick hier)</b></summary>

Falls dein VPN-Anbieter tatsächlich kein WireGuard unterstützt, kannst du die Umgebungsvariablen wie folgt auf OpenVPN anpassen:

```yaml
    environment:
      - VPN_SERVICE_PROVIDER=dein-vpn-provider
      - VPN_TYPE=openvpn
      - OPENVPN_USER=dein-benutzername
      - OPENVPN_PASSWORD=dein-passwort
      - SERVER_COUNTRIES=Netherlands
```
</details>

---

### VPN-Verbindung testen

Überprüfe nach dem Start, ob Gluetun erfolgreich verbunden ist und deine öffentliche IP-Adresse maskiert wird:

```bash
# Container starten
docker compose up -d

# Shell des Gluetun-Containers öffnen
docker exec -it gluetun sh

# Öffentliche VPN-IP-Adresse abfragen
curl ipinfo.io/ip
```

Die angezeigte IP-Adresse muss nun mit der deines gewählten VPN-Servers übereinstimmen.

---

## 4.3 Tailscale-Dienst auf dem Host-System hinzufügen

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