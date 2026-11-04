import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Api } from '../core/api.service';
import { AuthService } from '../core/auth.service';
import { Rdv } from '../core/models';
import { errMsg, fmtTime, todayIso } from '../core/util';

@Component({
  selector: 'app-appointments',
  imports: [FormsModule, RouterLink],
  template: `
    <div class="page">
      <div class="page-head"><div class="grow"><h1>Rendez-vous</h1><div class="muted">Agenda du jour sélectionné</div></div>
        <input type="date" [(ngModel)]="date" (change)="load()" style="width:auto" aria-label="Date" /></div>
      @if (error()) { <div class="alert-box err">{{ error() }}</div> }
      <div class="card">
        <table>
          <thead><tr><th>Heure</th><th>Patient</th><th>Mode</th><th>Motif</th><th>Statut</th><th></th></tr></thead>
          <tbody>
            @for (r of rdvs(); track r.id) {
              <tr>
                <td><strong>{{ time(r.dateHeure) }}</strong></td>
                <td><a [routerLink]="['/patients', r.patientId]">{{ r.patientNom }}</a></td>
                <td><span class="chip blue">{{ r.mode === 'TELECONSULTATION' ? 'Téléconsultation' : 'Présentiel' }}</span></td>
                <td>{{ r.motif || '—' }}</td>
                <td><span class="chip" [class.green]="r.statut === 'CONFIRME'" [class.red]="r.statut === 'ANNULE'" [class.orange]="r.statut === 'EN_ATTENTE'">{{ r.statut }}</span></td>
                <td class="right">
                  @if (isDoctor) {
                    @if (r.statut === 'EN_ATTENTE') { <button class="btn btn-sm btn-green" (click)="set(r.id, 'CONFIRME')">Accepter</button> }
                    @if (r.statut === 'CONFIRME') { <button class="btn btn-sm" (click)="set(r.id, 'TERMINE')">Terminé</button> }
                    @if (r.statut === 'EN_ATTENTE' || r.statut === 'CONFIRME') { <button class="btn btn-sm" (click)="set(r.id, 'ANNULE')">Annuler</button> }
                  }
                </td>
              </tr>
            } @empty { <tr><td colspan="6" class="empty">Aucun rendez-vous ce jour-là.</td></tr> }
          </tbody>
        </table>
      </div>
    </div>
  `,
})
export class AppointmentsPage {
  private api = inject(Api);
  readonly isDoctor = inject(AuthService).hasRole('MEDECIN');
  readonly rdvs = signal<Rdv[]>([]);
  readonly error = signal('');
  readonly time = fmtTime;
  date = todayIso();

  constructor() { void this.load(); }

  async load(): Promise<void> {
    try { this.error.set(''); this.rdvs.set(await this.api.get<Rdv[]>('/api/medecin/rendez-vous', { date: this.date })); }
    catch (e) { this.error.set(errMsg(e)); }
  }

  async set(id: number, statut: string): Promise<void> {
    try { await this.api.put(`/api/medecin/rendez-vous/${id}/statut`, { statut }); await this.load(); }
    catch (e) { this.error.set(errMsg(e)); }
  }
}
