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

### Brauche ich für das Usenet ein VPN? (SSL/TLS vs. VPN)

Eine der häufigsten Fragen von Einsteigern lautet, ob für Usenet-Downloads zwingend ein VPN benötigt wird. Die Antwort lautet: **Nein, ein VPN ist technisch nicht zwingend erforderlich – beide Ansätze haben handfeste Vor- und Nachteile:**

* **Direktverbindung via SSL/TLS (Standard Port 563):**
  * Verbindungen zu Usenet-Providern sind standardmäßig Ende-zu-Ende verschlüsselt (TLS), identisch mit moderner Browser- und Banking-Sicherheit.
  * Dein Internetanbieter (ISP) sieht zwar, dass Daten mit einem News-Server ausgetauscht werden, kann jedoch weder Dateinamen noch Inhalte einsehen.
  * Da es im Usenet keine P2P-Uploads an Dritte gibt, entfallen die typischen Filesharing-Abmahnrisiken vollständig.
  * **Vorteile:** Maximale native Leitungsgeschwindigkeit, kein CPU-Kryptographie-Overhead, keine MTU-Einbußen und keine monatlichen Kosten für ein VPN-Abonnement.

* **Zusätzlicher Schutz via VPN (Gluetun):**
  * Leitet den gesamten Netzwerkverkehr des Downloaders und der Indexer-Apps über einen VPN-Tunnel um.
  * Dein Internetanbieter sieht nicht einmal mehr die IP-Adresse des Usenet-Providers (hilfreich bei Providern, die Usenet-Ports in den Abendstunden drosseln).
  * Anfragen von Prowlarr an Indexer-Websites und APIs laufen über die maskierte VPN-IP statt über deinen privaten Internetanschluss.
  * **Vorteile:** Höchstmögliche Anonymität gegenüber allen externen Schnittstellen und Umgehung von ISP-Traffic-Shaping.

> Ob du deinen Stack direkt über SSL/TLS oder zusätzlich getunnelt über ein VPN betreibst, liegt ganz in deinem persönlichen Ermessen. Unser Guide und das Installationsskript unterstützen beide Varianten gleichermaßen.

---

## 1.2 Systemvoraussetzungen & Hardware-Wahl

Bevor du beginnst, solltest du dir überlegen, auf welcher Plattform du deinen Stack betreiben möchtest. Unser Setup ist modular aufgebaut und läuft gleichermaßen auf stromsparender lokaler Hardware (Homeserver) sowie auf externen Cloud-Servern (VPS).

### Warum Linux die beste Wahl ist

Obwohl Docker auch auf Windows und macOS läuft, wurde es **nativ für Linux entwickelt**. Auf Linux-Systemen arbeitet Docker am stabilsten, ressourcenschonendsten und ohne Virtualisierungs-Overhead.

Für diesen Guide empfiehlt sich eine schlanke Linux-Distribution wie **DietPi**, **Debian** oder **Ubuntu Server**. Diese Systeme sind extrem stabil, booten in Sekunden und sind ideal für den Dauerbetrieb.

#### 🍓 Tier 1: Budget & Single-Board-Computer (z. B. Raspberry Pi 5 oder 1–2 vCPU VPS)

* **Hardware:** Raspberry Pi 4/5 (DietPi), sparsame Thin-Clients oder Cloud-Einsteiger-VPS (1–2 vCPUs, 1–2 GB RAM).
* **Vorteile:** Extrem sparsam (3–5 Watt) bzw. minimale monatliche Serverkosten (3–4 €/Monat).
* **Fokus:** Schlanke Konfiguration. Ideal für NZBGet oder SABnzbd mit kleinerem Puffer (512M) und 15–20 Verbindungen. Video-Transkodierung in Jellyfin sollte deaktiviert bleiben (Direct Play only).

#### 💻 Tier 2: Midrange Homeserver (z. B. Intel N100 / N97 Mini-PC)

* **Hardware:** Kompakte x86-Mini-PCs (120–150 €) mit 4 Kernen, 8–16 GB RAM und NVMe-SSD (Leerlauf ca. 6 Watt).
* **Vorteile:** Verfügen über **Intel Quick Sync Video (QSV)** und können dank iGPU mehrere 4K-Videostreams in Jellyfin in Hardware transkodieren.
* **Fokus:** Der perfekte Allrounder für zu Hause mit Streaming über Tailscale an mobile Endgeräte.

#### 🚀 Tier 3: Power Cloud VPS & Dedicated Server (z. B. 6+ vCPUs / Hetzner / Netcup)

* **Hardware:** 6+ vCPUs (AMD EPYC) oder dedizierte Bare-Metal Root-Server, 8–32+ GB RAM, Enterprise NVMe-SSDs und Multi-Gigabit-Netzwerk (1–2,5 Gbit/s symmetrisch).
* **Vorteile:** Keine Drosselungen, keine Hardware-Kaufkosten, massive Datendurchsätze. 
* **Fokus:** **Kompromisslose Höchstleistung.** Hier wird SABnzbd mit 1,5–2 GB RAM-Schreibcache und **50 Verbindungen** gefahren: Durchsätze von **über 360 MB/s (~3 Gbit/s Netto)** lassen 1-GB-Dateien in 2 Sekunden auf der SSD landen. Reines Provider-SSL (Port 563) spart CPU-Kryptolast gegenüber VPN-Tunneln und reizt die High-Speed-Ports im Rechenzentrum voll aus. Für Jellyfin können Transcode-Puffer im schnellen RAM (`tmpfs`) eingerichtet werden, um SSDs vor Schreibzyklen zu schützen.

---

### Was ist Transkodierung und wann ist sie nötig?

**Transkodierung** ist das Umwandeln eines Videos in Echtzeit in ein anderes Format oder eine geringere Bitrate:

* **Direct Play (Standard):** Moderne Smart-TVs, Apple TV, Fire TV Sticks und Smartphones spielen nahezu alle Videoformate (H.264, HEVC, MKV) direkt ab – der Server reicht die Datei ohne CPU-Last weiter.
* **Transkodierung:** Wird nur nötig, wenn du von unterwegs streamst und dein Upload zu langsam für die volle 4K-Bitrate ist, oder wenn ein alter Browser ein Videoformat nicht nativ unterstützt.

---

| ⬅️ Vorheriges Kapitel | 🧭 Inhaltsverzeichnis | ➡️ Nächstes Kapitel |
| :--- | :---: | ---: |
| *Start* | [**Inhaltsverzeichnis**](../README.md#inhaltsverzeichnis) | [**2.0 Provider & Indexer**](../Provider%20%26%20Indexer/Provider%20%26%20Indexer.md) ➔ |