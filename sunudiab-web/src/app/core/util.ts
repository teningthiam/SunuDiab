import { HttpErrorResponse } from '@angular/common/http';

export const STATUS_LABEL: Record<string, string> = {
  HYPO_SEVERE: 'Hypoglycémie sévère', HYPO: 'Glycémie basse', NORMAL: 'Normal',
  LEGEREMENT_ELEVE: 'Légèrement élevé', ELEVE: 'Élevé', CRITIQUE: 'Critique',
};
export const STATUS_CLASS: Record<string, string> = {
  HYPO_SEVERE: 'red', HYPO: 'orange', NORMAL: 'green', LEGEREMENT_ELEVE: 'orange', ELEVE: 'orange', CRITIQUE: 'red',
};
export const TYPE_LABEL: Record<string, string> = {
  AUCUN: 'Pas de diagnostic', PREDIABETE: 'Prédiabète', TYPE_1: 'Diabète type 1', TYPE_2: 'Diabète type 2',
  GESTATIONNEL: 'Diabète gestationnel',
};
export const MOMENT_LABEL: Record<string, string> = {
  A_JEUN: 'À jeun', AVANT_REPAS: 'Avant repas', APRES_REPAS: 'Après repas', COUCHER: 'Au coucher',
};
export const GRAVITE_LABEL: Record<string, string> = {
  URGENCE_VITALE: 'Urgence vitale', ELEVEE: 'Élevée', MODEREE: 'Modérée',
};
export const GRAVITE_CLASS: Record<string, string> = { URGENCE_VITALE: 'red', ELEVEE: 'orange', MODEREE: 'blue' };
export const ALERTE_TYPE_LABEL: Record<string, string> = {
  HYPO_SEVERE: 'Hypoglycémie sévère', HYPER_CRITIQUE: 'Hyperglycémie critique', DERIVE_GLYCEMIQUE: 'Dérive glycémique',
  RUPTURE_TRANSMISSION: 'Rupture de transmission', RUPTURE_TRAITEMENT: 'Rupture de traitement',
  SYMPTOMES_SIGNALES: 'Symptômes signalés',
};
export const ROLE_LABEL: Record<string, string> = {
  PATIENT: 'Patient', MEDECIN: 'Médecin', INFIRMIER_RELAIS: 'Infirmier relais', ADMIN: 'Administrateur',
  SUPERVISEUR: 'Superviseur national',
};
export const RISK_LABEL: Record<string, string> = {
  FAIBLE: 'Risque faible', LEGER: 'Risque légèrement élevé', MODERE: 'Risque modéré', ELEVE: 'Risque élevé',
  TRES_ELEVE: 'Risque très élevé',
};

export function fmtDt(iso?: string | null): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '—';
  return d.toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

export function fmtDate(iso?: string | null): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

export function fmtTime(iso?: string | null): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return isNaN(d.getTime()) ? '—' : d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
}

export function todayIso(): string {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

/** Extrait un message lisible d'une erreur HTTP du backend. */
export function errMsg(e: unknown): string {
  if (e instanceof HttpErrorResponse) {
    if (e.status === 0) return 'Serveur injoignable. Vérifiez l\'adresse de l\'API et que le backend est démarré.';
    const body = e.error as { message?: string; details?: Record<string, string> } | null;
    if (body?.details && Object.keys(body.details).length) return Object.values(body.details)[0];
    if (body?.message) return body.message;
    if (e.status === 403) return 'Accès refusé.';
    return `Erreur ${e.status}`;
  }
  return e instanceof Error ? e.message : 'Une erreur est survenue.';
}
