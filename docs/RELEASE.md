# Kassa ilovasini chiqarish (T-093)

## Versiya
- Yagona manba — `apps/pos/pubspec.yaml`: `version: 1.2.3+45` (`1.2.3` — foydalanuvchi ko'radigan versiya, `45` — build raqami, Android `versionCode`; har chiqarishda oshadi).
- Ilova versiyani `--dart-define=POS_APP_VERSION` orqali biladi (build skriptlari pubspec'dan qo'yadi): Sozlamalar → "Ilova haqida", serverga qurilma ma'lumoti bilan yuboriladi.
- Semver: tuzatish — `1.2.4`, yangi imkoniyat — `1.3.0`, katta o'zgarish — `2.0.0`. Server API'si orqaga mos (CLAUDE.md 10-qoida) — eski kassa yangi serverda ishlaydi.

## Chiqarish tartibi
1. `pubspec.yaml` da versiyani oshiring, `docs/PROGRESS.md` ga qisqa yozuv, PR → `main`.
2. Teg: `git tag v1.2.3 && git push origin v1.2.3` → GitHub Actions **Release** (`.github/workflows/release.yml`):
   - Windows: `flutter build windows` + VC++ runtime DLL'lari + Inno Setup → `kassa-setup-1.2.3.exe`;
   - Android: `flutter build apk` (imzo kaliti bilan) → `kassa-1.2.3.apk`;
   - ikkalasi GitHub Release'ga yuklanadi. Teg va pubspec versiyasi mos kelmasa — yiqiladi.
3. Serverda kassalarga e'lon qilish — `.env.prod`:
   ```
   APP_LATEST_WINDOWS=1.2.3
   APP_DOWNLOAD_WINDOWS=https://github.com/<org>/POS/releases/download/v1.2.3/kassa-setup-1.2.3.exe
   APP_LATEST_ANDROID=1.2.3
   APP_DOWNLOAD_ANDROID=https://github.com/<org>/POS/releases/download/v1.2.3/kassa-1.2.3.apk
   ```
   `pos up -d backend` — kassalar keyingi sinxronda (≤ 60 s) holat qatorida **"Yangi versiya 1.2.3"** ko'rsatadi; Sozlamalar → "Ilova haqida" da havola (nusxa olinadi). Majburiy yangilash yo'q — savdo to'xtamaydi.

Kerakli GitHub sirlari: `POS_API_URL` (https://api.<domen>), `SUPPORT_PHONE` (Q-008), Android uchun `ANDROID_KEYSTORE_B64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

## Windows
- Lokal yig'ish (Windows, Flutter, Inno Setup 6):
  ```powershell
  pwsh apps/pos/tool/build-windows-installer.ps1 -ApiUrl https://api.<domen> -SupportPhone "+998 .."
  ```
  Natija: `dist/kassa-setup-<versiya>.exe` (~24 MB).
- O'rnatuvchi (`apps/pos/windows/installer/pos.iss`): standart — joriy foydalanuvchi uchun (admin huquqi shart emas), dialogda "barcha foydalanuvchilar" — Program Files'ga; ish stoli va Start menyu yorlig'i; yangilash eski versiya ustiga (AppId o'zgarmaydi), ishlab turgan ilova yopiladi.
- **Ma'lumot saqlanadi**: lokal baza foydalanuvchi AppData papkasida, o'chirish/qayta o'rnatish unga tegmaydi.
- Visual C++ runtime DLL'lari ilova yonida — toza Windows'da VC++ Redistributable shart emas.
- Jim o'rnatish (bir nechta kassa): `kassa-setup-1.2.3.exe /VERYSILENT /SUPPRESSMSGBOXES /CURRENTUSER`. O'chirish: `"%LOCALAPPDATA%\Programs\Kassa\unins000.exe" /VERYSILENT`.
- **Imzo:** hozir o'rnatuvchi imzolanmagan — Windows SmartScreen "noma'lum nashriyotchi" deydi ("Batafsil" → "Baribir ishga tushirish"). Kod imzolash sertifikati — Q-009.

## Android
- Imzo kaliti (bir marta, **xavfsiz saqlang** — yo'qolsa yangilash o'rnatilmaydi):
  ```sh
  keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
  Lokal: `apps/pos/android/key.properties` (repoga tushmaydi):
  ```
  storeFile=../upload-keystore.jks
  storePassword=...
  keyAlias=upload
  keyPassword=...
  ```
  CI: `base64 -w0 upload-keystore.jks` → `ANDROID_KEYSTORE_B64` sir.
- Kalit bo'lmasa APK debug kalit bilan yig'iladi — faqat sinov uchun.
- O'rnatish: APK'ni planshetga ko'chirib, "Noma'lum manbalardan o'rnatish" ruxsati bilan. Google Play — keyinroq (Q-009).

## Sinov natijasi (2026-10-15, lokal)
| Tekshiruv | Natija |
|---|---|
| `build-windows-installer.ps1` → `kassa-setup-1.0.0.exe` | ✅ 24,2 MB |
| Jim o'rnatish (`/VERYSILENT /CURRENTUSER`) | ✅ exit 0; exe, Flutter/sqlite DLL'lari, VC++ runtime, `data/` |
| O'rnatilgan ilovani ishga tushirish | ✅ 8 s dan keyin jarayon ishlayapti, oyna javob beradi |
| Jim o'chirish | ✅ exit 0, ilova fayllari o'chdi (ma'lumot qoldi) |
| `flutter build apk --release` | ✅ 77,9 MB (universal — barcha ABI; `--split-per-abi` bilan har biri ~25 MB) |

Toza (yangi o'rnatilgan) Windows kompyuterda sinov — birinchi haqiqiy chiqarishda, natija shu yerga yoziladi.
