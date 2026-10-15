import { expect, test } from "@playwright/test";

import { API, adminToken, createTenantViaApi, loginAsAdmin } from "./helpers";

// Qurilmalar umumiy (seed) — filtr va bloklash bitta testda, ketma-ket.
test("devices: stale and blocked filters, block with a reason, unblock", async ({ page }) => {
  await loginAsAdmin(page, "/devices");
  await expect(page.getByRole("heading", { level: 1, name: "Qurilmalar" })).toBeVisible();
  const rows = page.getByTestId("device-row");
  await expect(rows).toHaveCount(3);
  await expect(rows.filter({ hasText: "Eski planshet" })).toContainText("Hech qachon");

  await page.getByRole("link", { name: "3 kundan beri sinxronlanmagan" }).click();
  await expect(page).toHaveURL(/stale_days=3/);
  await expect(rows).toHaveCount(2);
  await expect(rows.filter({ hasText: "Kassa 1" })).toHaveCount(0);

  await page.getByRole("link", { name: "Bloklangan" }).click();
  await expect(page).toHaveURL(/blocked=true/);
  await expect(rows).toHaveCount(1);
  await expect(rows).toContainText("Eski planshet");

  await page.getByRole("link", { name: "Hammasi" }).click();
  const kassa = rows.filter({ hasText: "Oila kassa" });
  await kassa.getByRole("button", { name: "Bloklash" }).click();
  const dialog = page.getByRole("dialog");
  await expect(dialog.getByRole("heading", { name: "Qurilmani bloklash" })).toBeVisible();
  await dialog.getByRole("button", { name: "Bloklash" }).click();
  await expect(dialog.getByText("Sababni yozing")).toBeVisible();
  await dialog.getByLabel("Sabab").fill("Planshet yo'qolgan");
  await dialog.getByRole("button", { name: "Bloklash" }).click();
  await expect(dialog).toBeHidden();
  await expect(kassa).toContainText("Bloklangan");

  await kassa.getByRole("button", { name: "Blokdan chiqarish" }).click();
  await page.getByRole("dialog").getByRole("button", { name: "Blokdan chiqarish" }).click();
  await expect(page.getByRole("dialog")).toBeHidden();
  await expect(kassa).toContainText("Faol");

  // Ikkala amal audit jurnalida, sabab bilan.
  await page.goto("/audit?target_type=device");
  const entries = page.getByTestId("audit-row");
  await expect(entries.first()).toContainText("Qurilma blokdan chiqarildi");
  await expect(entries.filter({ hasText: "Qurilma bloklandi" }).first()).toContainText("Planshet yo'qolgan");
});

test("audit log: tenant entries with changes, action filter", async ({ page, request }) => {
  const id = await createTenantViaApi(request, `Audit ${Date.now()}`);
  const token = await adminToken(request);
  const response = await request.post(`${API}/api/v1/platform/tenants/${id}/block/`, {
    headers: { Authorization: `Bearer ${token}` },
    data: { reason: "Tekshiruv" },
  });
  expect(response.ok()).toBe(true);

  await loginAsAdmin(page, `/audit?tenant=${id}`);
  await expect(page.getByRole("heading", { level: 1, name: "Audit jurnali" })).toBeVisible();
  const rows = page.getByTestId("audit-row");
  await expect(rows).toHaveCount(2);
  await expect(rows.first()).toContainText("Mijoz bloklandi");
  await expect(rows.first()).toContainText("Platforma Admin");
  await expect(rows.first()).toContainText("Sabab: Tekshiruv");
  await expect(rows.nth(1)).toContainText("Mijoz yaratildi");

  await rows.first().getByText("2 ta o'zgarish").click();
  await expect(rows.first()).toContainText("is_blocked");
  await expect(rows.first()).toContainText("false → true");

  await rows.first().getByRole("link", { name: "Mijoz sahifasi" }).click();
  await expect(page).toHaveURL(new RegExp(`/tenants/${id}$`));

  await page.goto("/audit");
  await page.getByRole("combobox", { name: "Amal" }).click();
  await page.getByRole("option", { name: "Mijoz bloklandi" }).click();
  await expect(page).toHaveURL(/action=tenant\.block/);
  const filtered = page.getByTestId("audit-row");
  await expect(filtered.first()).toBeVisible();
  for (const text of await filtered.allTextContents()) expect(text).toContain("Mijoz bloklandi");
});
