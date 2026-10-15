import { expect, test } from "@playwright/test";

import { ADMIN, OWNER, login, loginAsAdmin } from "./helpers";

test("protected pages redirect to the login page", async ({ page }) => {
  await page.goto("/tenants");
  await expect(page).toHaveURL(/\/login\?next=%2Ftenants$/);
  await expect(page.getByRole("heading", { level: 1, name: "Kirish" })).toBeVisible();
});

test("wrong password shows an error and keeps the user out", async ({ page }) => {
  await login(page, { ...ADMIN, password: "notogri" });
  await expect(page.locator("form").getByRole("alert")).toHaveText("Telefon yoki parol noto'g'ri");
  await expect(page).toHaveURL(/\/login/);
  const cookies = await page.context().cookies();
  expect(cookies.map((c) => c.name)).not.toContain("pos_access");
});

test("a shop owner cannot enter the admin panel", async ({ page }) => {
  await login(page, OWNER);
  await expect(page.locator("form").getByRole("alert")).toHaveText("Bu hisob admin paneli uchun emas");
});

test("admin logs in (httpOnly cookies), returns to the page asked for, logs out", async ({ page }) => {
  await loginAsAdmin(page, "/tenants");
  await expect(page).toHaveURL(/\/tenants$/);

  const cookies = await page.context().cookies();
  const access = cookies.find((c) => c.name === "pos_access");
  expect(access?.httpOnly).toBe(true);
  expect(cookies.find((c) => c.name === "pos_refresh")?.httpOnly).toBe(true);
  expect(await page.evaluate(() => document.cookie)).not.toContain("pos_access");

  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1, name: "Bosh sahifa" })).toBeVisible();

  await page.getByRole("button", { name: "Chiqish" }).click();
  await expect(page).toHaveURL(/\/login$/);
  await page.goto("/");
  await expect(page).toHaveURL(/\/login\?next=%2F$/);
});

test("expired access token is renewed with the refresh cookie", async ({ page }) => {
  await loginAsAdmin(page);
  await page.context().clearCookies({ name: "pos_access" });
  await page.goto("/devices");
  await expect(page.getByTestId("admin-name")).toHaveText(ADMIN.name);
  const cookies = await page.context().cookies();
  expect(cookies.find((c) => c.name === "pos_access")?.value).toMatch(/^access-/);
});
