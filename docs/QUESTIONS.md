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
