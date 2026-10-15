import createClient from "openapi-fetch";

import type { paths } from "./schema";

/**
 * Django (WSGI, gunicorn) `Transfer-Encoding: chunked` so'rov tanasini o'qimaydi —
 * bo'sh deb qabul qiladi (400). openapi-fetch `Request` obyektini oqim sifatida
 * yuboradi, shuning uchun tana matnga aylantirib (`Content-Length` bilan) jo'natiladi.
 */
export async function fetchWithLength(request: Request): Promise<Response> {
  const body = request.method === "GET" || request.method === "HEAD" ? undefined : await request.text();
  return fetch(request.url, {
    method: request.method,
    headers: request.headers,
    body,
    cache: request.cache,
    signal: request.signal,
    redirect: request.redirect,
  });
}

/**
 * Django API klienti. Tiplar `schema.d.ts` dan (OpenAPI'dan generatsiya — `npm run api:generate`).
 * `schema.d.ts` qo'lda tahrirlanmaydi.
 */
export function createApiClient(baseUrl: string = process.env.NEXT_PUBLIC_API_URL ?? "") {
  return createClient<paths>({ baseUrl, fetch: fetchWithLength });
}

export type ApiClient = ReturnType<typeof createApiClient>;
