export type Role = 'PATIENT' | 'MEDECIN' | 'INFIRMIER_RELAIS' | 'ADMIN' | 'SUPERVISEUR';
export type GStatus = 'HYPO_SEVERE' | 'HYPO' | 'NORMAL' | 'LEGEREMENT_ELEVE' | 'ELEVE' | 'CRITIQUE';

export interface UserInfo {
  id: number;
  nom: string;
  prenom: string;
  email?: string | null;
  telephone?: string | null;
  role: Role;
  langue: string;
  patientId?: number | null;
}
export interface AuthResponse { accessToken: string; refreshToken: string; utilisateur: UserInfo; }
export interface PageResponse<T> { contenu: T[]; page: number; taille: number; total: number; totalPages: number; }

export interface Contact { id: number; nom: string; telephone: string; lien?: string | null; }

export interface PatientResume {
  id: number; userId: number; numeroDossier: string; nomComplet: string; age: number | null; sexe: string | null;
  typeDiabete: string | null; quartier: string | null; region: string | null; telephone: string | null;
  derniereGlycemie: number | null; derniereStatut: GStatus | null; derniereMesureLe: string | null;
}

export interface PatientDetail {
  id: number; userId: number; numeroDossier: string; nom: string; prenom: string; telephone: string | null;
  email: string | null; dateNaissance: string | null; age: number | null; sexe: string | null; typeDiabete: string;
  tailleCm: number | null; poidsKg: number | null; tourTailleCm: number | null; imc: number | null;
  tensionSystolique: number | null; tensionDiastolique: number | null; antecedentsFamiliaux: boolean;
  couvertureIpm: string | null; quartier: string | null; ville: string | null; region: string | null;
  medecinReferentId: number | null; medecinReferentNom: string | null;
  infirmierRelaisId: number | null; infirmierRelaisNom: string | null; infirmierRelaisTelephone: string | null;
  langueVocale: string; rappelSms: boolean; partageDossier: boolean; cibleMin: number; cibleMax: number;
  derniereHba1c: number | null; contacts: Contact[];
}

export interface Mesure {
  id: number; clientUuid: string; valeur: number; moment: string; methode: string; contexte: string | null;
  note: string | null; mesureLe: string; statut: GStatus; interpretation: string | null; supprime: boolean;
}
export interface GlycemieStats {
  jours: number; moyenne: number | null; nombreMesures: number; pourcentageDansCible: number;
  hypoglycemies: number; mesuresParJour: number; points: Mesure[];
}
export interface RisqueResult {
  id: number; score: number; scoreMax: number; niveau: string; probabilite: string;
  recommandationsCodes: string[]; recommandations: string[]; avertissement: string; date: string; validee: boolean;
}
export interface Traitement {
  id: number; medicament: string; dosage: string | null; posologie: string | null; horaires: string | null;
  dateDebut: string | null; dateFin: string | null; actif: boolean; stockRestant: number | null; prescripteur: string | null;
}
export interface Ordonnance {
  id: number; numero: string; lignes: string; pharmacie: string | null; dateEmission: string; dateExpiration: string;
  dureeMois: number; statut: string; medecin: string;
}
export interface Note { id: number; auteur: string; contenu: string; visibleRelais: boolean; createdAt: string; }
export interface Bilan { id: number; type: string; valeur: number; unite: string | null; dateBilan: string; }
export interface ChatMsg { auteur: string; contenu: string; urgence: boolean; createdAt: string; }
export interface Message { id: number; expediteurId: number; expediteurNom: string; destinataireId: number; contenu: string; lu: boolean; createdAt: string; }

export interface Alerte {
  id: number; patientId: number; patientNom: string; numeroDossier: string; type: string; gravite: string;
  statut: string; message: string; valeur: number | null; createdAt: string; telephonePatient: string | null;
}
export interface Rdv {
  id: number; patientId: number; patientNom: string; medecinId: number; medecinNom: string; dateHeure: string;
  mode: string; motif: string | null; statut: string; lieu: string | null;
}
export interface Intervention {
  id: number; ordre: string; patientId: number; patientNom: string; statut: string; localisation: string;
  repere: string | null; hopitalReception: string | null; declencheParNom: string; createdAt: string;
}

export interface Tir { total: number; normal: number; bas: number; eleve: number; critique: number; pctNormal: number; }
export interface Dashboard {
  patientsSuivis: number; alertesOuvertes: number; alertesUrgentes: number; consultationsDuJour: number;
  consultationsPresentiel: number; consultationsTele: number; risqueAConfirmer: number; tir30Jours: Tir;
}
export interface Observatoire {
  patientsSuivis: number; parRegion: Record<string, number>; parTypeDiabete: Record<string, number>;
  tirNational30Jours: Tir; alertesOuvertes: number;
}
export interface AuditEntry {
  id: number; acteurNom: string; acteurRole: string; typeAction: string; patientId: number | null;
  details: string | null; ip: string | null; horodatage: string; hash: string;
}
export interface PatientSansMedecin extends PatientResume {}
