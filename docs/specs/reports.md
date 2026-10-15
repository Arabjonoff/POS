# Hisobotlar (do'kon egasi)

- Bosh sahifa: bugun — savdo summasi, foyda, cheklar soni, o'rtacha chek, kechagi kun bilan solishtirish (↑/↓ %).
- Davr: bugun, kecha, 7 kun, shu oy, o'tgan oy, tanlangan oraliq.
- Savdo: kunlar bo'yicha grafik (ustun), soatlar bo'yicha (qaysi soat band).
- Tovarlar: top 20 (summa va miqdor), eng kam sotilganlar, foyda bo'yicha.
- Kassirlar: savdo, cheklar, qaytarishlar.
- To'lov turlari: naqd/karta/nasiya.
- Qarzlar: jami qarz, eng katta qarzdorlar.
- Ombor: kam qolganlar, manfiy qoldiq, ombor qiymati (tannarx bo'yicha).
- Eksport: xlsx.
- Raqamlar lokal ma'lumotdan hisoblanadi (oflayn), server bilan bir xil formulalar (`data-model.md` → hisoblanadigan qiymatlar).

## Kassada (T-070) — "Hisobotlar" bo'limi (Ctrl+5)
- Kim: ega va menejer. Kassirga — "Hisobotlar ega va menejer uchun" + "Menejer PIN" tugmasi (menejer PIN'i bilan shu kassir sessiyasi davomida ochiladi).
- Davr tugmalari: Bugun, Kecha, 7 kun, Shu oy, O'tgan oy (do'kon vaqt zonasi, `Asia/Tashkent`). Oldingi davr — shu uzunlikdagi oldingi kunlar.
- Ma'lumot: onlayn — server (`GET /api/v1/sync/reports/`, barcha kassalar); javob bo'lmasa — lokal baza (`LocalReports`, faqat shu kassa) va sariq belgi "Internet yo'q — faqat shu kassa ma'lumoti".
- Ekran: KPI (tushum ↑↓%, foyda ↑↓%, cheklar, o'rtacha chek; "Oldin: …"), grafik (bir kun — soatlar, ko'p kun — kunlar bo'yicha ustunlar), to'lov turlari + qaytarishlar, top 10 tovar (miqdor birlik bilan), kassirlar (cheklar, qaytarishlar), qarzlar (jami, qarzdorlar soni, top 5), ombor (qiymat, kam qolganlar, manfiy qoldiq).
- Planshet/desktop: KPI 4 (planshet 2) ustun, ostida ikki ustun kartalar; telefon — bir ustun.
- Hali yo'q: tanlangan oraliq (kalendar), xlsx eksport, "eng kam sotilganlar" / foyda bo'yicha saralash (server `top-products/?order=` bor).
