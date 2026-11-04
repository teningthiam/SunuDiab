import { Routes } from '@angular/router';
import { authGuard, homeRedirect, roleGuard } from './core/guards';
import { Shell } from './layout/shell';

export const routes: Routes = [
  { path: 'login', loadComponent: () => import('./pages/login').then((m) => m.LoginPage) },
  {
    path: '',
    component: Shell,
    canActivate: [authGuard],
    children: [
      { path: '', pathMatch: 'full', canActivate: [homeRedirect], children: [] },
      { path: 'dashboard', canActivate: [roleGuard('MEDECIN', 'INFIRMIER_RELAIS')], loadComponent: () => import('./pages/dashboard').then((m) => m.DashboardPage) },
      { path: 'patients', canActivate: [roleGuard('MEDECIN', 'INFIRMIER_RELAIS')], loadComponent: () => import('./pages/patients').then((m) => m.PatientsPage) },
      { path: 'patients/:id', canActivate: [roleGuard('MEDECIN', 'INFIRMIER_RELAIS')], loadComponent: () => import('./pages/patient-detail').then((m) => m.PatientDetailPage) },
      { path: 'alertes', canActivate: [roleGuard('MEDECIN', 'INFIRMIER_RELAIS')], loadComponent: () => import('./pages/alerts').then((m) => m.AlertsPage) },
      { path: 'rendez-vous', canActivate: [roleGuard('MEDECIN', 'INFIRMIER_RELAIS')], loadComponent: () => import('./pages/appointments').then((m) => m.AppointmentsPage) },
      { path: 'observatoire', canActivate: [roleGuard('ADMIN', 'SUPERVISEUR')], loadComponent: () => import('./pages/observatory').then((m) => m.ObservatoryPage) },
      { path: 'admin/utilisateurs', canActivate: [roleGuard('ADMIN')], loadComponent: () => import('./pages/admin-users').then((m) => m.AdminUsersPage) },
      { path: 'admin/patients', canActivate: [roleGuard('ADMIN')], loadComponent: () => import('./pages/admin-patients').then((m) => m.AdminPatientsPage) },
      { path: 'admin/audit', canActivate: [roleGuard('ADMIN')], loadComponent: () => import('./pages/admin-audit').then((m) => m.AdminAuditPage) },
    ],
  },
  { path: '**', redirectTo: '' },
];
