# Meine erste App

Ein Startpunkt mit Anmeldung für deine eigene App-Idee. Gebaut mit Angular, gespeichert in Firebase, automatisch veröffentlicht über GitHub und Firebase Hosting. Alles läuft im Browser, du musst nichts installieren.

## So funktioniert es

1. Du beauftragst die KI in Claude Code im Web, den Code zu ändern.
2. Du übernimmst die Änderung in den Hauptzweig (main).
3. GitHub baut die App und veröffentlicht sie. Das dauert ein bis zwei Minuten, den Fortschritt siehst du im Reiter Actions.
4. Deine App läuft unter https://DEIN-PROJEKT.web.app, auch auf dem Handy.

## Einmalig einrichten

1. In der [Firebase-Konsole](https://console.firebase.google.com) ein neues Projekt anlegen (Google Analytics ausschalten) und die **Projekt-ID** notieren.
2. Dort unter Authentication die Anmeldemethode E-Mail/Passwort einschalten.
3. Die [Google Cloud Shell](https://shell.cloud.google.com) öffnen (Terminal im Browser) und diese zwei Zeilen einfügen:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/martinhetschel/app-workshop-vorlage/main/scripts/setup-wif.sh -o setup.sh
   bash setup.sh
   ```

4. Das Skript fragt nach der Projekt-ID und nach deinem GitHub-Repo (`name/repo`). Es richtet die schlüssellose Anmeldung für den Deploy ein, legt Hosting und die Datenbank (Europa) an, holt die Firebase-Werte und trägt alles in dein Repo ein. Am Ende läuft der erste Deploy.
5. Das Skript kannst du beliebig oft starten, zum Beispiel nach einem Tippfehler. Es korrigiert, was nicht stimmt, und lässt den Rest in Ruhe.

Die Firestore-Regeln aus `firestore.rules` werden bei jedem Deploy automatisch veröffentlicht. Es wird kein Schlüssel erzeugt.

Zeigt die App nach dem Deploy eine Anmeldefehlermeldung, prüfe in der Firebase-Konsole unter Authentication, Einstellungen, Autorisierte Domains, ob `DEIN-PROJEKT.web.app` (mit deiner Projekt-ID) eingetragen ist.

## Den Code ändern lassen

Erzähle der KI deine Idee, zum Beispiel: "Ich möchte eine Einkaufsliste, in der ich Dinge mit Menge eintragen und abhaken kann." Die KI stellt dir ein paar Fragen und baut zuerst die kleinste Version. Danach geht es Schritt für Schritt weiter, immer nur eine Änderung auf einmal. Fehlermeldungen komplett kopieren und der KI zeigen.

## Regeln für die KI

- Niemals `firebase login` oder `firebase deploy` ausführen. Veröffentlicht wird nur über GitHub Actions.
- Keine Schlüssel, Passwörter oder Tokens in Dateien schreiben.
- Die Datei `firestore.rules` nur ändern, wenn es nötig ist, und vorher erklären, warum.

## Dateien

- `src/app/home.component.ts`: die Startseite nach der Anmeldung, hier entsteht deine App
- `src/app/data.service.ts`: Speichern und Laden in Firestore
- `src/app/login.component.ts`: die Anmeldeseite
- `firestore.rules`: wer welche Daten sehen darf
- `.github/workflows/deploy.yml`: das automatische Veröffentlichen
- `scripts/setup-wif.sh`: die einmalige Einrichtung für die Cloud Shell
