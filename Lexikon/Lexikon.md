# X.X Usenet Lexikon

## Grundlegende Begriffe

* **Newsgroup:** Das ist das Kernstück des Usenets. Eine Newsgroup ist ein themenspezifisches Diskussionsforum, vergleichbar mit einem Unterforum auf Reddit oder einem Kanal auf Discord. Sie sind hierarchisch geordnet, z.B. `alt.binaries.games`.

* **News-Server:** Der Server, der die Inhalte der Newsgroups speichert und mit anderen Servern weltweit synchronisiert. Um auf Usenet zugreifen zu können, brauchst du einen Zugang zu einem solchen Server, der meist von einem Usenet-Provider bereitgestellt wird.

* **Newsreader:** Die Software (Client), die du auf deinem Computer installierst, um dich mit dem News-Server zu verbinden, Newsgroups zu durchsuchen und Dateien herunterzuladen.

* **Provider:** Das Unternehmen, das dir gegen eine monatliche Gebühr Zugang zu seinen News-Servern gewährt. Ohne einen Provider-Account hast du keinen Zugriff.

* **Indexer:** Eine Website, die Usenet-Inhalte durchsucht und die entsprechenden NZB-Dateien bereitstellt. Ohne einen Indexer ist es sehr schwierig, bestimmte Dateien zu finden.

## Begriffe rund um Dateien und Downloads

* **Binärdateien (Binaries):** Bezeichnet alle Dateien, die keine reinen Textnachrichten sind, also z. B. Filme, Musik, Software oder Bilder.

* **Retention:** Die Speicherdauer der Dateien auf dem News-Server. Eine höhere Retention bedeutet, dass ältere Inhalte länger verfügbar sind. Bei modernen Providern kann die Retention 15 Jahre oder mehr betragen.

* **NZB-Datei:** Das ist eine kleine XML-basierte Datei, die als "Wegweiser" für den Newsreader dient. Sie enthält alle Informationen, die der Newsreader benötigt, um eine Binärdatei zu finden und herunterzuladen (vergleichbar mit einer `.torrent`-Datei, aber ohne P2P).

* **PAR2-Dateien (Parität):** Dateien, die zusammen mit den eigentlichen Binärdateien gepostet werden. Sie dienen der Reparatur von defekten oder fehlenden Teilen eines Downloads. Wenn ein Teil fehlt, können die PAR2-Dateien den ursprünglichen Download wiederherstellen.

* **RAR-Dateien:** Oft sind Binärdateien in `.rar`-Archive gepackt. Ein Newsreader entpackt diese Archive nach dem Download automatisch.

## Technische Begriffe

* **PVR (Personal Video Recorder):** Ein Sammelbegriff für Tools wie Sonarr und Radarr, die deine Mediensammlung automatisch verwalten. Sie suchen nach neuen Inhalten, laden sie über den Downloader herunter und sortieren sie.

* **SSL-Verschlüsselung:** Ein Sicherheitsstandard, der die Verbindung zwischen deinem Newsreader und dem News-Server verschlüsselt. Dies sorgt für Anonymität und verhindert, dass dein Internetanbieter oder andere Dritte deine Aktivitäten einsehen können.

* **NNTP (Network News Transfer Protocol):** Das Standardprotokoll, das Usenet verwendet, um Nachrichten und Dateien zwischen den News-Servern und zu deinem Newsreader zu übertragen.

* **Bandbreite (Bandwidth):** Die maximale Geschwindigkeit deiner Internetverbindung. Beim Usenet kannst du diese in der Regel voll ausschöpfen, da die Server extrem hohe Geschwindigkeiten liefern können.

* **VPN (Virtual Private Network):** Eine Technologie, die eine sichere und verschlüsselte Verbindung über das Internet herstellt. Sie leitet deinen gesamten Datenverkehr über einen externen Server, sodass deine eigene IP-Adresse verborgen bleibt und dein Internetanbieter deine Online-Aktivitäten nicht einsehen kann.

* **Mesh-VPN (z.B. Tailscale):** Eine moderne Form des VPN, die es ermöglicht, ein sicheres, dezentrales Netzwerk zu erstellen. Statt alle Geräte über einen zentralen Server zu verbinden, ermöglicht ein Mesh-VPN die direkte, verschlüsselte Kommunikation zwischen deinen Geräten (wie deinem Heimserver und deinem Handy), egal wo sie sich befinden. Das ist besonders nützlich für den sicheren Fernzugriff auf deine Usenet-Tools.
