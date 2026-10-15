import { expect, type Page } from "@playwright/test";

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
