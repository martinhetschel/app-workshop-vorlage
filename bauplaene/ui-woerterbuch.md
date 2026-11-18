# Wörterbuch: So heißen die Bausteine einer App

Wenn du der KI genau sagen kannst, was du willst, bekommst du genau das. Hier stehen die Wörter für die Bausteine, die in fast jeder App vorkommen. Die Fachwörter sind englisch, weil sie überall so benutzt werden. Wenn du sie benutzt, versteht dich die KI sofort.

## Navigation: Wie komme ich wohin?

- **Menü:** Eine Liste von Zielen, zum Beispiel "Start", "Einträge", "Einstellungen".
- **Hamburgermenü:** Das Symbol mit drei waagerechten Strichen (wie ein Hamburger). Ein Tipp darauf klappt das Menü auf. Es wird auf dem Handy benutzt, weil dort kein Platz für ein Menü am Rand ist. Auf einem großen Bildschirm steht das Menü meist offen am Rand oder oben.
- **Tabs:** Reiter nebeneinander (wie bei Aktenordnern). Ein Tipp wechselt die Ansicht, ohne die Seite zu verlassen.
- **Untere Leiste:** Auf dem Handy eine feste Leiste unten mit zwei bis fünf Symbolen. Gut für die wichtigsten Ziele, weil man sie mit dem Daumen erreicht.
- **Brotkrumen (Breadcrumbs):** Der Pfad oben, zum Beispiel "Start > Kunden > Müller". So sieht man, wo man ist, und kommt zurück.

## Eingaben: Wie gebe ich etwas ein?

- **Button (Knopf):** Löst eine Aktion aus, zum Beispiel "Speichern". Der wichtigste Knopf einer Seite wird auffällig gestaltet, die anderen zurückhaltend.
- **Eingabefeld:** Eine Zeile zum Tippen. Es gibt Varianten für Text, Zahlen, E-Mail, Passwort und Datum.
- **Dropdown (Auswahlliste):** Ein Feld, das beim Antippen eine Liste öffnet, aus der man **einen** Eintrag wählt. Gut, wenn es etwa fünf bis fünfzehn feste Möglichkeiten gibt, zum Beispiel eine Kategorie.
- **Checkbox (Kästchen):** Ein Kästchen mit Häkchen für ja oder nein. Mehrere Kästchen untereinander erlauben, **mehrere** Dinge anzukreuzen.
- **Radiobuttons (Runde Auswahlknöpfe):** Eine kleine Gruppe von Kreisen, aus der man **genau einen** wählt, zum Beispiel "Klein, Mittel, Groß". Gut bei zwei bis vier Möglichkeiten, wenn man alle sehen will.
- **Schalter (Toggle):** Ein Schieberegler zum Ein- und Ausschalten, der sofort wirkt, zum Beispiel "Benachrichtigungen".
- **Datumsauswahl (Datepicker):** Ein kleiner Kalender zum Antippen eines Datums.
- **Suchfeld:** Ein Eingabefeld mit Lupe. Die Liste darunter wird beim Tippen kürzer.
- **Slider (Schieberegler):** Ein Balken, auf dem man einen Wert zieht, zum Beispiel eine Menge.

## Hinweise und Fenster: Wie meldet sich die App?

- **Modalfenster (Dialog, Pop-up):** Ein Fenster, das sich über die Seite legt. Dahinter ist alles abgedunkelt, und man muss erst darauf reagieren. Gut für Sicherheitsfragen wie "Wirklich löschen?" oder kurze Formulare. Nicht gut für lange Inhalte oder mehrere Fenster übereinander.
- **Toast (Snackbar):** Eine kleine Meldung, die kurz am Rand auftaucht und von allein verschwindet, zum Beispiel "Gespeichert". Sie stört nicht.
- **Banner:** Ein dauerhafter Hinweis oben auf der Seite, zum Beispiel "Du bist offline".
- **Tooltip:** Ein winziger Hinweistext, der erscheint, wenn man mit der Maus über etwas fährt. Auf dem Handy gibt es kein Hovern, deshalb nie etwas Wichtiges nur dort verstecken.
- **Ladeanzeige (Spinner):** Ein drehender Kreis. Er sagt: Es wird gerade gearbeitet.
- **Leerzustand (Empty State):** Was man sieht, wenn noch nichts da ist, zum Beispiel "Noch keine Einträge. Lege deinen ersten an." Er sollte immer sagen, was man als Nächstes tun kann.
- **Fehlermeldung:** Sagt, was schiefging **und was man tun kann**, in normalen Worten.

## Inhalte zeigen

- **Liste:** Einträge untereinander. Siehe unten, wie Listen am PC und am Handy aussehen sollen.
- **Tabelle:** Zeilen und Spalten, gut zum Vergleichen vieler Einträge am großen Bildschirm.
- **Card (Karte):** Ein abgerundeter Kasten, der zusammengehörende Infos zeigt, zum Beispiel einen Kunden mit Name, Ort und Telefonnummer.
- **Badge (Etikett):** Ein kleines farbiges Schild mit einem Wort, zum Beispiel "offen" oder "erledigt".
- **Akkordeon:** Überschriften, die sich beim Antippen aufklappen und den Inhalt zeigen. Gut für Fragen und Antworten.
- **Seitenleiste (Drawer):** Ein Bereich, der vom Rand hereingeschoben wird, zum Beispiel für Filter.
- **Floating Action Button:** Ein runder Knopf, der über der Seite schwebt, meist unten rechts, für die wichtigste Aktion ("+ Neu").

## Listen: Tabelle am PC, Cards am Handy

Eine Liste mit mehreren Angaben je Eintrag (zum Beispiel Name, Ort, Telefon, Status) wird **zwei** Mal gebaut:

- **Am PC mit großem Bildschirm** (ab etwa 900 Pixel Breite) als **Tabelle**. Hier ist viel Platz, man sieht viele Einträge auf einmal und kann sie gut vergleichen.
- **Auf dem Handy** (schmaler als etwa 900 Pixel) als **Cards**: Jeder Eintrag ist ein eigener Kasten, die Angaben stehen untereinander, jeweils mit ihrer Beschriftung davor. Eine Tabelle mit fünf Spalten ist auf einem schmalen Handybildschirm nicht lesbar und man müsste seitlich wischen.

Die Vorlage bringt dafür schon alles mit. Es ist **ein** und dieselbe Tabelle, die sich je nach Bildschirm umbaut. Du sagst der KI nur:

> Zeige die Liste als Tabelle, die sich auf dem Handy in Cards verwandelt (class="responsive").

So sieht der Aufbau aus (die KI schreibt das für dich, du musst es nicht können). Wichtig ist `data-label`: Das ist die Beschriftung, die am Handy vor dem Wert erscheint. Die erste Zelle ist der Titel der Card:

```html
<table class="responsive">
  <thead>
    <tr><th>Name</th><th>Ort</th><th>Telefon</th></tr>
  </thead>
  <tbody>
    <tr>
      <td data-label="Name">Anna Meier</td>
      <td data-label="Ort">Köln</td>
      <td data-label="Telefon">0221 1234</td>
    </tr>
  </tbody>
</table>
```

Regeln dazu:

- Bis etwa fünf Spalten gehen Tabelle und Cards gut. Bei mehr Spalten fragt die KI, welche am Handy weggelassen werden dürfen.
- Eine Liste mit nur **einer** Angabe je Eintrag (zum Beispiel Einkaufsliste) braucht keine Tabelle: Dort reicht eine einfache Liste.
- Knöpfe in einer Zeile ("Bearbeiten", "Löschen") gehören in die letzte Zelle.
- Immer auch am Handy ansehen, nicht nur am PC.

## Gute Gewohnheiten für alle Bausteine

- **Antippflächen** sind mindestens so groß wie eine Fingerspitze (etwa 44 mal 44 Pixel).
- **Schrift** ist auf dem Handy mindestens 16 Pixel groß. Kleinere Eingabefelder zoomt das iPhone beim Antippen von allein heran, das nervt.
- **Farbe allein** sagt nichts. Ein rotes Feld braucht auch ein Wort wie "Fehler", sonst erkennen Menschen mit Farbschwäche es nicht.
- **Beschriftung:** Jedes Eingabefeld hat eine sichtbare Beschriftung. Ein Platzhaltertext im Feld verschwindet beim Tippen und ersetzt sie nicht.
- **Löschen** fragt nach ("Wirklich löschen?") oder lässt sich rückgängig machen.
- **Ein Wort, ein Ding:** In der ganzen App heißt dasselbe immer gleich ("Eintrag", nicht mal "Eintrag" und mal "Datensatz").
