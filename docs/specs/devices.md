# Qurilmalar (kassa)

Kassa qurilmasi (Windows kompyuter, Android/iOS planshet yoki telefon) serverga **qurilma tokeni** bilan ulanadi. Foydalanuvchi JWT'si faqat ro'yxatdan o'tish va ega/menejer amallari uchun.

## Ro'yxatdan o'tish
- Ega ilovaga telefon + parol bilan kiradi (`/auth/login/`) → `POST /api/v1/devices/register/` (faqat **owner**).
- So'rov: `{id?, name, platform: windows|android|ios, app_version, store?}`.
  - `id` — klient yaratgan UUIDv7 (tavsiya etiladi). Shu `id` bilan qayta yuborilsa (tarmoq uzilib javob kelmagan bo'lsa) — **yangi qurilma yaratilmaydi**, o'sha qurilmaga yangi token beriladi (eski token bekor), chegara sarflanmaydi.
  - `store` berilmasa — tenantning birinchi do'koni. Boshqa tenant do'koni — `400 validation_error`.
- Javob `201` (yangi) yoki `200` (qayta): `{device: {...}, token}`. **Token faqat shu javobda ko'rinadi**; kassa uni `flutter_secure_storage` da saqlaydi.
- Har qurilmaga tenant ichida tartib raqami `number` (1, 2, 3 …) — chek raqami prefiksi `D{number}-` uchun. Raqam qayta ishlatilmaydi.

## Chegara va xatolar
| Holat | Javob |
|---|---|
| Faol (bloklanmagan) qurilmalar soni = `Plan.max_devices` | `409 device_limit_reached` (`details: {max_devices}`) |
| Tenantda obuna yo'q | `409 no_subscription` |
| `id` boshqa tenantga tegishli | `409 device_id_conflict` |
| Bloklangan qurilmani qayta ro'yxatdan o'tkazish | `403 device_blocked` |
| Ega emas (menejer, kassir) | `403` |

Bloklangan qurilma chegaraga kirmaydi (yo'qolgan qurilma o'rniga yangisini ulash mumkin). Obuna `readonly`/`blocked` bo'lsa ham ro'yxatdan o'tish va sinxron ishlaydi — savdoni kassa o'zi o'chiradi (`sync.md`, "Obuna oflaynda").

## Token
- Format: `dev_` + 43 belgili tasodifiy satr (`secrets.token_urlsafe(32)`). Serverda faqat **sha256 hash** saqlanadi.
- Sarlavha: `Authorization: Device <token>`.
- Noto'g'ri yoki eskirgan token — `401`. Bloklangan qurilma — `403 device_blocked` (sinxron ham).
- Token turlari aralashmaydi: qurilma tokeni faqat qurilma endpoint'larida (`/devices/me/`, keyin `/sync/*`) qabul qilinadi; foydalanuvchi endpoint'lariga (`/users/`, `/auth/me/` va h.k.) qurilma tokeni bilan — `401`. Qurilma endpoint'lariga foydalanuvchi JWT'si bilan — `401`.

## Boshqa endpoint'lar
- `GET /api/v1/devices/me/` (qurilma tokeni) → `{device, subscription: {status, paid_until, days_left, offline_days}, server_time}`. `last_seen_at` va `last_ip` yangilanadi.
- `GET /api/v1/devices/`, `/devices/{id}/` (owner, manager) — o'z tenanti qurilmalari. Token/hash ko'rinmaydi.
- Bloklash — hozircha platforma admini (Django admin); admin dashboard API — T-020.

## Kassa tomoni (T-034)
- **Birinchi ishga tushirish** (`/setup`): ega telefon + parol → kassa nomi (standart "Kassa 1") → `devices/register` → **birinchi sinxron** (pull, progress — yuklangan yozuvlar soni) → xodim tanlash. Ro'yxatdan o'tish `id` si javobdan oldin `LocalSettings.pending_device_id` ga yoziladi — javob kelmay qolsa, qayta urinish yangi qurilma yaratmaydi.
- Token — `flutter_secure_storage` (`pos_device_token`); qurilma (`id`, `number` — chek prefiksi, `name`, `store`) — `LocalSettings`. Birinchi sinxron tugaganini `initial_sync_done` belgilaydi: ilova sinxron o'rtasida yopilsa, keyingi ochilishda sinxrondan davom etadi.
- Xatolar ekranda: noto'g'ri telefon/parol, ega emas (menejer/kassir ulay olmaydi), qurilmalar chegarasi, obuna yo'q, qurilma bloklangan, internet yo'q.
- Server manzili build paytida: `--dart-define=POS_API_URL=...` (standart — lokal `http://127.0.0.1:8100`).
- API klient: `packages/api_client_dart` (`make api-clients` — swagger_parser + retrofit, faqat kassa endpoint'lari: auth, devices, sync). API faqat JSON qabul qiladi (`DEFAULT_PARSER_CLASSES = JSONParser`).
