# apps/pos — kassa ilovasi (Flutter)

Windows desktop, Android, iOS. Oflayn-birinchi: barcha amallar lokal SQLite (Drift) da, server bilan outbox orqali sinxronlanadi.

```sh
flutter pub get          # repo ildizida (pub workspace)
flutter run -d windows
flutter analyze && flutter test
dart run build_runner build   # Drift kodini generatsiya qilish
```

Matnlar faqat `lib/l10n/app_*.arb` da (uz — asosiy, uz_Cyrl, ru).
