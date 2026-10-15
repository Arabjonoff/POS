# AGENT_WORKLOG — professional darajaga olib chiqish (audit → tuzatish)

> Bu fayl ish jurnali va nazorat nuqtasi. Sessiya uzilsa — avval shu faylni, keyin `docs/STATE.md` ni o'qib, "Keyingi qadam"dan davom et.
> Audit natijalari: `PROJECT_AUDIT.md`. Har bir bosqich alohida branch va PR (squash merge).

## Topshiriq (2026-10-15, loyiha egasi)
Butun ilovani audit qilish va amalda tuzatish: UI/UX (yashil chaqnash, yagona dizayn), mahsulot nomlari, mahsulot rasmi,
kirimni tahrirlash (qoldiq ikki marta hisoblanmasin), mijoz boshlang'ich balansi, chek sozlamalari (preview, test cheki, 58/80 mm),
barcha modullar regressiyasi, testlar, yakuniy hisobot.

## Muhit
- Lokal stack: `docker compose up -d` (backend :8100, admin :3100, postgres :55432). Lokal sinov bazasida "Demo do'kon"
  (10 tovar, ega va kassir) — faqat lokal; parollar repoga yozilmaydi.
- Kassa: `cd apps/pos && flutter run -d windows`.

## Reja (bosqichlar)
| # | Bosqich | Holat |
|---|---|---|
| 1 | Audit (5 yo'nalish) → `PROJECT_AUDIT.md`, `docs/audit/` | ✅ T-100 |
| 2 | P0: yashil chaqnash, overflow, mijoz telefoni, noma'lum mijoz (T-100); sinxron yaxlitligi (T-101) | ✅ T-100, T-101 |
| 3 | Kirimni tahrirlash (teskari yozuv + yangi kirim, atomar) | — |
| 4 | Mijoz boshlang'ich balansi | — |
| 5 | Mahsulot rasmi (server + sinx + kassa) | — |
| 6 | Chek sozlamalari (preview, logo, 58/80 mm, test cheki) | — |
| 7 | Vizual uslub va UX sayqali | — |
| 8 | Regressiya, yakuniy hisobot | — |

## Jurnal
### 2026-10-15
- Lokal backend konteyneri eski kod bilan yiqilgan edi (`ImportError: AppReleaseSerializer`) → `docker compose up -d --build backend admin`.
- Bo'sh lokal bazaga demo ma'lumot qo'shildi.
- Kassa ilovasi Windows'da ishga tushirildi. Logda: `RenderFlex overflowed by 4.0 pixels` — `apps/pos/lib/features/pos/widgets/product_panel.dart:147` (tez tugma kartasi, 2 qatorli nom + narx 88 px ga sig'maydi).
- 5 ta audit subagenti ishga tushirildi (faqat o'qish).

- Audit tugadi (5 hisobot `docs/audit/`). Asosiy topilmalar: yashil chaqnash sababi `PosScanFeedback` (oddiy bosishda ham, butun panel, fon bo'yalgan); server rad etgan tovar/mijoz savdolarni yo'qotadi; NUL belgisi sinxronni to'xtatadi; kirimni tahrirlash/bekor qilish yo'q; chekda preview/logo/STIR yo'q; rasm yo'q.
- T-100 tuzatishlari: chaqnash, overflow, telefon normallashtirish, noma'lum mijoz → pending. Testlar: backend to'liq yashil, pos 627, ui 134.

- T-101: noma'lum tovar → pending, ziddiyatli shtrix-kod tushiriladi, o'chirilgan bog'liqliklar qabul, yopiq smenaga kechikkan hodisa, NUL, nom tozalash/cheklovlar, qayta yuborish paytida pull yo'q. Backend to'liq yashil, pos 630.

## Keyingi qadam
- T-102 Kirimni tahrirlash va bekor qilish — dizayn: `docs/audit/audit_receipts.md` 2-bo'lim.
