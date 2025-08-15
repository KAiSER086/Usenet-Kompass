# 1.0 Grundlagen

## 1.1 Was ist Usenet?

Stell dir das **Usenet** als ein dezentrales, weltweites Netzwerk vor, das deutlich älter ist als das World Wide Web, wie wir es heute kennen. Ursprünglich als eine Art riesiges Diskussionsforum konzipiert, das in Tausende von Themenbereichen (sogenannten Newsgroups) unterteilt ist, wird es heute überwiegend für den dezentralen Austausch von Dateien genutzt.

Anders als bei zentralisierten Diensten wie Webseiten oder Cloud-Speichern gibt es keine zentrale Stelle. Stattdessen kommunizieren die Server von Usenet-Providern miteinander und synchronisieren ihre Inhalte, wodurch eine robuste und schnelle Verteilung von Informationen und Dateien ermöglicht wird.

### Usenet vs. Torrent: Die grundlegenden Unterschiede

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

### Warum Usenet gerade in Deutschland besser ist

In Deutschland spielt der Aspekt der **Rechtslage** eine entscheidende Rolle, der Usenet gegenüber Torrent oft vorteilhafter macht:

* **Rechtssicherheit und Abmahnungen:**
  * **Torrent:** Das deutsche Urheberrecht schützt die Werke von Rechteinhabern. Da bei Torrents das Herunterladen und gleichzeitige Hochladen (**Filesharing**) in der Regel gegen dieses Recht verstößt, sind **Abmahnungen** durch spezialisierte Anwaltskanzleien weit verbreitet. Die öffentlich sichtbaren IP-Adressen im P2P-Netzwerk werden von diesen Kanzleien erfasst und zur Identifizierung der Nutzer verwendet.
  * **Usenet:** Beim Usenet findet kein Filesharing im eigentlichen Sinne statt. Man lädt die Dateien lediglich von einem News-Server herunter. Solange man die Dateien nicht selbst über den News-Server hochlädt (was bei den meisten Nutzern nicht der Fall ist), gibt es keine direkte Möglichkeit, die eigene IP-Adresse öffentlich mit dem Herunterladen in Verbindung zu bringen. Die Verbindung zum News-Server ist eine private, oft verschlüsselte Verbindung, die sich rechtlich deutlich von der P2P-Nutzung unterscheidet. Das Herunterladen von urheberrechtlich geschütztem Material bleibt zwar auch hier illegal, aber die Rechtsverfolgung ist um ein Vielfaches schwieriger, und Abmahnungen wie bei Torrents sind nahezu unbekannt.

* **Anonymität und Privatsphäre:**
  * Die hohe Anonymität und die **SSL-Verschlüsselung**, die viele News-Provider anbieten, machen es für Dritte (inklusive Behörden und Rechteinhaber) extrem schwer, die Aktivitäten eines Nutzers zu überwachen. Im Gegensatz dazu sind Torrent-Nutzer im Prinzip „offen“ für jeden, der im selben Schwarm aktiv ist.

* **Zuverlässigkeit und Geschwindigkeit:**
  * Die konstant hohen Download-Geschwindigkeiten, die bei Usenet-Anbietern möglich sind, stellen einen klaren Vorteil dar. Im Gegensatz zu Torrents, bei denen die Geschwindigkeit stark schwankt, kann man sich auf Usenet meist auf die volle Bandbreite verlassen.

**Fazit:**

ZuZusammenfassend lässt sich festhalten, dass Usenet für Nutzer in Deutschland eine klare und überlegene Alternative zu Torrents darstellt. Besonders bei den entscheidenden Punkten Anonymität, Geschwindigkeit und einem besseren Schutz vor Dritten hat das Usenet deutliche Vorteile.
Dank seiner grundlegenden Client-Server-Struktur, die keine direkte Verbindung zu anderen Nutzern offenlegt, ist man hier deutlich besser geschützt als im Peer-to-Peer-Umfeld von Torrents. Kurz gesagt: Wer Wert auf Privatsphäre legt und dabei von hoher Geschwindigkeit profitieren möchte, findet im Usenet die passendere Lösung.

---

## 1.2 Systemvoraussetzungen & Hardware-Wahl

Bevor du beginnst, solltest du dir überlegen, welche Hardware du verwenden möchtest. Mein Setup ist darauf ausgelegt, auf einem **Raspberry Pi 5** zu laufen, da dieser eine gute Balance aus Leistung und Energieeffizienz bietet.

### Warum Linux die beste Wahl ist

Obwohl Docker auf Windows und macOS läuft, wurde es ursprünglich **nativ für Linux entwickelt**. Das bedeutet, dass Docker auf Linux-Systemen am besten funktioniert, die wenigsten Probleme verursacht und in der Regel auch die höchste Performance bietet.

Daher empfehlen wir für dieses Projekt die Verwendung einer schlanken Linux-Distribution wie **DietPi** oder **Debian**. Diese Systeme sind ideal für den 24/7-Betrieb deines Home-Servers. Sie sind ressourcenschonend, stabil und bieten die beste Basis, um deinen Docker-Stack reibungslos zu betreiben.

### Mein System: Raspberry Pi 5 mit DietPi

* **Vorteile**: Der Raspberry Pi 5 ist klein, verbraucht extrem wenig Strom und ist daher ideal für einen 24/7-Betrieb. Er ist leistungsstark genug, um alle Usenet-Dienste (Downloader, Indexer) problemlos auszuführen.
* **Nachteile**: Ein Single-Board-Computer (SBC) wie der Raspberry Pi hat seine Grenzen bei der Rechenleistung, insbesondere bei anspruchsvollen Aufgaben wie der **Transkodierung**.

### Was ist Transkodierung und wann ist sie nötig?

**Transkodierung** ist der Prozess, bei dem eine Mediendatei von einem Format in ein anderes umgewandelt wird.

In den allermeisten Fällen ist eine Transkodierung bei modernen Geräten **nicht notwendig**. Aktuelle Smart-TVs, Smartphones und Tablets unterstützen in der Regel das direkte Abspielen (`Direct Play`) der gängigsten Videoformate.

Transkodierung kommt in zwei Hauptszenarien ins Spiel:

1. **Format-Inkompatibilität**: Wenn dein Wiedergabegerät das Format der Mediendatei nicht unterstützt (was heute selten vorkommt).
2. **Unzureichende Upload-Bandbreite**: Dies ist der häufigste Grund. Wenn du von unterwegs auf deine Mediensammlung zugreifst und deine Upload-Geschwindigkeit nicht ausreicht, um den Stream in voller Qualität zu übertragen, transkodiert der Server die Datei in eine geringere Bitrate. Dies ermöglicht unterbrechungsfreies Streaming ohne Pufferung.

Da die CPU des Raspberry Pi 5 nicht für diese anspruchsvolle Echtzeit-Transkodierung ausgelegt ist, kann es in solchen Fällen zu Problemen kommen.

### Bessere Alternativen & Empfehlungen

Wenn du weißt, dass du häufig Medien mit hohen Bitraten von unterwegs streamen möchtest, solltest du eine leistungsstärkere Hardware in Betracht ziehen:

* **Mini-PCs**: Kompakte Computer (z. B. Intel NUCs) mit Prozessoren wie Intel Core i3 oder i5 (ab der 8. Generation oder neuer) bieten eine integrierte Hardware-Transkodierung (`Intel Quick Sync`), die den Prozessor entlastet.
* **NAS-Systeme (Synology, QNAP)**: Viele moderne NAS-Geräte haben ebenfalls eine integrierte Hardware-Transkodierung und die Möglichkeit, Docker-Container zu nutzen. Das macht sie zu einer idealen All-in-One-Lösung für einen Medienserver.
* **Ausrangierte Tower-PCs oder Server**: Ältere PCs mit dedizierter Grafikkarte (falls du keine Intel-CPU mit Quick Sync hast) oder leistungsstarken CPUs sind ebenfalls eine gute und oft kostengünstige Option.
