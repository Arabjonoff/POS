import { defineConfig, devices } from "@playwright/test";

const port = Number(process.env.E2E_PORT ?? 3100);
const apiPort = Number(process.env.E2E_API_PORT ?? 3199);
const baseURL = `http://127.0.0.1:${port}`;

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : "list",
  use: { baseURL, trace: "retain-on-failure" },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: [
    {
      // Soxta Django API (auth): haqiqiy backend'siz kirish/chiqish sinovlari.
      command: "node e2e/mock-api.mjs",
      url: `http://127.0.0.1:${apiPort}/health`,
      env: { E2E_API_PORT: String(apiPort) },
      reuseExistingServer: !process.env.CI,
      timeout: 30_000,
    },
    {
      command: `npm run start -- -p ${port} -H 127.0.0.1`,
      url: `${baseURL}/login`,
      env: { API_URL_INTERNAL: `http://127.0.0.1:${apiPort}` },
      reuseExistingServer: !process.env.CI,
      timeout: 120_000,
    },
  ],
});
