# Mijozlar va nasiya daftari

- Mijoz: ism (majburiy), telefon (ixtiyoriy, unique emas), izoh, qarz limiti.
- Ro'yxat: qarzi borlar tepada, qarz summasi bo'yicha saralash; qidiruv ism/telefon.
- Mijoz kartasi: joriy qarz (katta), tarix (savdo — qarz oshdi; to'lov — kamaydi), xaridlar.
- Qarzga sotish: kassada F4 yoki to'lov oynasida "Nasiya" → mijoz tanlash/tez yaratish → limit tekshiruvi (oshsa — menejer PIN bilan ruxsat).
- To'lov qabul qilish: summa (tez tugma "To'liq"), naqd/karta, chek (ixtiyoriy). DebtEntry(−).
- Qarzga sotilgan savdo qaytarilsa — qarz kamayadi.
- Balans = DebtEntry yig'indisi. Hech qachon qo'lda tahrirlanmaydi; tuzatish — "adjustment" yozuvi sabab bilan (faqat ega).
- Keyinroq: SMS/Telegram eslatma.

## Kassada amalga oshirilishi (T-060)
- **Bo'lim "Mijozlar"** (Ctrl+4) — `apps/pos/lib/features/customers/`:
  - ro'yxat: qarzdorlar tepada (qarz kamayib), keyin ism; qidiruv — ism (lotin/kirill farqsiz) yoki telefon raqamlari; "Qarzi borlar" filtri; jami qarz;
  - "Yangi mijoz" (ism majburiy, telefon) — `customer.upserted`.
- **Mijoz kartasi**:
  - katta qarz summasi, telefon, limit ("cheklovsiz" yoki summa);
  - "Qarzni to'lash", "Tahrirlash";
  - qarz tarixi: sana, turi (nasiyaga savdo / to'lov / qaytarish / tuzatish), savdo raqami, naqd/karta, kim, ±summa;
  - xaridlar (shu kassadagi savdolar).
- **Balans** = qarz daftari (`debt_entries`) yig'indisi: pull'dan kelgan (barcha kassalar) + shu kassada oflayn yozilganlar (`CustomerDirectory`). Daftarda hali yozuv bo'lmasa — serverdagi balans.
- **Qarz to'lovi** (`payDebt`) — bitta tranzaksiya: `DebtEntry(−summa, payment, cash|card, shift)` + outbox `debt.paid` `{id, customer, amount_tiyin, method, note, shift?, at, by}`. Joriy qarzdan ko'p bo'lsa — rad etiladi (avans yo'q, Q-003). Tez tugma — "To'liq". Naqd to'lov smena hisobotidagi kutilgan naqdga qo'shiladi.
- **Tahrirlash**: ism, telefon va izohni istalgan xodim o'zgartiradi. Qarz limiti (bo'sh — cheklovsiz, 0 — nasiya yo'q) — faqat ega/menejer; kassir o'zgartirsa PIN so'raladi. `customer.upserted` da `debt_limit_tiyin` faqat o'zgarganda yuboriladi.
- Kassada mijozni tez tanlash — T-043 (F4 va to'lov oynasidagi "Nasiya").
- Hali yo'q: `adjustment` (faqat ega) kassada — admin/keyin; SMS/Telegram eslatma.

## Boshlang'ich balans (T-103)
- **Yangi mijoz** oynasi: ism (majburiy), telefon (ixtiyoriy), **"Boshlang'ich balans"**: `Yo'q` (standart) / `Mijoz qarzi` / `Mijoz haqi (avans)` —
  har variant ostida ma'nosi yoziladi. Tanlansa: summa (mingliklar bo'shliq bilan, majburiy, > 0) va sana ("Qaysi sanadagi holat", bugungi
  sanadan keyin emas).
- Avansni kassir kiritsa — menejer PIN (`by` = menejer). Mijoz, `opening` yozuvi va hodisa bitta tranzaksiyada (`CustomerDirectory.create`).
- Kartada: manfiy balans — "Mijoz haqi (avans)" va musbat summa (yashil), "Qarzni to'lash" ko'rinmaydi; tarixda "Boshlang'ich qarz" /
  "Boshlang'ich avans". Ro'yxat va to'lov oynasidagi tanlovchida — "Avans: 50 000 so'm".
- To'lov oynasidagi tez yaratish — faqat ism va telefon (savdo 3 harakatda qoladi).
