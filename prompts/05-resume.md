# 05 — Uzilishdan keyin davom ettirish

> Elektr, internet o'chgandan yoki agent kutilmaganda to'xtagandan keyin beriladi. `scripts/run-agent.ps1` buni avtomatik qiladi.

Oldingi sessiya kutilmaganda to'xtagan bo'lishi mumkin. Ishni yo'qotmasdan davom ettir:

1. **Holatni o'qi:** `docs/STATE.md` (asosiy manba), keyin `docs/PROGRESS.md` ning oxirgi yozuvi.
2. **Git holatini tekshir:**
   - `git status` — commit qilinmagan o'zgarishlar bormi?
   - `git branch --show-current` — STATE.md dagi branch bilan bir xilmi? Bo'lmasa o'sha branchga o't (o'zgarishlarni avval `git stash` qil).
   - `git log --oneline -5` va `git log origin/<branch>..HEAD` — push qilinmagan commitlar bormi? Bo'lsa push qil.
   - `.git/index.lock` qolgan bo'lsa va boshqa git jarayoni ishlamayotgan bo'lsa — o'chir.
3. **Commit qilinmagan o'zgarishlar bo'lsa:** ularni ko'rib chiq (`git diff`). Elektr o'chganda fayl yarim yozilgan bo'lishi mumkin — sintaksis tekshir (`ruff check`, `flutter analyze`, `npm run typecheck`). Buzilgan faylni oxirgi commitdagi holatidan qayta tikla va qadamni qaytadan bajar. Butun o'zgarishlarni `wip: T-XXX <qadam>` bilan commit qil.
4. **Muhitni tikla:** `docker compose up -d`, kerak bo'lsa `pip install`, `npm install`, `flutter pub get`, migratsiyalar.
5. **Tekshir:** vazifaga tegishli testlarni ishga tushir — qaysi qadam haqiqatan tugaganini aniqlash uchun. STATE.md dagi belgilar bilan solishtir va STATE.md ni haqiqatga moslab tuzat.
6. **Ochiq PR bo'lsa:** `gh pr view` / `gh pr checks` — CI holatini ko'r, kerak bo'lsa davom ettir.
7. **Davom et:** STATE.md dagi "Keyingi aniq harakat" dan boshlab `prompts/01-next-task.md` tartibida ishla.
8. `docs/PROGRESS.md` ga qisqa yozuv: `Uzilishdan tiklandi: <nima topildi, nima tuzatildi>`.
