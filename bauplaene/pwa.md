# Bauplan: App fürs Handy (PWA)

## Was ist das?

PWA heißt "Progressive Web App". Gemeint ist eine ganz normale Web-App, die sich wie eine echte App verhält: Sie bekommt ein Symbol auf dem Startbildschirm, öffnet sich ohne Adresszeile und startet schneller. Du brauchst keinen App-Store und kein Entwicklerkonto.

Was dabei **nicht** passiert: Deine Daten werden nicht auf dem Handy zwischengespeichert. Nur das "Gehäuse" der App (Seiten, Bilder, Farben) wird gemerkt. Die Daten kommen immer frisch aus dem Netz. Das ist Absicht, denn so liegen keine alten oder fremden Daten auf dem Gerät. Ohne Internet siehst du also das Gehäuse, aber keine Einträge.

## So sagst du es der KI

> Baue die PWA nach bauplaene/pwa.md ein. Erkläre mir vorher in einfachen Worten, was sich ändert.

## Was die KI tut (Checkliste)

Wichtig: Es wird **eine** Änderung auf einmal gemacht und erst nach deinem Okay auf main übernommen. Dieser Bauplan ändert `package.json`, `angular.json`, `firebase.json`, `src/index.html` und `src/app/app.config.ts`. Er legt `ngsw-config.json`, `make-icons.mjs` und den Ordner `public/` neu an.

1. **Paket mit genau passender Version installieren.** Das Paket für den Service Worker (das ist das Stück, das das "Gehäuse" merkt) muss exakt dieselbe Version haben wie `@angular/core`, sonst bricht die Installation ab:

   ```bash
   VERSION=$(node -p "require('@angular/core/package.json').version")
   npm install --save-exact @angular/service-worker@$VERSION
   ```

2. **`angular.json`:** Im Abschnitt `build`, `options` zwei Einträge ergänzen:

   ```json
   "assets": [{ "glob": "**/*", "input": "public" }],
   "serviceWorker": "ngsw-config.json"
   ```

3. **`ngsw-config.json`** im Hauptordner anlegen. Hier steht, was gemerkt wird. Daten gehören hier nie hinein (keine `dataGroups`):

   ```json
   {
     "$schema": "./node_modules/@angular/service-worker/config/schema.json",
     "index": "/index.html",
     "assetGroups": [
       {
         "name": "app",
         "installMode": "prefetch",
         "resources": { "files": ["/index.html", "/manifest.webmanifest", "/*.css", "/*.js"] }
       },
       {
         "name": "assets",
         "installMode": "lazy",
         "updateMode": "prefetch",
         "resources": { "files": ["/icons/**", "/**/*.(svg|jpg|jpeg|png|webp|gif|woff|woff2)"] }
       }
     ]
   }
   ```

4. **`public/manifest.webmanifest`** anlegen. Das ist der "Ausweis" der App: Name, Farben, Symbole. Name und Farben dürfen auf deine App angepasst werden:

   ```json
   {
     "name": "Meine App",
     "short_name": "Meine App",
     "lang": "de",
     "start_url": "/",
     "scope": "/",
     "display": "standalone",
     "background_color": "#f4f5f7",
     "theme_color": "#2563eb",
     "icons": [
       { "src": "icons/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
       { "src": "icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any" },
       { "src": "icons/icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
     ]
   }
   ```

5. **Symbole erzeugen.** Handys wollen PNG-Bilder in zwei Größen. Das kleine Skript `make-icons.mjs` macht einfarbige Symbole ohne zusätzliche Pakete. Später kannst du die drei Dateien in `public/icons/` durch ein eigenes Bild ersetzen (gleiche Namen und Größen). Skript im Hauptordner anlegen und einmal ausführen (`node make-icons.mjs`):

   ```js
   // Erzeugt einfarbige App-Symbole (PNG) ohne zusätzliche Pakete. Später durch ein eigenes Bild ersetzbar.
   import { deflateSync } from 'node:zlib';
   import { mkdirSync, writeFileSync } from 'node:fs';

   const FARBE = [0x25, 0x63, 0xeb]; // Blau, passend zu theme_color

   function crc32(buf) {
     let c, crc = 0xffffffff;
     for (const byte of buf) {
       c = (crc ^ byte) & 0xff;
       for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
       crc = (crc >>> 8) ^ c;
     }
     return (crc ^ 0xffffffff) >>> 0;
   }
   function chunk(type, data) {
     const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
     const body = Buffer.concat([Buffer.from(type), data]);
     const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(body));
     return Buffer.concat([len, body, crc]);
   }
   function png(size) {
     const zeile = Buffer.alloc(1 + size * 3);
     for (let x = 0; x < size; x++) zeile.set(FARBE, 1 + x * 3);
     const daten = Buffer.concat(Array.from({ length: size }, () => zeile));
     const kopf = Buffer.alloc(13);
     kopf.writeUInt32BE(size, 0); kopf.writeUInt32BE(size, 4); kopf[8] = 8; kopf[9] = 2;
     return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', kopf), chunk('IDAT', deflateSync(daten)), chunk('IEND', Buffer.alloc(0))]);
   }
   mkdirSync('public/icons', { recursive: true });
   writeFileSync('public/icons/icon-192.png', png(192));
   writeFileSync('public/icons/icon-512.png', png(512));
   writeFileSync('public/icons/icon-maskable-512.png', png(512));
   console.log('Symbole angelegt');
   ```

6. **`src/index.html`:** Im `<head>` nach `<base href="/" />` drei Zeilen ergänzen:

   ```html
   <link rel="manifest" href="manifest.webmanifest" />
   <meta name="theme-color" content="#2563eb" />
   <link rel="apple-touch-icon" href="icons/icon-192.png" />
   ```

7. **`src/app/app.config.ts`:** Oben `isDevMode` zum Import aus `@angular/core` hinzufügen, `provideServiceWorker` aus `@angular/service-worker` importieren und in die Liste `providers` eintragen:

   ```ts
   // PWA: nur im fertigen Build aktiv. Zwischengespeichert wird nur die App-Hülle, nie Daten.
   provideServiceWorker('ngsw-worker.js', { enabled: !isDevMode(), registrationStrategy: 'registerWhenStable:30000' }),
   ```

8. **`firebase.json`:** Im Abschnitt `hosting` einen Block `headers` ergänzen. Er sorgt dafür, dass das Handy bei jedem Start nachfragt, ob es eine neue Version gibt. Ohne ihn kommen Aktualisierungen nicht an:

   ```json
   "headers": [
     { "source": "/@(ngsw-worker.js|ngsw.json|manifest.webmanifest)", "headers": [{ "key": "Cache-Control", "value": "no-cache" }] },
     { "source": "/manifest.webmanifest", "headers": [{ "key": "Content-Type", "value": "application/manifest+json" }] }
   ]
   ```

9. `npm run build` ausführen. Es darf kein Fehler kommen. Im Ordner `dist/workshop-app/browser` müssen danach `ngsw-worker.js`, `ngsw.json` und `manifest.webmanifest` liegen.

## So testest du es

1. Änderung auf main übernehmen lassen und auf den grünen Haken bei Actions warten.
2. Auf dem Handy die App-Adresse öffnen. **Zweimal** laden, der Service Worker wird erst beim ersten Besuch eingerichtet.
3. Android (Chrome): Menü mit den drei Punkten, dann "Zum Startbildschirm hinzufügen" oder "App installieren".
4. iPhone (Safari): Teilen-Symbol, dann "Zum Home-Bildschirm".
5. Das Symbol antippen. Die App öffnet sich ohne Adresszeile.

## Typische Stolpersteine

- **"Peer dependency"-Fehler bei der Installation:** Die Version des Service-Worker-Pakets passt nicht zu `@angular/core`. Schritt 1 mit der Versionsnummer wiederholen.
- **Nach einer Änderung sieht man noch die alte Version:** Die App einmal komplett schließen und neu öffnen, manchmal zweimal. Das ist normal bei PWAs.
- **Kein Symbol zum Installieren:** Die Seite muss über HTTPS laufen (auf web.app ist das so) und `manifest.webmanifest` samt Symbolen muss erreichbar sein.
- **Daten sind weg ohne Netz:** Gewollt, siehe oben. Bitte keine Daten in `ngsw-config.json` eintragen, auch nicht, wenn die KI es vorschlägt.

## Zum Nachschlagen

Dasselbe Muster läuft in unserem Projekt personio-connect (`admin-app/ngsw-config.json`, `public/manifest.webmanifest`, `src/app/app.config.ts`).
