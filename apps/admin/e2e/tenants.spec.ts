import { expect, test, type APIRequestContext } from "@playwright/test";

import { loginAsAdmin } from "./helpers";

const API = `http://127.0.0.1:${process.env.E2E_API_PORT ?? 3199}`;

/** Parallel testlar to'qnashmasin: har chaqiruvda yangi 9 xonali raqam. */
function uniquePhone(): string {
  const n = String(Date.now() % 10_000_000).padStart(7, "0");
  const r = String(Math.floor(Math.random() * 90) + 10);
  return `${r} ${n.slice(0, 3)} ${n.slice(3, 5)} ${n.slice(5)}`;
}

async function adminToken(request: APIRequestContext): Promise<string> {
  const response = await request.post(`${API}/api/v1/auth/login/`, {
    data: { phone: "90 123 45 67", password: "admin-parol" },
  });
  return (await response.json()).access;
}

async function createTenantViaApi(request: APIRequestContext, name: string): Promise<string> {
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

test("list: search and status filter", async ({ page }) => {
  await loginAsAdmin(page, "/tenants");
  await expect(page.getByRole("heading", { level: 1, name: "Mijozlar" })).toBeVisible();
  await expect(page.getByTestId("tenant-row").filter({ hasText: "Baraka do'koni" })).toBeVisible();

  await page.getByRole("searchbox", { name: "Do'kon nomi yoki telefon" }).fill("oila");
  await expect(page).toHaveURL(/search=oila/);
  await expect(page.getByTestId("tenant-row")).toHaveCount(1);
  await expect(page.getByTestId("tenant-row")).toContainText("Oila market");
  await expect(page.getByTestId("tenant-row")).toContainText("Sinovda");

  await page.getByRole("searchbox").fill("");
  await page.getByRole("combobox", { name: "Holat" }).click();
  await page.getByRole("option", { name: "Bloklangan" }).click();
  await expect(page).toHaveURL(/status=blocked/);
  await expect(page.getByTestId("tenant-row").filter({ hasText: "Yulduz" })).toBeVisible();
  await expect(page.getByTestId("tenant-row").filter({ hasText: "Baraka do'koni" })).toHaveCount(0);
});

test("new tenant wizard → shows credentials → in the list → owner can log in", async ({ page, request }) => {
  const name = `Sinov do'koni ${Date.now()}`;
  const phone = uniquePhone();
  await loginAsAdmin(page, "/tenants");
  await page.getByRole("link", { name: "Yangi mijoz" }).click();
  await expect(page.getByRole("heading", { level: 1, name: "Yangi mijoz" })).toBeVisible();

  await page.getByRole("button", { name: "Davom etish" }).click();
  await expect(page.getByText("Do'kon nomini kiriting")).toBeVisible();
  await page.getByLabel("Do'kon nomi").fill(name);
  await page.getByLabel("Manzil").fill("Chilonzor 5");
  await page.getByRole("button", { name: "Davom etish" }).click();

  await page.getByLabel("Ega telefoni").fill(phone);
  await page.getByLabel("Ega ismi").fill("Yangi Ega");
  await page.getByRole("button", { name: "Davom etish" }).click();

  await expect(page.getByRole("radio", { name: "Start" })).toBeChecked();
  await expect(page.getByText("Eski")).toHaveCount(0); // nofaol tarif ko'rinmaydi
  await page.getByRole("button", { name: "Mijozni yaratish" }).click();

  const result = page.getByTestId("onboard-result");
  await expect(result).toContainText("Mijoz yaratildi");
  await expect(result).toContainText(name);
  const password = (await page.getByTestId("temporary-password").textContent())?.trim() ?? "";
  expect(password).toMatch(/^Tmp-/);

  // Ega kassa ilovasiga shu ma'lumotlar bilan kira oladi (API darajasida).
  const login = await request.post(`${API}/api/v1/auth/login/`, { data: { phone, password } });
  expect(login.status()).toBe(200);
  expect((await login.json()).user.role).toBe("owner");

  await page.goto(`/tenants?search=${encodeURIComponent(name)}`);
  await expect(page.getByTestId("tenant-row")).toHaveCount(1);
  await expect(page.getByTestId("tenant-row")).toContainText("Yangi Ega");
});

test("wizard: a taken phone returns to the owner step", async ({ page }) => {
  await loginAsAdmin(page, "/tenants/new");
  await page.getByLabel("Do'kon nomi").fill(`Takror ${Date.now()}`);
  await page.getByRole("button", { name: "Davom etish" }).click();
  await page.getByLabel("Ega telefoni").fill("90 765 43 21");
  await page.getByLabel("Ega ismi").fill("Kimdir");
  await page.getByRole("button", { name: "Davom etish" }).click();
  await page.getByRole("button", { name: "Mijozni yaratish" }).click();
  await expect(page.getByText("Bu telefon allaqachon ro'yxatdan o'tgan")).toBeVisible();
  await expect(page.getByLabel("Ega telefoni")).toBeVisible();
});

test("block with a reason, then unblock", async ({ page, request }) => {
  const id = await createTenantViaApi(request, `Bloklash ${Date.now()}`);
  await loginAsAdmin(page, `/tenants/${id}`);

  await page.getByRole("button", { name: "Bloklash" }).click();
  const dialog = page.getByRole("dialog");
  await dialog.getByRole("button", { name: "Bloklash" }).click();
  await expect(dialog.getByText("Sababni yozing")).toBeVisible();
  await dialog.getByLabel("Sabab").fill("Qarzdorlik");
  await dialog.getByRole("button", { name: "Bloklash" }).click();
  await expect(dialog).toBeHidden();
  await expect(page.getByRole("status")).toContainText("Mijoz bloklangan. Sabab: Qarzdorlik");

  await page.getByRole("button", { name: "Blokdan chiqarish" }).click();
  await page.getByRole("dialog").getByRole("button", { name: "Blokdan chiqarish" }).click();
  await expect(page.getByRole("dialog")).toBeHidden();
  await expect(page.getByRole("status")).toHaveCount(0);
  await expect(page.getByRole("button", { name: "Bloklash" })).toBeVisible();
});

test("tenant tabs: payments with total, devices, users", async ({ page }) => {
  await loginAsAdmin(page, "/tenants?search=baraka");
  await page.getByRole("link", { name: "Baraka do'koni" }).click();
  await expect(page.getByRole("heading", { level: 1, name: "Baraka do'koni" })).toBeVisible();

  await page.getByRole("link", { name: "To'lovlar" }).last().click();
  await expect(page).toHaveURL(/tab=payments/);
  await expect(page.getByTestId("payment-row")).toHaveCount(2);
  await expect(page.getByText("Jami: 198 000 so'm")).toBeVisible();

  await page.getByRole("link", { name: "Qurilmalar" }).last().click();
  await expect(page.getByTestId("device-row")).toContainText("Kassa 1");

  await page.getByRole("link", { name: "Foydalanuvchilar" }).click();
  // Kassir PIN bilan kiradi — parol tiklash tugmasi yo'q.
  const cashier = page.getByTestId("user-row").filter({ hasText: "Aziza" });
  await expect(cashier.getByRole("button", { name: "Parolni tiklash" })).toHaveCount(0);
});

test("owner password reset shows a new temporary password", async ({ page, request }) => {
  // O'z mijozimiz: boshqa testlardagi ega paroli o'zgarmasin.
  const id = await createTenantViaApi(request, `Parol ${Date.now()}`);
  await loginAsAdmin(page, `/tenants/${id}?tab=users`);
  const owner = page.getByTestId("user-row").filter({ hasText: "Sinov Ega" });
  await owner.getByRole("button", { name: "Parolni tiklash" }).click();
  await page.getByRole("dialog").getByRole("button", { name: "Tiklash" }).click();
  await expect(page.getByTestId("new-password")).toHaveText(/^Tmp-/);
});
