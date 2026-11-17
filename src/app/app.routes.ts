import { Routes } from '@angular/router';
import { LoginComponent } from './login.component';
import { NotesComponent } from './notes.component';
import { authGuard } from './auth.guard';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'notes', component: NotesComponent, canActivate: [authGuard] },
  { path: '', pathMatch: 'full', redirectTo: 'notes' },
  { path: '**', redirectTo: 'notes' },
];
