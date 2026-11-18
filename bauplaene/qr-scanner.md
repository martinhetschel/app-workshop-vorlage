# Bauplan: QR-Code mit der Kamera lesen

## Was ist das?

Deine App bekommt einen Knopf "QR-Code scannen". Er schaltet die Handykamera ein, erkennt einen QR-Code im Bild und gibt den Text darin an deine App weiter. Beispiele: ein Paket oder Regalfach per Aufkleber finden, einen Mitarbeiterausweis lesen, eine Teilnehmerliste abhaken.

Gut zu wissen:

- Das Kamerabild bleibt auf dem Gerät. Es wird nichts hochgeladen, das Erkennen passiert im Browser.
- Der Browser fragt beim ersten Mal, ob die App die Kamera benutzen darf. Man muss "Erlauben" antippen.
- Die Kamera funktioniert nur auf einer sicheren Adresse (HTTPS). Auf `web.app` ist das automatisch so.
- Zum Testen brauchst du einen QR-Code. Im Internet gibt es kostenlose QR-Code-Erzeuger: einen kurzen Text eingeben und das Bild am zweiten Bildschirm anzeigen.

## So sagst du es der KI

> Baue den QR-Scanner nach bauplaene/qr-scanner.md ein. Nach dem Scannen soll [hier sagen, was passieren soll, zum Beispiel: der gelesene Text in das Suchfeld eingetragen werden]. Erkläre mir vorher in einfachen Worten, was sich ändert.

## Was die KI tut (Checkliste)

Dieser Bauplan legt `src/app/qr-scanner.component.ts` an und ändert `package.json` und `angular.json`. Danach wird der Scanner an der Stelle eingebaut, an der du ihn haben willst.

1. **Paket installieren.** `jsqr` ist ein kleines, kostenloses Paket, das QR-Codes in einem Bild erkennt:

   ```bash
   npm install jsqr
   ```

2. **`angular.json`:** Im Abschnitt `build`, `options` ergänzen. Das unterdrückt nur einen harmlosen Hinweis beim Bauen:

   ```json
   "allowedCommonJsDependencies": ["jsqr"]
   ```

3. **`src/app/qr-scanner.component.ts`** anlegen:

   ```ts
   import { Component, ElementRef, OnDestroy, OnInit, output, signal, viewChild } from '@angular/core';
   import jsQR from 'jsqr';

   // Liest einen QR-Code mit der Kamera. Sobald ein Code erkannt wird, meldet die Komponente den Text
   // über `gelesen` und schaltet die Kamera aus. Die Kamera braucht HTTPS (auf web.app ist das so)
   // und die Erlaubnis der Person. Es wird nichts hochgeladen: das Erkennen passiert im Browser.
   @Component({
     selector: 'app-qr-scanner',
     standalone: true,
     template: `
       <div class="scanner">
         <video #video playsinline muted></video>
         <canvas #canvas hidden></canvas>
         @if (meldung()) {
           <p>{{ meldung() }}</p>
         }
         <button type="button" class="secondary" (click)="abbrechen.emit()">Abbrechen</button>
       </div>
     `,
     styles: `
       .scanner { max-width: 420px; }
       video { display: block; width: 100%; max-height: 50vh; object-fit: cover; border-radius: 12px; background: #000; }
     `,
   })
   export class QrScannerComponent implements OnInit, OnDestroy {
     readonly gelesen = output<string>();
     readonly abbrechen = output<void>();
     readonly meldung = signal('Kamera wird gestartet …');

     private readonly video = viewChild.required<ElementRef<HTMLVideoElement>>('video');
     private readonly canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('canvas');
     private stream?: MediaStream;
     private timer?: ReturnType<typeof setInterval>;

     async ngOnInit(): Promise<void> {
       if (!navigator.mediaDevices?.getUserMedia) {
         this.meldung.set('Dieses Gerät erlaubt hier keinen Kamerazugriff.');
         return;
       }
       try {
         // Rückkamera bevorzugen, sonst die vorhandene Kamera
         this.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: { ideal: 'environment' } }, audio: false });
       } catch {
         this.meldung.set('Kein Zugriff auf die Kamera. Bitte in den Browser-Einstellungen erlauben.');
         return;
       }
       const video = this.video().nativeElement;
       video.srcObject = this.stream;
       await video.play();
       this.meldung.set('Halte den QR-Code ins Bild.');
       this.timer = setInterval(() => this.lesen(), 250);
     }

     private lesen(): void {
       const video = this.video().nativeElement;
       if (video.videoWidth === 0) return;
       const canvas = this.canvas().nativeElement;
       canvas.width = video.videoWidth;
       canvas.height = video.videoHeight;
       const context = canvas.getContext('2d', { willReadFrequently: true });
       if (!context) return;
       context.drawImage(video, 0, 0, canvas.width, canvas.height);
       const bild = context.getImageData(0, 0, canvas.width, canvas.height);
       const code = jsQR(bild.data, bild.width, bild.height);
       if (code?.data) {
         this.stoppen();
         this.gelesen.emit(code.data);
       }
     }

     private stoppen(): void {
       if (this.timer) clearInterval(this.timer);
       this.stream?.getTracks().forEach((spur) => spur.stop());
     }

     ngOnDestroy(): void {
       this.stoppen();
     }
   }
   ```

4. **Einbauen.** In der Seite, die scannen soll, die Komponente importieren (`imports: [QrScannerComponent]`) und so benutzen:

   ```html
   @if (scannt) {
     <app-qr-scanner (gelesen)="ergebnis = $event; scannt = false" (abbrechen)="scannt = false" />
   } @else {
     <button (click)="scannt = true">QR-Code scannen</button>
   }
   ```

   Dazu in der Klasse der Seite `scannt = false;` und `ergebnis = '';`. Was mit `ergebnis` passiert, bestimmst du.

5. `npm run build` ausführen. Es darf kein Fehler kommen.

## So testest du es

Nach dem Deploy die App auf dem **Handy** öffnen (am PC mit Webcam geht es auch). "QR-Code scannen" antippen, Kamera erlauben, auf einen QR-Code am zweiten Bildschirm halten. Im Entwicklungs-Browser in Claude Code geht das nicht, dort gibt es keine Kamera.

## Sicherheit: dem gelesenen Text nie blind vertrauen

Ein QR-Code kann **beliebigen** Text enthalten, auch einen Link auf eine fremde, gefährliche Seite. Deshalb:

- Gelesene Links werden nie automatisch geöffnet.
- Gespeichert wird nur, was die App erwartet (zum Beispiel eine Nummer in einem bestimmten Format). Alles andere wird abgelehnt mit einer freundlichen Meldung.
- Der gelesene Text kommt nie als fertiger HTML-Text in die Seite, sondern nur als normaler Text.

## Typische Stolpersteine

- **Schwarzes Bild oder keine Kamera:** Erlaubnis fehlt. In den Browser-Einstellungen der Seite die Kamera erlauben und die Seite neu laden.
- **Es wird nichts erkannt:** Mehr Licht, den Code ruhig halten und nah genug ranhalten. Ein sehr kleiner oder verschmierter Code geht nicht.
- **Auf dem iPhone kein Bild:** In Safari die Seite neu laden und die Kamera erlauben. Der Scanner nutzt `playsinline`, deshalb bleibt das Bild in der Seite.
- **Beim Bauen erscheint eine Warnung zu `jsqr`:** Schritt 2 fehlt.

## Zum Nachschlagen

Dieselbe Technik (mit zusätzlichem "Kamera wechseln") läuft in personio-connect: `admin-app/src/app/shared/qr-scanner.ts`.
