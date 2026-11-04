import { Component, effect, inject, input, signal, untracked } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Api } from '../core/api.service';
import { AuthService } from '../core/auth.service';
import {
  Bilan, ChatMsg, GlycemieStats, Intervention, Mesure, Message, Note, Ordonnance, PageResponse, PatientDetail,
  RisqueResult, Traitement,
} from '../core/models';
import { errMsg, fmtDate, fmtDt, MOMENT_LABEL, RISK_LABEL, TYPE_LABEL } from '../core/util';
import { StatusChip } from '../shared/chip';
import { LineChart } from '../shared/line-chart';

type Tab = 'resume' | 'glycemies' | 'traitements' | 'ordonnances' | 'notes' | 'bilans' | 'ia' | 'messages';

@Component({
  selector: 'app-patient-detail',
  imports: [FormsModule, RouterLink, StatusChip, LineChart],
  template: `
    <div class="page">
      <a routerLink="/patients" class="muted">← Retour à la liste</a>
      @if (error()) { <div class="alert-box err mt">{{ error() }}</div> }
      @if (info()) { <div class="alert-box ok mt">{{ info() }}</div> }

      @if (p(); as pt) {
        <div class="page-head mt">
          <div class="grow">
            <h1>{{ pt.prenom }} {{ pt.nom }}</h1>
            <div class="row">
              <span class="chip blue">{{ pt.numeroDossier }}</span>
              <span class="chip">{{ tl(pt.typeDiabete) }}</span>
              <span class="muted">{{ pt.age ?? '—' }} ans · {{ pt.sexe === 'F' ? 'Femme' : 'Homme' }} · {{ pt.quartier || pt.region || '' }}</span>
              <span class="muted">☎ {{ pt.telephone }}</span>
            </div>
          </div>
          @if (isDoctor) {
            <select [ngModel]="pt.typeDiabete" (ngModelChange)="setDiagnostic($event)" style="width:auto" aria-label="Diagnostic">
              @for (t of types; track t) { <option [value]="t">{{ tl(t) }}</option> }
            </select>
            <button class="btn btn-danger" (click)="samuOpen.set(!samuOpen())">🚑 Ordre SAMU</button>
          }
        </div>

        @if (samuOpen()) {
          <div class="card" style="border-color:var(--red)">
            <h2>Ordre d'intervention SAMU</h2>
            <div class="alert-box warn">Cette action enregistre un ordre dans SunuDiab (traçabilité). Elle n'appelle pas le SAMU : appelez le 1515 en parallèle.</div>
            <div class="row">
              <div class="field"><label for="sl">Localisation</label><input id="sl" name="sl" [(ngModel)]="samu.localisation" /></div>
              <div class="field"><label for="sr">Repère</label><input id="sr" name="sr" [(ngModel)]="samu.repere" /></div>
              <div class="field"><label for="sh">Hôpital de réception</label><input id="sh" name="sh" [(ngModel)]="samu.hopitalReception" /></div>
            </div>
            <button class="btn btn-danger" (click)="sendSamu()">Confirmer l'ordre d'intervention</button>
            @if (lastIntervention(); as i) { <div class="alert-box ok mt">Ordre enregistré : {{ i.ordre }}</div> }
          </div>
        }

        <div class="grid g4 mb">
          <div class="card kpi"><div class="label">IMC</div><div class="value">{{ pt.imc ?? '—' }}</div><div class="sub">{{ pt.poidsKg ?? '—' }} kg · {{ pt.tailleCm ?? '—' }} cm</div></div>
          <div class="card kpi green"><div class="label">Dernière HbA1c</div><div class="value">{{ pt.derniereHba1c ?? '—' }}<small>{{ pt.derniereHba1c ? ' %' : '' }}</small></div><div class="sub">objectif &lt; 7 %</div></div>
          <div class="card kpi"><div class="label">Tension</div><div class="value">{{ pt.tensionSystolique ?? '—' }}/{{ pt.tensionDiastolique ?? '—' }}</div><div class="sub">mmHg</div></div>
          <div class="card kpi orange"><div class="label">Cible glycémique</div><div class="value" style="font-size:24px">{{ pt.cibleMin }} – {{ pt.cibleMax }}</div><div class="sub">g/L</div></div>
        </div>

        <div class="tabs">
          @for (t of tabs; track t.id) { <button class="tab" [class.active]="tab() === t.id" (click)="open(t.id)">{{ t.label }}</button> }
        </div>

        @switch (tab()) {
          @case ('resume') {
            <div class="grid g-main">
              <div class="card">
                <div class="row"><h2 style="margin:0">Évolution glycémique (30 jours)</h2></div>
                @if (stats(); as s) {
                  <div class="row mt small">
                    <span class="chip green">Dans la cible {{ s.pourcentageDansCible }} %</span>
                    <span class="chip">Moyenne {{ s.moyenne ?? '—' }} g/L</span>
                    <span class="chip">{{ s.nombreMesures }} mesures</span>
                    <span class="chip" [class.red]="s.hypoglycemies > 0">{{ s.hypoglycemies }} hypoglycémie(s)</span>
                  </div>
                  <app-glycemia-chart [data]="s.points" [cmin]="pt.cibleMin" [cmax]="pt.cibleMax" />
                }
              </div>
              <div>
                <div class="card">
                  <h2>Évaluation du risque (FINDRISC)</h2>
                  @for (r of risques(); track r.id; let first = $first) {
                    @if (first) {
                      <div class="row"><strong style="font-size:26px">{{ r.score }}/{{ r.scoreMax }}</strong><span class="chip orange">{{ rl(r.niveau) }}</span></div>
                      <div class="muted small mt">{{ r.probabilite }} · {{ dt(r.date) }}</div>
                      @if (r.validee) { <div class="chip green mt">Validée par un médecin</div> }
                      @else if (isDoctor) { <button class="btn btn-sm btn-green mt" (click)="validate(r.id)">Valider l'évaluation</button> }
                    }
                  } @empty { <div class="empty">Pas de test de risque.</div> }
                </div>
                <div class="card">
                  <h2>Équipe de soins</h2>
                  <div>Médecin : <strong>{{ pt.medecinReferentNom ?? '—' }}</strong></div>
                  <div>Relais : <strong>{{ pt.infirmierRelaisNom ?? '—' }}</strong> <span class="muted">{{ pt.infirmierRelaisTelephone }}</span></div>
                  <h3 class="mt">Contacts d'urgence</h3>
                  @for (c of pt.contacts; track c.id) { <div class="small">{{ c.nom }} ({{ c.lien }}) — {{ c.telephone }}</div> } @empty { <div class="muted small">Aucun.</div> }
                </div>
              </div>
            </div>
          }
          @case ('glycemies') {
            <div class="card">
              <table>
                <thead><tr><th>Date</th><th>Valeur</th><th>Statut</th><th>Moment</th><th>Saisie</th><th>Contexte</th></tr></thead>
                <tbody>
                  @for (m of mesures(); track m.id) {
                    <tr><td>{{ dt(m.mesureLe) }}</td><td><strong>{{ m.valeur.toFixed(2) }}</strong> g/L</td><td><app-status [status]="m.statut" /></td>
                      <td>{{ ml(m.moment) }}</td><td>{{ m.methode }}</td><td>{{ m.contexte || '' }}</td></tr>
                  } @empty { <tr><td colspan="6" class="empty">Aucune mesure.</td></tr> }
                </tbody>
              </table>
            </div>
          }
          @case ('traitements') {
            @if (isDoctor) {
              <div class="card">
                <h2>Prescrire un traitement</h2>
                <div class="row">
                  <div class="field"><label for="tm">Médicament</label><input id="tm" name="tm" [(ngModel)]="tForm.medicament" /></div>
                  <div class="field"><label for="td">Dosage</label><input id="td" name="td" [(ngModel)]="tForm.dosage" placeholder="500 mg" /></div>
                  <div class="field"><label for="th">Horaires</label><input id="th" name="th" [(ngModel)]="tForm.horaires" placeholder="08:00,20:00" /></div>
                  <div class="field"><label for="ts">Stock (prises)</label><input id="ts" name="ts" type="number" [(ngModel)]="tForm.stockRestant" /></div>
                </div>
                <div class="field"><label for="tp">Posologie</label><input id="tp" name="tp" [(ngModel)]="tForm.posologie" placeholder="1 comprimé matin et soir, au milieu des repas" /></div>
                <button class="btn btn-primary" (click)="addTraitement()">Prescrire</button>
              </div>
            }
            <div class="card">
              <table>
                <thead><tr><th>Médicament</th><th>Posologie</th><th>Stock</th><th>Statut</th><th></th></tr></thead>
                <tbody>
                  @for (t of traitements(); track t.id) {
                    <tr><td><strong>{{ t.medicament }}</strong> {{ t.dosage }}<div class="muted small">{{ t.prescripteur }}</div></td>
                      <td>{{ t.posologie }}<div class="muted small">{{ t.horaires }}</div></td>
                      <td>{{ t.stockRestant ?? '—' }}</td>
                      <td><span class="chip" [class.green]="t.actif">{{ t.actif ? 'En cours' : 'Arrêté' }}</span></td>
                      <td class="right">@if (isDoctor && t.actif) { <button class="btn btn-sm" (click)="stopTraitement(t.id)">Arrêter</button> }</td></tr>
                  } @empty { <tr><td colspan="5" class="empty">Aucun traitement.</td></tr> }
                </tbody>
              </table>
            </div>
          }
          @case ('ordonnances') {
            @if (isDoctor) {
              <div class="card">
                <h2>Nouvelle ordonnance</h2>
                <div class="field"><label for="ol">Lignes de prescription</label><textarea id="ol" name="ol" rows="3" [(ngModel)]="oForm.lignes" placeholder="Metformine 500 mg x60&#10;Bandelettes x50"></textarea></div>
                <div class="row">
                  <div class="field"><label for="op">Pharmacie</label><input id="op" name="op" [(ngModel)]="oForm.pharmacie" /></div>
                  <div class="field"><label for="om">Durée (mois)</label><input id="om" name="om" type="number" min="1" max="12" [(ngModel)]="oForm.dureeMois" /></div>
                </div>
                <button class="btn btn-primary" (click)="addOrdonnance()">Émettre l'ordonnance</button>
              </div>
            }
            <div class="card">
              @for (o of ordonnances(); track o.id) {
                <div class="list-item"><div class="row"><strong>{{ o.numero }}</strong><span class="chip blue">{{ o.statut }}</span><span class="spacer"></span>
                  <span class="muted small">émise le {{ d(o.dateEmission) }} · expire le {{ d(o.dateExpiration) }} · {{ o.medecin }}</span></div>
                  <div style="white-space:pre-line;margin-top:6px">{{ o.lignes }}</div><div class="muted small">{{ o.pharmacie }}</div></div>
              } @empty { <div class="empty">Aucune ordonnance.</div> }
            </div>
          }
          @case ('notes') {
            <div class="card">
              <h2>Ajouter une note</h2>
              <div class="field"><textarea name="nc" rows="3" [(ngModel)]="nForm.contenu" aria-label="Note"></textarea></div>
              <label class="row small"><input type="checkbox" name="nv" [(ngModel)]="nForm.visibleRelais" style="width:auto" /> Visible par l'infirmier relais</label>
              <button class="btn btn-primary mt" (click)="addNote()">Enregistrer la note</button>
            </div>
            <div class="card">
              @for (n of notes(); track n.id) {
                <div class="list-item"><div class="row"><strong>{{ n.auteur }}</strong><span class="muted small">{{ dt(n.createdAt) }}</span>
                  @if (n.visibleRelais) { <span class="chip">Visible relais</span> }</div><div style="white-space:pre-line">{{ n.contenu }}</div></div>
              } @empty { <div class="empty">Aucune note.</div> }
            </div>
          }
          @case ('bilans') {
            @if (isDoctor) {
              <div class="card">
                <h2>Ajouter un bilan</h2>
                <div class="row">
                  <div class="field"><label for="bt">Type</label><select id="bt" name="bt" [(ngModel)]="bForm.type"><option>HBA1C</option><option>CREATININE</option><option>CHOLESTEROL</option><option>AUTRE</option></select></div>
                  <div class="field"><label for="bv">Valeur</label><input id="bv" name="bv" type="number" step="0.1" [(ngModel)]="bForm.valeur" /></div>
                  <div class="field"><label for="bu">Unité</label><input id="bu" name="bu" [(ngModel)]="bForm.unite" placeholder="%" /></div>
                  <div class="field"><label for="bd">Date</label><input id="bd" name="bd" type="date" [(ngModel)]="bForm.dateBilan" /></div>
                </div>
                <button class="btn btn-primary" (click)="addBilan()">Enregistrer</button>
              </div>
            }
            <div class="card">
              <table><thead><tr><th>Date</th><th>Type</th><th>Valeur</th></tr></thead><tbody>
                @for (b of bilans(); track b.id) { <tr><td>{{ d(b.dateBilan) }}</td><td>{{ b.type }}</td><td><strong>{{ b.valeur }}</strong> {{ b.unite }}</td></tr> }
                @empty { <tr><td colspan="3" class="empty">Aucun bilan.</td></tr> }
              </tbody></table>
            </div>
          }
          @case ('ia') {
            <div class="card">
              <h2>Échanges du patient avec l'assistant IA</h2>
              <div class="chat">
                @for (c of chat(); track $index) {
                  <div class="bubble" [class.me]="c.auteur === 'PATIENT'" [class.urg]="c.urgence">{{ c.contenu }}<small>{{ dt(c.createdAt) }}</small></div>
                } @empty { <div class="empty">Aucun échange.</div> }
              </div>
            </div>
          }
          @case ('messages') {
            <div class="card">
              <h2>Messagerie avec {{ pt.prenom }}</h2>
              <div class="chat">
                @for (m of messages(); track m.id) {
                  <div class="bubble" [class.me]="m.expediteurId !== pt.userId">{{ m.contenu }}<small>{{ m.expediteurNom }} · {{ dt(m.createdAt) }}</small></div>
                } @empty { <div class="empty">Aucun message.</div> }
              </div>
              <div class="row mt">
                <input name="mt" [(ngModel)]="msgText" placeholder="Votre message…" (keyup.enter)="sendMessage(pt.userId)" aria-label="Message" />
                <button class="btn btn-primary" (click)="sendMessage(pt.userId)">Envoyer</button>
              </div>
            </div>
          }
        }
      } @else if (!error()) { <div class="empty">Chargement…</div> }
    </div>
  `,
})
export class PatientDetailPage {
  readonly id = input.required<string>();
  private api = inject(Api);
  private auth = inject(AuthService);
  readonly isDoctor = this.auth.hasRole('MEDECIN');

  readonly p = signal<PatientDetail | null>(null);
  readonly error = signal('');
  readonly info = signal('');
  readonly tab = signal<Tab>('resume');
  readonly stats = signal<GlycemieStats | null>(null);
  readonly mesures = signal<Mesure[]>([]);
  readonly risques = signal<RisqueResult[]>([]);
  readonly traitements = signal<Traitement[]>([]);
  readonly ordonnances = signal<Ordonnance[]>([]);
  readonly notes = signal<Note[]>([]);
  readonly bilans = signal<Bilan[]>([]);
  readonly chat = signal<ChatMsg[]>([]);
  readonly messages = signal<Message[]>([]);
  readonly samuOpen = signal(false);
  readonly lastIntervention = signal<Intervention | null>(null);

  tForm = { medicament: '', dosage: '', posologie: '', horaires: '', stockRestant: null as number | null };
  oForm = { lignes: '', pharmacie: '', dureeMois: 3 };
  nForm = { contenu: '', visibleRelais: true };
  bForm = { type: 'HBA1C', valeur: null as number | null, unite: '%', dateBilan: '' };
  samu = { localisation: '', repere: '', hopitalReception: '' };
  msgText = '';

  readonly types = ['AUCUN', 'PREDIABETE', 'TYPE_1', 'TYPE_2', 'GESTATIONNEL'];
  readonly tabs: { id: Tab; label: string }[] = [
    { id: 'resume', label: 'Résumé' }, { id: 'glycemies', label: 'Glycémies' }, { id: 'traitements', label: 'Traitements' },
    { id: 'ordonnances', label: 'Ordonnances' }, { id: 'notes', label: 'Notes' }, { id: 'bilans', label: 'Bilans' },
    { id: 'ia', label: 'Échanges IA' }, { id: 'messages', label: 'Messages' },
  ];
  readonly dt = fmtDt; readonly d = fmtDate;
  readonly tl = (t: string) => TYPE_LABEL[t] ?? t;
  readonly rl = (n: string) => RISK_LABEL[n] ?? n;
  readonly ml = (m: string) => MOMENT_LABEL[m] ?? m;

  constructor() {
    effect(() => {
      const id = this.id();
      untracked(() => void this.init(id));
    });
  }

  private flash(msg: string): void {
    this.info.set(msg);
    setTimeout(() => this.info.set(''), 4000);
  }

  private async run(fn: () => Promise<void>): Promise<void> {
    try { this.error.set(''); await fn(); } catch (e) { this.error.set(errMsg(e)); }
  }

  private async init(id: string): Promise<void> {
    this.tab.set('resume');
    this.p.set(null);
    await this.run(async () => {
      const [p, stats, risques] = await Promise.all([
        this.api.get<PatientDetail>(`/api/medecin/patients/${id}`),
        this.api.get<GlycemieStats>(`/api/medecin/patients/${id}/mesures/stats`, { jours: 30 }),
        this.api.get<RisqueResult[]>(`/api/medecin/patients/${id}/risque`),
      ]);
      this.p.set(p); this.stats.set(stats); this.risques.set(risques);
    });
  }

  async open(t: Tab): Promise<void> {
    this.tab.set(t);
    const id = this.id();
    await this.run(async () => {
      switch (t) {
        case 'glycemies': this.mesures.set((await this.api.get<PageResponse<Mesure>>(`/api/medecin/patients/${id}/mesures`, { size: 60 })).contenu); break;
        case 'traitements': this.traitements.set(await this.api.get<Traitement[]>(`/api/medecin/patients/${id}/traitements`)); break;
        case 'ordonnances': this.ordonnances.set(await this.api.get<Ordonnance[]>(`/api/medecin/patients/${id}/ordonnances`)); break;
        case 'notes': this.notes.set(await this.api.get<Note[]>(`/api/medecin/patients/${id}/notes`)); break;
        case 'bilans': this.bilans.set(await this.api.get<Bilan[]>(`/api/medecin/patients/${id}/bilans`)); break;
        case 'ia': this.chat.set(await this.api.get<ChatMsg[]>(`/api/medecin/patients/${id}/chat`)); break;
        case 'messages': { const uid = this.p()?.userId; if (uid) this.messages.set(await this.api.get<Message[]>(`/api/messages/${uid}`)); break; }
        default: break;
      }
    });
  }

  setDiagnostic(type: string): Promise<void> {
    return this.run(async () => {
      this.p.set(await this.api.put<PatientDetail>(`/api/medecin/patients/${this.id()}/diagnostic`, {}, { type }));
      this.flash('Diagnostic mis à jour.');
    });
  }

  validate(evalId: number): Promise<void> {
    return this.run(async () => {
      await this.api.put<RisqueResult>(`/api/medecin/patients/${this.id()}/risque/${evalId}/valider`);
      this.risques.set(await this.api.get<RisqueResult[]>(`/api/medecin/patients/${this.id()}/risque`));
      this.flash('Évaluation validée.');
    });
  }

  addTraitement(): Promise<void> {
    return this.run(async () => {
      if (!this.tForm.medicament.trim()) throw new Error('Le nom du médicament est obligatoire.');
      await this.api.post(`/api/medecin/patients/${this.id()}/traitements`, { ...this.tForm, stockRestant: this.tForm.stockRestant ?? null });
      this.tForm = { medicament: '', dosage: '', posologie: '', horaires: '', stockRestant: null };
      await this.open('traitements'); this.flash('Traitement prescrit.');
    });
  }

  stopTraitement(tid: number): Promise<void> {
    return this.run(async () => {
      await this.api.put(`/api/medecin/patients/${this.id()}/traitements/${tid}/arreter`);
      await this.open('traitements'); this.flash('Traitement arrêté.');
    });
  }

  addOrdonnance(): Promise<void> {
    return this.run(async () => {
      if (!this.oForm.lignes.trim()) throw new Error('Saisissez les lignes de prescription.');
      await this.api.post(`/api/medecin/patients/${this.id()}/ordonnances`, this.oForm);
      this.oForm = { lignes: '', pharmacie: '', dureeMois: 3 };
      await this.open('ordonnances'); this.flash('Ordonnance émise.');
    });
  }

  addNote(): Promise<void> {
    return this.run(async () => {
      if (!this.nForm.contenu.trim()) throw new Error('La note est vide.');
      await this.api.post(`/api/medecin/patients/${this.id()}/notes`, this.nForm);
      this.nForm = { contenu: '', visibleRelais: true };
      await this.open('notes'); this.flash('Note enregistrée.');
    });
  }

  addBilan(): Promise<void> {
    return this.run(async () => {
      if (this.bForm.valeur === null || !this.bForm.dateBilan) throw new Error('Valeur et date obligatoires.');
      await this.api.post(`/api/medecin/patients/${this.id()}/bilans`, this.bForm);
      this.bForm = { type: 'HBA1C', valeur: null, unite: '%', dateBilan: '' };
      await this.open('bilans');
      const p = await this.api.get<PatientDetail>(`/api/medecin/patients/${this.id()}`);
      this.p.set(p); this.flash('Bilan enregistré.');
    });
  }

  sendSamu(): Promise<void> {
    return this.run(async () => {
      if (!this.samu.localisation.trim()) throw new Error('Indiquez la localisation du patient.');
      if (!confirm('Enregistrer un ordre d\'intervention SAMU pour ce patient ?')) return;
      this.lastIntervention.set(await this.api.post<Intervention>(`/api/medecin/patients/${this.id()}/samu`, this.samu));
    });
  }

  sendMessage(userId: number): Promise<void> {
    return this.run(async () => {
      if (!this.msgText.trim()) return;
      await this.api.post('/api/messages', { destinataireId: userId, contenu: this.msgText.trim() });
      this.msgText = '';
      this.messages.set(await this.api.get<Message[]>(`/api/messages/${userId}`));
    });
  }
}
