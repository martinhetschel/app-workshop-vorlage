import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  addDoc,
  collection,
  collectionData,
  deleteDoc,
  doc,
  query,
  serverTimestamp,
  updateDoc,
  where,
} from '@angular/fire/firestore';
import { Auth, authState } from '@angular/fire/auth';
import { Observable, of, switchMap } from 'rxjs';

export interface Note {
  id?: string;
  uid: string;
  text: string;
  done: boolean;
}

@Injectable({ providedIn: 'root' })
export class NotesService {
  private db = inject(Firestore);
  private auth = inject(Auth);

  // Erst wenn der Nutzer sicher angemeldet ist, wird geladen.
  // Die Abfrage filtert immer auf die eigene uid. Die Firestore-Regeln
  // sind kein Filter: Eine Abfrage ohne diesen Filter würde komplett abgelehnt.
  list(): Observable<Note[]> {
    return authState(this.auth).pipe(
      switchMap((user) => {
        if (!user) return of([] as Note[]);
        const q = query(
          collection(this.db, 'notes'),
          where('uid', '==', user.uid),
        );
        return collectionData(q, { idField: 'id' }) as Observable<Note[]>;
      }),
    );
  }

  add(text: string) {
    const uid = this.auth.currentUser!.uid;
    return addDoc(collection(this.db, 'notes'), {
      uid,
      text,
      done: false,
      createdAt: serverTimestamp(),
    });
  }

  toggle(note: Note) {
    return updateDoc(doc(this.db, 'notes', note.id!), { done: !note.done });
  }

  remove(note: Note) {
    return deleteDoc(doc(this.db, 'notes', note.id!));
  }
}
