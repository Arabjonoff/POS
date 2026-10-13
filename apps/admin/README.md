# apps/admin — admin dashboard (Next.js)

Platforma egasi uchun panel: mijozlar (tenantlar), tariflar, obunalar, to'lovlar, qurilmalar, audit.
Spec: `docs/specs/admin-dashboard.md`.

```sh
npm ci
npm run dev            # http://localhost:3000
npm run lint && npm run typecheck && npm test
npm run build && npm run e2e   # Playwright (127.0.0.1:3100)
npm run api:generate   # backend/openapi.yaml -> src/api/schema.d.ts
```

Matnlar faqat `messages/uz.json` va `messages/ru.json` da.
