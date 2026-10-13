# POS loyihasi — AI agent uchun to'plam

Bu papkada AI agent loyihani boshidan oxirigacha mustaqil qurishi uchun kerak bo'lgan hamma narsa bor: qoidalar, to'liq vazifalar ro'yxati, har funksiya spec'i va tayyor promptlar. Kod yo'q — kodni agent yozadi.

## Nima qayerda
| Fayl | Nima |
|---|---|
| `CLAUDE.md` | Agent konstitutsiyasi: stack, buzilmaydigan qoidalar, UI qoidalari, ish tartibi |
| `docs/ROADMAP.md` | 48 ta vazifa (T-001 … T-094), har biri qabul mezonlari bilan |
| `docs/specs/` | 15 ta spec: ma'lumotlar modeli, sinxron, skaner, kassa, kirim, nasiya, admin, dizayn tizimi va b. |
| `docs/decisions/` | Qabul qilingan qarorlar (stack, pul, oflayn, filiallarsiz) |
| `docs/AGENT_SETUP.md` | O'rnatish, MCP serverlar, ruxsatlar, avtomatik sikl |
| `docs/PROGRESS.md` | Agent har vazifadan keyin yozadi |
| `docs/QUESTIONS.md` | Agent sizga savollarini shu yerga yozadi |
| `docs/plan.md` | Umumiy reja va bozor konteksti |
| `prompts/` | 00 boshlash · 01 keyingi vazifa · 02 o'z-o'zini tekshirish · 03 UI/UX tekshiruv · 04 xato tuzatish |
| `.claude/settings.json` | Agent ruxsatlari |

## 5 qadamda boshlash
1. GitHub'da bo'sh repo yarating (masalan `ZellyPos/pos`) va kompyuteringizga clone qiling.
2. Shu papkadagi **hamma narsani** (yashirin `.claude/` papkasi bilan) repo ildiziga nusxalang, commit va push qiling.
3. `docs/AGENT_SETUP.md` 1-bo'limidagi dasturlarni o'rnating (`flutter doctor` yashil bo'lsin), `gh auth login`.
4. Repo papkasida `claude` ni oching va `prompts/00-bootstrap.md` matnini bering.
5. 0-bosqich tugagach, `docs/AGENT_SETUP.md` 4-bo'limidagi avtomatik siklni ishga tushiring va keting.

Qaytganingizda: `docs/PROGRESS.md` va `docs/QUESTIONS.md` ni o'qing.
