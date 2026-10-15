# 0011. Mijozning boshlang'ich balansi — `opening` qarz yozuvi

- Holat: qabul qilingan (2026-10-15, T-103)
- Kontekst: ilova ilgari ishlagan do'konga o'rnatiladi; mijozlarning eski qarzi yoki oldindan to'lagan pullari bor. Loyiha egasi buni
  "bitta tushunarsiz raqam" emas, yo'nalishi aniq, tarixda ko'rinadigan va tahrirda takrorlanmaydigan qilib kiritishni talab qildi.

## Qaror
1. Yangi qarz turi `opening` (±): `+` — mijoz qarzi, `−` — avans (do'kon mijozga qarzdor). Mavjud o'zgarmas qarz daftariga qo'shiladi —
   balans formulasi (yozuvlar yig'indisi) o'zgarmaydi.
2. Faqat mijoz **yaratilganda**, mijoz bilan bitta tranzaksiyada va bitta `customer.upserted` hodisasida (`opening_balance`). Tahrir yo'li
   uni yozmaydi; server tahrirda rad etadi; DB'da bitta mijozga bitta `opening` (qisman unique indeks).
3. Savdo va smenaga bog'lanmaydi: tushum, foyda, Z-hisobot naqdiga kirmaydi.
4. Avans — faqat ega/menejer (firibgarlik xavfi). Bu Q-003 ("avans yo'q") ning qisman javobi: avans faqat boshlang'ich balans sifatida;
   ortiqcha to'lov hali ham qabul qilinmaydi.
5. Yuborishda yo'nalish va musbat summa (`direction`, `amount_tiyin`) — belgi xatosi bo'lmasin.

## Oqibatlar
- Eski kassa `opening` yozuvini pull qilsa, balans to'g'ri yig'iladi, tarixda "Tuzatish" deb ko'rinadi.
- Qarzlar hisobotida avans alohida (`total_credit_tiyin`, `creditors_count`, ixtiyoriy maydonlar).
- Avansni naqd qaytarish oqimi yo'q (kerak bo'lsa — keyin, alohida teskari yozuv).
