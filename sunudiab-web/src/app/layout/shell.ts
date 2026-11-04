import { Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../core/auth.service';
import { ROLE_LABEL } from '../core/util';

interface MenuItem { path: string; label: string; icon: string; }

@Component({
  selector: 'app-shell',
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  styles: [`
    :host { display: flex; min-height: 100vh; }
    aside { width: 250px; background: #fff; border-right: 1px solid var(--border); padding: 18px 12px; display: flex; flex-direction: column; position: sticky; top: 0; height: 100vh; }
    .logo { display: flex; align-items: center; gap: 8px; font-weight: 800; font-size: 20px; color: var(--primary-dark); padding: 4px 10px 18px; }
    nav a { display: flex; align-items: center; gap: 10px; padding: 11px 12px; border-radius: 10px; color: var(--text); font-weight: 600; margin-bottom: 4px; }
    nav a:hover { background: var(--bg); text-decoration: none; }
    nav a.active { background: var(--primary); color: #fff; }
    .me { margin-top: auto; border-top: 1px solid var(--border); padding: 14px 8px 4px; }
    main { flex: 1; min-width: 0; }
  `],
  template: `
    <aside>
      <div class="logo">💧 SunuDiab <span class="chip blue">Pro</span></div>
      <nav>
        @for (m of menu(); track m.path) {
          <a [routerLink]="m.path" routerLinkActive="active">{{ m.icon }} {{ m.label }}</a>
        }
      </nav>
      <div class="me">
        <div style="font-weight:700">{{ auth.user()?.prenom }} {{ auth.user()?.nom }}</div>
        <div class="muted small">{{ role() }}</div>
        <button class="btn btn-sm mt" (click)="auth.logout()">Se déconnecter</button>
      </div>
    </aside>
    <main><router-outlet /></main>
  `,
})
export class Shell {
  readonly auth = inject(AuthService);
  readonly role = computed(() => ROLE_LABEL[this.auth.user()?.role ?? ''] ?? '');

  readonly menu = computed<MenuItem[]>(() => {
    const r = this.auth.user()?.role;
    if (r === 'ADMIN') {
      return [
        { path: '/observatoire', label: 'Observatoire', icon: '🗺️' },
        { path: '/admin/utilisateurs', label: 'Utilisateurs', icon: '👥' },
        { path: '/admin/patients', label: 'Affectation patients', icon: '🧑‍⚕️' },
        { path: '/admin/audit', label: "Journal d'audit", icon: '🔒' },
      ];
    }
    if (r === 'SUPERVISEUR') return [{ path: '/observatoire', label: 'Observatoire', icon: '🗺️' }];
    return [
      { path: '/dashboard', label: 'Tableau de bord', icon: '📊' },
      { path: '/patients', label: 'Patients', icon: '🧑' },
      { path: '/alertes', label: 'Alertes', icon: '🚨' },
      { path: '/rendez-vous', label: 'Rendez-vous', icon: '📅' },
    ];
  });
}
