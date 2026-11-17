import { Component, inject } from '@angular/core';
import { AsyncPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from './auth.service';
import { Note, NotesService } from './notes.service';

@Component({
  selector: 'app-notes',
  standalone: true,
  imports: [FormsModule, AsyncPipe],
  template: `
    <main class="card">
      <header class="row between">
        <h1>Meine Notizen</h1>
        <button class="secondary" (click)="logout()">Abmelden</button>
      </header>

      <form class="row" (ngSubmit)="add()">
        <input name="text" placeholder="Neue Notiz" [(ngModel)]="text" />
        <button type="submit">Hinzufügen</button>
      </form>

      <ul>
        @for (note of notes$ | async; track note.id) {
          <li [class.done]="note.done">
            <input type="checkbox" [checked]="note.done" (change)="toggle(note)" />
            <span>{{ note.text }}</span>
            <button class="link" (click)="remove(note)">Löschen</button>
          </li>
        } @empty {
          <li class="empty">Noch keine Notizen.</li>
        }
      </ul>
    </main>
  `,
})
export class NotesComponent {
  private notesService = inject(NotesService);
  private auth = inject(AuthService);
  private router = inject(Router);

  notes$ = this.notesService.list();
  text = '';

  async add() {
    const value = this.text.trim();
    if (!value) return;
    await this.notesService.add(value);
    this.text = '';
  }

  toggle(note: Note) {
    this.notesService.toggle(note);
  }

  remove(note: Note) {
    this.notesService.remove(note);
  }

  async logout() {
    await this.auth.logout();
    await this.router.navigate(['/login']);
  }
}
