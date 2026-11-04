import { Component, computed, input } from '@angular/core';
import { Mesure } from '../core/models';

const COLORS: Record<string, string> = {
  NORMAL: '#2eb872', HYPO: '#f5a524', LEGEREMENT_ELEVE: '#f5a524', ELEVE: '#e8590c', HYPO_SEVERE: '#e5484d', CRITIQUE: '#e5484d',
};

/** Courbe de glycémie en SVG avec zone cible verte (aucune bibliothèque externe). */
@Component({
  selector: 'app-glycemia-chart',
  template: `
    @if (pts().length === 0) {
      <div class="empty">Pas encore de mesures sur cette période.</div>
    } @else {
      <svg [attr.viewBox]="'0 0 ' + W + ' ' + H" width="100%" preserveAspectRatio="xMidYMid meet">
        <rect [attr.x]="L" [attr.y]="yBand().y" [attr.width]="W - L - R" [attr.height]="yBand().h" fill="#dff5ea" />
        @for (t of yTicks(); track t.v) {
          <line [attr.x1]="L" [attr.x2]="W - R" [attr.y1]="t.y" [attr.y2]="t.y" stroke="#e3e8f0" />
          <text [attr.x]="L - 6" [attr.y]="t.y + 4" text-anchor="end" font-size="11" fill="#6b7788">{{ t.v.toFixed(1) }}</text>
        }
        @for (t of xTicks(); track t.x) {
          <text [attr.x]="t.x" [attr.y]="H - 8" text-anchor="middle" font-size="11" fill="#6b7788">{{ t.label }}</text>
        }
        <polyline [attr.points]="line()" fill="none" stroke="#1e6fd9" stroke-width="2.5" stroke-linejoin="round" />
        @for (p of dots(); track p.i) {
          <circle [attr.cx]="p.x" [attr.cy]="p.y" r="4.5" [attr.fill]="p.c" stroke="#fff" stroke-width="1.5">
            <title>{{ p.tip }}</title>
          </circle>
        }
      </svg>
    }
  `,
})
export class LineChart {
  readonly data = input.required<Mesure[]>();
  readonly cmin = input(0.7);
  readonly cmax = input(1.3);

  readonly W = 640; readonly H = 240; readonly L = 40; readonly R = 12; readonly T = 12; readonly B = 30;

  readonly pts = computed(() => [...this.data()].sort((a, b) => +new Date(a.mesureLe) - +new Date(b.mesureLe)));
  private readonly yMax = computed(() => Math.max(1.8, ...this.pts().map((m) => m.valeur + 0.1)));
  private readonly yMin = 0.4;
  private readonly t0 = computed(() => +new Date(this.pts()[0]?.mesureLe ?? 0));
  private readonly t1 = computed(() => Math.max(+new Date(this.pts()[this.pts().length - 1]?.mesureLe ?? 0), this.t0() + 86400000));

  private y(v: number): number {
    return this.T + (1 - (v - this.yMin) / (this.yMax() - this.yMin)) * (this.H - this.T - this.B);
  }
  private x(t: number): number {
    return this.L + ((t - this.t0()) / (this.t1() - this.t0())) * (this.W - this.L - this.R);
  }

  readonly yBand = computed(() => {
    const top = this.y(Math.min(this.cmax(), this.yMax()));
    const bottom = this.y(Math.max(this.cmin(), this.yMin));
    return { y: top, h: Math.max(0, bottom - top) };
  });
  readonly yTicks = computed(() => {
    const out: { v: number; y: number }[] = [];
    for (let v = 0.4; v <= this.yMax() + 0.001; v += 0.4) out.push({ v, y: this.y(v) });
    return out;
  });
  readonly xTicks = computed(() => {
    const out: { x: number; label: string }[] = [];
    for (let i = 0; i <= 4; i++) {
      const t = this.t0() + ((this.t1() - this.t0()) * i) / 4;
      out.push({ x: this.x(t), label: new Date(t).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' }) });
    }
    return out;
  });
  readonly line = computed(() => this.pts().map((m) => `${this.x(+new Date(m.mesureLe))},${this.y(m.valeur)}`).join(' '));
  readonly dots = computed(() =>
    this.pts().map((m, i) => ({
      i, x: this.x(+new Date(m.mesureLe)), y: this.y(m.valeur), c: COLORS[m.statut] ?? '#1e6fd9',
      tip: `${m.valeur.toFixed(2)} g/L — ${new Date(m.mesureLe).toLocaleString('fr-FR')}`,
    })),
  );
}
