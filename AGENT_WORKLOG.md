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
| 1 | Audit (5 yo'nalish: UI/UX, mahsulotlar, kirim, mijozlar, chek/printer) → `PROJECT_AUDIT.md` | ishlanmoqda |
| 2 | P0 tuzatishlar: yashil chaqnash, layout overflow, mahsulot nomi xatolari | — |
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

## Keyingi qadam
- Audit natijalarini `PROJECT_AUDIT.md` ga jamlash, ROADMAP'ga T-100… vazifalarini qo'shish, 2-bosqichdan boshlash.
