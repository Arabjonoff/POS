# Tovarlar

## Ro'yxat
- Qidiruv (nom, shtrix-kod, PLU), kategoriya filtri, "kam qolgan", "manfiy qoldiq", "nofaol" filtrlari.
- Ustunlar (desktop): nom, shtrix-kod, kategoriya, narx, tannarx, qoldiq, holat. Telefon: kartalar.
- Bo'sh holat: "Hali tovar yo'q" + "Tovar qo'shish" va "Excel'dan yuklash".

## Tovar kartasi
- Majburiy: nom, birlik, sotish narxi. Ixtiyoriy: kategoriya, tannarx, shtrix-kodlar (bir nechta, skaner bilan), vaznli tovar + PLU, min qoldiq, IKPU, tez tugmada ko'rsatish.
- Ustama foizi avtomatik ko'rsatiladi (narx − tannarx).
- Saqlash → `product.upserted` outbox. O'chirish = nofaol qilish (tarix saqlanadi).

## Import
- Shablon (xlsx): nom, shtrix-kod, kategoriya, birlik, narx, tannarx, qoldiq (ixtiyoriy — boshlang'ich kirim sifatida).
- Ustunlarni moslash, 20 qator oldindan ko'rish, xatolar (qator raqami + sabab), shtrix-kod bo'yicha mavjudlarini yangilash.
