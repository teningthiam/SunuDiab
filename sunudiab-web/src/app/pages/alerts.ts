import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Api } from '../core/api.service';
import { Alerte, PageResponse } from '../core/models';
import { ALERTE_TYPE_LABEL, errMsg, fmtDt, GRAVITE_CLASS, GRAVITE_LABEL } from '../core/util';

@Component({
  selector: 'app-alerts',
  imports: [FormsModule, RouterLink],
  template: `
    <div class="page">
      <div class="page-head"><div class="grow"><h1>Alertes</h1><div class="muted">Détection automatique : hypoglycémies, hyperglycémies critiques, ruptures de suivi</div></div>
        <select [(ngModel)]="statut" (change)="reload()" style="width:auto" aria-label="Statut">
          <option value="">Toutes</option><option value="OUVERTE">Ouvertes</option><option value="EN_COURS">En cours</option><option value="TRAITEE">Traitées</option>
        </select></div>
      @if (error()) { <div class="alert-box err">{{ error() }}</div> }
      <div class="card">
        @for (a of res()?.contenu ?? []; track a.id) {
          <div class="list-item">
            <div class="row">
              <span class="chip" [class]="gcls(a.gravite)">{{ glabel(a.gravite) }}</span>
              <strong>{{ tlabel(a.type) }}</strong>
              <span class="spacer"></span>
              <span class="chip" [class.green]="a.statut === 'TRAITEE'" [class.orange]="a.statut === 'EN_COURS'" [class.red]="a.statut === 'OUVERTE'">{{ a.statut }}</span>
              <span class="muted small">{{ dt(a.createdAt) }}</span>
            </div>
            <div style="margin:6px 0">{{ a.message }}</div>
            <div class="row">
              <a [routerLink]="['/patients', a.patientId]"><strong>{{ a.patientNom }}</strong></a>
              <span class="muted small">{{ a.numeroDossier }} · ☎ {{ a.telephonePatient }}</span>
              <span class="spacer"></span>
              @if (a.statut === 'OUVERTE') { <button class="btn btn-sm" (click)="set(a.id, 'EN_COURS')">Prendre en charge</button> }
              @if (a.statut !== 'TRAITEE') { <button class="btn btn-sm btn-green" (click)="set(a.id, 'TRAITEE')">Marquer traitée</button> }
            </div>
          </div>
        } @empty { <div class="empty">Aucune alerte.</div> }
        <div class="pager">
          <button class="btn btn-sm" [disabled]="page() === 0" (click)="go(page() - 1)">← Précédent</button>
          <span class="muted small">Page {{ page() + 1 }} / {{ res()?.totalPages || 1 }}</span>
          <button class="btn btn-sm" [disabled]="page() + 1 >= (res()?.totalPages || 1)" (click)="go(page() + 1)">Suivant →</button>
        </div>
      </div>
    </div>
  `,
})
export class AlertsPage {
  private api = inject(Api);
  readonly res = signal<PageResponse<Alerte> | null>(null);
  readonly page = signal(0);
  readonly error = signal('');
  statut = 'OUVERTE';
  readonly dt = fmtDt;
  readonly gcls = (g: string) => GRAVITE_CLASS[g] ?? ''; readonly glabel = (g: string) => GRAVITE_LABEL[g] ?? g;
  readonly tlabel = (t: string) => ALERTE_TYPE_LABEL[t] ?? t;

  constructor() { void this.load(); }
  reload(): void { this.page.set(0); void this.load(); }
  go(p: number): void { this.page.set(p); void this.load(); }

  async set(id: number, statut: string): Promise<void> {
    try { await this.api.put(`/api/medecin/alertes/${id}`, { statut }); await this.load(); } catch (e) { this.error.set(errMsg(e)); }
  }

  private async load(): Promise<void> {
    try {
      this.error.set('');
      this.res.set(await this.api.get<PageResponse<Alerte>>('/api/medecin/alertes', { statut: this.statut, page: this.page(), size: 15 }));
    } catch (e) { this.error.set(errMsg(e)); }
  }
}
