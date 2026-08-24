# Usenet-Lexikon

## Grundlegende Begriffe

* **Usenet:** Ein dezentrales, weltweites Netzwerk, das den Austausch von Texten und Dateien in Newsgroups ermöglicht. Es ist deutlich älter als das moderne Web.
* **Newsgroup:** Ein themenspezifisches Forum im Usenet, in dem Beiträge und Dateisegmente ausgetauscht werden.
* **Provider:** Ein Dienstleister, der dir gegen Gebühr Zugang zu den News-Servern (NNTP) gewährt. Ohne Provider-Zugang hast du keinen Zugriff auf das Usenet.
* **Indexer:** Eine spezialisierte Suchmaschine für das Usenet, die NZB-Dateien bereitstellt und Suchanfragen für Automatisierungstools via API beantwortet.
* **PVR (Personal Video Recorder):** Sammelbegriff für Automatisierungsanwendungen wie Sonarr und Radarr. Diese überwachen deine Wunschliste, suchen Releases, übergeben sie an den Downloader und benennen fertige Dateien um.

---

## Begriffe rund um Dateien und Downloads

* **NZB-Datei:** Eine XML-Metadatei, die alle notwendigen Informationen (Dateinamen, Teile, Serverorte) enthält, die ein Downloader zum Abrufen und Zusammensetzen einer Datei benötigt.
* **Downloader (SABnzbd / NZBGet):** Die Client-Software, die Dateien über verschlüsselte Verbindungen vom Usenet-Server lädt, repariert und entpackt.
* **Retention (Vorhaltezeit):** Die Zeitspanne, über die ein Provider hochgeladene Dateien auf seinen Servern vorhält. Gute Provider bieten 15+ Jahre Retention.
* **Binärdateien (Binaries):** Alle nicht-reinen Textdateien (Filme, Serien, Software, Archive).
* **PAR2-Dateien (Parität):** Wiederherstellungsdaten, mit denen der Downloader beschädigte oder unvollständige Archive automatisch repariert.
* **RAR-Dateien:** Geteilte Archive, in denen Binärdateien im Usenet verpackt sind. Dein Downloader entpackt diese nach erfolgreichem Download automatisch.

---

## Technische Begriffe

* **VPN (Virtual Private Network):** Verschlüsselt den Internetverkehr und leitet ihn über externe Server um, wodurch deine reale IP-Adresse verborgen wird.
* **Mesh-VPN (z. B. Tailscale):** Ein privates Punkt-zu-Punkt-VPN-Netzwerk, das sichere Direktverbindungen zwischen deinen eigenen Geräten ohne Router-Portfreigaben ermöglicht.
* **SSL/TLS-Verschlüsselung:** Verschlüsselt die Verbindung zwischen deinem Downloader und dem Usenet-Server (Standardports: 563 oder 443).
* **Docker & Docker Compose:** Containerisierungsplattform, um Anwendungen samt Abhängigkeiten isoliert und reproduzierbar auszuführen.
* **PUID/PGID (User/Group ID):** Kennungen deines Linux-Benutzers, damit Docker-Container mit den korrekten Dateizugriffsrechten auf deine Festplatte schreiben dürfen.
* **NNTP (Network News Transfer Protocol):** Das Netzwerkprotokoll zur Übertragung von Usenet-Artikeln und Dateien.

---

## Release-Begriffe

* **German DL (Dual Language):** Release mit deutscher und originaler Sprachspur (z. B. Deutsch + Englisch).
* **Remux:** 1:1 verlustfreie Kopie des Original-Videomaterials einer Blu-ray / UHD-Disc ohne Neucodierung. Höchstmögliche Bild- und Tonqualität.
* **BDRip / BluRay:** Von einer Blu-ray neu komprimiertes Release (z. B. 1080p oder 720p).
* **WEB-DL / WEBRip:** Direkter digitaler Mitschnitt eines Streaming-Anbieters (Amazon, Netflix, Disney+, Apple TV).
* **x264 / AVC:** Klassischer, hochkompatibler Videocodec für HD-Inhalte.
* **x265 / HEVC:** Moderner Videocodec mit deutlich besserer Kompression; Standard für 4K/HDR und platzsparende 1080p-Releases.
* **AC3 / EAC3 / Atmos:** Audioformate. AC3 = Dolby Digital, EAC3 = Dolby Digital Plus (Streaming-Standard), Atmos = objektbasiertes 3D-Audio.
* **MKV (Matroska):** Flexibles Containerformat für Video, mehrere Audiospuren und Untertitel.