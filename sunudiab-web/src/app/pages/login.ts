import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../core/auth.service';
import { apiUrl, DEFAULT_API_URL } from '../core/config';
import { errMsg } from '../core/util';

@Component({
  selector: 'app-login',
  imports: [FormsModule],
  styles: [`
    .wrap { min-height: 100vh; display: grid; place-items: center; padding: 20px; background: linear-gradient(135deg, #e6f0fd, #f7f9fc); }
    .box { width: 100%; max-width: 420px; }
    .logo { text-align: center; font-size: 30px; font-weight: 800; color: var(--primary-dark); margin-bottom: 4px; }
  `],
  template: `
    <div class="wrap">
      <div class="box">
        <div class="logo">💧 SunuDiab Pro</div>
        <p class="muted" style="text-align:center;margin-top:0">Espace médecins, hôpitaux et administration</p>
        <form class="card" (ngSubmit)="submit()">
          @if (error()) { <div class="alert-box err">{{ error() }}</div> }
          <div class="field">
            <label for="id">E-mail ou téléphone</label>
            <input id="id" name="identifiant" [(ngModel)]="identifiant" autocomplete="username" required />
          </div>
          <div class="field">
            <label for="pw">Mot de passe</label>
            <input id="pw" name="password" type="password" [(ngModel)]="password" autocomplete="current-password" required />
          </div>
          <button class="btn btn-primary" style="width:100%;justify-content:center" [disabled]="loading()">
            {{ loading() ? 'Connexion…' : 'Se connecter' }}
          </button>
        </form>
        <details class="card">
          <summary class="muted small" style="cursor:pointer">Serveur : {{ server }}</summary>
          <div class="field mt"><label for="srv">Adresse de l'API</label>
            <input id="srv" name="srv" [(ngModel)]="serverInput" placeholder="http://localhost:8080" /></div>
          <button type="button" class="btn btn-sm" (click)="saveServer()">Enregistrer et recharger</button>
        </details>
      </div>
    </div>
  `,
})
export class LoginPage {
  private auth = inject(AuthService);
  private router = inject(Router);
  identifiant = '';
  password = '';
  server = apiUrl();
  serverInput = apiUrl();
  readonly loading = signal(false);
  readonly error = signal('');

  async submit(): Promise<void> {
    if (!this.identifiant || !this.password) return;
    this.loading.set(true);
    this.error.set('');
    try {
      await this.auth.login(this.identifiant, this.password);
      await this.router.navigateByUrl(this.auth.homeRoute());
    } catch (e) {
      this.error.set(errMsg(e));
    } finally {
      this.loading.set(false);
    }
  }

  saveServer(): void {
    let u = this.serverInput.trim() || DEFAULT_API_URL;
    if (!/^https?:\/\//.test(u)) u = 'http://' + u;
    localStorage.setItem('api_url', u.replace(/\/+$/, ''));
    location.reload();
  }
}
