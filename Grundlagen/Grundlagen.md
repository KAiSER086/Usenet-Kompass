# 1.0 Grundlagen

## 1.1 Was ist Usenet?

Stell dir das **Usenet** als ein dezentrales, weltweites Netzwerk vor, das deutlich älter ist als das World Wide Web, wie wir es heute kennen. Ursprünglich als eine Art riesiges Diskussionsforum konzipiert, das in Tausende von Themenbereichen (sogenannten Newsgroups) unterteilt ist, wird es heute überwiegend für den dezentralen Austausch von Dateien genutzt.

Anders als bei zentralisierten Diensten wie Webseiten oder Cloud-Speichern gibt es keine zentrale Stelle. Stattdessen kommunizieren die Server von Usenet-Providern miteinander und synchronisieren ihre Inhalte, wodurch eine robuste und schnelle Verteilung von Informationen und Dateien ermöglicht wird.

### Usenet vs. Torrent: Die grundlegenden Unterschiede

Obwohl sowohl Usenet als auch Torrent (BitTorrent) zum Austausch von Dateien genutzt werden, unterscheiden sie sich grundlegend in ihrer Funktionsweise und den damit verbundenen Konsequenzen:

* **Usenet**
  * **Technologie:** Usenet basiert auf dem **Client-Server-Prinzip**. Du lädst Daten verschlüsselt direkt von den Servern deines Providers herunter – du lädst selbst nichts für andere Nutzer hoch.
  * **Anonymität:** Sehr hoch. Die Verbindung besteht ausschließlich zwischen dir und dem News-Server und wird über SSL/TLS (Port 563/443) verschlüsselt. Dritte oder andere Nutzer sehen deine IP-Adresse nicht.
  * **Geschwindigkeit:** Konstant maximale Bandbreite deiner Internetverbindung, unabhängig von anderen Nutzern.
  * **Verfügbarkeit:** Wird durch die sogenannte **Retention (Vorhaltezeit)** bestimmt. Führende Provider speichern Uploads über 15 Jahre (5.800+ Tage) verlässlich auf ihren Servern.
  * **Nutzung:** Erfordert einen (meist kostenpflichtigen) Zugang zu einem Usenet-Provider.

* **Torrent**
  * **Technologie:** Torrent ist ein **Peer-to-Peer (P2P)-System**. Dateien werden nicht von einem Server geladen, sondern in kleinen Teilen von vielen anderen Nutzern (Peers) herunter- und gleichzeitig hochgeladen.
  * **Anonymität:** Sehr gering. Jeder Teilnehmer im Download-Schwarm (Swarm) sieht öffentlich die IP-Adressen aller anderen Teilnehmer.
  * **Geschwindigkeit:** Stark abhängig von der Anzahl der „Seeder“ (Upload-Quellen).
  * **Verfügbarkeit:** Sobald niemand mehr eine Datei aktiv bereitstellt (seetet), ist sie verloren.
  * **Nutzung:** Meist kostenlos, birgt aber ohne komplexe Absicherung hohe Risiken.

### Warum Usenet gerade in Deutschland besser ist

In Deutschland spielt der Aspekt der **Rechtslage** eine entscheidende Rolle:

* **Rechtssicherheit und Schutz vor Abmahnungen:**
  * **Torrent:** Da bei Torrents das Herunterladen und gleichzeitige Hochladen (**Filesharing**) untrennbar verknüpft ist, erfassen spezialisierte Kanzleien die öffentlich sichtbaren IP-Adressen im P2P-Schwarm für teure Abmahnungen.
  * **Usenet:** Beim Usenet lädst du ausschließlich herunter (reiner Client-Server-Traffic). Deine IP-Adresse ist im Netzwerk nicht öffentlich sichtbar, und der Transfer zum Server ist TLS-verschlüsselt. Abmahnungen, wie sie bei Torrents an der Tagesordnung sind, gibt es im Usenet nicht.

---

## 1.2 Systemvoraussetzungen & Hardware-Wahl

Bevor du beginnst, solltest du dir überlegen, welche Hardware du verwenden möchtest. Unser Setup ist ideal für stromsparende 24/7-Homeserver konzipiert.

### Warum Linux die beste Wahl ist

Obwohl Docker auch auf Windows und macOS läuft, wurde es **nativ für Linux entwickelt**. Auf Linux-Systemen arbeitet Docker am stabilsten, ressourcenschonendsten und ohne Virtualisierungs-Overhead.

Für diesen Guide empfiehlt sich eine schlanke Linux-Distribution wie **DietPi** oder **Debian**. Diese Systeme sind extrem stabil, booten in Sekunden und sind ideal für den Dauerbetrieb.

#### 🍓 Option 1: Raspberry Pi 5 mit DietPi (Der stromsparende Klassiker)

* **Vorteile:** Sehr geringer Stromverbrauch (ca. 3–5 Watt), geräuschlos, kompakt und vollkommen ausreichend für Downloader (NZBGet/SABnzbd), *arr-Apps und Direct-Play-Streaming.
* **Beachte:** Ein Single-Board-Computer (ARM CPU) stößt an Grenzen bei rechenintensiver Video-Transkodierung in Echtzeit.

#### 💻 Option 2: Intel N100 / N97 Mini-PC (Die moderne Allround-Empfehlung)

* **Vorteile:** Kompakte x86-Mini-PCs mit Intel N100 Prozessor kosten oft nur 120–150 € und verbrauchen im Leerlauf ebenfalls nur ca. 6 Watt. Sie verfügen über **Intel Quick Sync Video (QSV)** und können mehrere 4K-Videostreams in Jellyfin mühelos in Hardware transkodieren.
* **Ideal für:** Nutzer, die häufig von unterwegs mit begrenzter mobiler Bandbreite auf ihre Mediathek zugreifen möchten.

---

### Was ist Transkodierung und wann ist sie nötig?

**Transkodierung** ist das Umwandeln eines Videos in Echtzeit in ein anderes Format oder eine geringere Bitrate:

* **Direct Play (Standard):** Moderne Smart-TVs, Apple TV, Fire TV Sticks und Smartphones spielen nahezu alle Videoformate (H.264, HEVC, MKV) direkt ab – der Server reicht die Datei ohne CPU-Last weiter.
* **Transkodierung:** Wird nur nötig, wenn du von unterwegs streamst und dein Upload zu langsam für die volle 4K-Bitrate ist, oder wenn ein alter Browser ein Videoformat nicht nativ unterstützt.