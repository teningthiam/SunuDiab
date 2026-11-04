import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { apiUrl } from './config';

type Params = Record<string, string | number | boolean | null | undefined>;

@Injectable({ providedIn: 'root' })
export class Api {
  private http = inject(HttpClient);

  get<T>(path: string, params?: Params): Promise<T> {
    let hp = new HttpParams();
    for (const [k, v] of Object.entries(params ?? {})) {
      if (v !== undefined && v !== null && v !== '') hp = hp.set(k, String(v));
    }
    return firstValueFrom(this.http.get<T>(apiUrl() + path, { params: hp }));
  }

  post<T>(path: string, body?: unknown): Promise<T> {
    return firstValueFrom(this.http.post<T>(apiUrl() + path, body ?? {}));
  }

  put<T>(path: string, body?: unknown, params?: Params): Promise<T> {
    let hp = new HttpParams();
    for (const [k, v] of Object.entries(params ?? {})) {
      if (v !== undefined && v !== null && v !== '') hp = hp.set(k, String(v));
    }
    return firstValueFrom(this.http.put<T>(apiUrl() + path, body ?? {}, { params: hp }));
  }
}
