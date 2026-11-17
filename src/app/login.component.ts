import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from './auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule],
  template: `
    <main class="card">
      <h1>Anmelden</h1>
      <input type="email" placeholder="E-Mail" [(ngModel)]="email" />
      <input type="password" placeholder="Passwort (mind. 6 Zeichen)" [(ngModel)]="password" />
      <div class="row">
        <button (click)="login()">Anmelden</button>
        <button class="secondary" (click)="register()">Neu registrieren</button>
      </div>
      @if (error) {
        <p class="error">{{ error }}</p>
      }
    </main>
  `,
})
export class LoginComponent {
  private auth = inject(AuthService);
  private router = inject(Router);

  email = '';
  password = '';
  error = '';

  async login() {
    await this.run(() => this.auth.login(this.email, this.password));
  }

  async register() {
    await this.run(() => this.auth.register(this.email, this.password));
  }

  private async run(action: () => Promise<unknown>) {
    this.error = '';
    try {
      await action();
      await this.router.navigate(['/home']);
    } catch (e: any) {
      this.error = 'Das hat nicht geklappt: ' + (e?.code ?? e?.message ?? 'unbekannter Fehler');
    }
  }
}
