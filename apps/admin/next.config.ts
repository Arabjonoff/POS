import type { NextConfig } from "next";
import createNextIntlPlugin from "next-intl/plugin";

const withNextIntl = createNextIntlPlugin("./src/i18n/request.ts");

// Admin panel to'liq dinamik (autentifikatsiya, cookie'dagi til), shuning uchun
// cacheComponents yoqilmagan.
const nextConfig: NextConfig = {
  // Monorepo: admin o'z papkasidan tashqaridagi lock fayllarga qaramasin.
  outputFileTracingRoot: process.cwd(),
  turbopack: {
    root: process.cwd(),
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default withNextIntl(nextConfig);
