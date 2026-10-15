import { expect, test, type APIRequestContext } from "@playwright/test";

import { API, adminToken, createTenantViaApi, loginAsAdmin } from "./helpers";

async function payViaApi(request: APIRequestContext, tenantId: string, months: number) {
  const token = await adminToken(request);
  const response = await request.post(`${API}/api/v1/platform/tenants/${tenantId}/payments/`, {
    headers: { Authorization: `Bearer ${token}` },
    data: { amount_tiyin: 9_900_000 * months, months, method: "cash", note: "" },
  });
  expect(response.status()).toBe(201);
  return response.json() as Promise<{ period_to: string }>;
}

/** `2026-11-30` → `30.11.2026` (ekrandagi kabi). */
const shown = (iso: string) => iso.split("-").reverse().join(".");

test("plans: create, edit price, deactivate", async ({ page }) => {
  const name = `Premium ${Date.now()}`;
  await loginAsAdmin(page, "/plans");
  await expect(page.getByRole("heading", { level: 1, name: "Tariflar" })).toBeVisible();

  await page.getByRole("button", { name: "Yangi tarif" }).click();
  const dialog = page.getByRole("dialog");
  await dialog.getByRole("button", { name: "Saqlash" }).click();
  await expect(dialog.getByText("Nomini kiriting")).toBeVisible();
  await dialog.getByLabel("Nomi").fill(name);
  await dialog.getByLabel("Narx (oyiga)").fill("249 000");
  await dialog.getByLabel("Qurilmalar").fill("5");
  await dialog.getByLabel("Xodimlar").fill("15");
  await dialog.getByRole("button", { name: "Saqlash" }).click();
  await expect(dialog).toBeHidden();

  const row = page.getByTestId("plan-row").filter({ hasText: name });
  await expect(row).toContainText("249 000 so'm");
  await expect(row).toContainText("Faol");

  await row.getByRole("button", { name: "Tahrirlash" }).click();
  await expect(page.getByRole("dialog").getByLabel("Narx (oyiga)")).toHaveValue("249 000");
  await page.getByRole("dialog").getByLabel("Narx (oyiga)").fill("259 000");
  await page.getByRole("dialog").getByRole("button", { name: "Saqlash" }).click();
  await expect(row).toContainText("259 000 so'm");

  await row.getByRole("button", { name: "Nofaol qilish" }).click();
  await page.getByRole("dialog").getByRole("button", { name: "Nofaol qilish" }).click();
  await expect(row).toContainText("Nofaol");
  await expect(row.getByRole("button", { name: "Nofaol qilish" })).toHaveCount(0);
});

test("payment extends the subscription exactly as previewed", async ({ page, request }) => {
  const id = await createTenantViaApi(request, `To'lov ${Date.now()}`);
  await loginAsAdmin(page, `/tenants/${id}?payment=1`);

  const dialog = page.getByRole("dialog");
  await expect(dialog.getByRole("heading", { name: "To'lov kiritish" })).toBeVisible();
  // Tarif (Start, 99 000) × 1 oy taklif qilinadi; 3 oy — 297 000.
  await expect(dialog.getByLabel("Summa (so'm)")).toHaveValue("99 000");
  await dialog.getByRole("button", { name: "3", exact: true }).click();
  await expect(dialog.getByLabel("Summa (so'm)")).toHaveValue("297 000");
  await dialog.getByText("O'tkazma").click();
  await dialog.getByLabel("Izoh").fill("Click orqali");

  const preview = (await dialog.getByTestId("payment-preview").textContent()) ?? "";
  const [, from, to] = /Yangi davr: (\S+) – (\S+)/.exec(preview) ?? [];
  expect(from).toBeTruthy();
  await dialog.getByRole("button", { name: "To'lovni saqlash" }).click();
  await expect(dialog).toBeHidden();

  await expect(page).toHaveURL(/tab=payments/);
  const row = page.getByTestId("payment-row").first();
  await expect(row).toContainText("297 000 so'm");
  await expect(row).toContainText(`${from} – ${to}`);
  await expect(row).toContainText("O'tkazma");
  await expect(row).toContainText("Click orqali");

  await page.getByRole("link", { name: "Umumiy" }).click();
  await expect(page.getByText(to, { exact: true })).toBeVisible();
  await expect(page.getByRole("heading", { level: 1 }).locator("..").getByText("Faol")).toBeVisible();
});

test("only the latest payment can be reversed; paid-until goes back", async ({ page, request }) => {
  const id = await createTenantViaApi(request, `Bekor ${Date.now()}`);
  const first = await payViaApi(request, id, 1);
  await payViaApi(request, id, 2);
  await loginAsAdmin(page, `/tenants/${id}?tab=payments`);

  const rows = page.getByTestId("payment-row");
  await expect(rows).toHaveCount(2);
  await expect(rows.nth(1).getByRole("button", { name: "Bekor qilish" })).toHaveCount(0);
  await rows.first().getByRole("button", { name: "Bekor qilish" }).click();

  const dialog = page.getByRole("dialog");
  await dialog.getByRole("button", { name: "To'lovni bekor qilish" }).click();
  await expect(dialog.getByText("Sababni yozing")).toBeVisible();
  await dialog.getByLabel("Sabab").fill("Xato kiritilgan");
  await dialog.getByRole("button", { name: "To'lovni bekor qilish" }).click();
  await expect(dialog).toBeHidden();

  await expect(rows).toHaveCount(3);
  await expect(rows.first()).toContainText("−198 000 so'm");
  await expect(rows.first()).toContainText("Xato kiritilgan");
  await expect(rows.nth(1)).toContainText("Bekor qilingan");
  // Endi birinchi to'lov oxirgisi — uni bekor qilsa bo'ladi.
  await expect(rows.nth(2).getByRole("button", { name: "Bekor qilish" })).toBeVisible();

  await page.getByRole("link", { name: "Umumiy" }).click();
  await expect(page.getByText(shown(first.period_to), { exact: true })).toBeVisible();
});

test("payments list: date range, total and tenant link", async ({ page }) => {
  await loginAsAdmin(page, "/payments");
  await expect(page.getByRole("heading", { level: 1, name: "To'lovlar" })).toBeVisible();
  await page.getByLabel("Sanadan").fill("2026-09-01");
  await page.getByLabel("Sanagacha").fill("2026-09-30");
  await page.getByRole("button", { name: "Ko'rsatish" }).click();
  await expect(page).toHaveURL(/date_from=2026-09-01&date_to=2026-09-30/);
  await expect(page.getByTestId("payment-row")).toHaveCount(1);
  await expect(page.getByTestId("payment-row")).toContainText("Baraka do'koni");
  await expect(page.getByTestId("payments-total")).toHaveText("Jami (netto): 99 000 so'm");

  await page.getByRole("link", { name: "Baraka do'koni" }).click();
  await expect(page).toHaveURL(/\/tenants\/.+\?tab=payments$/);
});
