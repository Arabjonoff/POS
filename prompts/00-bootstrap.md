# 00 — Birinchi ishga tushirish prompti

> Buni AI agentga (Claude Code) repo papkasida **bir marta** bering.

Sen bu loyihaning yagona dasturchisisan va loyihani to'liq mustaqil olib borasan. Loyiha egasi kompyuter yonida bo'lmaydi, shuning uchun savol berib to'xtama: noaniq joyda eng oqilona variantni tanla, uni `docs/QUESTIONS.md` ga "vaqtincha tanlangan" deb yoz va davom et.

1. `CLAUDE.md`, `docs/ROADMAP.md`, `docs/specs/` dagi barcha fayllar va `docs/decisions/` ni to'liq o'qi.
2. Muhitni tekshir: `git`, `gh` (avtorizatsiya qilinganmi), `docker`, `python` (3.12+), `node` (20+), `flutter doctor`. Yetishmayotganini `docs/QUESTIONS.md` ga yoz (o'rnatish administrator huquqini talab qilsa, o'zing o'rnatishga urinma).
3. `docs/AGENT_SETUP.md` dagi MCP serverlar o'rnatilganini tekshir (`claude mcp list`); yo'qlarini o'rnat.
4. `docs/ROADMAP.md` dagi 0-bosqichni (T-001 … T-006) ketma-ket bajar — `CLAUDE.md` dagi "Ish tartibi" bo'yicha: har vazifa alohida branch, testlar yashil, PR, CI yashil bo'lgach merge, ROADMAP'da `[x]`, `docs/PROGRESS.md` ga yozuv.
5. 0-bosqich tugagach, keyingi vazifalarga `prompts/01-next-task.md` dagi tartibda o'tib, imkon qadar ko'p vazifani bajar.

Muhim:
- Spec'dan chetga chiqma. Spec'da xato yoki bo'shliq topsang — avval spec'ni tuzat (alohida commit), keyin kod.
- Hech qachon testni o'chirma yoki o'tkazib yuborma.
- Har vazifa oxirida ish holati commit qilingan va push qilingan bo'lsin — sessiya istalgan payt to'xtashi mumkin.
