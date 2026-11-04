import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Api } from '../core/api.service';
import { PageResponse, UserInfo } from '../core/models';
import { errMsg, ROLE_LABEL } from '../core/util';

@Component({
  selector: 'app-admin-users',
  imports: [FormsModule],
  template: `
    <div class="page">
      <div class="page-head"><div class="grow"><h1>Utilisateurs</h1><div class="muted">Comptes du personnel (les patients s'inscrivent depuis l'application mobile)</div></div>
        <select [(ngModel)]="role" (change)="load()" style="width:auto" aria-label="Rôle">
          <option value="">Tous les rôles</option><option value="MEDECIN">Médecins</option><option value="INFIRMIER_RELAIS">Infirmiers relais</option>
          <option value="SUPERVISEUR">Superviseurs</option><option value="ADMIN">Administrateurs</option><option value="PATIENT">Patients</option>
        </select></div>
      @if (error()) { <div class="alert-box err">{{ error() }}</div> }
      @if (info()) { <div class="alert-box ok">{{ info() }}</div> }
      <div class="card">
        <h2>Créer un compte</h2>
        <div class="row">
          <div class="field"><label for="n1">Prénom</label><input id="n1" name="prenom" [(ngModel)]="f.prenom" /></div>
          <div class="field"><label for="n2">Nom</label><input id="n2" name="nom" [(ngModel)]="f.nom" /></div>
          <div class="field"><label for="n3">E-mail</label><input id="n3" name="email" type="email" [(ngModel)]="f.email" /></div>
          <div class="field"><label for="n4">Téléphone</label><input id="n4" name="tel" [(ngModel)]="f.telephone" placeholder="+221 77 000 00 00" /></div>
        </div>
        <div class="row">
          <div class="field"><label for="n5">Rôle</label>
            <select id="n5" name="role" [(ngModel)]="f.role">
              <option value="MEDECIN">Médecin</option><option value="INFIRMIER_RELAIS">Infirmier relais</option>
              <option value="SUPERVISEUR">Superviseur national</option><option value="ADMIN">Administrateur</option>
            </select></div>
          <div class="field"><label for="n6">Structure</label><input id="n6" name="structure" [(ngModel)]="f.structure" placeholder="Hôpital Principal de Dakar" /></div>
          <div class="field"><label for="n7">Spécialité</label><input id="n7" name="spec" [(ngModel)]="f.specialite" /></div>
          <div class="field"><label for="n8">Mot de passe (8 caractères min.)</label><input id="n8" name="pw" type="password" [(ngModel)]="f.password" autocomplete="new-password" /></div>
        </div>
        <button class="btn btn-primary" (click)="create()">Créer le compte</button>
      </div>
      <div class="card">
        <table>
          <thead><tr><th>Nom</th><th>Rôle</th><th>E-mail</th><th>Téléphone</th></tr></thead>
          <tbody>
            @for (u of res()?.contenu ?? []; track u.id) {
              <tr><td><strong>{{ u.prenom }} {{ u.nom }}</strong></td><td><span class="chip blue">{{ rl(u.role) }}</span></td><td>{{ u.email || '—' }}</td><td>{{ u.telephone || '—' }}</td></tr>
            } @empty { <tr><td colspan="4" class="empty">Aucun utilisateur.</td></tr> }
          </tbody>
        </table>
        <div class="pager">
          <button class="btn btn-sm" [disabled]="page() === 0" (click)="go(page() - 1)">← Précédent</button>
          <span class="muted small">Page {{ page() + 1 }} / {{ res()?.totalPages || 1 }}</span>
          <button class="btn btn-sm" [disabled]="page() + 1 >= (res()?.totalPages || 1)" (click)="go(page() + 1)">Suivant →</button>
        </div>
      </div>
    </div>
  `,
})
export class AdminUsersPage {
  private api = inject(Api);
  readonly res = signal<PageResponse<UserInfo> | null>(null);
  readonly page = signal(0);
  readonly error = signal('');
  readonly info = signal('');
  role = '';
  f = { prenom: '', nom: '', email: '', telephone: '', role: 'MEDECIN', structure: '', specialite: '', password: '' };
  readonly rl = (r: string) => ROLE_LABEL[r] ?? r;

  constructor() { void this.load(); }
  go(p: number): void { this.page.set(p); void this.load(); }

  async load(): Promise<void> {
    try {
      this.error.set('');
      this.res.set(await this.api.get<PageResponse<UserInfo>>('/api/admin/utilisateurs', { role: this.role, page: this.page(), size: 15 }));
    } catch (e) { this.error.set(errMsg(e)); }
  }

  async create(): Promise<void> {
    try {
      this.error.set(''); this.info.set('');
      const body: Record<string, string> = { ...this.f };
      if (!body['email'].trim()) delete body['email'];
      if (!body['telephone'].trim()) delete body['telephone'];
      await this.api.post('/api/admin/utilisateurs', body);
      this.f = { prenom: '', nom: '', email: '', telephone: '', role: 'MEDECIN', structure: '', specialite: '', password: '' };
      this.info.set('Compte créé.');
      this.page.set(0);
      await this.load();
    } catch (e) { this.error.set(errMsg(e)); }
  }
}
