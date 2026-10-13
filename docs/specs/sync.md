# Oflayn ishlash va sinxronlash

## Maqsad
Internet yoki elektr uzilganda kassa to'xtamaydi; hech bir savdo yo'qolmaydi va ikki marta hisoblanmaydi.

## Lokal saqlash (Flutter, Drift/SQLite)
- WAL rejimi, `synchronous=FULL`.
- Savdo yopilishi = **bitta tranzaksiya**: Sale + SaleItem + SalePayment + StockMovement + (DebtEntry) + OutboxEvent.
- "Chek yopildi" ekrani faqat commit'dan keyin.
- Ochiq savat har o'zgarishda saqlanadi (`CartDraft` jadvali); ilova qayta ochilganda tiklanadi.

## Yuqoriga: outbox (kassa → server)
- Hodisa turlari: `sale.completed`, `refund.created`, `shift.opened`, `shift.closed`, `cash.moved`, `receipt.posted`, `inventory.posted`, `debt.paid`, `product.upserted`, `customer.upserted`, `supplier.upserted`.
- Fon xizmati: internet bo'lsa har 10 s yoki yangi hodisa paydo bo'lganda, 100 tadan paket: `POST /api/v1/sync/push` `{device_id, events:[{id,type,payload,created_at}]}`.
- Server har hodisani `id` bo'yicha idempotent qabul qiladi: bor bo'lsa `duplicate` (xato emas). Har hodisa alohida tranzaksiyada qo'llanadi.
- Javob: `{results:[{id,status:"applied"|"duplicate"|"rejected",error?}]}`. Kassa `applied`/`duplicate`ni `sent_at` bilan belgilaydi; `rejected` — `last_error` saqlanadi, holat qatorida ogohlantirish, qayta yuborilmaydi (admin ko'radi).
- Tarmoq xatosida: eksponensial kutish 5 s → 5 daq.
- Hodisalar tartibi: bir qurilma ichida `created_at` bo'yicha; server bog'liq obyekt hali yo'q bo'lsa (masalan smena) — `pending` holatida saqlaydi va keyingi push'da qayta urinadi.

## Pastga: pull (server → kassa)
- `GET /api/v1/sync/pull?cursor=<int>&limit=500` → `{changes:[{entity,op,data}], next_cursor, has_more, subscription:{status,paid_until,...}, server_time}`.
- Entitylar: Product, ProductBarcode, Category, Unit, Customer, Supplier, User (pin_hash bilan), Store, Plan cheklovlari, DebtEntry (boshqa qurilmalardan), StockMovement yig'indisi (`ProductStock`).
- Katalog uchun konflikt qoidasi: **server g'olib**. Klient o'zgarishi outbox orqali serverga boradi, pull orqali qaytadi.
- Pull har 60 s va push'dan keyin.

## Qoldiq
- Qoldiq harakatlar yig'indisi — bir nechta kassa oflayn sotsa ham hisob buzilmaydi.
- Manfiy qoldiq sotuvni **bloklamaydi**; hisobotda "manfiy qoldiq" ro'yxati.
- Klientda qoldiq = serverdan kelgan oxirgi qiymat + hali yuborilmagan lokal harakatlar.

## Obuna oflaynda
- Har pull'da `subscription` va `offline_grace_until = server_time + offline_days` saqlanadi.
- `readonly`/`blocked` yoki `offline_grace_until` o'tgan bo'lsa: savdo va kirim tugmalari o'chadi; ko'rish, hisobot va **sinxronlash ishlaydi** (ma'lumot hech qachon qamalib qolmaydi).

## Qurilma soati
- Har pull'da `server_time` bilan farq saqlanadi; farq > 5 daqiqa bo'lsa holat qatorida ogohlantirish. Hodisalarda ham qurilma vaqti, ham tuzatilgan vaqt saqlanadi.

## Qabul mezonlari
Server:
1. Bir xil paketni 2 marta push → ikkinchisida hammasi `duplicate`, ma'lumot o'zgarmaydi.
2. Smena hodisasidan oldin savdo hodisasi kelsa → `pending`, smena kelgach qo'llanadi.
3. Ikki qurilma bir tovarni oflayn sotadi → qoldiq = boshlang'ich − ikkala sotuv.
4. Boshqa tenant qurilmasi hodisasi rad etiladi.
Klient:
5. Internetsiz 500 savdo, keyin ulanish → serverda aynan 500 savdo.
6. Push o'rtasida tarmoq uziladi → qayta yuborishda dublikat yo'q.
7. Savdo yopish o'rtasida jarayon o'ldiriladi → savdo yoki to'liq bor, yoki umuman yo'q.
8. `readonly` holatida savdo tugmasi o'chiq, sinxronlash ishlaydi.
