/** Adresse de l'API. Modifiable depuis l'écran de connexion (stockée dans le navigateur). */
export const DEFAULT_API_URL = 'http://localhost:8080';

export function apiUrl(): string {
  try {
    return localStorage.getItem('api_url') || DEFAULT_API_URL;
  } catch {
    return DEFAULT_API_URL;
  }
}
