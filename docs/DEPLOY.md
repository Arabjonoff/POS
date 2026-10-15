# Production'ga chiqarish (T-092)

Bitta server: Docker Compose — **Caddy** (avtomatik HTTPS) → **backend** (Django + gunicorn) va **admin** (Next.js), **PostgreSQL 16**, **Redis 7**, kunlik **zaxira** va **obuna holatini yangilash**. Fayllar: `docker-compose.prod.yml`, `deploy/`, `.env.prod.example`.

```
Internet ──443──> Caddy ─┬─ api.example.uz   → backend:8000 (/api, /admin, /static)
                         └─ admin.example.uz → admin:3000
backend, scheduler ──> postgres, redis        backup ──> postgres → ./backups
```

## 1. Server (taxminan 30 daqiqa)
Talab: Ubuntu 22.04/24.04, 2 vCPU, 4 GB RAM, 40 GB disk; 80 va 443 portlar ochiq.

1. **DNS:** `api.<domen>` va `admin.<domen>` A yozuvlari server IP manziliga (Caddy sertifikatni shu orqali oladi).
2. **Docker:**
   ```sh
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER && newgrp docker
   ```
3. **Kod:**
   ```sh
   git clone https://github.com/Arabjonoff/POS.git /opt/pos && cd /opt/pos
   cp .env.prod.example .env.prod
   ```
4. **`.env.prod`** — domenlar, `ACME_EMAIL`, sirlar:
   ```sh
   sed -i "s|^DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY=$(openssl rand -base64 48 | tr -d '\n/+=')|" .env.prod
   sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '\n/+=')|" .env.prod
   nano .env.prod   # API_DOMAIN, ADMIN_DOMAIN, ACME_EMAIL, (ixtiyoriy) SENTRY_DSN
   ```
5. **Ishga tushirish** (birinchi marta 5–10 daqiqa — image'lar yig'iladi):
   ```sh
   docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
   docker compose -f docker-compose.prod.yml --env-file .env.prod ps   # hammasi healthy
   curl https://api.<domen>/api/health/                                  # {"status":"ok"}
   ```
6. **Platforma admini** (admin panelga kirish uchun):
   ```sh
   docker compose -f docker-compose.prod.yml --env-file .env.prod exec backend \
     python manage.py createsuperuser        # telefon, ism, parol
   ```
   `https://admin.<domen>` — shu telefon va parol bilan kiring, tarif yarating, keyin birinchi mijozni.
7. **Kassa ilovasi** shu API'ga ulanadi: build paytida `--dart-define=POS_API_URL=https://api.<domen>` (va `SUPPORT_PHONE`, Q-008) — `docs/RELEASE.md` (T-093).

Qisqa buyruq uchun: `alias pos='docker compose -f /opt/pos/docker-compose.prod.yml --env-file /opt/pos/.env.prod'`.

## 2. Yangilash
```sh
cd /opt/pos && git pull
pos up -d --build          # migratsiyalar backend ishga tushganda avtomatik (orqaga mos, CLAUDE.md 10)
pos ps && curl https://api.<domen>/api/health/
```
Yangilashdan oldin qo'lda zaxira: `pos exec backup sh /deploy/backup.sh once`.

## 3. Zaxira (backup) va tiklash
- `backup` xizmati har 24 soatda `pg_dump -Fc` qiladi: `./backups/pos-YYYYMMDD-HHMM.dump` (`BACKUP_DIR`), `BACKUP_KEEP_DAYS` (14) kundan eskisi o'chadi. Har zaxira yozilgach `pg_restore --list` bilan tekshiriladi.
- **Serverdan tashqariga nusxa** (disk buzilsa ham saqlansin) — masalan, kuniga bir marta boshqa serverga yoki S3'ga:
  ```sh
  # crontab -e
  30 3 * * * rsync -a /opt/pos/backups/ backup@boshqa-server:/srv/pos-backups/
  ```
- Qo'lda zaxira: `pos exec backup sh /deploy/backup.sh once`.
- **Tiklash** (joriy ma'lumot almashtiriladi):
  ```sh
  pos stop backend scheduler admin
  pos run --rm --entrypoint sh backup /deploy/restore.sh /backups/pos-20261015-0300.dump
  pos up -d
  ```
- Tiklash sinovi (oyiga bir marta tavsiya): zaxirani alohida bo'sh bazaga tiklab, `docs/DEPLOY.md` dagi "Tiklash sinovi" kabi tekshiring — lokal natija pastda.

## 4. Monitoring
- **Sentry:** `.env.prod` da `SENTRY_DSN` — backend xatolari (shaxsiy ma'lumot yuborilmaydi, `send_default_pii=False`). `SENTRY_TRACES_SAMPLE_RATE` (standart 0).
- **Health:** `GET https://api.<domen>/api/health/` — tashqi kuzatuv (UptimeRobot va h.k.) uchun.
- **Loglar:** `pos logs -f backend` (gunicorn access log ham), `pos logs backup`.
- **Obunalar:** `scheduler` har kuni `update_subscriptions` (holat keshi); kassa holatni sinxronda oladi.

## 5. Xavfsizlik
- `.env.prod` faqat serverda (repoga tushmaydi, `.gitignore`). Postgres va Redis tashqariga ochilmagan (faqat ichki tarmoq).
- HTTPS majburiy (Django `SECURE_SSL_REDIRECT`, HSTS — `DJANGO_HSTS_SECONDS`). Admin JWT httpOnly + Secure cookie'da (T-080).
- Server: `ufw allow 22,80,443/tcp && ufw enable`; SSH faqat kalit bilan.

## Lokal sinov natijasi (2026-10-15)
Windows 11 + Docker Desktop, `.env.prod` o'rniga lokal qiymatlar (`CADDY_TLS=tls internal`, `api.localhost` / `admin.localhost`, 18080/18443 portlar):

| Tekshiruv | Natija |
|---|---|
| `up -d --build` (image'lar yig'ilib, birinchi ishga tushish) | ✅ barcha xizmatlar healthy, migratsiyalar avtomatik |
| `GET https://api…/api/health/` | ✅ `{"status":"ok"}`; HTTP → HTTPS 308; `/static/` Caddy'dan 200 |
| `createsuperuser` → admin panelga kirish (httpOnly cookie) → bosh sahifa | ✅ |
| Admin oqimi **haqiqiy Django** bilan: tarif → yangi mijoz (usta) → ega vaqtinchalik parol bilan API'ga kiradi → to'lov (server davri = oldindan ko'rsatilgan) → bloklash → audit | ✅ |
| Zaxira: `backup.sh once` → `pg_restore --list` tekshiruvi | ✅ 172 KB |
| Tiklash yangi bazaga | ✅ jadvallar soni bir xil |
| To'liq tiklash mashqi: ma'lumot "buzildi" → `restore.sh` → xizmatlar qayta | ✅ ma'lumot zaxiradagi holatga qaytdi, health va login ishlaydi |

**Topilgan va tuzatilgan:** admin server tomoni Django'ga so'rov tanasini `Transfer-Encoding: chunked` bilan yuborardi — gunicorn/Django (WSGI) uni bo'sh o'qiydi, natijada prod'da kirish va barcha o'zgartirishlar 400 qaytarardi (soxta API buni qabul qilgani uchun e2e sezmagan). Endi tana matn sifatida (`Content-Length` bilan) yuboriladi (`apps/admin/src/api/client.ts`), soxta API ham Django kabi qat'iy.

Haqiqiy toza serverda (DNS va Let's Encrypt bilan) sinov — birinchi chiqarishda; yo'riqnoma shu sinov asosida.
