import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  addDoc,
  collection,
  collectionData,
  deleteDoc,
  doc,
  serverTimestamp,
  updateDoc,
} from '@angular/fire/firestore';
import { Auth, authState } from '@angular/fire/auth';
import { Observable, of, switchMap } from 'rxjs';

// Speichert und lädt Daten im privaten Bereich der angemeldeten Person.
// Pfad: users/<uid>/<sammlung>. Die Firestore-Regeln erlauben genau diesen Bereich,
// deshalb braucht eine neue Sammlung keine neuen Regeln. Eine Sammlung entsteht
// automatisch, sobald der erste Eintrag gespeichert wird.
// Beispiel: this.data.add('aufgaben', { titel: 'Milch kaufen', erledigt: false })
@Injectable({ providedIn: 'root' })
export class DataService {
  private db = inject(Firestore);
  private auth = inject(Auth);

  private path(sammlung: string): string {
    const uid = this.auth.currentUser?.uid;
    if (!uid) throw new Error('Nicht angemeldet');
    return `users/${uid}/${sammlung}`;
  }

  // Lädt erst, wenn die Person sicher angemeldet ist
  list<T>(sammlung: string): Observable<(T & { id: string })[]> {
    return authState(this.auth).pipe(
      switchMap((user) => {
        if (!user) return of([] as (T & { id: string })[]);
        const ref = collection(this.db, `users/${user.uid}/${sammlung}`);
        return collectionData(ref, { idField: 'id' }) as Observable<(T & { id: string })[]>;
      }),
    );
  }

  add(sammlung: string, daten: Record<string, unknown>) {
    return addDoc(collection(this.db, this.path(sammlung)), {
      ...daten,
      erstelltAm: serverTimestamp(),
    });
  }

  update(sammlung: string, id: string, daten: Record<string, unknown>) {
    return updateDoc(doc(this.db, this.path(sammlung), id), daten);
  }

  remove(sammlung: string, id: string) {
    return deleteDoc(doc(this.db, this.path(sammlung), id));
  }
}
