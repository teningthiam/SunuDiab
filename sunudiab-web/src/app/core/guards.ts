import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';
import { Role } from './models';

export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  return auth.user() ? true : inject(Router).parseUrl('/login');
};

export const roleGuard = (...roles: Role[]): CanActivateFn => () => {
  const auth = inject(AuthService);
  if (!auth.user()) return inject(Router).parseUrl('/login');
  return auth.hasRole(...roles) ? true : inject(Router).parseUrl(auth.homeRoute());
};

/** Redirige "/" vers la page d'accueil du rôle. */
export const homeRedirect: CanActivateFn = () => {
  const auth = inject(AuthService);
  return inject(Router).parseUrl(auth.user() ? auth.homeRoute() : '/login');
};
