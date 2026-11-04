import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Api } from '../core/api.service';
import { PageResponse, PatientResume } from '../core/models';
import { errMsg, fmtDt, TYPE_LABEL } from '../core/util';
import { StatusChip } from '../shared/chip';

@Component({
  selector: 'app-patients',
  imports: [FormsModule, StatusChip],
  template: `
    <div class="page">
      <div class="page-head"><div class="grow"><h1>Patients</h1><div class="muted">{{ res()?.total ?? 0 }} patient(s) dans votre file active</div></div></div>
      <div class="card">
        <div class="row">
          <div class="field"><label for="q">Recherche</label><input id="q" name="q" [(ngModel)]="q" (input)="onSearch()" placeholder="Nom, téléphone, n° de dossier…" /></div>
          <div class="field"><label for="t">Type de diabète</label>
            <select id="t" name="t" [(ngModel)]="type" (change)="reload()">
              <option value="">Tous</option>
              @for (t of types; track t) { <option [value]="t">{{ tl(t) }}</option> }
            </select></div>
        </div>
      </div>
      @if (error()) { <div class="alert-box err">{{ error() }}</div> }
      <div class="card">
        <table>
          <thead><tr><th>Patient</th><th>Dossier</th><th>Âge</th><th>Type</th><th>Dernière glycémie</th><th></th></tr></thead>
          <tbody>
            @for (p of res()?.contenu ?? []; track p.id) {
              <tr class="clickable" (click)="open(p.id)">
                <td><strong>{{ p.nomComplet }}</strong><div class="muted small">{{ p.quartier || p.region || '' }}</div></td>
                <td>{{ p.numeroDossier }}</td><td>{{ p.age ?? '—' }}</td><td>{{ tl(p.typeDiabete) }}</td>
                <td>@if (p.derniereGlycemie !== null) { <strong>{{ p.derniereGlycemie.toFixed(2) }} g/L</strong> <app-status [status]="p.derniereStatut" />
                  <div class="muted small">{{ dt(p.derniereMesureLe) }}</div> } @else { <span class="muted">Aucune mesure</span> }</td>
                <td class="right"><button class="btn btn-sm">Ouvrir</button></td>
              </tr>
            } @empty { <tr><td colspan="6" class="empty">Aucun patient trouvé.</td></tr> }
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
export class PatientsPage {
  private api = inject(Api);
  private router = inject(Router);
  readonly res = signal<PageResponse<PatientResume> | null>(null);
  readonly page = signal(0);
  readonly error = signal('');
  q = '';
  type = '';
  readonly types = ['TYPE_1', 'TYPE_2', 'GESTATIONNEL', 'PREDIABETE', 'AUCUN'];
  readonly dt = fmtDt;
  readonly tl = (t: string | null) => TYPE_LABEL[t ?? 'AUCUN'] ?? t ?? '—';
  private timer: ReturnType<typeof setTimeout> | null = null;

  constructor() { void this.load(); }

  onSearch(): void {
    if (this.timer) clearTimeout(this.timer);
    this.timer = setTimeout(() => this.reload(), 350);
  }
  reload(): void { this.page.set(0); void this.load(); }
  go(p: number): void { this.page.set(p); void this.load(); }
  open(id: number): void { void this.router.navigate(['/patients', id]); }

  private async load(): Promise<void> {
    try {
      this.error.set('');
      this.res.set(await this.api.get<PageResponse<PatientResume>>('/api/medecin/patients', {
        q: this.q.trim(), type: this.type, page: this.page(), size: 15,
      }));
    } catch (e) { this.error.set(errMsg(e)); }
  }
}
