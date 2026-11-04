import { Component, computed, inject, signal } from '@angular/core';
import { Api } from '../core/api.service';
import { Observatoire } from '../core/models';
import { errMsg, TYPE_LABEL } from '../core/util';

@Component({
  selector: 'app-observatory',
  template: `
    <div class="page">
      <div class="page-head"><div class="grow"><h1>Observatoire national du diabète</h1>
        <div class="muted">Statistiques agrégées et anonymes : aucune identité de patient n'est affichée.</div></div></div>
      @if (error()) { <div class="alert-box err">{{ error() }}</div> }
      @if (o(); as o) {
        <div class="grid g4 mb">
          <div class="card kpi"><div class="label">Patients enregistrés</div><div class="value">{{ o.patientsSuivis }}</div></div>
          <div class="card kpi green"><div class="label">Dans la cible (30 j)</div><div class="value">{{ o.tirNational30Jours.pctNormal }}%</div><div class="sub">{{ o.tirNational30Jours.total }} mesures</div></div>
          <div class="card kpi red"><div class="label">Alertes ouvertes</div><div class="value">{{ o.alertesOuvertes }}</div></div>
          <div class="card kpi orange"><div class="label">Mesures critiques (30 j)</div><div class="value">{{ o.tirNational30Jours.critique }}</div></div>
        </div>
        <div class="grid g2">
          <div class="card">
            <h2>Patients par région</h2>
            @for (r of regions(); track r.name) {
              <div class="hbar"><span class="name">{{ r.name }}</span><div class="track"><div class="fill" [style.width.%]="r.pct"></div></div><span class="num">{{ r.n }}</span></div>
            } @empty { <div class="empty">Pas de données.</div> }
          </div>
          <div>
            <div class="card">
              <h2>Répartition par type de diabète</h2>
              @for (t of types(); track t.name) {
                <div class="hbar"><span class="name">{{ t.name }}</span><div class="track"><div class="fill" style="background:var(--green)" [style.width.%]="t.pct"></div></div><span class="num">{{ t.n }}</span></div>
              } @empty { <div class="empty">Pas de données.</div> }
            </div>
            <div class="card">
              <h2>Qualité du contrôle glycémique (30 jours)</h2>
              @if (o.tirNational30Jours.total > 0) {
                <div class="bar">
                  <div style="background:var(--green)" [style.width.%]="p(o.tirNational30Jours.normal, o.tirNational30Jours.total)"></div>
                  <div style="background:var(--orange)" [style.width.%]="p(o.tirNational30Jours.eleve + o.tirNational30Jours.bas, o.tirNational30Jours.total)"></div>
                  <div style="background:var(--red)" [style.width.%]="p(o.tirNational30Jours.critique, o.tirNational30Jours.total)"></div>
                </div>
                <div class="row mt small"><span class="chip green">Cible {{ o.tirNational30Jours.normal }}</span>
                  <span class="chip orange">Élevé/bas {{ o.tirNational30Jours.eleve + o.tirNational30Jours.bas }}</span>
                  <span class="chip red">Critique {{ o.tirNational30Jours.critique }}</span></div>
              } @else { <div class="empty">Aucune mesure.</div> }
            </div>
          </div>
        </div>
      } @else if (!error()) { <div class="empty">Chargement…</div> }
    </div>
  `,
})
export class ObservatoryPage {
  private api = inject(Api);
  readonly o = signal<Observatoire | null>(null);
  readonly error = signal('');

  private rows(rec: Record<string, number> | undefined, label: (k: string) => string) {
    const entries = Object.entries(rec ?? {}).sort((a, b) => b[1] - a[1]);
    const max = Math.max(1, ...entries.map((e) => e[1]));
    return entries.map(([k, n]) => ({ name: label(k), n, pct: (n * 100) / max }));
  }
  readonly regions = computed(() => this.rows(this.o()?.parRegion, (k) => k));
  readonly types = computed(() => this.rows(this.o()?.parTypeDiabete, (k) => TYPE_LABEL[k] ?? k));

  constructor() { void this.load(); }
  p(n: number, total: number): number { return total ? (n * 100) / total : 0; }

  private async load(): Promise<void> {
    try { this.o.set(await this.api.get<Observatoire>('/api/admin/observatoire')); }
    catch (e) { this.error.set(errMsg(e)); }
  }
}
