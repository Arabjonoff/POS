# 02 — O'z-o'zini tekshirish (har 5 vazifadan keyin)

Oxirgi 5 ta merge qilingan PR'ni ko'rib chiq (`git log --oneline -20`, `gh pr list --state merged -L 5`) va quyidagilarni tekshir:
1. `CLAUDE.md` dagi buzilmaydigan qoidalar: float pul yo'qmi, tenant filtri har joydami, qattiq yozilgan matn yo'qmi, testlar o'chirilmaganmi.
2. Spec bilan kod mosmi? Farq bo'lsa — qaysi biri to'g'ri ekanini hal qil va tuzat.
3. Takrorlangan kod va keraksiz murakkablik.
4. Xavfsizlik: autentifikatsiyasiz endpoint, sirlar kodda, SQL injection, boshqa tenant ma'lumotiga yo'l.
5. Tezlik: N+1 so'rovlar (backend), keraksiz rebuild (Flutter).
Topilganlarni bitta `chore/review-<sana>` PR bilan tuzat va `docs/PROGRESS.md` ga qisqa hisobot yoz.
