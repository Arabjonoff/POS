import { expect, test } from "@playwright/test";

test("home page opens with navigation", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1, name: "Bosh sahifa" })).toBeVisible();
  await expect(page.getByRole("navigation", { name: "Asosiy menyu" })).toBeVisible();
  await expect(page).toHaveTitle("POS Admin");
});

test("language can be switched to Russian", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("button", { name: "ru" }).click();
  await expect(page.getByRole("heading", { level: 1, name: "Главная" })).toBeVisible();
  await expect(page.locator("html")).toHaveAttribute("lang", "ru");
});

test("dark theme applies the dark class", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("button", { name: "Mavzu" }).click();
  await page.getByRole("menuitemradio", { name: "Qorong'i" }).click();
  await expect(page.locator("html")).toHaveClass(/dark/);
});
