import { Component, inject } from '@angular/core';
import { AsyncPipe } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from './auth.service';

// Startseite für angemeldete Personen. Hier entsteht die eigene App:
// Diese Datei wird im Gespräch mit der KI umgebaut.
@Component({
  selector: 'app-home',
  standalone: true,
  imports: [AsyncPipe],
  template: `
    <main class="card">
      <header class="row between">
        <h1>Meine App</h1>
        <button class="secondary" (click)="logout()">Abmelden</button>
      </header>
      @if (auth.user$ | async; as user) {
        <p>Hallo {{ user.email }}. Die Anmeldung funktioniert.</p>
      }
      <p>Hier entsteht deine App. Beschreibe der KI deine Idee, dann baut sie die erste Version.</p>
    </main>
  `,
})
export class HomeComponent {
  protected auth = inject(AuthService);
  private router = inject(Router);

  async logout() {
    await this.auth.logout();
    await this.router.navigate(['/login']);
  }
}
