import { cookies } from "next/headers";
import { notFound, redirect } from "next/navigation";

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

export type TenantRow = components["schemas"]["TenantList"];
export type TenantDetail = components["schemas"]["TenantDetail"];
export type Plan = components["schemas"]["Plan"];
export type StaffUser = components["schemas"]["UserBrief"];
export type PlatformDevice = components["schemas"]["PlatformDevice"];
export type Payment = components["schemas"]["Payment"];
export type SyncEvent = components["schemas"]["SyncEvent"];
export type TenantStatus = "trial" | "active" | "grace" | "readonly" | "blocked";

export const TENANT_STATUSES: TenantStatus[] = ["trial", "active", "grace", "readonly", "blocked"];
export const PAGE_SIZE = 25;

function ensure<T>(data: T | undefined, response: Response): T {
  if (data === undefined) {
    if (response.status === 404) notFound();
    throw new PlatformApiError(response.status);
  }
  return data;
}

/** `GET /platform/tenants/` — qidiruv (nom/telefon), holat, sahifa. */
export async function listTenants(query: { search?: string; status?: TenantStatus; page?: number }) {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/tenants/", {
    params: {
      query: {
        search: query.search || undefined,
        status: query.status,
        page: query.page && query.page > 1 ? query.page : undefined,
        page_size: PAGE_SIZE,
      },
    },
    cache: "no-store",
  });
  return ensure(data, response);
}

export async function getTenant(id: string): Promise<TenantDetail> {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/tenants/{id}/", {
    params: { path: { id } },
    cache: "no-store",
  });
  return ensure(data, response);
}

/** Faol tariflar (yangi mijoz ustasi uchun). */
export async function listPlans(): Promise<Plan[]> {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/plans/", {
    params: { query: { page_size: 100 } },
    cache: "no-store",
  });
  return ensure(data, response).results.filter((p) => p.is_active !== false);
}

export async function tenantUsers(id: string): Promise<StaffUser[]> {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/tenants/{id}/users/", {
    params: { path: { id }, query: { page_size: 100 } },
    cache: "no-store",
  });
  return ensure(data, response).results;
}

export async function tenantDevices(id: string): Promise<PlatformDevice[]> {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/devices/", {
    params: { query: { tenant: id, page_size: 100 } },
    cache: "no-store",
  });
  return ensure(data, response).results;
}

export async function tenantPayments(id: string) {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/payments/", {
    params: { query: { tenant: id, page_size: 100 } },
    cache: "no-store",
  });
  return ensure(data, response);
}

export async function tenantSyncEvents(id: string): Promise<SyncEvent[]> {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/tenants/{id}/sync-events/", {
    params: { path: { id }, query: { page_size: 50 } },
    cache: "no-store",
  });
  return ensure(data, response).results;
}

/** Barcha tariflar (nofaollari ham) — "Tariflar" sahifasi uchun. */
export async function listAllPlans(): Promise<Plan[]> {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/plans/", {
    params: { query: { page_size: 100 } },
    cache: "no-store",
  });
  return ensure(data, response).results;
}

/** `GET /platform/payments/` — sana oralig'i (Toshkent, `paid_at`), sahifa; javobda `total_tiyin`. */
export async function listPayments(query: { dateFrom?: string; dateTo?: string; page?: number }) {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/payments/", {
    params: {
      query: {
        date_from: query.dateFrom || undefined,
        date_to: query.dateTo || undefined,
        page: query.page && query.page > 1 ? query.page : undefined,
        page_size: PAGE_SIZE,
      },
    },
    cache: "no-store",
  });
  return ensure(data, response);
}

export type AuditEntry = components["schemas"]["AuditLog"];

/** `GET /platform/devices/` — `stale_days` (oxirgi sinxron N kundan oldin yoki umuman yo'q), `blocked`. */
export async function listDevices(query: { staleDays?: number; blocked?: boolean; page?: number }) {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/devices/", {
    params: {
      query: {
        stale_days: query.staleDays,
        blocked: query.blocked,
        page: query.page && query.page > 1 ? query.page : undefined,
        page_size: PAGE_SIZE,
      },
    },
    cache: "no-store",
  });
  return ensure(data, response);
}

/** `GET /platform/audit-log/` — yangisi birinchi. */
export async function listAuditLog(query: {
  action?: string;
  targetType?: string;
  tenant?: string;
  page?: number;
}) {
  const api = await platformApi();
  const { data, response } = await api.GET("/api/v1/platform/audit-log/", {
    params: {
      query: {
        action: query.action || undefined,
        target_type: query.targetType || undefined,
        tenant: query.tenant || undefined,
        page: query.page && query.page > 1 ? query.page : undefined,
        page_size: PAGE_SIZE,
      },
    },
    cache: "no-store",
  });
  return ensure(data, response);
}
