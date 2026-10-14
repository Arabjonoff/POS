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
