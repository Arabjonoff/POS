# 0010. Kirimni tahrirlash — teskari yozuv + yangi versiya

- Holat: qabul qilingan (2026-10-15, T-102)
- Kontekst: loyiha egasi tasdiqlangan kirimni tahrirlashni talab qildi (10 → 7 o'zgartirilganda qoldiq ikki marta oshmasin, balanslar
  takror hisoblanmasin). CLAUDE.md 3-qoida: kirim o'zgarmas, faqat teskari yozuv. Kassa oflayn ishlaydi, bir nechta kassa bor.

## Qaror
1. Tahrirlash = **tuzatish**: asl kirim teskari yozuv bilan bekor qilinadi (manfiy qatorlar va harakatlar) va yangi versiya
   (`corrects` → asl) tasdiqlanadi. Asl yozuv, uning qatorlari va harakatlari hech qachon o'zgarmaydi.
2. Kassada bitta tranzaksiya va bitta outbox hodisasi (`receipt.corrected`); bekor qilish — `receipt.reversed`. Barcha harakatlar shu
   hodisaga bog'langan, shuning uchun qoldiq "server + yuborilmagan" formulasida bir marta hisoblanadi.
3. Server ziddiyatda **rad etmaydi**: zanjirning oxirgi versiyasi bekor qilinib, kelgan versiya qo'yiladi va `conflict` belgilanadi.
   Rad etish kassa qoldig'ini server bilan abadiy farq qildirardi.
4. Yangi versiyaning hujjat sanasi — asl kirimniki; tannarx faqat bu kirimdan keyin boshqa amaldagi kirim bo'lmasa yangilanadi.
5. Kassa yangi hodisani faqat server pull javobida `features: ["receipt_corrections"]` ni e'lon qilsa yuboradi (10-qoida). Avval server
   yangilanadi.

## Oqibatlar
- Tarix to'liq: ro'yxatda "Tuzatilgan" / "Tuzatish" / "Bekor qilingan".
- Oldingi savdolarning tannarxi qayta hisoblanmaydi.
- Yetkazib beruvchi qarzi hozir yo'q; qo'shilsa — kirimga bog'langan o'zgarmas jurnal, tuzatishda teskari + yangi yozuv.
- Boshqa kassada yaratilgan kirimlar hali ko'rinmaydi (pull entity `stock_receipt` — keyinroq).
