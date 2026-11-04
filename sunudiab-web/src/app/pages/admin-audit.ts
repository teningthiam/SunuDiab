import { Component, inject, signal } from '@angular/core';
import { Api } from '../core/api.service';
import { AuditEntry, PageResponse } from '../core/models';
import { errMsg, fmtDt, ROLE_LABEL } from '../core/util';

@Component({
  selector: 'app-admin-audit',
  template: `
    <div class="page">
      <div class="page-head"><div class="grow"><h1>Journal d'audit</h1>
        <div class="muted">Chaque accès à un dossier patient est tracé. Chaque ligne contient l'empreinte SHA-256 de la précédente (journal chaîné, non modifiable sans détection).</div></div></div>
      @if (error()) { <div class="alert-box err">{{ error() }}</div> }
      <div class="card" style="overflow-x:auto">
        <table>
          <thead><tr><th>Horodatage</th><th>Acteur</th><th>Action</th><th>Patient</th><th>IP</th><th>Empreinte</th></tr></thead>
          <tbody>
            @for (a of res()?.contenu ?? []; track a.id) {
              <tr><td>{{ dt(a.horodatage) }}</td><td><strong>{{ a.acteurNom }}</strong><div class="muted small">{{ rl(a.acteurRole) }}</div></td>
                <td><span class="chip blue">{{ a.typeAction }}</span></td><td>{{ a.patientId ?? '—' }}</td><td>{{ a.ip || '—' }}</td>
                <td><code class="small">{{ a.hash.substring(0, 12) }}…</code></td></tr>
            } @empty { <tr><td colspan="6" class="empty">Aucune entrée.</td></tr> }
          </tbody>
        </table>
        <div class="pager">
          <button class="btn btn-sm" [disabled]="page() === 0" (click)="go(page() - 1)">← Précédent</button>
          <span class="muted small">Page {{ page() + 1 }} / {{ res()?.totalPages || 1 }} · {{ res()?.total ?? 0 }} entrées</span>
          <button class="btn btn-sm" [disabled]="page() + 1 >= (res()?.totalPages || 1)" (click)="go(page() + 1)">Suivant →</button>
        </div>
      </div>
    </div>
  `,
})
export class AdminAuditPage {
  private api = inject(Api);
  readonly res = signal<PageResponse<AuditEntry> | null>(null);
  readonly page = signal(0);
  readonly error = signal('');
  readonly dt = fmtDt;
  readonly rl = (r: string) => ROLE_LABEL[r] ?? r;

  constructor() { void this.load(); }
  go(p: number): void { this.page.set(p); void this.load(); }

  private async load(): Promise<void> {
    try { this.error.set(''); this.res.set(await this.api.get<PageResponse<AuditEntry>>('/api/admin/audit', { page: this.page(), size: 25 })); }
    catch (e) { this.error.set(errMsg(e)); }
  }
}
