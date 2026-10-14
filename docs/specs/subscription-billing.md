# Obuna (abonent to'lovi)

## Holatlar (har kuni va har so'rovda hisoblanadi)
| Holat | Shart | Ilovada |
|---|---|---|
| trial | now < trial_ends_at va to'lov yo'q | To'liq ishlaydi; "Sinov: N kun qoldi" banneri |
| active | now ≤ paid_until | To'liq; tugashiga ≤ 3 kun qolganda sariq banner |
| grace | paid_until < now ≤ paid_until + grace_days | To'liq; qizil banner "To'lov muddati o'tdi, N kun ichida to'lang" |
| readonly | grace'dan keyin | Savdo/kirim o'chiq; ko'rish, hisobot, sinxron, eksport ishlaydi |
| blocked | admin qo'lda | readonly bilan bir xil + kirish ekranida sabab |

## To'lov kiritish (admin)
- Summa, oylar soni (tarif narxi × oy taklif qilinadi), usul, izoh.
- `period_from = max(paid_until, today)`, `period_to = period_from + oylar`; `paid_until = period_to`.
- To'lovni bekor qilish — teskari yozuv, audit jurnalida.

## Cheklovlar
- `max_devices`: yangi qurilma ro'yxatdan o'tmaydi, aniq xabar.
- `max_users`: yangi xodim qo'shilmaydi.
- Ma'lumot hech qachon o'chirilmaydi (obuna tugasa ham).

## Testlar
Sanalar bo'yicha parametrlangan: sinov ichida, sinov tugagan, to'langan, 3 kun qolgan, grace 1-kun, grace oxirgi kun, readonly, bloklangan, to'lovdan keyin qayta active.

## Sanalar (T-013 aniqlashtirish)
- Hamma sanalar — kun (`date`), tenant vaqt zonasida (`Tenant.timezone`, standart `Asia/Tashkent`). "Bugun" = shu zonadagi joriy sana.
- `trial_ends_at` — sinovning **birinchi to'lanmagan kuni** (14 kunlik sinov 1-oktabrda boshlansa — 15-oktabr). Sinov: `bugun < trial_ends_at`.
- `paid_until` — to'langan **oxirgi kun** (shu kun ham ishlaydi). Active: `bugun ≤ paid_until`.
- Grace: `qoplangan_oxirgi_kun < bugun ≤ qoplangan_oxirgi_kun + grace_days`. Qoplangan oxirgi kun = `paid_until`, to'lov bo'lmasa `trial_ends_at − 1 kun` (Q-001, A).
- Obunasi yo'q tenant — readonly. `Tenant.is_blocked` — har doim blocked.
- To'lov: `period_from = max(paid_until, trial_ends_at, bugun)` (Q-002, B), `period_to = period_from + oylar` (oy oxiri qisqartiriladi: 31-yanvar + 1 oy = 28/29-fevral).
- Bekor qilish: faqat oxirgi bekor qilinmagan to'lov; teskari yozuv (manfiy summa va oy), `paid_until` to'lovdan oldingi qiymatga qaytadi.
- `Subscription.status` — kesh (admin ro'yxati va filtrlash uchun); manba — `compute_status`. Kunlik `manage.py update_subscriptions` keshni yangilaydi.
