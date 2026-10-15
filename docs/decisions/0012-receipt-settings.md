# 0012. Chek sozlamalari: do'kon rekvizitlari serverda, printer — kassada

- Holat: qabul qilingan (2026-10-15, T-104)
- Kontekst: loyiha egasi chekda do'kon nomi, logotip, manzil, telefon, soliq rekvizitlari, sarlavha va pastki matnni yoqish/o'chirish va
  o'zgartirishni, jonli ko'rinish va test chekini talab qildi. Ilgari do'kon ma'lumotini faqat platforma admini (Django admin) o'zgartirardi.

## Qaror
1. **Do'kon identifikatori** (nom, yuridik nom, STIR/JShShIR, manzil, telefon, sarlavha, pastki matn, logotip, ko'rsat/yashir) — `Store`
   modelida, hamma kassada bir xil; kassa qayta o'rnatilsa ham yo'qolmaydi. Kassadan `store.upserted` (ega/menejer) — `product.upserted`
   kabi, oflayn-birinchi.
2. **Printer apparati** (ulanish, kenglik, kod sahifasi, kesish...) — har kassada `local_settings` (kassalar har xil printerda).
3. Ko'rsat/yashir — JSON (`receipt_options`), noma'lum kalitlar e'tiborsiz, yo'qlari — ko'rsatiladi: migratsiyasiz kengayadi.
4. Logotip — kulrang PNG (base64) `Store` da; 1 bitga aylantirish chop etish paytida, printer kengligiga qarab. Tashqi rasm kutubxonasi yo'q
   (PNG kodlash/dekodlash — o'zimizning ~150 qator, `dart:io` zlib).
5. Chek ko'rinishi va printer bitta `ReceiptRow` ro'yxatidan — farq qila olmaydi.

## Oqibatlar
- Server avval yangilanadi (`features: store_settings`), aks holda kassada forma o'chiq.
- Grafik (rasm) rejimida butun chekni chop etish (қ ғ ҳ uchun) — keyinroq (Q-011).
