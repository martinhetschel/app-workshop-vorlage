# Bauplan: Nur mein Team

## Was ist das?

Normalerweise kann sich jede Person mit einer E-Mail-Adresse registrieren und die App benutzen. Mit diesem Bauplan wird deine App zur **Mitgliederliste**: Hinein kommt nur, wer auf deiner Liste steht und seine E-Mail-Adresse bestätigt hat. Alle anderen können sich zwar registrieren, sehen aber nur eine Seite mit dem Hinweis, dass sie noch nicht freigeschaltet sind.

Und so funktioniert es, ohne Fachwörter:

- **Die Liste** führst du selbst, im Browser, in der Firebase-Konsole. Sie heißt `erlaubt` und enthält pro Person einen Eintrag: die E-Mail-Adresse. Die App kann diese Liste **nicht** ändern. Das ist Absicht: Sonst könnte sich jeder selbst eintragen.
- **Die Bestätigung** schützt vor Betrügern. Ohne sie könnte jemand deine Adresse eingeben, ohne dir zu gehören, und bekäme deinen Zugang. Darum schickt die App nach dem Registrieren eine Mail mit einem Bestätigungslink.
- **Die Sperre** sitzt in den Firestore-Regeln, also bei Google und nicht in der App. Selbst wenn jemand die App-Seiten umgeht, bekommt er keine Daten.

## Wichtig vorab: nicht aussperren

Wenn die Regeln live gehen, kommt nur noch hinein, wer in der Liste steht. Deshalb gilt die Reihenfolge: **zuerst deine eigene Adresse in die Liste, dann erst auf main übernehmen.** Hast du dich schon vor diesem Bauplan registriert, ist deine Adresse noch nicht bestätigt. Das ist kein Problem: Die Seite „Zugang“ hat dafür einen Knopf „Mail noch einmal senden“.

## So sagst du es der KI

> Baue den Bauplan bauplaene/team.md in meine App ein. Erkläre mir vorher in einfachen Worten, was sich ändert, und warte auf mein Okay, bevor du die Datei firestore.rules änderst.

## Was die KI tut (Checkliste)

Dieser Bauplan ändert `firestore.rules`, `src/app/auth.service.ts` und `src/app/app.routes.ts`. Er legt `src/app/team.service.ts`, `src/app/team.guard.ts` und `src/app/zugang.component.ts` neu an. Es wird **eine** Änderung auf einmal gemacht, und erst nach deinem Okay auf main übernommen.

### 1. `firestore.rules` ersetzen

Die Regeln bekommen eine Prüfung „steht in der Liste und ist bestätigt“. Der eigene Bereich `users/<uid>` gilt dann nur noch für Mitglieder. Die Liste `erlaubt` darf nur der Mensch lesen, dessen Adresse darin steht, und **niemand** darf sie aus der App heraus schreiben:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Wahr, wenn die angemeldete Person ihre E-Mail bestätigt hat UND in "erlaubt" steht.
    function istErlaubt() {
      return request.auth != null
        && request.auth.token.email_verified == true
        && exists(/databases/$(database)/documents/erlaubt/$(request.auth.token.email.lower()));
    }

    // Die Mitgliederliste: Dokument-ID = E-Mail-Adresse, klein geschrieben.
    // Lesen darf nur der eigene Eintrag (damit die App "nicht freigeschaltet" anzeigen kann).
    // Schreiben darf niemand aus der App: die Liste pflegt nur der Besitzer in der Firebase-Konsole.
    match /erlaubt/{email} {
      allow get: if request.auth != null && request.auth.token.email.lower() == email;
    }

    // Eigener Bereich: nur für Mitglieder, und nur der eigene.
    match /users/{uid}/{document=**} {
      allow read, write: if istErlaubt() && request.auth.uid == uid;
    }
    // Alles andere bleibt gesperrt
  }
}
```

### 2. `src/app/auth.service.ts` ergänzen

Nach dem Registrieren wird die Bestätigungs-Mail verschickt. Zwei neue Funktionen schicken die Mail erneut und laden den Zustand neu, wenn die Person auf den Link geklickt hat. Der Import `sendEmailVerification` kommt zu den bestehenden Importen aus `@angular/fire/auth` dazu. So sieht die Datei danach aus:

```ts
import { Injectable, inject } from '@angular/core';
import {
  Auth,
  authState,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  sendEmailVerification,
  signOut,
} from '@angular/fire/auth';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private auth = inject(Auth);

  // Liefert den angemeldeten Nutzer oder null
  user$ = authState(this.auth);

  // Nach dem Registrieren geht automatisch eine Bestätigungs-Mail raus
  async register(email: string, password: string) {
    const cred = await createUserWithEmailAndPassword(this.auth, email, password);
    await sendEmailVerification(cred.user);
    return cred;
  }

  async sendeBestaetigung() {
    const user = this.auth.currentUser;
    if (user) await sendEmailVerification(user);
  }

  // Nach dem Klick auf den Link in der Mail: neu laden, damit die App es merkt
  async neuPruefen() {
    const user = this.auth.currentUser;
    if (!user) return;
    await user.reload();
    await user.getIdToken(true);
  }

  login(email: string, password: string) {
    return signInWithEmailAndPassword(this.auth, email, password);
  }

  logout() {
    return signOut(this.auth);
  }
}
```

### 3. Neue Datei `src/app/team.service.ts`

Sie fragt, ob die Person zum Team gehört. Die Antwort hat vier mögliche Werte: `ok`, `unbestaetigt`, `nicht-freigegeben`, `abgemeldet`.

```ts
import { Injectable, inject } from '@angular/core';
import { Auth } from '@angular/fire/auth';
import { Firestore, doc, getDoc } from '@angular/fire/firestore';

export type ZugangStatus = 'ok' | 'unbestaetigt' | 'nicht-freigegeben' | 'abgemeldet';

// Prüft, ob die angemeldete Person zum Team gehört. Die Liste "erlaubt" pflegt nur
// der Besitzer der App in der Firebase-Konsole. Die App darf sie nie ändern.
// Die eigentliche Sperre sitzt in den Firestore-Regeln, diese Prüfung hier ist nur
// dafür da, der Person freundlich zu sagen, was fehlt.
@Injectable({ providedIn: 'root' })
export class TeamService {
  private db = inject(Firestore);
  private auth = inject(Auth);

  async status(): Promise<ZugangStatus> {
    const user = this.auth.currentUser;
    if (!user || !user.email) return 'abgemeldet';
    if (!user.emailVerified) return 'unbestaetigt';
    try {
      const eintrag = await getDoc(doc(this.db, 'erlaubt', user.email.toLowerCase()));
      return eintrag.exists() ? 'ok' : 'nicht-freigegeben';
    } catch {
      return 'nicht-freigegeben';
    }
  }
}
```

### 4. Neue Datei `src/app/team.guard.ts`

Der Türsteher für die Startseite. Er ersetzt `authGuard` (die Datei `auth.guard.ts` kann bleiben, wird dann aber nicht mehr benutzt):

```ts
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { AuthService } from './auth.service';
import { TeamService } from './team.service';

// Ersetzt authGuard: Wer nicht angemeldet ist, geht zur Anmeldung.
// Wer angemeldet, aber nicht im Team (oder noch nicht bestätigt) ist, sieht die Seite "Zugang".
export const teamGuard: CanActivateFn = async () => {
  const router = inject(Router);
  const auth = inject(AuthService);
  const team = inject(TeamService);
  const user = await firstValueFrom(auth.user$);
  if (!user) return router.createUrlTree(['/login']);
  return (await team.status()) === 'ok' ? true : router.createUrlTree(['/zugang']);
};
```

### 5. Neue Seite `src/app/zugang.component.ts`

Hier landet, wer angemeldet, aber noch nicht drin ist. Sie erklärt freundlich, was fehlt, und hat die nötigen Knöpfe:

```ts
import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from './auth.service';
import { TeamService, ZugangStatus } from './team.service';

@Component({
  selector: 'app-zugang',
  standalone: true,
  template: `
    <main class="card">
      <h1>Zugang</h1>
      @switch (status) {
        @case ('laedt') {
          <p>Einen Moment …</p>
        }
        @case ('unbestaetigt') {
          <p>
            Bitte bestätige deine E-Mail-Adresse. Wir haben dir eine Mail geschickt (schau auch im
            Spam-Ordner). Klicke auf den Link darin und danach hier auf den Knopf.
          </p>
          <div class="row">
            <button (click)="pruefen()">Ich habe bestätigt</button>
            <button class="secondary" (click)="nochmalSenden()">Mail noch einmal senden</button>
          </div>
        }
        @case ('nicht-freigegeben') {
          <p>
            Deine Adresse ist noch nicht freigeschaltet. Gib sie an die Person weiter, die diese
            App verwaltet. Danach kannst du es erneut versuchen.
          </p>
          <button (click)="pruefen()">Erneut prüfen</button>
        }
      }
      @if (info) {
        <p>{{ info }}</p>
      }
      <button class="secondary" (click)="logout()">Abmelden</button>
    </main>
  `,
})
export class ZugangComponent implements OnInit {
  private auth = inject(AuthService);
  private team = inject(TeamService);
  private router = inject(Router);

  status: ZugangStatus | 'laedt' = 'laedt';
  info = '';

  ngOnInit() {
    void this.pruefen();
  }

  async pruefen() {
    this.info = '';
    try {
      await this.auth.neuPruefen();
      const neu = await this.team.status();
      if (neu === 'ok') {
        await this.router.navigate(['/home']);
        return;
      }
      if (neu === 'abgemeldet') {
        await this.router.navigate(['/login']);
        return;
      }
      this.status = neu;
    } catch (e: any) {
      this.info = 'Das hat nicht geklappt: ' + (e?.code ?? e?.message ?? 'unbekannter Fehler');
    }
  }

  async nochmalSenden() {
    try {
      await this.auth.sendeBestaetigung();
      this.info = 'Die Mail ist unterwegs.';
    } catch (e: any) {
      this.info = 'Das hat nicht geklappt: ' + (e?.code ?? e?.message ?? 'unbekannter Fehler');
    }
  }

  async logout() {
    await this.auth.logout();
    await this.router.navigate(['/login']);
  }
}
```

### 6. `src/app/app.routes.ts` anpassen

Die Startseite wird mit `teamGuard` geschützt, die neue Seite bekommt eine Adresse:

```ts
import { Routes } from '@angular/router';
import { LoginComponent } from './login.component';
import { HomeComponent } from './home.component';
import { teamGuard } from './team.guard';
import { ZugangComponent } from './zugang.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'zugang', component: ZugangComponent },
  { path: 'home', component: HomeComponent, canActivate: [teamGuard] },
  { path: '', pathMatch: 'full', redirectTo: 'home' },
  { path: '**', redirectTo: 'home' },
];
```

### 7. Bauen und prüfen

`npm ci` und danach `npm run build` müssen ohne Fehler durchlaufen.

## Was du selbst tust (im Browser, in der Firebase-Konsole)

Das kann die KI nicht für dich. **Vor dem Übernehmen auf main:**

1. Firebase-Konsole öffnen, dein Projekt wählen, links **Build**, dann **Firestore Database**, Reiter **Daten**.
2. **Sammlung starten**, als Sammlungs-ID `erlaubt` eintragen.
3. Als **Dokument-ID** deine E-Mail-Adresse eintragen, **komplett klein geschrieben** (zum Beispiel `anna@beispiel.de`). Ein Feld ist nicht nötig, ein Feld `name` mit dem Namen ist aber hilfreich. Speichern.
4. Erst jetzt der KI sagen, dass sie auf main übernehmen soll. Warte ein bis zwei Minuten (Actions, grüner Haken).
5. App öffnen, **Seite neu laden**, anmelden. Du landest auf der Seite „Zugang“, drückst „Mail noch einmal senden“, klickst den Link in der Mail (Spam-Ordner prüfen) und dann „Ich habe bestätigt“. Danach bist du drin.

**Eine Person dazunehmen:** In `erlaubt` ein neues Dokument mit ihrer Adresse (klein geschrieben) anlegen. Die Person muss sich in der App registrieren und die Mail bestätigen. **Eine Person entfernen:** ihr Dokument in `erlaubt` löschen. Sie verliert sofort den Zugang zu den Daten. Ihr Konto selbst bleibt bestehen (zu sehen unter **Build**, **Authentication**, dort kannst du es auch löschen).

## Und die gemeinsamen Daten?

Dieser Bauplan regelt nur, **wer hinein darf**. Jede Person sieht weiterhin nur ihre eigenen Daten unter `users/<uid>`. Wenn das Team eine gemeinsame Liste sehen und bearbeiten soll (zum Beispiel gemeinsame Aufgaben), ist das ein **zweiter, eigener Schritt**. Dafür kommt eine weitere Regel dazu, zum Beispiel:

```
    match /team/{document=**} {
      allow read, write: if istErlaubt();
    }
```

Die KI erklärt dir vorher, was das bedeutet: Alle Mitglieder können dann alles in dieser Sammlung lesen, ändern und löschen. Wer das nicht möchte, braucht feinere Regeln (zum Beispiel „nur Einträge, die ich selbst angelegt habe“). Frag die KI danach, sie schlägt dir die kleinste Lösung vor.

## Sicherheit: das solltest du wissen

- **Die Liste gehört dir.** Die App darf `erlaubt` nie ändern, und die KI soll dafür keine Funktion „Mitglied hinzufügen“ in der App bauen, auch wenn es bequem wäre: Wer die Liste in der App ändern kann, kann sich im schlimmsten Fall selbst hineinschreiben.
- **Adressen klein schreiben.** Die Regeln vergleichen die Adresse in Kleinbuchstaben. Steht in der Liste `Anna@Beispiel.de`, findet sie niemand.
- **Kosten:** Jede Prüfung in den Regeln liest die Liste einmal. Das ist bei einer kleinen Gruppe vernachlässigbar, steht aber in der Nutzung unter Firestore.
- **Wer die Mail nicht bekommt,** schaut im Spam-Ordner nach. Die Mail kommt von einer Firebase-Adresse (noreply@…firebaseapp.com).
- **Passwort vergessen** gibt es in dieser Vorlage nicht. Wer es braucht, bittet die KI um einen Link „Passwort vergessen“ (das ist eine eigene, kleine Änderung).
- **Mehr Sicherheit** (zum Beispiel Anmeldung nur mit Google-Konto, oder Rollen wie „Chef“ und „Mitarbeiter“) ist möglich und ein eigener Bauplan wert. Sag der KI, was du brauchst.

## Ehrlich gesagt

Der Code ist in einer Testkopie der Vorlage gebaut worden (der Build läuft durch). Die **Firestore-Regeln** und der **Ablauf mit der Bestätigungs-Mail** sind noch nicht in einem echten Firebase-Projekt ausprobiert. Probiere sie deshalb zuerst mit einem Test-Projekt oder mit einer zweiten Adresse aus, die nicht in der Liste steht: Sie darf nach der Bestätigung nur die Seite „Zugang“ sehen und keine Daten bekommen.
