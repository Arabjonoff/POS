import { expect, test } from "@playwright/test";

import { login, loginAsAdmin } from "./helpers";

test("dashboard shows KPIs, expiring subscriptions and stale devices", async ({ page }) => {
  await loginAsAdmin(page);
  await expect(page.getByTestId("kpi-active")).toContainText("7");
  await expect(page.getByTestId("kpi-active")).toContainText("Jami 12");
  await expect(page.getByTestId("kpi-trial")).toContainText("3");
  await expect(page.getByTestId("kpi-mrr")).toContainText("1 350 000 so'm");
  await expect(page.getByTestId("kpi-revenue")).toContainText("450 000 so'm");

  const expiring = page.getByTestId("expiring").getByRole("listitem");
  await expect(expiring).toHaveCount(2);
  await expect(expiring.first()).toContainText("Baraka do'koni");
  await expect(expiring.first()).toContainText("16.10.2026 gacha to'langan");
  await expect(expiring.first().getByRole("link", { name: "To'lov kiritish" })).toHaveAttribute(
    "href",
    /\/tenants\/.+\?payment=1$/,
  );

  await expect(page.getByTestId("stale-devices")).toContainText("2 ta qurilma sinxronlanmagan");
  await expect(page.getByTestId("revenue-chart").locator(".recharts-bar-rectangle")).toHaveCount(12);
});

test("dashboard in Russian", async ({ page }) => {
  await loginAsAdmin(page);
  await page.getByRole("button", { name: "ru" }).click();
  await expect(page.getByRole("heading", { level: 1, name: "Главная" })).toBeVisible();
  await expect(page.getByTestId("kpi-mrr")).toContainText("1 350 000 сум");
  await expect(page.getByTestId("stale-devices")).toContainText("2 устройства не синхронизированы");
});

test("server error shows a retry screen, not a crash", async ({ page }) => {
  await login(page, { phone: "91 111 11 11", password: "admin-parol" });
  await expect(page.getByRole("heading", { name: "Ma'lumotni yuklab bo'lmadi" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Qayta urinish" })).toBeVisible();
});
