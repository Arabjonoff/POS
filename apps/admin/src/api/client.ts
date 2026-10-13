import createClient from "openapi-fetch";

import type { paths } from "./schema";

/**
 * Django API klienti. Tiplar `schema.d.ts` dan (OpenAPI'dan generatsiya — `npm run api:generate`).
 * `schema.d.ts` qo'lda tahrirlanmaydi.
 */
export function createApiClient(baseUrl: string = process.env.NEXT_PUBLIC_API_URL ?? "") {
  return createClient<paths>({ baseUrl });
}

export type ApiClient = ReturnType<typeof createApiClient>;
