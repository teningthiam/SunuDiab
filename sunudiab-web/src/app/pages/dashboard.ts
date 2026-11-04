import { Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Api } from '../core/api.service';
import { Alerte, Dashboard, PageResponse, Rdv } from '../core/models';
import { ALERTE_TYPE_LABEL, errMsg, fmtDt, fmtTime, GRAVITE_CLASS, GRAVITE_LABEL } from '../core/util';

@Component({
  selector: 'app-dashboard',
  imports: [RouterLink],
  template: `
    <div class="page">
      <div class="page-head"><div class="grow"><h1>Tableau de bord</h1><div class="muted">Vue d'ensemble de votre file active</div></div></div>
      @if (error()) { <div class="alert-box err">{{ error() }}</div> }
      @if (d(); as d) {
        <div class="grid g4 mb">
          <div class="card kpi"><div class="label">Patients suivis</div><div class="value">{{ d.patientsSuivis }}</div><div class="sub">file active</div></div>
          <div class="card kpi red"><div class="label">Alertes ouvertes</div><div class="value">{{ d.alertesOuvertes }}</div><div class="sub">dont {{ d.alertesUrgentes }} urgence(s) vitale(s)</div></div>
          <div class="card kpi"><div class="label">Consultations du jour</div><div class="value">{{ d.consultationsDuJour }}</div><div class="sub">{{ d.consultationsPresentiel }} présentiel · {{ d.consultationsTele }} téléconsultation</div></div>
          <div class="card kpi orange"><div class="label">Risque élevé à confirmer</div><div class="value">{{ d.risqueAConfirmer }}</div><div class="sub">sans diagnostic posé</div></div>
        </div>
        <div class="grid g-main">
          <div>
            <div class="card">
              <h2>Temps dans la cible (30 jours)</h2>
              @if (d.tir30Jours.total === 0) { <div class="empty">Aucune mesure sur la période.</div> } @else {
                <div class="bar">
                  <div style="background:var(--green)" [style.width.%]="pct(d.tir30Jours.normal, d.tir30Jours.total)"></div>
                  <div style="background:var(--orange)" [style.width.%]="pct(d.tir30Jours.eleve + d.tir30Jours.bas, d.tir30Jours.total)"></div>
                  <div style="background:var(--red)" [style.width.%]="pct(d.tir30Jours.critique, d.tir30Jours.total)"></div>
                </div>
                <div class="row mt small">
                  <span class="chip green">Dans la cible {{ d.tir30Jours.pctNormal }} %</span>
                  <span class="chip orange">Élevé / bas {{ d.tir30Jours.eleve + d.tir30Jours.bas }}</span>
                  <span class="chip red">Critique {{ d.tir30Jours.critique }}</span>
                  <span class="muted">sur {{ d.tir30Jours.total }} mesures</span>
                </div>
              }
            </div>
            <div class="card">
              <div class="row"><h2 style="margin:0">Alertes prioritaires</h2><span class="spacer"></span><a routerLink="/alertes">Tout voir →</a></div>
              @for (a of alertes(); track a.id) {
                <div class="list-item">
                  <div class="row">
                    <span class="chip" [class]="gcls(a.gravite)">{{ glabel(a.gravite) }}</span>
                    <strong>{{ a.patientNom }}</strong><span class="muted small">{{ a.numeroDossier }}</span>
                    <span class="spacer"></span><span class="muted small">{{ dt(a.createdAt) }}</span>
                  </div>
                  <div style="margin:6px 0">{{ tlabel(a.type) }} — {{ a.message }}</div>
                  <a [routerLink]="['/patients', a.patientId]" class="btn btn-sm">Voir le dossier</a>
                </div>
              } @empty { <div class="empty">Aucune alerte ouverte 🎉</div> }
            </div>
          </div>
          <div class="card">
            <div class="row"><h2 style="margin:0">Rendez-vous du jour</h2><span class="spacer"></span><a routerLink="/rendez-vous">Agenda →</a></div>
            @for (r of rdvs(); track r.id) {
              <div class="list-item">
                <div class="row"><strong>{{ time(r.dateHeure) }}</strong><span>{{ r.patientNom }}</span><span class="spacer"></span>
                  <span class="chip blue">{{ r.mode === 'TELECONSULTATION' ? 'Téléconsultation' : 'Présentiel' }}</span></div>
                <div class="muted small">{{ r.motif || 'Consultation' }} · {{ r.statut }}</div>
              </div>
            } @empty { <div class="empty">Aucun rendez-vous aujourd'hui.</div> }
          </div>
        </div>
      } @else if (!error()) { <div class="empty">Chargement…</div> }
    </div>
  `,
})
export class DashboardPage {
  private api = inject(Api);
  readonly d = signal<Dashboard | null>(null);
  readonly alertes = signal<Alerte[]>([]);
  readonly rdvs = signal<Rdv[]>([]);
  readonly error = signal('');
  readonly dt = fmtDt; readonly time = fmtTime;
  readonly gcls = (g: string) => GRAVITE_CLASS[g] ?? ''; readonly glabel = (g: string) => GRAVITE_LABEL[g] ?? g;
  readonly tlabel = (t: string) => ALERTE_TYPE_LABEL[t] ?? t;

  constructor() { void this.load(); }

  pct(n: number, total: number): number { return total ? (n * 100) / total : 0; }

  private async load(): Promise<void> {
    try {
      const [d, al, r] = await Promise.all([
        this.api.get<Dashboard>('/api/medecin/dashboard'),
        this.api.get<PageResponse<Alerte>>('/api/medecin/alertes', { statut: 'OUVERTE', size: 5 }),
        this.api.get<Rdv[]>('/api/medecin/rendez-vous'),
      ]);
      this.d.set(d); this.alertes.set(al.contenu); this.rdvs.set(r);
    } catch (e) { this.error.set(errMsg(e)); }
  }
}
