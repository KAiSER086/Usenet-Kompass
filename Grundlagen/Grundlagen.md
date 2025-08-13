# 1.1 Was ist Usenet?

Stell dir das **Usenet** als ein dezentrales, weltweites Netzwerk vor, das deutlich älter ist als das World Wide Web, wie wir es heute kennen. Ursprünglich als eine Art riesiges Diskussionsforum konzipiert, das in Tausende von Themenbereichen (sogenannten Newsgroups) unterteilt ist, wird es heute überwiegend für den dezentralen Austausch von Dateien genutzt.

Anders als bei zentralisierten Diensten wie Webseiten oder Cloud-Speichern gibt es keine zentrale Stelle. Stattdessen kommunizieren die Server von Usenet-Providern miteinander und synchronisieren ihre Inhalte, wodurch eine robuste und schnelle Verteilung von Informationen und Dateien ermöglicht wird.

## Usenet vs. Torrent: Die grundlegenden Unterschiede

Obwohl sowohl Usenet als auch Torrent (BitTorrent) zum Austausch von Dateien genutzt werden, unterscheiden sie sich grundlegend in ihrer Funktionsweise und den damit verbundenen Konsequenzen.

* **Usenet**
  * **Technologie:** Usenet basiert auf dem Client-Server-Prinzip. Nutzer laden Dateien von einem News-Server herunter, zu dem sie über einen Provider Zugang haben.
  * **Anonymität:** Die Anonymität im Usenet ist relativ hoch. Da die Verbindung nur zwischen dem Nutzer und dem News-Server besteht, ist es für Dritte schwer, die Herkunft einer Datei zurückzuverfolgen. Oft wird die Verbindung zusätzlich über SSL verschlüsselt.
  * **Geschwindigkeit:** Die Download-Geschwindigkeit hängt stark vom News-Server und der eigenen Internetverbindung ab. Da der Server die Dateien zentral vorhält, können sehr hohe und konstante Geschwindigkeiten erreicht werden.
  * **Verfügbarkeit:** Die Verfügbarkeit von Dateien wird durch die sogenannte „**Retention**“ bestimmt – die Zeitspanne, in der ein News-Server eine Datei speichert. Einige Anbieter bieten Retention-Zeiten von über 15 Jahren, wodurch auch sehr alte Inhalte noch verfügbar sind.
  * **Nutzung:** Für die Nutzung ist meist ein kostenpflichtiger Zugang zu einem News-Server erforderlich.

* **Torrent**
  * **Technologie:** Torrent ist ein **Peer-to-Peer (P2P)-System**. Dateien werden nicht von einem zentralen Server geladen, sondern in kleinen Teilen von vielen anderen Nutzern (Peers) herunter- und gleichzeitig hochgeladen.
  * **Anonymität:** Die Anonymität bei Torrents ist deutlich geringer. Jeder, der eine Datei herunterlädt, teilt seine IP-Adresse mit allen anderen Nutzern im Schwarm (Swarm). Diese IP-Adressen sind öffentlich sichtbar und können leicht von Dritten erfasst werden.
  * **Geschwindigkeit:** Die Geschwindigkeit ist abhängig von der Anzahl der „**Seeder**“ (Nutzer, die die komplette Datei zur Verfügung stellen) und „**Leecher**“ (Nutzer, die noch Teile der Datei herunterladen). Bei vielen Seedern kann die Geschwindigkeit sehr hoch sein, bei wenigen jedoch sehr langsam oder der Download bricht ab.
  * **Verfügbarkeit:** Die Verfügbarkeit ist an die Nutzer gebunden. Wenn niemand mehr eine Datei teilt, ist sie nicht mehr verfügbar.
  * **Nutzung:** Die Nutzung ist in der Regel kostenlos, es gibt aber auch private Tracker, die eine Registrierung erfordern.

## Warum Usenet gerade in Deutschland besser ist

In Deutschland spielt der Aspekt der **Rechtslage** eine entscheidende Rolle, der Usenet gegenüber Torrent oft vorteilhafter macht:

* **Rechtssicherheit und Abmahnungen:**
  * **Torrent:** Das deutsche Urheberrecht schützt die Werke von Rechteinhabern. Da bei Torrents das Herunterladen und gleichzeitige Hochladen (**Filesharing**) in der Regel gegen dieses Recht verstößt, sind **Abmahnungen** durch spezialisierte Anwaltskanzleien weit verbreitet. Die öffentlich sichtbaren IP-Adressen im P2P-Netzwerk werden von diesen Kanzleien erfasst und zur Identifizierung der Nutzer verwendet.
  * **Usenet:** Beim Usenet findet kein Filesharing im eigentlichen Sinne statt. Man lädt die Dateien lediglich von einem News-Server herunter. Solange man die Dateien nicht selbst über den News-Server hochlädt (was bei den meisten Nutzern nicht der Fall ist), gibt es keine direkte Möglichkeit, die eigene IP-Adresse öffentlich mit dem Herunterladen in Verbindung zu bringen. Die Verbindung zum News-Server ist eine private, oft verschlüsselte Verbindung, die sich rechtlich deutlich von der P2P-Nutzung unterscheidet. Das Herunterladen von urheberrechtlich geschütztem Material bleibt zwar auch hier illegal, aber die Rechtsverfolgung ist um ein Vielfaches schwieriger, und Abmahnungen wie bei Torrents sind nahezu unbekannt.

* **Anonymität und Privatsphäre:**
  * Die hohe Anonymität und die **SSL-Verschlüsselung**, die viele News-Provider anbieten, machen es für Dritte (inklusive Behörden und Rechteinhaber) extrem schwer, die Aktivitäten eines Nutzers zu überwachen. Im Gegensatz dazu sind Torrent-Nutzer im Prinzip „offen“ für jeden, der im selben Schwarm aktiv ist.

* **Zuverlässigkeit und Geschwindigkeit:**
  * Die konstant hohen Download-Geschwindigkeiten, die bei Usenet-Anbietern möglich sind, stellen einen klaren Vorteil dar. Im Gegensatz zu Torrents, bei denen die Geschwindigkeit stark schwankt, kann man sich auf Usenet meist auf die volle Bandbreite verlassen.

**Fazit:**

Zusammenfassend lässt sich sagen, dass Usenet in Deutschland eine Alternative darstellt, die in Bezug auf **Anonymität, Geschwindigkeit** und vor allem der **Rechtssicherheit** deutliche Vorteile gegenüber Torrents bietet. Während das Herunterladen von urheberrechtlich geschützten Inhalten in beiden Systemen illegal ist, ist die Wahrscheinlichkeit einer rechtlichen Verfolgung über Usenet durch die zugrundeliegende Client-Server-Struktur signifikant geringer.

---

# 1.2 Usenet Lexikon

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
