# Usenet-Lexikon

## Grundlegende Begriffe

* **Usenet:** Ein dezentrales, weltweites Diskussionsnetzwerk, das den Austausch von Texten und Dateien in Newsgroups ermöglicht. Es ist ein Vorläufer des Internets.
* **Newsgroup:** Ein themenspezifisches Forum im Usenet, in dem Beiträge ausgetauscht werden. Man kann es sich wie einen Kanal auf Discord oder ein Subreddit vorstellen.
* **Provider:** Ein Unternehmen, das dir gegen eine Gebühr Zugang zu seinen News-Servern gewährt. Ohne einen Account hast du keinen Zugriff auf das Usenet.
* **Indexer:** Eine Suchmaschine für das Usenet, die NZB-Dateien bereitstellt. Ohne einen Indexer ist es schwierig, bestimmte Dateien zu finden.
* **PVR (Personal Video Recorder):** Ein Sammelbegriff für Automatisierungstools wie Sonarr und Radarr. Diese verwalten deine Mediensammlung, suchen nach neuen Inhalten, laden sie herunter und sortieren sie.

## Begriffe rund um Dateien und Downloads

* **NZB-Datei:** Eine kleine XML-basierte Datei, die alle notwendigen Informationen (wie Dateinamen und Speicherorte) enthält, die ein Downloader zum Herunterladen einer Datei benötigt. Sie ist vergleichbar mit einer Torrent-Datei.
* **Downloader (SABnzbd/NZBGet):** Die Software, die mit den News-Servern kommuniziert, um die Dateien basierend auf der NZB-Datei herunterzuladen.
* **Retention:** Die Zeitspanne, für die ein Provider eine Datei auf seinen Servern speichert. Moderne Provider bieten eine Retention von 15 Jahren oder mehr.
* **Binärdateien (Binaries):** Bezeichnet alle Dateien, die keine reinen Textnachrichten sind, wie z. B. Filme, Musik oder Software.
* **PAR2-Dateien (Parität):** Dateien, die zur Reparatur von beschädigten oder fehlenden Teilen eines Downloads verwendet werden. Sie stellen sicher, dass auch bei einem fehlerhaften Download alle Teile wiederhergestellt werden können.
* **RAR-Dateien:** Archivdateien, in denen die meisten Binärdateien im Usenet verpackt sind. Dein Downloader entpackt diese automatisch nach dem Download.

## Technische Begriffe

* **VPN (Virtual Private Network):** Ein Dienst, der deine Internetverbindung verschlüsselt und deine IP-Adresse verbirgt. Er wird verwendet, um deine Online-Aktivitäten vor Dritten zu schützen.
* **Mesh-VPN (z.B. Tailscale):** Eine moderne Form des VPN, die eine direkte, sichere Kommunikation zwischen deinen Geräten (z. B. Server und Handy) ermöglicht. Ideal für den Fernzugriff, ohne Ports am Router freigeben zu müssen.
* **SSL-Verschlüsselung:** Ein Protokoll, das die Verbindung zwischen deinem Downloader und dem Usenet-Server verschlüsselt. Dies ist unerlässlich für deine Privatsphäre.
* **Docker:** Eine Software, die es dir ermöglicht, Anwendungen und alle ihre Abhängigkeiten in isolierten Umgebungen (Containern) auszuführen. `Docker Compose` wird verwendet, um mehrere Container gleichzeitig zu verwalten.
* **PUID/PGID:** Steht für **P**rocess **U**ser **ID** und **P**rocess **G**roup **ID**. Diese IDs stellen sicher, dass deine Docker-Container die korrekten Zugriffsrechte auf die Ordner deines Host-Systems haben.
* **NNTP (Network News Transfer Protocol):** Das Kommunikationsprotokoll, das für die Übertragung von Daten im Usenet verwendet wird.

## Release-Begriffe

* **DVDRip / BDRip:** Eine Kopie von einer DVD oder Blu-ray. **BDRips** bieten die höchste Qualität.
* **HDRip / WEB-DL:** Ein direkter Mitschnitt von einem Streaming-Dienst (z. B. Netflix oder Amazon). Die Qualität ist in der Regel sehr hoch.
* **TS (Telesync) / CAM:** Ein Film, der im Kino aufgenommen wurde. Die Qualität ist oft sehr schlecht.
* **AC3 / AAC:** **AC3** ist ein Standard-Audioformat (Dolby Digital). **AAC** ist ein moderneres Format, das bei gleicher Qualität oft eine kleinere Dateigröße hat.
* **x264 / x265 (HEVC):** **x264** ist ein sehr weit verbreiteter Videocodec. **x265** ist sein Nachfolger und bietet eine bessere Kompression, was zu kleineren Dateien bei gleicher Qualität führt.
* **mkv (Matroska):** Ein flexibles Containerformat, das Video, Audio und Untertitelspuren in einer einzigen Datei speichert.
