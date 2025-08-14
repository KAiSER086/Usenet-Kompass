# 2.0 Provider und Indexer

## 2.1 Usenet-Provider wählen

Der Usenet-Provider ist der grundlegende Baustein deines Setups. Er gewährt dir Zugang zu den Usenet-Servern und ist somit die Quelle für deine Downloads. Die Wahl des richtigen Providers hängt von deinen individuellen Bedürfnissen ab.

---

### Worauf sollte man bei der Auswahl achten?

* **Retention:** Die Retention bezeichnet die Zeitspanne, über die der Provider Dateien speichert. Je länger die Retention, desto höher die Wahrscheinlichkeit, dass auch ältere Dateien verfügbar sind. Moderne Provider bieten oft eine Retention von mehreren Jahren an.
* **Geschwindigkeit & Verbindungen:** Die Geschwindigkeit sollte deiner maximalen Internet-Bandbreite entsprechen. Achte zudem auf die Anzahl der gleichzeitig möglichen Verbindungen, die der Provider anbietet.
* **Sicherheit (SSL/TLS):** Stelle sicher, dass der Provider eine verschlüsselte Verbindung (SSL/TLS) anbietet. Dies schützt deine Privatsphäre, indem es die heruntergeladenen Daten vor Dritten verbirgt.
* **Preis**: Die Kosten variieren je nach Retention, Geschwindigkeit und Anzahl der Verbindungen. Viele Provider bieten verschiedene Tarife und oft auch Testphasen an.
* **Block Accounts:** Ein Block Account ist ein einmaliger Kauf eines bestimmten Datenvolumens (z. B. 500 GB), das nicht verfällt, sind aber meist teurer pro TB als reguläre Accounts. Er wird nicht als Hauptzugang genutzt, sondern dient als **Back-up-Lösung**.

---

### Beispiele für Provider

Es gibt unzählige Usenet-Provider. Bekannte Premium-Anbieter wie **Eweka**, **UsenetServer** oder **NewsgroupDirect** zeichnen sich durch hohe Retention und exzellente Bandbreite aus. Günstigere Alternativen wie **SunnyUsenet**, **Pure Usenet** oder **ViperNews** haben oft eine niedrigere Retention, weniger gleichzeitige Verbindungen und je nach Abomodell auch eine begrenzte Bandbreite.

Gerade für Nutzer, die ihren Fokus auf neue Releases legen, ist ein erschwinglicher Provider oft ausreichend. Falls man jedoch ältere Dateien herunterladen möchte, die beim Hauptprovider nicht mehr verfügbar sind, kommen **Block Accounts** ins Spiel. Sie dienen als perfekte Ergänzung, um diese Lücken zu füllen.

Auf Reddit unter [r/usenet](https://www.reddit.com/r/usenet/) findet man eine Liste mit [aktuellen Providerdeals](https://www.reddit.com/r/usenet/wiki/providerdeals/). **Eweka** ist ein Anbieter, der oft attraktive Angebote hat, wie zum Beispiel den [Eweka Deal1](https://www.eweka.nl/en/landing/promo-deal-evm-e), der in der Community sehr beliebt ist. Es lohnt sich, die Angebote zu vergleichen.

---

## 2.2 Indexer finden

Ein Indexer ist die Suchmaschine für das Usenet. Ohne einen Indexer wäre es unmöglich, die gesuchten Dateien in der Masse der Newsgroups zu finden. Die Indexer stellen die benötigten **NZB-Dateien** bereit, die deine Downloader dann verwenden.

### Öffentlich, Privat oder doch eher Boards?

* **Private vs. Öffentliche Indexer:** Öffentliche Indexer sind frei zugänglich, bieten aber oft weniger exklusive Inhalte. Für dein automatisiertes Setup sind sie meist nur bedingt nützlich. Private Indexer erfordern in der Regel eine Einladung oder eine kleine Spende, bieten aber eine höhere Qualität, Zuverlässigkeit und eine bessere API-Anbindung.
* **Usenet Boards:** Das sind Foren oder Communities, die manuell von Nutzern erstellte NZB-Dateien teilen. Sie eignen sich gut für die manuelle Suche nach speziellen Inhalten, bieten aber keinen API-Zugang für Tools zur Automatisierung.
* **API-Zugang:** Dies ist der wichtigste Punkt für dein automatisiertes Setup. Deine PVR-Tools (Sonarr, Radarr, Prowlarr) benötigen eine API-Schnittstelle, um automatisch nach Inhalten suchen zu können. Achte darauf, dass der Indexer dies anbietet.
* **Inhalt:** Verschiedene Indexer haben oft unterschiedliche Schwerpunkte, was die Art der indizierten Inhalte angeht. Es ist sinnvoll, mehrere Indexer zu kombinieren, um eine breitere Abdeckung zu erzielen.

---

### Beliebte Indexer

Viele Nutzer beginnen mit einem öffentlichen Indexer wie **NZBIndex**, **NZBKing** oder **Binsearch**. Für ein automatisiertes Setup ist es jedoch am effektivsten, direkt auf private Indexer zu setzen.

### Private Indexer mit Fokus auf deutschem Content

* **SceneNZBs:** Essentiell für deutsche Releases, listet aber auch englisch- und italienischsprachige Inhalte. Die Registrierung ist dauerhaft geöffnet.
* **NewzBay:** Fokussiert auf deutsche Releases. Die Registrierung ist geschlossen, Zugang erhält man nur durch User-Invites.

### Private Indexer mit Fokus auf englischem Content

* **NZBGeek** und **NZB.su:** Bieten hauptsächlich englischsprachige Releases an, mit etwas Glück findet man dort aber auch älteren deutschen Content. Die Registrierung ist dauerhaft geöffnet.
* **DrunkenSlug:** Ein sehr beliebter Indexer, der ebenfalls hauptsächlich englischen Content listet. Die Registrierung ist in der Regel geschlossen, öffnet aber in unregelmäßigen Abständen.

Die Kosten für private Indexer bewegen sich meist zwischen 10 und 25 Euro pro Jahr, je nach VIP-Modell.

### Deutsche Usenet Boards

Es gibt einige deutsche Usenet Boards, die sich auf deutschsprachige Inhalte spezialisiert haben. Zu den bekanntesten und etabliertesten gehören **Fileleechers**, **Brothers of Usenet** und **Sky of Usenet**.

Ein wichtiger Punkt, den man beachten muss: Die meisten dieser Boards sind **private Communities**. Das bedeutet, dass die Registrierungen oft geschlossen sind. Ein Zugang ist meist nur über eine persönliche Einladung (`User Invite`) eines bereits registrierten Mitglieds möglich.

Gelegentlich öffnen diese Boards ihre Registrierung für einen kurzen Zeitraum. Es gibt jedoch keine festen Zeiten dafür. Für Nutzer, die primär auf der Suche nach deutschsprachigem Content sind, können diese Boards eine wertvolle Ergänzung zu einem Indexer sein.

**Wichtig:** Für eine vollständige Automatisierung deines Setups sind diese Boards nicht geeignet. Da sie in der Regel **keinen API-Zugang** bieten, ist eine automatische Suche und ein Download über Tools wie Sonarr oder Radarr hier nicht möglich. Du musst die Inhalte manuell suchen.
