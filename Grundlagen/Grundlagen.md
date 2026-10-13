# 1.0 Grundlagen

## 1.1 Was ist Usenet?

Stell dir das **Usenet** als ein dezentrales, weltweites Netzwerk vor, das deutlich älter ist als das World Wide Web, wie wir es heute kennen. Ursprünglich als eine Art riesiges Diskussionsforum konzipiert, das in Tausende von Themenbereichen (sogenannten Newsgroups) unterteilt ist, wird es heute überwiegend für den dezentralen Austausch von Dateien genutzt.

Anders als bei zentralisierten Diensten wie Webseiten oder Cloud-Speichern gibt es keine zentrale Stelle. Stattdessen kommunizieren die Server von Usenet-Providern miteinander und synchronisieren ihre Inhalte, wodurch eine robuste und schnelle Verteilung von Informationen und Dateien ermöglicht wird.

> [!TIP]
> **Das Zusammenspiel der Komponenten im Überblick:**
> * **Usenet-Provider:** Stellt den eigentlichen Zugang zu den weltweiten News-Servern bereit. Hier liegen die gespeicherten Datenpakete (Retention).
> * **Indexer:** Fungiert als spezialisierte Suchmaschine. Da Dateien im Usenet aus Sicherheitsgründen oft kryptisch benannt und aufgeteilt sind, verknüpft der Indexer diese Fragmente mit verständlichen Titeln und erzeugt die passende NZB-Datei.
> * **NZB-Datei:** Eine XML-Datei mit den genauen Positions- und Header-Daten aller Segmente, aus denen der gewünschte Download besteht.
> * **Downloader (SABnzbd / NZBGet):** Liest die NZB-Datei ein, lädt alle Segmente parallel über TLS herunter, verifiziert die Prüfsummen, repariert fehlerhafte Archive automatisch per PAR2 und entpackt die fertige Mediendatei.
> * **Medienserver (Jellyfin):** Organisiert die fertigen Filme und Serien mit Metadaten und streamt sie auf Smart-TVs, Mobilgeräte und Computer.

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

#### Option 1: Raspberry Pi 5 mit DietPi (Der stromsparende Homeserver)

* **Vorteile:** Sehr geringer Stromverbrauch (ca. 3–5 Watt), geräuschlos, kompakt und vollkommen ausreichend für Downloader (SABnzbd/NZBGet), *arr-Apps und Direct-Play-Streaming.
* **Beachte:** Ein Single-Board-Computer (ARM CPU) stößt an Grenzen bei rechenintensiver Video-Transkodierung in Echtzeit.

#### Option 2: Intel N100 / N97 Mini-PC (Die moderne Allround-Empfehlung)

* **Vorteile:** Kompakte x86-Mini-PCs mit Intel N100 Prozessor kosten oft nur 120–150 € und verbrauchen im Leerlauf ebenfalls nur ca. 6 Watt. Sie verfügen über **Intel Quick Sync Video (QSV)** und können mehrere 4K-Videostreams in Jellyfin mühelos in Hardware transkodieren.
* **Ideal für:** Nutzer, die eine vollwertige Multimedia-Zentrale zu Hause suchen und häufig von unterwegs streamen möchten.

#### Option 3: Cloud VPS & Dedicated Server (Das flexible Offsite-Setup)

* **Vorteile:** Keine Hardware-Anschaffungskosten, professionelles Hosting im Rechenzentrum mit garantierter Gigabit- oder Multi-Gigabit-Anbindung (oft 1–2,5 Gbit/s symmetrisch) und fester öffentlicher IP. Perfekt, wenn das heimische Internet zu langsam ist oder der private Router nicht durch 24/7-Downloads ausgelastet werden soll.
* **Typisches Setup:** Instanzen mit 2–6+ vCPUs (z. B. AMD EPYC bei Hetzner Cloud, Netcup etc.) und NVMe-Speicher. Auf leistungsstarken Systemen lassen sich Usenet-Downloads direkt über SSL (Port 563) mit maximalen Durchsätzen von über 360 MB/s betreiben.

#### Option 4: Bestehendes NAS (Synology, QNAP, Unraid, TrueNAS)

* **Vorteile:** Wer bereits ein 24/7 laufendes NAS besitzt, kann den Stack direkt darauf betreiben (z. B. via *Container Manager* ab DSM 7.2 auf Synology oder Docker Compose auf Unraid/TrueNAS), ohne zusätzliche Hardware anschaffen zu müssen.
* **Beachte:** Günstige Einsteiger-NAS nutzen oft sparsame ARM- oder Celeron-Prozessoren, die bei parallelem Entpacken (PAR2/RAR) oder Video-Transkodierung in Jellyfin an ihre Leistungsgrenzen stoßen. Viele Nutzer kombinieren daher ihr NAS als reinen Netzwerkspeicher mit einem günstigen N100 Mini-PC oder Raspberry Pi 5 für die eigentliche Rechenlast.

---

## 1.3 Video- & Audio-Codecs verstehen: Der Schlüssel zu ruckelfreiem Streaming

Ein häufiger Frustrationspunkt bei Einsteigern: Der Download über Sonarr oder Radarr ist fehlerfrei abgeschlossen, aber beim Abspielen auf dem Fernseher buffert das Video im Sekundentakt oder der Server friert ein. 

Um zu verstehen, warum das passiert und wie du dein Setup optimal konfigurierst, musst du das Zusammenspiel aus **Direct Play**, den **verschiedenen Videocodecs** und den **typischen Flaschenhälsen** kennen.

---

#### 1. Die drei Wiedergabe-Modi: Direct Play vs. Transkodierung

Wenn Jellyfin einen Film oder eine Serie an dein Abspielgerät (Smart-TV, Tablet, Streaming-Stick) sendet, geschieht dies in einem von drei Modi:

1. **Direct Play (Das Ideal):**
   * Das Endgerät unterstützt den Videocodec, den Audiocodec und das Container-Format (`.mkv`, `.mp4`) der Datei zu 100 % in Hardware.
   * **Server-Last:** Praktisch **0 % CPU-Last**. Der Server fungiert als reiner Dateiserver und reicht den Datenstrom unverändert weiter. Selbst ein stromsparender Raspberry Pi 5 kann hochbitratige 4K-Dateien mühelos an mehrere Endgeräte gleichzeitig ausliefern.
2. **Direct Stream / Remuxing (Unkritisch):**
   * Das Bild wird nativ unterstützt, aber das Audioformat oder der Container muss angepasst werden (z. B. von `.mkv` nach `.mp4` oder Ton von DTS nach AAC).
   * **Server-Last:** Sehr geringe CPU-Last (< 2–5 %), da nur das Audiosignal oder die Verpackung („Container“) angepasst wird, nicht das rechenintensive Videobild.
3. **Transkodierung (Der Ressourcen-Killer):**
   * Das Abspielgerät kann das Videoformat, die Farbtiefe (10-Bit) oder die Bitrate nicht nativ decodieren.
   * Der Server muss jedes einzelne Videobild in Echtzeit decodieren und in ein kompatibles Format umrechnen.
   * **Server-Last:** Extrem hoch! Ohne dedizierte Hardwarebeschleunigung (z. B. Intel QuickSync auf einem Mini-PC) bricht ein Raspberry Pi 5 oder einfaches NAS bei 4K-Material innerhalb von Sekunden auf 100 % CPU-Auslastung zusammen – das Video buffert ununterbrochen.

---

#### 2. Der Video-Codec-Kompass: Von H.264 bis AV1

Nicht jeder Fernseher oder Browser versteht jeden Codec. In den Hardware-Chips der Abspielgeräte stecken fest gegossene Decoder-Blöcke (ASICs), die bestimmte Standards unterstützen – andere wiederum nicht:

| Codec | Voller Name | Entwickler / Lizenz | Typischer Einsatz | Hardware-Decoding auf TVs |
| :--- | :--- | :--- | :--- | :---: |
| **H.264 (AVC)** | Advanced Video Coding | Proprietär (MPEG-LA) | 1080p SDR, Web, YouTube-Archiv | **Nahezu 100 %** (Universell) |
| **H.265 (HEVC)** | High Efficiency Video Coding | Proprietär (komplexe Lizenzpools) | 4K UHD, HDR10, Dolby Vision | **Sehr hoch** auf allen 4K-Geräten |
| **VP9** | Video Processor 9 | Open Source / Royalty-Free (Google) | YouTube 4K/HDR | **Sehr hoch** (jeder TV mit YouTube-App) |
| **AV1** | AOMedia Video 1 | Open Source / Royalty-Free (AOMedia) | Modernes Web-Streaming, Zukunft | **Mittel bis steigend** (nur neuere Geräte ab ~2021) |

##### Die Codecs im Detail:

* **H.264 (AVC):**
  * *H.264 8-Bit (High Profile, 4:2:0):* Der bewährte Standard für **1080p SDR**. Wird von nahezu allen Fernsehern, Streaming-Sticks, Smartphones und älteren PCs hardwareseitig decodiert und bietet maximale Kompatibilität.
  * *H.264 Hi10P (10-Bit-Profil):* Wird vor allem bei Anime-Releases eingesetzt, um Banding-Artefakte bei vergleichbarer Bitrate zu reduzieren. Da typische Consumer-Hardwaredecoder in Fernsehern und Streaming-Sticks vor allem auf 8-Bit ausgelegt sind, unterstützen sie Hi10P meist nicht in Hardware. Geräte müssen dann auf Software-Decodierung ausweichen – während leistungsfähige PCs oder Apple TV das problemlos schaffen, geraten schwächere TV-Prozessoren dabei oft ins Ruckeln oder zwingen den Server zum Transkodieren.
  * *4K in H.264:* Viele moderne Chipsätze (z. B. neuere Fire-TV-Modelle) unterstützen H.264 auch bis 4K @ 60 fps hardwareseitig. In der Praxis setzen Streaming-Dienste und moderne Releases bei 4K dennoch fast ausnahmslos auf HEVC, VP9 oder AV1: H.264 ist für 4K wesentlich ineffizienter und benötigt für vergleichbare Bildqualität deutlich höhere Bitraten und mehr Speicherplatz.

* **H.265 (HEVC):**
  * *Der 4K-Standard:* Bietet etwa 50 % bessere Kompression als H.264 bei gleicher Bildqualität und ist die technische Grundlage für HDR10 und Dolby Vision.
  * *Einsatzgebiet:* De-facto-Standard für **4K-Releases** (sowohl Filme als auch hochkarätige Serien) sowie platzsparende 1080p-Archive.
  * *Stolperfalle:* Ältere reine 1080p-Fernseher oder betagte Streaming-Sticks besitzen keine HEVC-Lizenz und keinen Decodierchip. Versucht man darauf 4K HEVC abzuspielen, muss der Server transkodieren.

* **VP9:**
  * *Googles Antwort auf HEVC:* Wurde speziell für YouTube entwickelt und ist lizenzgebührenfrei.
  * *Vorteil:* Da praktisch jeder Smart-TV eine offizielle YouTube-App mitbringt, haben nahezu alle modernen Fernseher hardwarebeschleunigte VP9-Decoder an Bord.
  * *Usenet-Relevanz:* In der Filmszene und im Usenet spielt VP9 kaum eine Rolle, da Szene-Standards fast ausschließlich auf H.264 und HEVC setzen.

* **AV1 (AOMedia Video 1):**
  * *Der moderne Hoffnungsträger:* Entwickelt von einem Konsortium aus Tech-Giganten (Google, Netflix, Amazon, Apple, Meta, Intel, Mozilla), um das teure Lizenzchaos von HEVC zu beenden. Bietet ~30 % bessere Effizienz als HEVC.
  * *Usenet-Relevanz:* Immer mehr P2P- und Web-Releases erscheinen in AV1, da die Dateigrößen bei brillanter Bildqualität sehr gering ausfallen.
  * *Die große Falle heute:* **AV1 erfordert zwingend Hardware-Decoding!** Ältere Smart-TVs, ältere Fire TV Sticks (vor 4K Max 2nd Gen) oder ältere Apple TVs haben keine AV1-Hardwareunterstützung. Die CPU des Fernsehers versucht dann krampfhaft, das Bild per Software zu decodieren, was zu Rucklern führt – oder der Server muss transkodieren. Auf AV1 sollte man aktuell nur setzen, wenn die eigenen Abspielgeräte neu genug sind (Smart-TVs ab ca. 2021/2022, moderne Streaming-Boxen).

---

#### 3. Die Faustformel für Medien-Profile in Sonarr & Radarr

Richte deine Qualitätsprofile nach deinen Endgeräten und Speicherwünschen aus:

* **4K HDR & Dolby Vision (Filme & Serien):** **2160p WEB-DL** mit Codec **H.265 (HEVC)** und Audio **E-AC3 / Atmos**. Überragende Bildqualität, satte Farben und handliche 15–30 Mbit/s Bitrate – läuft butterweich auf jedem 4K-Smart-TV ohne Ruckeln.
* **1080p SDR (Maximale Kompatibilität):** **1080p WEB-DL** mit Codec **H.264 (AVC)** und Audio **E-AC3 / AAC**. Läuft auf absolut jedem Gerät (auch alten Tablets oder unterwegs), startet verzögerungsfrei und schont Speicherplatz.
* **Platzsparendes Serien-Archiv:** Wer viele Staffeln dauerhaft archivieren möchte und moderne Abspielgeräte nutzt, kann auch bei Serien auf **1080p H.265 (HEVC)** setzen, um rund 40–50 % Speicherplatz gegenüber H.264 zu sparen.
* **UHD Remux (Enthusiasten):** Nur gezielt für persönliche Film-Highlights anfordern, wenn ein potenter Streaming-Client (Apple TV 4K, Shield Pro), ein AV-Receiver und eine Gigabit-Netzwerkanbindung vorhanden sind.

> [!TIP]
> **Hilfe bei Pufferung & Ruckeln:** Falls ein Video auf deinem Fernseher trotz schneller Leitung buffert (z. B. durch 100-Mbit/s-Netzwerkports am TV, PGS-Untertitel-Einbrennen oder Audio-Inkompatibilitäten), findest du die Ursachen und Lösungen in unserem [FAQ-Kapitel: Video buffert oder ruckelt](../FAQ/FAQ.md#3-streaming--hardware-transkodierung).

---

## 1.4 Anatomie eines Releasenamens: Wie du jeden Titel sofort entschlüsselst

Wenn du auf einem Indexer nach Inhalten suchst oder die Downloads in Sonarr und Radarr beobachtest, begegnen dir lange Dateinamen nach festen Szene-Standards:

```text
House.of.the.Dragon.S02E08.German.DL.EAC3.Atmos.2160p.HDR.WEB.H265-TVS
```

Was auf den ersten Blick wie ein unleserlicher Buchstabensalat wirkt, folgt einer strengen, logischen Reihenfolge. Jeder Baustein gibt dir Auskunft über Herkunft, Bild- und Tonqualität:

| Baustein im Namen | Beispiel | Bedeutung | Praxistipp für dein Setup |
| :--- | :--- | :--- | :--- |
| **Titel & Episode** | `House.of.the.Dragon.S02E08` | Titel der Serie/des Films, Staffel 2, Folge 8 (*Season 02, Episode 08*). | Standard-Syntax für automatisierte Zuordnung in Sonarr. |
| **Sprache (DL)** | `German.DL` | **Dual Language:** Das Release enthält sowohl die deutsche Tonspur als auch die Originalsprache (meist Englisch). | **Erste Wahl:** Maximale Flexibilität für dich und Mitnutzer. |
| **Nur Deutsch** | `German` | Enthält ausschließlich die deutsche Tonspur (ohne englischen Originalton). | Völlig ausreichend, wenn du Serien und Filme nur auf Deutsch schaust. |
| **Tonformat & Kanäle** | `EAC3.Atmos` | Dolby Digital Plus (`E-AC3`) mit räumlichem Dolby Atmos Audio. | Modernes Streaming-Audio, ideal für Soundbars und Fernseher. |
| **Auflösung** | `2160p` | 4K Ultra HD (`3840×2160`). Bei `1080p` entsprechend Full HD. | Wähle 2160p für 4K-TVs und 1080p für Standardgeräte oder Tablets. |
| **Dynamikumfang** | `HDR` *(oder `DV` / `DoVi`)* | High Dynamic Range (HDR10) oder Dolby Vision für lebendige Farben. | Erfordert einen HDR-fähigen Fernseher/Bildschirm. |
| **Quelle (Source)** | `WEB` *(oder `WEB-DL`)* | Direkter, verlustfreier digitaler Stream-Rip (z. B. von Netflix, Apple TV+, Prime). | **Ideal für Streaming:** Sauberes Bild ohne Senderlogos bei optimaler Bitrate. |
| **Disc-Quellen** | `BluRay` / `Remux` | `BluRay` = neu komprimierter Rip. `Remux` = unveränderte 1:1-Kopie der Disc. | `Remux` bietet maximale Bildqualität, erfordert aber viel Speicher und Bandbreite. |
| **Videocodec** | `H265` *(oder `x265`, `x264`)* | Kompressionsstandard (HEVC für 4K, H.264 für 1080p). | Achte auf die Hardwareunterstützung deiner Abspielgeräte. |
| **Release-Gruppe** | `-TVS` | Das Kürzel der Releasegruppe, die die Datei erstellt und veröffentlicht hat. | In Sonarr/Radarr können verlässliche Gruppen gezielt bevorzugt werden. |

> [!IMPORTANT]
> **Kino-Tonspuren und mangelhafte Rips meiden:**
> Meide Releases mit den Kürzeln **`MD`**, **`MIC`**, **`LINE`** oder **`LINE DUBBED`**. Hierbei wurde der Ton im Kinosaal per Mikrofon aufgenommen – die Tonqualität ist blechern, verrauscht und voller Publikumsgeräusche. Hochwertige Releases tragen immer Bezeichnungen wie **`DL`**, **`AC3`**, **`DTS`** oder **`EAC3`**.
>
> **Gefixte Releases bevorzugen:**
> Releases mit dem Zusatz **`PROPER`** oder **`REPACK`** korrigieren Fehler eines früheren Uploads (z. B. Tonversatz, fehlende Untertitel oder Asynchronität) und sollten einem gleichnamigen Release ohne diesen Zusatz immer vorgezogen werden.

---

| Vorheriges Kapitel | Inhaltsverzeichnis | Nächstes Kapitel |
| :--- | :---: | ---: |
| *Start* | [**Inhaltsverzeichnis**](../README.md#inhaltsverzeichnis) | [**2.0 Provider & Indexer**](../Provider%20%26%20Indexer/Provider%20%26%20Indexer.md) |