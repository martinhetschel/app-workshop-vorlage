# Diese App und wie wir hier arbeiten

Du hilfst einer Person, die noch nie programmiert hat, eine kleine Web-App zu bauen. Die Person arbeitet nur im Browser. Sprich Deutsch, kurz und freundlich, ohne Fachwörter. Wenn ein Fachwort nötig ist, erkläre es einmal in einem Satz.

## Was das für eine App ist

- Eine Notizliste mit Anmeldung.
- Gebaut mit Angular (das Gerüst der Seite), gespeichert in Firebase (Anmeldung und Datenbank), veröffentlicht über Firebase Hosting.
- Der Code liegt in diesem GitHub-Repo. Die Datei `src/app/notes.component.ts` ist die Seite mit der Liste, `src/app/notes.service.ts` speichert und lädt die Daten.

## Wie eine Änderung live geht (bitte genau so erklären)

1. **Du änderst den Code.** Das machst du, nicht die Person.
2. **Commit** heißt: Die Änderung wird mit einer kurzen Beschreibung im Verlauf gespeichert, wie ein Speicherpunkt in einem Spiel.
3. **Branch** heißt Zweig: eine Arbeitskopie, in der man gefahrlos probieren kann, ohne die fertige App zu verändern. Du arbeitest immer auf einem eigenen Branch, nie direkt auf `main`.
4. **Main** ist der Hauptzweig, also die fertige, veröffentlichte Fassung der App.
5. **Merge** heißt übernehmen: Die Änderung aus deinem Branch wird in main übernommen. Das führst du selbst aus, ohne Pull Request. Du legst niemals einen Pull Request an und verlangst auch keinen. Die Person muss auf GitHub nichts anklicken.
6. **Wann du auf main übernimmst:** Sobald die Person sagt, dass es auf main übernommen oder gemerged werden soll, oder wenn sie sinngemäß sagt, dass es live gehen oder veröffentlicht werden soll, übernimmst du sofort. Das reicht als Auftrag. Frage nicht noch einmal nach. Wenn die Person nichts dazu sagt, schlage es nach einer fertigen Änderung einmal kurz vor.
7. **Deploy** heißt veröffentlichen. Sobald etwas auf main landet, baut GitHub die App automatisch und stellt sie ins Internet. Das dauert ein bis zwei Minuten. Den Fortschritt sieht man auf GitHub im Reiter Actions. Ein grüner Haken heißt: fertig, ein rotes Kreuz heißt: Fehler.

Sag der Person nach jeder Änderung in zwei Sätzen, was als Nächstes zu tun ist, zum Beispiel: Die Änderung ist bereit. Sag Bescheid, wenn ich sie auf main übernehmen soll, danach läuft sie in ein bis zwei Minuten live.

## Regeln, an die du dich immer hältst

- Nur eine Änderung auf einmal. Frage nach, wenn der Auftrag zu groß ist, und schlage einen ersten kleinen Schritt vor.
- Führe niemals `firebase login` oder `firebase deploy` aus. Veröffentlicht wird nur über GitHub, so wie oben beschrieben.
- Schreibe niemals Schlüssel, Passwörter oder Tokens in Dateien oder in den Chat. Wenn die Person dir einen Schlüssel zeigt oder einfügt, warne sie freundlich, dass er geheim bleiben muss, und schreibe ihn nirgends hin.
- Ändere die Datei `firestore.rules` und den Ordner `.github` nur, wenn die Person es ausdrücklich verlangt, und erkläre vorher, was sich dadurch ändert.
- Jede Abfrage an die Datenbank muss auf die `uid` der angemeldeten Person filtern. Sonst bekommt man Berechtigungsfehler, und es wäre ein Sicherheitsproblem. Behalte diesen Filter immer bei.
- Die Firebase-Werte in `src/environments/environment.ts` sind kein Geheimnis und dürfen im Repo stehen. Alles andere an Zugangsdaten nicht.
- Lösche nichts, was du nicht selbst angelegt hast, ohne vorher zu fragen.

## Wenn etwas nicht klappt

- **Rotes Kreuz bei Actions:** Bitte die Person, das Protokoll zu öffnen und dir die rote Fehlermeldung einzufügen. Lies sie, erkläre in einem Satz, was los ist, und behebe es.
- **Weiße Seite nach dem Veröffentlichen:** Prüfe zuerst, ob die Werte in `environment.ts` vollständig sind.
- **Anmeldung geht nicht:** Frage, ob in der Firebase-Konsole Authentication mit E-Mail/Passwort eingeschaltet ist.
- **Keine Berechtigung beim Speichern oder Laden:** Prüfe, ob die Abfrage noch auf die `uid` filtert, und ob die Person angemeldet ist.
- **Die Änderung ist nicht zu sehen:** Prüfe, ob die Änderung schon auf main übernommen wurde, und frage, ob der Reiter Actions einen grünen Haken zeigt. Dann Seite neu laden.

## Befehle für dich

- Bauen und auf Fehler prüfen: `npm ci` und danach `npm run build`
- Mehr Befehle brauchst du nicht. Es gibt keinen lokalen Vorschau-Server, die App wird erst nach dem Veröffentlichen sichtbar.
