import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { createApiClient } from "@/api/client";
import type { components } from "@/api/schema";

import { ACCESS_COOKIE, LOGIN_PATH } from "./auth/config";
import { apiBaseUrl } from "./auth/django";

export type Stats = components["schemas"]["Stats"];

/** Serverdagi API xatosi (sahifa `error.tsx` ga tushadi). */
export class PlatformApiError extends Error {
  constructor(readonly status: number) {
    super(`platform api ${status}`);
  }
}

/** Django platforma API'si joriy admin tokeni bilan (faqat server komponentlarda). */
export async function platformApi() {
  const access = (await cookies()).get(ACCESS_COOKIE)?.value;
  if (!access) redirect(LOGIN_PATH);
  const client = createApiClient(apiBaseUrl());
  client.use({
    onRequest({ request }) {
      request.headers.set("Authorization", `Bearer ${access}`);
      return request;
    },
    onResponse({ response }) {
      if (response.status === 401) redirect(LOGIN_PATH);
      return response;
    },
  });
  return client;
}

/** `GET /api/v1/platform/stats/` — bosh sahifa ko'rsatkichlari. */
export async function getStats(): Promise<Stats> {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/stats/", { cache: "no-store" });
  if (!data) throw new PlatformApiError(response.status);
  return data;
}
