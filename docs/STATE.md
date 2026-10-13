# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-005 Next.js admin skeleti
- Branch: feat/T-005-admin-skeleton
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14 01:57

## Qadamlar (vazifa ichida)
- [x] 1. create-next-app (TS, App Router, Tailwind, ESLint, src/)
- [x] 2. shadcn/ui init + asosiy komponentlar, next-themes (yorug'/qorong'i)
- [ ] 3. TanStack Query provider, src/api (openapi-typescript + openapi-fetch), npm run api:generate
- [ ] 4. Layout: sidebar + header, bosh sahifa
- [ ] 5. Vitest (unit) + Playwright smoke testi
- [ ] 6. package.json skriptlari: lint, typecheck, test, build; tekshiruv
- [ ] 7. PR, merge

## Oxirgi bajarilgan ish
shadcn komponentlari qo'shildi (button, card, badge, separator, dropdown-menu, skeleton, tooltip, sheet, input).

## Keyingi aniq harakat
3-qadam: src/api/client.ts va package.json 'api:generate' skripti

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: pos-pg-dev konteyner (postgres:16, 127.0.0.1:55432) — testlar uchun
- Yiqilayotgan testlar: —

## Eslatmalar
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*) tomonidan band. Ularni to'xtatma! POS lokal portlari: postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub; `uv run` yoki `py -3.12` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
