# 3.0 Der Docker-Compose Stack

## Was sind Docker-Container und wie funktionieren sie?

Ein **Docker-Container** ist ein in sich geschlossenes Softwarepaket. Er bündelt eine Anwendung und alle ihre Abhängigkeiten – also Code, Laufzeitumgebung, Bibliotheken und Konfigurationsdateien – in einer einzigen, isolierten Einheit.

Der Container läuft in einer isolierten Umgebung, die das Host-Betriebssystem und andere Container nicht beeinträchtigt. Im Gegensatz zu traditionellen virtuellen Maschinen, die ein komplettes Betriebssystem emulieren, nutzen Docker-Container den Kernel des Host-Systems. Das macht sie extrem schlank, effizient und schnell.

### Warum ist die Arbeit mit Docker optimal?

* **Portabilität:** Container laufen überall gleich, wo Docker installiert ist. Du kannst deinen Stack problemlos auf einem Linux-Server, einem Synology-NAS oder einem Windows-System starten, ohne die Konfiguration ändern zu müssen.
* **Isolierung:** Jeder Dienst (z. B. Sonarr oder Radarr) läuft in seinem eigenen Container, wodurch Konflikte vermieden werden und die Stabilität des Gesamtsystems erhöht wird.
* **Reproduzierbarkeit:** Einmal konfiguriert, kannst du deinen gesamten Stack jederzeit exakt gleich wiederherstellen oder auf einen neuen Server umziehen.
* **Einfache Verwaltung:** Container lassen sich mit einfachen Befehlen starten, stoppen oder neu starten. Du musst dich nicht um die Installation von Abhängigkeiten auf deinem System kümmern.

### Wie funktioniert ein Docker-Compose-Stack?

Ein **Docker-Compose-Stack** ist eine Ansammlung von mehreren Docker-Containern, die in einer einzigen Datei (`docker-compose.yml`) definiert werden. Diese Datei ist die Bauanleitung für dein gesamtes System. Sie beschreibt, welche Container zusammengehören, wie sie miteinander kommunizieren sollen und welche Konfigurationen sie benötigen.

Für unseren Usenet-Guide definieren wir in dieser zentralen Datei alle Dienste wie **Gluetun (VPN)**, **SABnzbd/NZBGet (Downloader)**, **Sonarr, Radarr, Prowlarr (PVR)** und **Seerr (Requests)**. Mit einem einzigen Befehl startest du dann das gesamte System als einen zusammenhängenden "Stack".

---

## 3.1 Das System vorbereiten

Bevor wir mit der Konfiguration der `docker-compose.yml` beginnen, müssen die notwendigen Abhängigkeiten auf deinem System installiert werden: Docker und Docker Compose. Wir haben hier die Befehle für die gängigsten Linux-Distributionen zusammengefasst.

### Installation für Debian, Ubuntu und Derivate

Öffne ein Terminal und führe die folgenden Befehle aus, um Docker zu installieren. Wir beginnen mit der Quelle für Debian/Bookworm.

```bash
# Paketlisten aktualisieren
sudo apt update

# Notwendige Pakete für die Installation hinzufügen
sudo apt install ca-certificates curl gnupg

# Das offizielle Docker GPG-Schlüsselverzeichnis hinzufügen
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Das Docker-Repository für Debian hinzufügen
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Paketlisten erneut aktualisieren und Docker installieren
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Den aktuellen Benutzer zur Docker-Gruppe hinzufügen, damit du nicht ständig sudo benutzen musst
sudo usermod -aG docker $USER
```

### Installation für CentOS, Fedora und RHEL

Öffne ein Terminal und führe die folgenden Befehle aus. Wir nutzen dnf, was der neuere Paketmanager ist.

```bash
# System aktualisieren
sudo dnf update

# Docker-Repository hinzufügen
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Docker und Docker Compose installieren
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Den Docker-Dienst starten und für den Systemstart aktivieren
sudo systemctl start docker
sudo systemctl enable docker

# Den aktuellen Benutzer zur Docker-Gruppe hinzufügen
sudo usermod -aG docker $USER
```

### Installation für Arch Linux und Derivate

Öffne ein Terminal und führe die folgenden Befehle aus.

```bash
# Paketlisten aktualisieren
sudo pacman -Syu

# Docker und Docker Compose installieren
sudo pacman -S docker docker-compose

# Den Docker-Dienst starten und für den Systemstart aktivieren
sudo systemctl start docker.service
sudo systemctl enable docker.service

# Den aktuellen Benutzer zur Docker-Gruppe hinzufügen
sudo usermod -aG docker $USER
```

### Installation überprüfen

```bash
# Zeigt die installierte Docker-Version an
docker --version

# Zeigt die installierte Docker Compose-Version an
docker compose version
```

---

## 3.2 Konfigurationsverwaltung (.env) & Log-Rotation

Damit du vertrauliche Daten (wie VPN-Schlüssel) und systemspezifische Einstellungen (wie Benutzer-IDs und Pfade) nicht direkt in der `docker-compose.yml` verwalten musst, unterstützt der Usenet-Kompass das **Environment-File-Prinzip (`.env`)**.

### Warum eine `.env`-Datei?
* **Sicherheit:** Deine Passwörter und WireGuard-Keys verbleiben in der lokalen `.env`-Datei. Diese wird über `.gitignore` geschützt und landet niemals versehentlich in öffentlichen Repositories.
* **Zentralität:** Musst du z. B. deine Festplattenpfade (`DATA_DIR`) oder die Zeitzone ändern, passt du das an einer einzigen Stelle an.
* **Standard-Fallbacks:** Alle Compose-Dateien im Usenet-Kompass nutzen das Format `${VARIABLENNAME:-standardwert}`. Das bedeutet: Falls keine `.env` vorhanden ist, startet der Stack trotzdem stabil mit erprobten Standardwerten.

### Die Vorlage `.env.example` nutzen
Kopiere einfach die bereitgestellte Vorlage in dein Projektverzeichnis:
```bash
cp .env.example .env
nano .env
```

Hier trägst du deine Benutzer-IDs (`id -u` und `id -g`), deine Zeitzone und ggf. deine VPN-Zugangsdaten ein.

### Schutz vor vollen Festplatten (Docker Log-Rotation)
Docker speichert Container-Logs standardmäßig unbegrenzt. Läuft ein Downloader oder Arr-Dienst über längere Zeit, können Logs gigabyteweise Speicherplatz füllen und insbesondere auf SD-Karten (z. B. beim Raspberry Pi) oder kleinen SSDs zum Systemstillstand führen.

Alle Vorlagen im Usenet-Kompass definieren daher einen ressourcenschonenden Logging-Block:
```yaml
x-logging: &default-logging
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"
```
Damit ist garantiert, dass ein Dienst niemals mehr als 30 MB (3 Dateien à 10 MB) an Logs auf deinem System belegt.

---

Jetzt können wir mit der Einrichtung des VPN und Mesh-Netzwerks fortfahren.
