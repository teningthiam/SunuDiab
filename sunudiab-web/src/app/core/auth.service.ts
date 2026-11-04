import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { apiUrl } from './config';
import { AuthResponse, Role, UserInfo } from './models';

const KEY_ACCESS = 'sd_access';
const KEY_REFRESH = 'sd_refresh';
const KEY_USER = 'sd_user';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);
  private refreshing: Promise<boolean> | null = null;

  readonly user = signal<UserInfo | null>(this.loadUser());
  readonly isStaff = computed(() => {
    const r = this.user()?.role;
    return r === 'MEDECIN' || r === 'INFIRMIER_RELAIS';
  });

  private loadUser(): UserInfo | null {
    try {
      const s = localStorage.getItem(KEY_USER);
      return s ? (JSON.parse(s) as UserInfo) : null;
    } catch {
      return null;
    }
  }

  get accessToken(): string | null {
    return localStorage.getItem(KEY_ACCESS);
  }

  hasRole(...roles: Role[]): boolean {
    const r = this.user()?.role;
    return !!r && roles.includes(r);
  }

  /** Page d'accueil selon le rôle. */
  homeRoute(): string {
    const r = this.user()?.role;
    return r === 'ADMIN' || r === 'SUPERVISEUR' ? '/observatoire' : '/dashboard';
  }

  private save(r: AuthResponse): void {
    localStorage.setItem(KEY_ACCESS, r.accessToken);
    localStorage.setItem(KEY_REFRESH, r.refreshToken);
    localStorage.setItem(KEY_USER, JSON.stringify(r.utilisateur));
    this.user.set(r.utilisateur);
  }

  async login(identifiant: string, password: string): Promise<void> {
    const r = await firstValueFrom(
      this.http.post<AuthResponse>(apiUrl() + '/api/auth/login', { identifiant: identifiant.trim(), password }),
    );
    if (r.utilisateur.role === 'PATIENT') {
      throw new Error('Ce portail est réservé au personnel de santé et aux administrateurs. Les patients utilisent l\'application mobile.');
    }
    this.save(r);
  }

  /** Renouvelle le jeton (une seule requête à la fois). */
  refresh(): Promise<boolean> {
    if (!this.refreshing) {
      this.refreshing = this.doRefresh().finally(() => (this.refreshing = null));
    }
    return this.refreshing;
  }

  private async doRefresh(): Promise<boolean> {
    const rt = localStorage.getItem(KEY_REFRESH);
    if (!rt) return false;
    try {
      const r = await firstValueFrom(
        this.http.post<AuthResponse>(apiUrl() + '/api/auth/refresh', { refreshToken: rt }),
      );
      this.save(r);
      return true;
    } catch {
      return false;
    }
  }

  logout(): void {
    localStorage.removeItem(KEY_ACCESS);
    localStorage.removeItem(KEY_REFRESH);
    localStorage.removeItem(KEY_USER);
    this.user.set(null);
    void this.router.navigate(['/login']);
  }
}
