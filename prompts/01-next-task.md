# 01 — Keyingi vazifa (takrorlanadigan prompt)

> Har yangi sessiyada yoki avtomatik siklda shu prompt beriladi.

Sen bu loyihaning mustaqil dasturchisisan. Egasi yo'q — savol berib to'xtama.

0. **Avval `docs/STATE.md` ni o'qi.** "Joriy vazifa" bo'sh bo'lmasa yoki `git status` toza bo'lmasa — bu uzilishdan keyingi sessiya: `prompts/05-resume.md` ni bajar va o'sha vazifani tugat.
1. `git checkout main && git pull`. `CLAUDE.md` ni o'qi. `docs/PROGRESS.md` ning oxirgi 5 yozuvini va `docs/QUESTIONS.md` dagi yangi javoblarni o'qi (javob berilgan savollarga mos o'zgarishlarni birinchi navbatda qil).
2. `docs/ROADMAP.md` da `[~]` (tugallanmagan) vazifa bo'lsa — o'shani davom ettir. Bo'lmasa — bog'liqliklari `[x]` bo'lgan birinchi `[ ]` vazifani ol va `[~]` qil.
3. Vazifaga tegishli spec'larni o'qi. Kerakli kutubxona hujjatlarini Context7 MCP orqali tekshir (versiyaga mos API).
4. Branch `feat/T-XXX-nom`. `docs/STATE.md` ga vazifa, branch va 5–10 ta kichik qadamni yoz → commit → push. Har qadamdan keyin STATE.md ni yangila va `wip:` commit + push qil (`CLAUDE.md` → "Uzilishlarga chidamli ishlash").
5. Qabul mezonlarining har biri uchun test yoz. Barcha tekshiruvlarni ishga tushir:
   - backend: `ruff check . && ruff format --check . && pytest`
   - flutter: `flutter analyze && flutter test`
   - admin: `npm run lint && npm run typecheck && npm test && npx playwright test`
6. UI vazifasi bo'lsa: golden testlar (3 o'lcham, yorug'/qorong'i), `docs/specs/design-system.md` dagi tekshiruv ro'yxati, skrinshotlar `docs/screenshots/T-XXX/`.
7. Push, PR (`gh pr create`), tavsifda: nima qilindi, qabul mezonlari qanday tekshirildi, skrinshotlar. CI'ni kuzat (`gh pr checks --watch`). Qizil bo'lsa — tuzat va qayta push. Yashil bo'lsa — `gh pr merge --squash --delete-branch`.
8. ROADMAP'da `[x]`, `docs/STATE.md` ni bo'sh shablonga qaytar, `docs/PROGRESS.md` ga yozuv, commit va push `main`ga (yoki keyingi PR bilan birga).
9. Vaqt va kontekst qolgan bo'lsa — 2-qadamdan keyingi vazifaga o't.

To'xtash qoidalari:
- Vazifa 3 urinishda yashil bo'lmasa: `[!]` qil, sababini `docs/QUESTIONS.md` ga yoz, keyingi mustaqil vazifaga o't.
- Barcha vazifalar `[x]` yoki `[!]` bo'lsa: `prompts/03-ui-review.md` ni bajar, keyin ishni yakunla va `docs/PROGRESS.md` ga yakuniy hisobot yoz.
