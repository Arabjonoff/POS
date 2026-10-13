# 0003. Oflayn-birinchi: lokal SQLite + outbox + changelog pull
- Sana: 2026-10-13 · Holat: qabul qilingan

**Qaror.** Kassa barcha amallarni lokal SQLite tranzaksiyasida bajaradi. O'zgarmas hodisalar (UUIDv7) outbox orqali serverga idempotent yuboriladi. Katalog serverdan ChangeLog cursor bilan tortiladi, konfliktda server g'olib. Qoldiq — harakatlar yig'indisi.

**Sabab.** Internet va elektr uzilishlari tez-tez; savdo hech qachon to'xtamasligi va yo'qolmasligi kerak. CRDT yoki to'liq ikki tomonlama replikatsiya MVP uchun ortiqcha murakkab.

**Batafsil:** `docs/specs/sync.md`.
