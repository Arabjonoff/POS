# AI agentni sozlash va mustaqil ishlatish

Bu yo'riqnoma Claude Code uchun yozilgan. Boshqa agent (Cursor, Codex va h.k.) ishlatsangiz, `CLAUDE.md` ni `AGENTS.md` nomi bilan ham nusxalang — qolgan hammasi bir xil.

## 1. Kompyuterga o'rnatiladigan dasturlar (siz o'rnatasiz, bir marta)
Bular administrator huquqini so'raydi, shuning uchun agent ularni o'zi o'rnata olmaydi.

| Dastur | Nima uchun | O'rnatish (Windows, PowerShell) |
|---|---|---|
| Git | Kod tarixi | `winget install Git.Git` |
| GitHub CLI | PR, CI, merge | `winget install GitHub.cli` → `gh auth login` |
| Docker Desktop | Postgres, Redis, backend | o'rnatilgan ✓ |
| Python 3.12 | Django | `winget install Python.Python.3.12` |
| Node.js 22 LTS | Next.js admin | `winget install OpenJS.NodeJS.LTS` |
| Flutter SDK (stable) | Kassa ilovasi | flutter.dev → Windows yo'riqnomasi, `flutter doctor` |
| Visual Studio 2022 (Community), "Desktop development with C++" | Flutter Windows build | `winget install Microsoft.VisualStudio.2022.Community` → C++ workload |
| Android Studio | Android build, emulyator | `winget install Google.AndroidStudio` → `flutter doctor --android-licenses` |
| Claude Code | AI agent | `irm https://claude.ai/install.ps1 \| iex` (yoki `npm install -g @anthropic-ai/claude-code`) |

Tekshiruv: `flutter doctor` da Windows va Android qatorlari yashil bo'lishi kerak. iOS build faqat Mac'da — hozircha kerak emas.

## 2. MCP serverlar (agent o'zi o'rnatadi, yoki siz bir marta)
Repo papkasida:
```powershell
# Kutubxonalarning yangi hujjatlari (Django, Flutter, Next.js, Drift...)
claude mcp add --transport http context7 https://mcp.context7.com/mcp
# Dart/Flutter: analyze, test, pub, hot reload, widget daraxti
claude mcp add --transport stdio dart -- dart mcp-server
# Brauzer: admin dashboardni ochib sinash va skrinshot olish
claude mcp add playwright -- npx @playwright/mcp@latest
# Next.js dev server xatolari va marshrutlari (ixtiyoriy)
claude mcp add next-devtools -- npx next-devtools-mcp@latest
```
Tekshirish: `claude mcp list`. GitHub uchun MCP shart emas — `gh` CLI yetarli.

Ixtiyoriy: Claude Code ichida `/plugin` orqali `frontend-design` plaginini o'rnatish (Next.js admin UI sifati uchun), agar marketplace'da mavjud bo'lsa.

## 3. Ruxsatlar
`.claude/settings.json` (to'plamda bor) — agentga git, gh, docker, python, npm, flutter buyruqlarini so'rovsiz bajarishga ruxsat beradi, xavfli buyruqlarni (force push, hard reset, volume o'chirish, `.env` o'qish) taqiqlaydi. Uni repo ildiziga qo'ying.

## 4. Agentni mustaqil ishlatishning 2 yo'li

### A. Kompyuteringizda, avtomatik sikl bilan (Windows build ham sinaladi)
Kompyuter yoqiq va uyqu rejimi o'chiq bo'lishi kerak. Repo papkasida `scripts/run-agent.ps1` yarating:
```powershell
New-Item -ItemType Directory -Force logs | Out-Null
$prompt = Get-Content prompts/01-next-task.md -Raw
for ($i = 1; $i -le 50; $i++) {
  if (Test-Path STOP) { break }                                   # to'xtatish: repo ildizida STOP fayl yarating
  if (-not (Select-String -Path docs/ROADMAP.md -Pattern '\[ \]|\[~\]' -Quiet)) { break }
  "=== Sessiya $i  $(Get-Date) ===" | Tee-Object -Append logs/agent.log
  claude -p $prompt --max-turns 300 2>&1 | Tee-Object -Append logs/agent.log
  if ($i % 5 -eq 0) { claude -p (Get-Content prompts/02-self-review.md -Raw) --max-turns 150 2>&1 | Tee-Object -Append logs/agent.log }
}
```
Ishga tushirish: `powershell -ExecutionPolicy Bypass -File scripts/run-agent.ps1`.
`logs/` ni `.gitignore` ga qo'shing.

### B. Bulutda (kompyuter o'chiq bo'lsa ham)
claude.ai/code da repo'ni ulab, sessiyaga `prompts/01-next-task.md` matnini bering. Backend, admin va Flutter testlari bulutda ishlaydi; faqat Windows build'ni keyin o'z kompyuteringizda `flutter build windows` bilan tekshirasiz.

Tavsiya: kunduzi A (Windows sinovi bilan), uzoq vaqt yo'q bo'lsangiz B.

## 5. Siz qaytganingizda nimani tekshirasiz (10 daqiqa)
1. `docs/PROGRESS.md` — nima qilindi.
2. `docs/QUESTIONS.md` — sizdan nima so'raldi; javobni shu faylga yozing.
3. GitHub'da merge qilingan PR'lar va skrinshotlar.
4. `flutter run -d windows` — kassani o'zingiz sinab ko'ring (skaner bilan!).
5. Xato bo'lsa — `prompts/04-bugfix.md` ga tavsif yozib agentga bering.

## 6. Agent o'zi qila olmaydigan ishlar
- Haqiqiy skaner, printer, pul qutisini sinash (siz sinab, natijani `docs/QUESTIONS.md` yoki bugfix promptiga yozasiz).
- Kassirlar bilan suhbat va pilot.
- Server ijarasi, domen, to'lov tizimlari bilan shartnomalar.
- Biznes qarorlari (narx, tariflar).
