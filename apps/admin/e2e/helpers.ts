import { expect, type APIRequestContext, type Page } from "@playwright/test";

export const ADMIN = { phone: "90 123 45 67", password: "admin-parol", name: "Platforma Admin" };
export const OWNER = { phone: "90 765 43 21", password: "ega-parol" };

export async function login(
  page: Page,
  account: { phone: string; password: string } = ADMIN,
  path = "/",
) {
  await page.goto(path);
  await page.getByLabel("Telefon").fill(account.phone);
  await page.getByLabel("Parol").fill(account.password);
  await page.getByRole("button", { name: "Kirish" }).click();
}

export async function loginAsAdmin(page: Page, path = "/") {
  await login(page, ADMIN, path);
  await expect(page.getByTestId("admin-name")).toHaveText(ADMIN.name);
}

export const API = `http://127.0.0.1:${process.env.E2E_API_PORT ?? 3199}`;

/** Parallel testlar to'qnashmasin: har chaqiruvda yangi 9 xonali raqam. */
export function uniquePhone(): string {
  const n = String(Date.now() % 10_000_000).padStart(7, "0");
  const r = String(Math.floor(Math.random() * 90) + 10);
  return `${r} ${n.slice(0, 3)} ${n.slice(3, 5)} ${n.slice(5)}`;
}

export async function adminToken(request: APIRequestContext): Promise<string> {
  const response = await request.post(`${API}/api/v1/auth/login/`, {
    data: { phone: "90 123 45 67", password: "admin-parol" },
  });
  return (await response.json()).access;
}

export async function createTenantViaApi(request: APIRequestContext, name: string): Promise<string> {
  const token = await adminToken(request);
  const response = await request.post(`${API}/api/v1/platform/tenants/`, {
    headers: { Authorization: `Bearer ${token}` },
    data: {
      name,
      owner: { phone: uniquePhone(), full_name: "Sinov Ega" },
      plan: "00000000-0000-7000-8000-0000000000p1",
      trial_days: 14,
    },
  });
  expect(response.status()).toBe(201);
  return (await response.json()).tenant.id;
}
