# Baupläne

Ein Bauplan ist eine Anleitung für die KI. Du musst ihn nicht selbst lesen oder umsetzen. Du sagst Claude Code, welchen Bauplan es nehmen soll, und die KI baut das Stück in deine App ein. Wenn du neugierig bist, was dabei passiert, steht in jedem Bauplan zuerst eine Erklärung ohne Fachwörter.

Die Baupläne sind **optional**. Deine App funktioniert auch ohne sie.

| Bauplan | Was du davon hast | Schwierigkeit | Kosten |
|---|---|---|---|
| [pwa.md](pwa.md) | Deine App lässt sich wie eine echte App auf den Startbildschirm legen | leicht | keine |
| [qr-scanner.md](qr-scanner.md) | Deine App liest QR-Codes mit der Handykamera | mittel | keine |
| [team.md](team.md) | Nur Personen auf deiner Liste kommen in die App (zum Beispiel dein Team) | mittel | keine |
| [mcp.md](mcp.md) | Claude kann die Daten deiner App lesen (nur lesen) | schwer | braucht den Blaze-Tarif von Firebase |
| [ui-woerterbuch.md](ui-woerterbuch.md) | Die Fachwörter für Knöpfe, Menüs und Fenster, mit Bildern, damit du der KI genau sagen kannst, was du willst | leicht | keine |
| [vor-dem-teilen.md](vor-dem-teilen.md) | Checkliste, bevor andere deine App benutzen | leicht | keine |

## So benutzt du einen Bauplan

Sag der KI zum Beispiel:

> Baue die PWA nach bauplaene/pwa.md in meine App ein. Erkläre mir vorher in einfachen Worten, was sich ändert.

Dann gilt wie immer: Die KI macht nur diese eine Änderung, du testest sie am Handy, danach übernimmt die KI sie auf main.

## Ehrlich gesagt

Die Baupläne für PWA und QR-Scanner wurden in einer Testkopie der Vorlage gebaut (der Build läuft durch). Auf einem echten Handy getestet sind sie noch nicht. Der Bauplan für MCP wurde nur übersetzt, nicht im echten Betrieb getestet. Sie folgen dem Muster aus unseren eigenen Projekten (personio-connect, zammad-dispatch). Wenn etwas nicht klappt: die Fehlermeldung kopieren und der KI zeigen.
