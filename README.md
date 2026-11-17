# Meine erste App

Eine kleine Notizliste mit Anmeldung. Gebaut mit Angular, gespeichert in Firebase, automatisch veröffentlicht über GitHub und Firebase Hosting. Alles läuft im Browser, du musst nichts installieren.

## So funktioniert es

1. Du beauftragst die KI in Claude Code im Web, den Code zu ändern.
2. Du übernimmst die Änderung in den Hauptzweig (main).
3. GitHub baut die App und veröffentlicht sie. Das dauert ein bis zwei Minuten, den Fortschritt siehst du im Reiter Actions.
4. Deine App läuft unter https://DEIN-PROJEKT.web.app, auch auf dem Handy.

## Einmalig einrichten

1. In der Firebase-Konsole eine Web-App registrieren und die Werte kopieren.
2. Authentication (E-Mail/Passwort) und Firestore (Standort eur3, Produktionsmodus) einschalten.
3. Die Werte in `src/environments/environment.ts` eintragen lassen. Sag der KI: "Trage diese Firebase-Werte in environment.ts ein" und füge die Werte ein.
4. In der Google Cloud Shell den Einrichtungsblock aus dem Workshop ausführen. Er gibt zwei Werte aus (Provider und Dienstkonto). Es wird kein Schlüssel erzeugt.
5. In `.github/workflows/deploy.yml` und in `.firebaserc` DEIN-PROJEKT durch deine Projekt-ID ersetzen und die zwei Werte aus Schritt 4 sowie die Projektnummer eintragen.
6. In der Firebase-Konsole unter Authentication, Einstellungen, Autorisierte Domains prüfen, dass `DEIN-PROJEKT.web.app` eingetragen ist.

Die Firestore-Regeln aus `firestore.rules` werden bei jedem Deploy automatisch veröffentlicht.

## Den Code ändern lassen

Beschreibe der KI in einem Satz, was sich ändern soll, zum Beispiel: "Aus der Notizliste soll eine Einkaufsliste mit Mengenangabe werden." Immer nur eine Änderung auf einmal. Fehlermeldungen komplett kopieren und der KI zeigen. Jede Abfrage an die Datenbank muss weiterhin auf die uid des Nutzers filtern.

## Regeln für die KI

- Niemals `firebase login` oder `firebase deploy` ausführen. Veröffentlicht wird nur über GitHub Actions.
- Keine Schlüssel, Passwörter oder Tokens in Dateien schreiben.
- Die Datei `firestore.rules` nur ändern, wenn ich es ausdrücklich verlange.

## Dateien

- `src/app/notes.component.ts`: die Seite mit der Liste
- `src/app/notes.service.ts`: Speichern und Laden in Firestore
- `src/app/login.component.ts`: die Anmeldeseite
- `firestore.rules`: wer welche Daten sehen darf
- `.github/workflows/deploy.yml`: das automatische Veröffentlichen
