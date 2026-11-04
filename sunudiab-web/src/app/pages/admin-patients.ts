import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Api } from '../core/api.service';
import { PageResponse, PatientResume, UserInfo } from '../core/models';
import { errMsg } from '../core/util';

@Component({
  selector: 'app-admin-patients',
  imports: [FormsModule],
  template: `
    <div class="page">
      <div class="page-head"><div class="grow"><h1>Affectation des patients</h1>
        <div class="muted">Patients inscrits qui n'ont pas encore de médecin référent (identité administrative uniquement, aucune donnée de santé).</div></div></div>
      @if (error()) { <div class="alert-box err">{{ error() }}</div> }
      @if (info()) { <div class="alert-box ok">{{ info() }}</div> }
      <div class="card">
        <table>
          <thead><tr><th>Patient</th><th>Dossier</th><th>Région</th><th>Médecin</th><th>Relais</th><th></th></tr></thead>
          <tbody>
            @for (p of res()?.contenu ?? []; track p.id) {
              <tr>
                <td><strong>{{ p.nomComplet }}</strong><div class="muted small">{{ p.telephone }}</div></td>
                <td>{{ p.numeroDossier }}</td><td>{{ p.region || '—' }}</td>
                <td><select [ngModel]="sel[p.id]?.m ?? ''" (ngModelChange)="pick(p.id, 'm', $event)" aria-label="Médecin">
                  <option value="">—</option>@for (m of medecins(); track m.id) { <option [value]="m.id">{{ m.prenom }} {{ m.nom }}</option> }</select></td>
                <td><select [ngModel]="sel[p.id]?.r ?? ''" (ngModelChange)="pick(p.id, 'r', $event)" aria-label="Relais">
                  <option value="">—</option>@for (r of relais(); track r.id) { <option [value]="r.id">{{ r.prenom }} {{ r.nom }}</option> }</select></td>
                <td class="right"><button class="btn btn-sm btn-primary" (click)="assign(p.id)">Affecter</button></td>
              </tr>
            } @empty { <tr><td colspan="6" class="empty">Tous les patients ont un médecin référent.</td></tr> }
          </tbody>
        </table>
      </div>
    </div>
  `,
})
export class AdminPatientsPage {
  private api = inject(Api);
  readonly res = signal<PageResponse<PatientResume> | null>(null);
  readonly medecins = signal<UserInfo[]>([]);
  readonly relais = signal<UserInfo[]>([]);
  readonly error = signal('');
  readonly info = signal('');
  sel: Record<number, { m?: string; r?: string }> = {};

  constructor() { void this.load(); }

  pick(id: number, k: 'm' | 'r', v: string): void { this.sel[id] = { ...this.sel[id], [k]: v }; }

  async load(): Promise<void> {
    try {
      this.error.set('');
      const [p, m, r] = await Promise.all([
        this.api.get<PageResponse<PatientResume>>('/api/admin/patients-sans-medecin', { size: 50 }),
        this.api.get<PageResponse<UserInfo>>('/api/admin/utilisateurs', { role: 'MEDECIN', size: 100 }),
        this.api.get<PageResponse<UserInfo>>('/api/admin/utilisateurs', { role: 'INFIRMIER_RELAIS', size: 100 }),
      ]);
      this.res.set(p); this.medecins.set(m.contenu); this.relais.set(r.contenu);
    } catch (e) { this.error.set(errMsg(e)); }
  }

  async assign(id: number): Promise<void> {
    const s = this.sel[id];
    if (!s?.m && !s?.r) { this.error.set('Choisissez au moins un médecin ou un infirmier relais.'); return; }
    try {
      this.error.set('');
      await this.api.put(`/api/admin/patients/${id}/assignation`, {
        medecinId: s.m ? Number(s.m) : null, infirmierRelaisId: s.r ? Number(s.r) : null,
      });
      this.info.set('Patient affecté.');
      await this.load();
    } catch (e) { this.error.set(errMsg(e)); }
  }
}
