import { createApiClient } from "@/api/client";
import type { components } from "@/api/schema";

export type Me = components["schemas"]["Me"];
export type Tokens = { access: string; refresh: string };

/** Serverdan Django'ga (Docker ichida `backend:8000`). */
export function apiBaseUrl(): string {
  return process.env.API_URL_INTERNAL ?? process.env.NEXT_PUBLIC_API_URL ?? "http://127.0.0.1:8000";
}

function api() {
  return createApiClient(apiBaseUrl());
}

export type LoginResult =
  | { ok: true; tokens: Tokens; user: Me }
  | { ok: false; status: number };

/** `POST /api/v1/auth/login/`. Tarmoq xatosi — istisno. */
export async function login(phone: string, password: string): Promise<LoginResult> {
  const { data, response } = await api().POST("/api/v1/auth/login/", {
    body: { phone, password },
    cache: "no-store",
  });
  if (!data) return { ok: false, status: response.status };
  return { ok: true, tokens: { access: data.access, refresh: data.refresh }, user: data.user };
}

/** `POST /api/v1/auth/refresh/` (rotatsiya: yangi refresh ham). Yaroqsiz — `null`. */
export async function refreshTokens(refresh: string): Promise<Tokens | null> {
  const { data } = await api().POST("/api/v1/auth/refresh/", {
    body: { refresh },
    cache: "no-store",
  });
  return data ? { access: data.access, refresh: data.refresh } : null;
}

/** `GET /api/v1/auth/me/`. Token yaroqsiz — `null`. */
export async function fetchMe(access: string): Promise<Me | null> {
  const { data } = await api().GET("/api/v1/auth/me/", {
    headers: { Authorization: `Bearer ${access}` },
    cache: "no-store",
  });
  return data ?? null;
}
