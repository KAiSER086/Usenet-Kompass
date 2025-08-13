# 2.2 Indexer finden

Ein Indexer ist die Suchmaschine für das Usenet. Ohne einen Indexer wäre es unmöglich, die gesuchten Dateien in der Masse der Newsgroups zu finden. Die Indexer stellen die benötigten **NZB-Dateien** bereit, die deine Downloader dann verwenden.

---

### Worauf sollte man bei der Auswahl achten?

* **Private vs. Öffentliche Indexer:** Öffentliche Indexer sind frei zugänglich, bieten aber oft weniger exklusive Inhalte. Für dein automatisiertes Setup sind sie meist nur bedingt nützlich. Private Indexer erfordern in der Regel eine Einladung oder eine kleine Spende, bieten aber eine höhere Qualität, Zuverlässigkeit und eine bessere API-Anbindung.
* **Usenet Boards:** Das sind Foren oder Communities, die manuell von Nutzern erstellte NZB-Dateien teilen. Sie eignen sich gut für die manuelle Suche nach speziellen Inhalten, bieten aber keinen API-Zugang für Tools zur Automatisierung.
* **API-Zugang:** Dies ist der wichtigste Punkt für dein automatisiertes Setup. Deine PVR-Tools (Sonarr, Radarr, Prowlarr) benötigen eine API-Schnittstelle, um automatisch nach Inhalten suchen zu können. Achte darauf, dass der Indexer dies anbietet.
* **Inhalt:** Verschiedene Indexer haben oft unterschiedliche Schwerpunkte, was die Art der indizierten Inhalte angeht. Es ist sinnvoll, mehrere Indexer zu kombinieren, um eine breitere Abdeckung zu erzielen.

---

### Beliebte Indexer

Viele Nutzer beginnen mit einem öffentlichen Indexer wie **NZBIndex**, **NZBKing** oder **Binsearch**. Für ein automatisiertes Setup ist es jedoch am effektivsten, direkt auf private Indexer zu setzen.

#### Private Indexer mit Fokus auf deutschem Content

* **SceneNZBs:** Essentiell für deutsche Releases, listet aber auch englisch- und italienischsprachige Inhalte. Die Registrierung ist dauerhaft geöffnet.
* **NewzBay:** Fokussiert auf deutsche Releases. Die Registrierung ist meist geschlossen, Zugang erhält man oft nur durch User-Invites.

#### Private Indexer mit Fokus auf englischem Content

* **NZBGeek** und **NZB.su:** Bieten hauptsächlich englischsprachige Releases an, mit etwas Glück findet man dort aber auch älteren deutschen Content. Die Registrierung ist dauerhaft geöffnet.
* **DrunkenSlug:** Ein sehr beliebter Indexer, der ebenfalls hauptsächlich englischen Content listet. Die Registrierung ist in der Regel geschlossen, öffnet aber in unregelmäßigen Abständen.

Die Kosten für private Indexer bewegen sich meist zwischen 10 und 25 Euro pro Jahr, je nach VIP-Modell.

