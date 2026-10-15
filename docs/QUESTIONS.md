# QUESTIONS — loyiha egasiga savollar

Agent biznes qarori kerak bo'lganda yoki to'xtab qolganda shu yerga yozadi va boshqa vazifaga o'tadi.
Loyiha egasi javobni shu yerga yozadi; agent keyingi sessiyada o'qiydi va `[javob berildi]` qiladi.

Format:
```
### Q-001 (T-XXX) Qisqa savol
- Kontekst: ...
- Variantlar: A) ... B) ...
- Agentning tavsiyasi: ...
- Hozircha tanlangan: A (vaqtincha)
- Javob: ...
```

---

### Q-001 (T-013) Sinov to'lovsiz tugasa — grace beriladimi?
- Kontekst: spec'da grace faqat `paid_until` dan keyin yozilgan. Sinov tugab, to'lov bo'lmasa — darhol readonly yoki avval grace?
- Variantlar: A) sinovdan keyin ham `grace_days` (3 kun) grace, keyin readonly. B) sinov tugashi bilan darhol readonly.
- Agentning tavsiyasi: A — do'kon kutilmaganda to'xtab qolmaydi, ega to'lashga ulguradi.
- Hozircha tanlangan: A (vaqtincha)
- Javob: A [javob berildi]

### Q-002 (T-013) Sinov davomida to'lov qilinsa — qolgan sinov kunlari kuyadimi?
- Kontekst: spec: `period_from = max(paid_until, today)`. Sinov ichida birinchi to'lovda `paid_until` yo'q → davr bugundan boshlanadi, qolgan sinov kunlari yo'qoladi.
- Variantlar: A) spec bo'yicha — bugundan. B) `period_from = max(paid_until, trial_ends_at, today)` — sinov oxirigacha bepul, to'langan davr undan keyin.
- Agentning tavsiyasi: B — erta to'laganni jazolamaydi.
- Hozircha tanlangan: B (vaqtincha; `services.record_payment` da bitta joyda o'zgartiriladi)
- Javob: B [javob berildi]

### Q-003 (T-016) Mijoz qarzidan ko'p to'lasa — avans sifatida qabul qilinadimi?
- Kontekst: `debts.md` da to'lov faqat qarzni yopish uchun ("To'liq" tugmasi). Ortiqcha to'lov qabul qilinsa balans manfiy bo'ladi (do'kon mijozga qarzdor).
- Variantlar: A) ruxsat yo'q — `409 payment_exceeds_debt`, kassir summani to'g'rilaydi. B) avans sifatida qabul qilinadi (manfiy balans), keyingi nasiya savdodan ayriladi.
- Agentning tavsiyasi: A — oddiyroq, kassada xato kiritilgan summa (ortiqcha nol) qarzni buzmaydi. Avans kerak bo'lsa keyin qo'shiladi.
- Hozircha tanlangan: A (vaqtincha; `services.pay_debt` da bitta joyda). Oflayn kassadan kelgan to'lov (sinxron) baribir qabul qilinadi.
- Javob:

### Q-004 (T-019) Foyda qanday hisoblanadi — chek chegirmasi va qaytarishlar bilanmi?
- Kontekst: `data-model.md`: `Foyda = SUM(SaleItem.total − cost × qty / 1000)`. Bu chekka berilgan chegirmani (masalan, 125 300 → 125 000 yaxlitlash) va qaytarilgan tovarlarni hisobga olmaydi — foyda ortiq ko'rinadi.
- Variantlar: A) foyda = tushum (chek chegirmasi va qaytarishlardan keyin) − sotilgan tannarx + qaytarilgan tannarx. B) `data-model.md` dagi qator formulasi (chegirma va qaytarishsiz).
- Agentning tavsiyasi: A — egasi ko'radigan foyda kassadagi haqiqiy pulga mos keladi.
- Hozircha tanlangan: A (vaqtincha; `apps/reports/services.py` da bitta joyda; kassa hisobotlari ham shu formulani oladi).
- Javob:

### Q-005 (T-042) Kassir qancha chegirmani o'zi bera oladi?
- Kontekst: `auth-roles.md` — "katta chegirma" menejer/ega PIN tasdig'ini talab qiladi; `pos-screen.md` — "huquq va maksimal foiz sozlamada". Chegara qiymati va sozlama joyi aniqlanmagan.
- Variantlar: A) kassir 5% gacha o'zi, undan katta — menejer/ega PIN. B) kassir umuman chegirma bera olmaydi (har chegirma — PIN). C) chegara 10%.
- Agentning tavsiyasi: A — yaxlitlash ("125 300 → 125 000") va kichik chegirmalar savdoni to'xtatmaydi, kattasi nazoratda.
- Hozircha tanlangan: A (vaqtincha; lokal sozlama `discount_cashier_max_bp`, standart 500 = 5%; `features/pos/cart/discount_policy.dart`). Menejer va ega — cheklovsiz. Tasdiqlagan xodim savdoning `approved_by` iga yoziladi. Sozlamani o'zgartirish ekrani — keyin (ega sozlamalari).
- Javob:

### Q-006 (T-045) Boshqa kassada sotilgan chekni qaytarish mumkinmi?
- Kontekst: T-045 da qaytarish faqat shu kassaning lokal bazasidagi savdolar uchun ishlaydi (oflayn-birinchi). Bir do'konda bir nechta kassa bo'lsa, mijoz chekni boshqa kassaga olib kelishi mumkin. Server bunday qaytarishni qabul qiladi (`record_refund` savdoni tenant bo'yicha topadi), lekin kassada boshqa kassalarning savdolari yo'q.
- Variantlar: A) internet bo'lsa, chek raqami bo'yicha serverdan savdoni olib (`GET /api/v1/sales/?number=`) qaytarish; oflaynda — faqat o'z savdolari. B) hamma kassaga oxirgi N kunlik savdolarni pull qilish (oflaynda ham ishlaydi, lekin baza kattalashadi). C) faqat sotgan kassada qaytarish.
- Agentning tavsiyasi: A — oddiy, ma'lumotni ko'paytirmaydi, mahalla do'konida kassalar odatda bir xonada va internet ko'pincha bor.
- Hozircha tanlangan: C (T-045 ning hozirgi holati). A uchun backend'ga `?number=` filtri va kassada onlayn qidiruv kerak bo'ladi.
- Javob:

### Q-007 (T-047) Android Bluetooth/USB printer — qaysi printerlar va qurilma?
- Kontekst: T-047 (qaror 0008) Android uchun Bluetooth (SPP) va USB printer ulanishini qo'shadi. Buning uchun native plagin kerak va uni haqiqiy Android qurilma hamda printerda sinash shart (ruxsatlar: Android 12+ `BLUETOOTH_CONNECT`/`BLUETOOTH_SCAN`, USB host). CI va emulyatorda bunday sinov imkoni yo'q.
- Savol: do'konlarda qaysi printer modellari ko'p (masalan, Xprinter XP-58/80, MTP-II, Sunmi ichki printeri)? Sinov uchun Android qurilma va printer bormi?
- Agentning tavsiyasi: T-047 ni haqiqiy qurilmada sinov imkoni paydo bo'lguncha keyinga qoldirish. Hozircha Android'da Wi-Fi/LAN printer ishlaydi (T-044). Sunmi kabi ichki printerli qurilmalar uchun alohida transport kerak bo'lishi mumkin.
- Hozircha tanlangan: T-047 o'tkazib yuborildi, keyingi mustaqil vazifa (T-050) olindi.
- Javob:

### Q-008 (T-085) Obuna to'lovi uchun aloqa raqami qaysi?
- Kontekst: obuna tugaganda (`readonly`), bloklanganda yoki muddat o'tganda (`grace`) kassa "to'lang / bog'laning" deydi. Spec "aniq xabar va aloqa raqami" talab qiladi, lekin raqam berilmagan.
- Savol: do'kon egalari to'lov va yordam uchun qaysi telefon (yoki Telegram) bilan bog'lanadi?
- Agentning tavsiyasi: bitta qo'llab-quvvatlash raqami, ilova build paytida beriladi (`--dart-define=SUPPORT_PHONE=+998...`); keyinchalik serverdan (`/devices/me/` javobida) olish mumkin — raqam o'zgarsa ilovani qayta chiqarmaslik uchun.
- Hozircha tanlangan: `SUPPORT_PHONE` build parametri; berilmasa matn "Administrator bilan bog'laning".
- Javob: **+998 91 498 01 68** (2026-10-15). Kassada standart raqam (`defaultSupportPhone`); build paytida `SUPPORT_PHONE` bilan almashtirish mumkin.

### Q-009 (T-093) Ilovani imzolash va tarqatish
- Kontekst: Windows o'rnatuvchi hozir imzolanmagan — SmartScreen "noma'lum nashriyotchi" ogohlantirishini ko'rsatadi. Android APK yangilanishlari uchun bitta imzo kaliti kerak (yo'qolsa, yangi versiya eski ustiga o'rnatilmaydi).
- Savollar: (1) Windows uchun kod imzolash sertifikati (OV/EV, yiliga ~$200–500) olinadimi va kim nomiga? (2) Android: Google Play'ga chiqariladimi yoki APK to'g'ridan-to'g'ri (sayt/Telegram) tarqatiladimi? (3) Imzo kalitini kim va qayerda saqlaydi?
- Agentning tavsiyasi: dastlab APK va imzolanmagan o'rnatuvchi (sinov do'konlari), keyin — OV sertifikat va Google Play (ichki test kanali). Kalit — parol menejerida + oflayn nusxa.
- Hozircha tanlangan: imzosiz Windows o'rnatuvchi; Android — `key.properties` bo'lsa release kalit, bo'lmasa debug (faqat sinov). Yo'riqnoma: `docs/RELEASE.md`.
- Javob:
