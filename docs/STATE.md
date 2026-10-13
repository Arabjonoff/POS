# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-006 Flutter skeleti
- Branch: feat/T-006-flutter-skeleton
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14 02:02

## Qadamlar (vazifa ichida)
- [ ] 1. flutter create apps/pos (windows, android, ios), workspace'ga qo'shish
- [ ] 2. Bog'liqliklar: flutter_riverpod, go_router, drift, drift_flutter, flutter_localizations, intl; very_good_analysis
- [ ] 3. ARB (uz, uz_Cyrl, ru) + gen-l10n, l10n.yaml
- [ ] 4. Ilova: main.dart, App (MaterialApp.router), router, bo'sh kassa ekrani
- [ ] 5. Drift: bo'sh AppDatabase (keyin T-032), provider
- [ ] 6. packages/ui widgetbook ilovasi
- [ ] 7. Testlar: widget test (ilova ochiladi, 3 til); flutter analyze toza
- [ ] 8. flutter build windows tekshiruvi; PR, merge

## Oxirgi bajarilgan ish
Vazifa boshlandi.

## Keyingi aniq harakat
1-qadam: rm apps/pos/README.md; flutter create --org uz.zellypos --platforms windows,android,ios --project-name pos_app apps/pos

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: pos-pg-dev konteyner (postgres:16, 127.0.0.1:55432) — testlar uchun
- Yiqilayotgan testlar: —

## Eslatmalar
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*) tomonidan band. Ularni to'xtatma! POS lokal portlari: postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub; `uv run` yoki `py -3.12` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
