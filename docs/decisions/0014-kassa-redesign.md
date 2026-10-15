# 0014. Kassa ekrani yangi dizayni — tugmalar, to'lov va mijoz qatorlari

- Holat: qabul qilingan (2026-10-15, T-108; loyiha egasi eskizni tasdiqladi — "Takliflaringiz ma'qul")
- Eskiz: https://claude.ai/artifact/321zbc39k53LuPjnmgrjhT (1920×1080, 1366×768, to'lov oynasi, qorong'i/oflayn)
- Kontekst: loyiha egasi kassa ekranini qayta loyihalashni so'radi (yig'iladigan menyu, tovar kartalari panjarasi,
  F9/F10/F11 bir bosishli to'lov, QQS qatori, mijoz bonusi). Ba'zi talablar loyiha qoidalariga zid edi.

## Qaror
1. **F11 = Nasiya** (Click/Payme emas): onlayn/QR to'lov "Keyinroq" (CLAUDE.md), to'lov tizimi shartnomasi yo'q.
2. **F9 = Naqd (aniq summa, bir bosish), F10 = Karta (bir bosish)**, F12 = to'lov oynasi (qaytim, aralash).
   Kassaga pul kiritish/chiqarish F9 dan **Ctrl+F9** ga ko'chdi. F2 (miqdor) qoladi, `*` ham ishlaydi; `+`/`−` — tanlangan qator.
3. **QQS qatori** faqat do'kon "QQS to'lovchi" bo'lsa (`receipt_options.vat_payer`, standart — yo'q); stavka 12%, narx ichida.
   Hisob — faqat ko'rsatish uchun (savdo yozuviga tushmaydi; fiskal chek — keyinroq).
4. **Mijoz bonusi o'rniga qarz** ko'rsatiladi: sodiqlik tizimi yo'q ("Keyinroq").
5. Chek qatorida −/+ tugmalari o'rniga **miqdor tugmasi** (raqamlar oynasini ochadi): 1366 kenglikda nomga joy qolsin.
   Tovar kartasini qayta bosish — +1.
6. **Skanerdan keyin faqat qator** 1 s yashil fonda turadi (butun ekran chaqnashi qaytmaydi; fon o'tishi ≤ 200 ms).
7. Desktopda menyu **64 px ikonlar** (sichqoncha olib borilsa yoki Ctrl+B — ochiladi); sinov banneri 28 px, yopiladi (sessiya davomida).
8. Kategoriya rangi — avtomatik palitra (bazada maydon yo'q); "Sevimlilar" = tez tugmalar + so'nggi 30 kun eng ko'p sotilganlar.

## Oqibatlar
- `pos-screen.md` klaviatura jadvali yangilandi; F9 eski odatini o'zgartiradi — qo'llanmada yozildi.
- QQS to'lovchi belgisi serverda `receipt_options` ichida (yangi ustun/migratsiya yo'q, eski kassalar e'tiborsiz qoldiradi).
