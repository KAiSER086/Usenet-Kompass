# 7.0 Jellyfin & Jellyseerr: Das Frontend deiner Mediathek

## Jellyfin vs. Plex vs. Emby: Warum diese Wahl?

Als Medienserver gibt es drei Hauptanwärter: das beliebte **Plex**, das quelloffene **Jellyfin** und das Freemium-Modell **Emby**. Auch wenn Plex und Emby gute Optionen sind, entscheiden wir uns in dieser Anleitung für Jellyfin, und das aus gutem Grund.

Der größte Vorteil von Jellyfin für unser Setup ist seine **nahtlose Integration mit Tailscale**. Plex nutzt für das Streaming außerhalb deines Heimnetzwerks eine **von den Plex-Servern vermittelte Verbindung**, die einen **kostenpflichtigen "Remote-Pass"** erfordert. Dies würde die Vorteile unserer sicheren Tailscale-Verbindung untergraben.

Zusätzlich dazu hat Emby ein sogenanntes **Freemium-Modell**. Das bedeutet, dass grundlegende Funktionen kostenlos sind, viele wichtige Features (wie der Zugriff über mobile Apps oder Hardware-Transcoding) jedoch eine monatliche oder einmalige Gebühr erfordern.

Jellyfin hingegen ist komplett quelloffen und vertraut der Sicherheit deines eigenen Netzwerks. Da Tailscale einen direkten, sicheren Tunnel zu deinem Server aufbaut, benötigt Jellyfin keine zusätzlichen Einstellungen.

Zusammenfassend bietet Jellyfin die folgenden Vorteile:

* **100% kostenlos:** Alle Funktionen sind ohne Abonnement oder Lizenzgebühren verfügbar.
* **Volle Kontrolle:** Du hast die volle Kontrolle über deine Daten und deinen Server. Es gibt keine Verbindung zu externen Cloud-Diensten.
* **Ideal für Tailscale:** Es ist die perfekte Ergänzung für unser sicheres VPN, da keine Port-Freigaben oder externen Server erforderlich sind.
* **Keine Einschränkungen:** Alle Funktionen, wie das mobile Streaming oder Hardware-Transcoding, stehen dir sofort zur Verfügung.

## 7.1 Jellyfin zum Docker-Stack hinzufügen

Füge den folgenden Codeblock in deine `docker-compose.yml` ein, idealerweise unter deinen anderen Diensten.

```yaml
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
```

**Wichtiger Hinweis zu den Pfaden:** Die volumes stellen die Verbindung zwischen deinen Medienordnern auf der Festplatte und dem Jellyfin-Container her. Achte darauf, dass du hier exakt die gleichen Pfade verwendest, die du bereits für Radarr und Sonarr (in meinem Fall `/mnt/16TB/Media/movies` und `/mnt/16TB/Media/tvshows`) festgelegt hast. Dies ist entscheidend, damit Jellyfin die heruntergeladenen Dateien auch finden kann.

### Jellyfin konfigurieren

Sobald du deine docker-compose.yml aktualisiert hast, starte deinen Stack neu, damit der neue Dienst erstellt wird:

```bash
docker compose up -d
```

Nachdem der Container gestartet ist, kannst du mit der Einrichtung beginnen:

* **Öffne das Webinterface:** Gehe in deinem Browser zu `http://<deine-tailscale-ip>:8096`.
* **Mediathek hinzufügen:** Folge dem Einrichtungsassistenten und füge deine Mediatheken hinzu. Wähle als Pfade die internen Container-Pfade, die du in deiner docker-compose.yml festgelegt hast:
  * Für Filme: /data/movies
  * Für Serien: /data/tvshows

Jellyfin scannt nun deine Ordner und organisiert automatisch deine gesamte Mediensammlung.

---

## Was ist Jellyseerr?

Jellyseerr ist ein **Medienanfrage-Portal**, das als Frontend für Radarr und Sonarr fungiert. Es bietet eine intuitive, Netflix-ähnliche Oberfläche, über die du, deine Familienmitglieder oder Freunde ganz einfach Filme und Serien vorschlagen können, die sie sich wünschen.

Anstatt dir eine Nachricht mit einem Titel zu schicken, können sie einfach nach dem Film oder der Serie suchen und auf "Anfragen" klicken.

### Wie funktioniert es?

* **Benutzerfreundlich:** Jeder, dem du Zugriff gewährst, kann die Seite in seinem Browser öffnen und nach Titeln suchen. Die Benutzeroberfläche zeigt an, welche Titel bereits in deiner Mediathek vorhanden sind und welche angefragt werden können.
* **Automatisierung:** Wenn ein Benutzer eine Anfrage stellt, sendet Jellyseerr diese automatisch an den entsprechenden Dienst (Radarr für Filme, Sonarr für Serien).
* **Status-Updates:** Radarr und Sonarr kümmern sich um den Download. Jellyseerr informiert den anfragenden Nutzer, sobald der Titel heruntergeladen und in deiner Mediathek verfügbar ist.

## 7.2 Jellyseer zum Docker-Stack hinzufügen

Füge den folgenden Codeblock in deine `docker-compose.yml` ein, idealerweise unter deinem Jellyfin-Dienst.

```yaml
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
      - gluetun
    restart: unless-stopped
```

### Jellyseerr konfigurieren

Nachdem du den Docker-Stack mit `docker compose up -d` aktualisiert hast, ist die Einrichtung von Jellyseerr in wenigen Schritten erledigt.

* **Öffne das Webinterface:** Gehe in deinem Browser zu `http://<deine-tailscale-ip>:5055`.
* **Verbinde Jellyfin:** Folge dem Assistenten und verbinde Jellyseerr mit deinem Jellyfin-Server. Dies ermöglicht Jellyseerr, die Inhalte deiner Mediathek zu sehen und zu synchronisieren.
* **Verbinde Radarr & Sonarr:** Dies ist der entscheidende Schritt. Gib die Hostnamen deiner Radarr- und Sonarr-Container ein, gefolgt von ihren jeweiligen Ports.
  * Für **Radarr**: Hostname `radarr` und Port `8686`.
  * Für **Sonarr**: Hostname `sonarr` und Port `8989`.
  * **Wichtig**: Da die Container im selben Docker-Netzwerk laufen, kannst du die Containernamen (`radarr`, `sonarr`) anstelle von IP-Adressen verwenden.
* **Konfiguriere Anfragen & Nutzer**: Lege in den Einstellungen fest, welche Nutzer Anfragen stellen dürfen und welche Mediathek sie sehen können.

Sobald du diese Schritte abgeschlossen hast, ist dein vollautomatisierter Stack einsatzbereit. Deine Nutzer können Filme und Serien anfragen, die dann automatisch heruntergeladen und zu deiner Jellyfin-Mediathek hinzugefügt werden.
