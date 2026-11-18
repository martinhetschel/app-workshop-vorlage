# Checkliste: Bevor andere deine App benutzen

Für den Workshop reicht eine App, die für dich allein läuft. Sobald Kolleginnen, Kunden oder Freunde sie benutzen, lohnt sich ein Blick auf diese Punkte. Du kannst die Checkliste der KI geben: "Geh bauplaene/vor-dem-teilen.md mit mir Punkt für Punkt durch."

## 1. Personenbezogene Daten

Sobald du Namen, Telefonnummern, E-Mail-Adressen oder Ähnliches von anderen Menschen speicherst (zum Beispiel in einer Kundenkartei), gilt der Datenschutz (DSGVO).

- Speichere nur, was du wirklich brauchst.
- Die Menschen müssen wissen, dass du ihre Daten speicherst, und du brauchst einen Grund dafür (zum Beispiel ihre Einwilligung oder eine Kundenbeziehung).
- Google speichert die Daten für dich. Die Datenbank liegt in Europa (eur3), das ist gut. Für eine geschäftliche Nutzung gibt es einen Vertrag zur Auftragsverarbeitung mit Google, den du in der Google-Cloud-Konsole annehmen kannst. Frag im Zweifel bei der Datenschutzbeauftragten oder einer Rechtsberatung nach. Ich bin keine Rechtsberatung.
- Besonders sensible Daten (Gesundheit, Religion und Ähnliches) gehören nicht in eine selbstgebaute App.

## 2. Impressum und Datenschutzerklärung

Läuft die App öffentlich oder für Außenstehende (nicht nur für dich privat), gehören ein Impressum und eine Datenschutzerklärung dazu, mit einem Link im Fuß der Seite.

## 3. Wer darf sich anmelden?

In der Vorlage kann sich **jede Person mit einer E-Mail-Adresse registrieren**. Sie sieht nur ihre eigenen Daten, aber sie kann die App benutzen. Soll die App nur für bestimmte Personen sein (zum Beispiel dein Team), muss die Registrierung eingeschränkt werden. Das ist ein Sicherheitsthema: Sag der KI, was du willst, sie erklärt dir die Möglichkeiten, und ändert erst nach deinem Einverständnis etwas.

## 4. Sicherung und Export

Die Daten liegen bei Google, aber ein Knopf "Als Datei herunterladen" (zum Beispiel CSV für Excel) gibt dir und den Nutzern eine eigene Kopie. Bitte die KI darum, wenn die Daten wichtig sind.

## 5. Löschen können

Wer Daten speichert, sollte sie auch wieder löschen können, einzelne Einträge ebenso wie alles zu einer Person.

## 6. Die App fühlt sich fertig an

- Beim Laden zeigt sie eine Ladeanzeige.
- Ohne Einträge zeigt sie einen Leerzustand mit einem Hinweis, was man tun kann.
- Fehlermeldungen sagen, was man tun kann.
- Sie wurde am Handy **und** am PC angesehen (siehe [ui-woerterbuch.md](ui-woerterbuch.md)).
- Der Text ist gut lesbar (genug Kontrast, mindestens 16 Pixel auf dem Handy).

## 7. Kosten im Blick

Der kostenlose Spark-Tarif hat Grenzen. Wer viel Verkehr hat oder auf Blaze wechselt, richtet ein Budget mit Warnung ein (Google Cloud, Abrechnung, Budgets und Benachrichtigungen).

## 8. Eigene Adresse und Symbol

Eine eigene Domain statt `projekt.web.app` wirkt professioneller (Firebase Hosting, "Domain hinzufügen"). Mit dem Bauplan [pwa.md](pwa.md) bekommt die App ein Symbol auf dem Startbildschirm.
