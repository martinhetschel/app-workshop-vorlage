# Bauplan: Claude liest die Daten deiner App (MCP)

**Schwierigkeit: schwer. Nur für Fortgeschrittene und nicht für den Workshop gedacht.** Dieser Bauplan ist bisher nur übersetzt, nicht im echten Betrieb getestet.

## Was ist das?

Normalerweise sieht Claude nur, was du in den Chat schreibst. MCP ist eine Art Steckdose, an der eine KI Werkzeuge anschließen kann. Deine App bekommt eine kleine, abgesicherte Tür, durch die Claude **nachschauen** darf, zum Beispiel: "Welche Aufgaben sind noch offen?" oder "Was habe ich diese Woche eingetragen?". Claude kann dabei nur lesen. Es kann nichts ändern oder löschen.

Das ist praktisch, weil du keine Auswertungsseite mit Diagrammen und Filtern bauen musst. Du fragst einfach.

## Was du dafür brauchst

- **Den Blaze-Tarif von Firebase.** Der kostenlose Spark-Tarif erlaubt keine Cloud Functions. Blaze ist "bezahlen, was man verbraucht". Für eine kleine App bleibt man meist unter dem kostenlosen Kontingent, aber du hinterlegst eine Zahlungsmethode. **Richte unbedingt ein Budget mit Warnung ein** (Google Cloud, Abrechnung, Budgets und Benachrichtigungen).
- Ein Programm, das MCP versteht und Zugangsdaten mitschicken kann. Claude Code auf dem eigenen Computer kann das (`claude mcp add`). Ob Claude Code im Web oder die Claude-Webseite einen eigenen Server mit Passwort anbinden kann, ist nicht geprüft.
- Etwa 30 Minuten und die Bereitschaft, Fehlermeldungen zu kopieren.

## So sagst du es der KI

> Baue den MCP-Zugang nach bauplaene/mcp.md ein. Erkläre mir vorher in einfachen Worten, was sich ändert. Du musst mich vorher fragen, bevor du den Ordner .github änderst.

Die KI wird dich bitten, ein paar Schritte in der Google Cloud Shell selbst auszuführen (Schritte 1 bis 3). Das kann sie nicht für dich tun.

## Das Passwort

Der Zugang wird durch ein langes Passwort geschützt (das "Token"). Wer es hat, kann deine Daten lesen. Deshalb:

- Es liegt nur im Secret Manager von Google, nie im Code, nie in GitHub, nie im Chat mit der KI.
- Du holst es dir nur, um es in deinem MCP-Programm einzutragen, und zeigst es niemandem.
- Wenn es doch irgendwo gelandet ist: ein neues anlegen (Schritt 3 wiederholen, `gcloud secrets versions add`) und das alte unbrauchbar machen.

## Was die KI tut (Checkliste)

1. **In der Cloud Shell (du):** Die nötigen Dienste einschalten. Das geht erst, wenn der Blaze-Tarif aktiv ist:

   ```bash
   gcloud services enable cloudfunctions.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com eventarc.googleapis.com secretmanager.googleapis.com
   ```

2. **In der Cloud Shell (du):** Dem Dienstkonto des automatischen Deploys die zusätzlichen Rechte geben. `PROJEKT` ist deine Projekt-ID:

   ```bash
   PROJEKT=DEINE-PROJEKT-ID
   for ROLLE in roles/iam.serviceAccountUser roles/secretmanager.admin; do
     gcloud projects add-iam-policy-binding "$PROJEKT" \
       --member="serviceAccount:github-deployer@$PROJEKT.iam.gserviceaccount.com" \
       --role="$ROLLE" --condition=None >/dev/null
   done
   ```

3. **In der Cloud Shell (du):** Das Passwort erzeugen und sicher ablegen. Es wird zufällig erzeugt und nirgends angezeigt:

   ```bash
   openssl rand -base64 32 | tr -d '\n' | gcloud secrets create MCP_TOKEN --data-file=- --replication-policy=automatic
   ```

   Zum Eintragen in dein MCP-Programm später anzeigen: `gcloud secrets versions access latest --secret=MCP_TOKEN` (nur im eigenen Terminal, nie in den Chat kopieren).

4. **Deine Nutzer-Kennung finden (du):** In der Firebase-Konsole, Authentication, Nutzer, die Spalte "Nutzer-UID" deines Kontos kopieren. Sie ist kein Geheimnis. Die KI trägt sie in `functions/src/index.ts` ein (`OWNER_UID`). Der Zugang liest nur die Daten dieser einen Person.

5. **Ordner `functions/` anlegen.** Drei Dateien:

   `functions/package.json`:

   ```json
   {
     "name": "functions",
     "private": true,
     "main": "lib/index.js",
     "engines": { "node": "22" },
     "scripts": { "build": "tsc" },
     "dependencies": {
       "firebase-admin": "^13.0.0",
       "firebase-functions": "^6.0.0"
     },
     "devDependencies": {
       "@types/node": "^22.0.0",
       "typescript": "~5.9.0"
     }
   }
   ```

   `functions/tsconfig.json`:

   ```json
   {
     "compilerOptions": {
       "module": "commonjs",
       "target": "es2022",
       "outDir": "lib",
       "rootDir": "src",
       "strict": true,
       "esModuleInterop": true,
       "skipLibCheck": true
     },
     "include": ["src"]
   }
   ```

   `functions/src/index.ts`:

   ```ts
   import { createHash, timingSafeEqual } from 'node:crypto';
   import { initializeApp } from 'firebase-admin/app';
   import { getFirestore } from 'firebase-admin/firestore';
   import { defineSecret } from 'firebase-functions/params';
   import { onRequest } from 'firebase-functions/v2/https';

   initializeApp();

   // Das Passwort für den Zugang. Es liegt im Secret Manager, nie im Code.
   const MCP_TOKEN = defineSecret('MCP_TOKEN');

   // Deine Nutzer-Kennung (UID). Du findest sie in der Firebase-Konsole unter Authentication.
   // Sie ist kein Geheimnis. Ein Zugang gilt immer nur für die Daten dieser einen Person.
   const OWNER_UID = 'HIER-DEINE-UID';

   const NAME_OK = /^[A-Za-z0-9_-]{1,60}$/;

   const TOOLS = [
     {
       name: 'sammlungen_auflisten',
       description: 'Listet die Sammlungen (Tabellen) deiner App auf.',
       inputSchema: { type: 'object', properties: {}, additionalProperties: false },
     },
     {
       name: 'sammlung_lesen',
       description: 'Liest die Einträge einer Sammlung (nur lesen, höchstens 50).',
       inputSchema: {
         type: 'object',
         properties: {
           sammlung: { type: 'string', description: 'Name der Sammlung, zum Beispiel aufgaben' },
           anzahl: { type: 'number', description: 'Wie viele Einträge (1 bis 50)' },
         },
         required: ['sammlung'],
         additionalProperties: false,
       },
     },
   ];

   // Zeitstempel als lesbaren Text ausgeben
   const alsText = (wert: unknown) =>
     JSON.stringify(wert, (_schluessel, v) => (v && typeof v.toDate === 'function' ? v.toDate().toISOString() : v), 2);

   async function werkzeugAufrufen(name: string, args: Record<string, unknown>): Promise<string> {
     const db = getFirestore();
     const basis = db.doc(`users/${OWNER_UID}`);
     if (name === 'sammlungen_auflisten') {
       const sammlungen = await basis.listCollections();
       return alsText(sammlungen.map((s) => s.id));
     }
     if (name === 'sammlung_lesen') {
       const sammlung = String(args.sammlung ?? '');
       if (!NAME_OK.test(sammlung)) throw new Error('Ungültiger Name der Sammlung.');
       const anzahl = Math.min(Math.max(Number(args.anzahl) || 20, 1), 50);
       const treffer = await basis.collection(sammlung).limit(anzahl).get();
       return alsText(treffer.docs.map((d) => ({ id: d.id, ...d.data() })));
     }
     throw new Error(`Unbekanntes Werkzeug: ${name}`);
   }

   // Beide Seiten werden gehasht, damit der Vergleich immer gleich lang dauert und nichts verrät.
   function tokenStimmt(header: string | undefined): boolean {
     const angegeben = /^Bearer\s+(\S+)\s*$/i.exec(header ?? '')?.[1] ?? '';
     const a = createHash('sha256').update(angegeben).digest();
     const b = createHash('sha256').update(MCP_TOKEN.value()).digest();
     return timingSafeEqual(a, b);
   }

   export const mcp = onRequest(
     { region: 'europe-west3', secrets: [MCP_TOKEN], cors: false, maxInstances: 2, memory: '256MiB' },
     async (req, res) => {
       // Falsches Passwort und fehlendes Passwort sehen von außen gleich aus
       if (req.method !== 'POST' || !tokenStimmt(req.get('authorization'))) {
         res.status(401).json({ error: 'Nicht erlaubt.' });
         return;
       }
       const nachricht = req.body ?? {};
       const antwort = (result: unknown) => res.json({ jsonrpc: '2.0', id: nachricht.id, result });
       const fehler = (code: number, message: string) => res.json({ jsonrpc: '2.0', id: nachricht.id ?? null, error: { code, message } });

       switch (nachricht.method) {
         case 'initialize':
           antwort({
             protocolVersion: '2025-06-18',
             capabilities: { tools: {} },
             serverInfo: { name: 'meine-app', version: '1.0.0' },
             instructions: 'Lesender Zugang zu den Daten meiner App. Es wird nichts verändert.',
           });
           return;
         case 'ping':
           antwort({});
           return;
         case 'tools/list':
           antwort({ tools: TOOLS });
           return;
         case 'tools/call':
           try {
             const text = await werkzeugAufrufen(String(nachricht.params?.name), nachricht.params?.arguments ?? {});
             antwort({ content: [{ type: 'text', text }] });
           } catch (e) {
             // Die Meldung nennt nur den Grund, nie Daten oder das Passwort
             antwort({ content: [{ type: 'text', text: e instanceof Error ? e.message : 'Fehler' }], isError: true });
           }
           return;
         default:
           // Hinweise ohne Antwort (zum Beispiel "initialized") einfach bestätigen
           if (nachricht.id === undefined) {
             res.status(202).end();
             return;
           }
           fehler(-32601, 'Methode nicht unterstützt.');
       }
     },
   );
   ```

   Danach im Ordner `functions/` einmal `npm install` ausführen (das legt `package-lock.json` an, die Datei muss mit ins Repo) und `npm run build` (es darf kein Fehler kommen). In die Datei `.gitignore` kommen zusätzlich `functions/node_modules/` und `functions/lib/`.

6. **`firebase.json`:** Einen Abschnitt `functions` ergänzen. Er sagt dem Deploy, wo der Code liegt und dass er vorher gebaut wird:

   ```json
   "functions": [
     {
       "source": "functions",
       "codebase": "default",
       "predeploy": ["npm --prefix functions ci", "npm --prefix functions run build"]
     }
   ]
   ```

7. **`.github/workflows/deploy.yml`** (hier vorher fragen!): In der letzten Zeile `--only=hosting,firestore:rules` durch `--only=hosting,firestore:rules,functions` ersetzen.

8. Auf main übernehmen lassen. Der erste Deploy mit Cloud Functions dauert mehrere Minuten. Die Adresse der Function steht im Protokoll bei Actions (Zeile "Function URL (mcp(europe-west3))").

## Verbinden und ausprobieren

Im eigenen Terminal, mit Claude Code auf dem eigenen Computer (die Adresse stammt aus dem Deploy-Protokoll, das Passwort aus Schritt 3):

```bash
claude mcp add --transport http meine-app DIE-ADRESSE --header "Authorization: Bearer DAS-PASSWORT"
```

Danach in Claude Code fragen: "Welche Sammlungen hat meine App?" und "Zeig mir die letzten Einträge in aufgaben."

## Sicherheit

- Nur lesen. Das Programm hat kein Werkzeug, das etwas ändert oder löscht. Neue Werkzeuge nur lesend einbauen, es sei denn, du weißt genau, was du tust.
- Das Passwort liegt nur im Secret Manager und wird nie geloggt.
- Ein falsches oder fehlendes Passwort liefert immer dieselbe Antwort (401).
- Der Zugang liest nur den privaten Bereich einer einzigen Person (`users/<uid>`), nie andere Bereiche.
- Wenn du Kundendaten oder andere personenbezogene Daten speicherst: überleg, ob wirklich eine KI darauf zugreifen soll. Siehe [vor-dem-teilen.md](vor-dem-teilen.md).
- Die Meldung bei Fehlern enthält nur den Grund, keine Daten.

## Typische Stolpersteine

- **Deploy meldet "billing account required" oder "must be on the Blaze plan":** Tarif umstellen (Firebase-Konsole, links unten "Upgrade").
- **Deploy meldet fehlende Rechte (permission denied):** Die Fehlermeldung nennt die Rolle. Der Cloud-Shell-Befehl aus Schritt 2 mit der genannten Rolle wiederholen.
- **Antwort 401:** Passwort falsch oder der Kopf `Authorization` fehlt.
- **Leere Liste bei `sammlungen_auflisten`:** In `OWNER_UID` steht noch `HIER-DEINE-UID` oder eine falsche Kennung, oder du hast noch keine Daten gespeichert.

## Zum Nachschlagen

Das ausführlichere Vorbild ist personio-connect: `functions/src/devAccessMcp.ts` (der Server), `devAccessAuth.ts` (Tokens als Hash, widerrufbar, mit Ablaufdatum) und `devAccessTools.ts` (die Werkzeuge). Dort gibt es auch ein Protokoll aller Aufrufe.
