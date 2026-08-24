# 2.0 Provider und Indexer

## 2.1 Usenet-Provider wählen

Der Usenet-Provider ist der grundlegende Baustein deines Setups. Er gewährt dir Zugang zu den Usenet-Servern und ist somit die Quelle für deine Downloads. Die Wahl des richtigen Providers hängt von deinen individuellen Bedürfnissen ab.

---

### Worauf sollte man bei der Auswahl achten?

* **Retention (Vorhaltezeit):** Die Retention bezeichnet die Zeitspanne, über die der Provider Dateien auf seinen Servern speichert. Je länger die Retention, desto höher die Wahrscheinlichkeit, dass auch ältere Dateien noch vollständig heruntergeladen werden können. Moderne Premium-Provider bieten oft eine Retention von 15+ Jahren (über 5.800 Tage).
* **Geschwindigkeit & Verbindungen:** Die Geschwindigkeit sollte deiner maximalen Internet-Bandbreite entsprechen. Achte zudem auf die Anzahl der gleichzeitig erlaubten Verbindungen (ca. 15–30 reichen für fast alle Leitungen völlig aus).
* **Sicherheit (SSL/TLS):** Stelle sicher, dass der Provider eine verschlüsselte Verbindung (SSL/TLS über Port 563 oder 443) anbietet. Dies schützt deine Privatsphäre, indem es die übertragenen Daten vor deinem Internetanbieter verbirgt.
* **Preis & Deals:** Die Kosten variieren je nach Retention und Vertragslaufzeit. Über spezielle Aktionen liegen gute Flatrates oft bei ca. 2,50–4,00 € pro Monat.
* **Block-Accounts:** Ein Block-Account ist ein einmaliger Kauf eines festen Datenvolumens (z. B. 1 TB oder 2 TB), das nicht verfällt. Er wird meist nicht als Hauptaccount genutzt, sondern dient als **Backup-Lösung** auf einem anderen Server-Netzwerk (Backbone), um eventuell gelöschte Teile nachzuladen.

---

### Bekannte Provider & Deals

Bekannte Premium-Anbieter mit eigenem Backbone und maximaler Vorhaltezeit sind beispielsweise **Eweka** (sehr beliebt in Europa mit herausragender Retention) oder **NewsgroupDirect** (ideal auch für günstige Block-Accounts).

* Auf Reddit unter [r/usenet](https://www.reddit.com/r/usenet/) findest du eine [Übersicht aktueller Providerdeals](https://www.reddit.com/r/usenet/wiki/providerdeals/).
* Auch [rexum.space](https://rexum.space/p/usenet-provider-deals/) bietet eine regelmäßig gepflegte Liste empfehlenswerter Aktionen.

---

## 2.2 Indexer finden

Ein Indexer ist die Suchmaschine für das Usenet. Da moderne Uploads verschlüsselt und mit kryptischen Dateinamen in Newsgroups gepostet werden, sind Indexer unerlässlich. Sie erstellen und verwalten die **NZB-Dateien**, die dein Downloader zum Rekonstruieren der Downloads benötigt.

### Öffentlich, Privat oder Foren-Boards?

* **Öffentliche Indexer:** Frei zugänglich, bieten jedoch kaum passwortgeschützte oder moderierte Releases und sind für automatisierte Setups kaum geeignet.
* **Private Indexer (mit API):** Für automatisierte PVR-Tools (Sonarr, Radarr, Prowlarr) sind private Indexer mit **API-Zugang (Newznab)** essenziell. Sie bieten hohe Zuverlässigkeit, strukturierte Kategorien und saubere Releases.
* **Usenet-Boards (Foren):** Foren-Communities teilen manuell erstellte NZB-Dateien. Sie eignen sich hervorragend für manuelle Suchen nach seltenem deutschem Content, bieten in der Regel jedoch keinen automatisierten API-Zugriff für Sonarr/Radarr.

---

### Empfehlenswerte Indexer

#### Private Indexer mit Fokus auf deutschem Content

* **Treasure-Maps (ehemals SceneNZBs):** Der wichtigste und umfangreichste Indexer für deutsche Produktionen, Synchronisationen und German DL Releases. Die Registrierung ist in der Regel dauerhaft geöffnet.
* **NewzBay:** Spezialisiert auf deutschen Content. Die Registrierung ist meist geschlossen (Zugang nur via User-Invite).
* **NZB.life:** Gute Ergänzung für deutschsprachige Veröffentlichungen.

#### Private Indexer mit Fokus auf internationalem Content

* **NZBGeek:** Sehr große Community, dauerhaft offene Registrierung, moderater VIP-Preis und gute API-Anbindung.
* **DrunkenSlug:** Äußerst beliebter internationaler Indexer mit hoher Trefferquote; öffnet seine Registrierung alle paar Monate für kurze Zeit.
* **NZBFinder:** Exzellenter Allrounder mit großem englischen und europäischem Datenbestand.

#### Deutsche Usenet-Boards (für manuelle Suche)

Zu den bekanntesten deutschen Boards zählen **Fileleechers**, **Sky of Usenet** oder **House of Usenet (HoU)**. Diese erfordern meist geschlossene Registrierungen oder Einladungen und dienen als manuelle Ergänzung zu deinem automatisierten Stack.