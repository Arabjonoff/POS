import { expect, test } from "@playwright/test";

import { loginAsAdmin } from "./helpers";

// UI tekshiruvi (T-091): har sahifa telefon kengligida (390 px) va rus tilida
// gorizontal surilmaydi (jadvallar o'z konteynerida suriladi) va sarlavhasi bor.
const PAGES = ["/", "/tenants", "/tenants/new", "/plans", "/payments", "/devices", "/audit", "/settings"];

for (const locale of ["uz", "ru"] as const) {
  test(`${locale}: every page fits a 390 px phone`, async ({ page, context }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await loginAsAdmin(page);
    // Til — kirgandan keyin (kirish yordamchisi o'zbekcha yorliqlarni izlaydi).
    await context.addCookies([{ name: "locale", value: locale, url: page.url() }]);
    for (const path of PAGES) {
      await page.goto(path);
      await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
      );
      expect(overflow, `${locale} ${path}`).toBeLessThanOrEqual(1);
    }
  });
}
