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
- Fon xizmati: internet bo'lsa har 10 s yoki yangi hodisa paydo bo'lganda, 100 tadan paket: `POST /api/v1/sync/push/` `{events:[{id,type,payload,created_at}]}` (qurilma tokendan aniqlanadi). Server tafsilotlari: `sync-api.md`.
- Server har hodisani `id` bo'yicha idempotent qabul qiladi: bor bo'lsa `duplicate` (xato emas). Har hodisa alohida tranzaksiyada qo'llanadi.
- Javob: `{results:[{id,status:"applied"|"duplicate"|"pending"|"rejected",error?}]}`. Kassa `applied`/`duplicate`/`pending`ni `sent_at` bilan belgilaydi (`pending` — server saqlab, o'zi qayta urinadi); `rejected` — `last_error` saqlanadi, holat qatorida ogohlantirish, qayta yuborilmaydi (admin ko'radi).
- Tarmoq xatosida: eksponensial kutish 5 s → 5 daq.
- Hodisalar tartibi: bir qurilma ichida `created_at` bo'yicha; server bog'liq obyekt hali yo'q bo'lsa (masalan smena) — `pending` holatida saqlaydi va keyingi push'da qayta urinadi.

## Pastga: pull (server → kassa)
- `GET /api/v1/sync/pull/?cursor=<str>&limit=500` (kursor — ochiq bo'lmagan satr, boshida `"0"`) → `{changes:[{entity,op,data}], next_cursor, has_more, subscription:{status,paid_until,...}, server_time}`.
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

## Kassa tomoni (T-034, T-035)
- Kod: `apps/pos/lib/data/sync/` — `push.dart` (`OutboxPusher`), `pull.dart` (`PullApplier`, `SyncPuller`), `sync_engine.dart` (`SyncEngine.syncOnce`: avval hamma navbat, keyin pull; hech qachon tashlamaydi — natija `SyncHealth`); `apps/pos/lib/app/sync/` — `sync_runner.dart` (fon tsikli), `sales_gate.dart` (savdo ruxsati).
- **Push**: navbat `created_at` (teng bo'lsa `id`) tartibida, 100 tadan. Natija: `applied`/`duplicate`/`pending` → `sent` (+`sent_at`), `rejected` → `rejected` + `last_error` (qayta yuborilmaydi, holat qatorida "N ta yozuv qabul qilinmadi"), javobda yo'q — keyinroq. Tarmoq/server xatosida paketdagi hodisalarga `next_attempt_at = now + 5 s × 2^(urinish−1)` (≤ 5 daq). **Navbat boshi kutayotgan bo'lsa, hech narsa yuborilmaydi** — yangi hodisa eskisidan oldin ketmaydi. Javob yo'qolsa — o'sha `id` lar qayta yuboriladi (server `duplicate`).
- **Fon tsikli** (`SyncRunner`): qurilma ulangandan keyin (PIN ekranida ham) har 10 s push; yangi outbox hodisasi paydo bo'lsa 1 s ichida; pull — har 60 s (push bilan bir siklda). Ulanish holati (`connectionStatusProvider`) — oxirgi siklning natijasi (haqiqiy server bilan aloqa, Wi-Fi emas).
- **Savdo ruxsati** (`salesBlockProvider`): obuna `readonly`/`blocked`, `offline_grace_until` o'tgan (qurilma soati server farqi bilan tuzatiladi) yoki qurilma bloklangan (403 `device_blocked`, keyingi muvaffaqiyatli sinxrongacha eslab qolinadi) → savdo va kirim tugmalari o'chadi (T-042/T-052 shu provayderni ishlatadi), sababi holat qatorida. Sinxron, ko'rish, hisobotlar ishlayveradi.
- **Soat**: `|server_time − qurilma vaqti| > 5 daq` → holat qatorida "Kompyuter soati noto'g'ri".
- Hali qilinmagan: hodisada tuzatilgan vaqtni ham yuborish (server maydoni yo'q), qoldiqni "server + yuborilmagan harakatlar" bo'yicha ko'rsatish — T-042/T-054.
