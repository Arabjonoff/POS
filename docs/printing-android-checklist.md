# Android chek printeri — qo'lda sinov ro'yxati (T-047)

Agent muhitida Android qurilma va printer yo'q, shuning uchun Bluetooth/USB ulanishi faqat soxta kanal bilan sinalgan
(`docs/specs/printing.md`). Birinchi do'konga o'rnatishdan oldin quyidagilarni haqiqiy qurilmada tekshiring va natijani
`docs/PROGRESS.md` ga yozing (qurilma, Android versiyasi, printer modeli, natija).

## Tayyorlash
- Debug yoki release APK: `cd apps/pos && flutter build apk --dart-define=POS_API_URL=...` (`docs/RELEASE.md`).
- Kamida bitta Android 12+ (yangi Bluetooth ruxsatlari) va iloji bo'lsa Android 8–11 qurilma.
- Printerlar: Bluetooth (masalan Xprinter XP-P323B / XP-58IIB, MTP-II), USB (Xprinter XP-58/80), OTG kabel.

## Bluetooth
1. [ ] Printer telefonning Bluetooth sozlamalarida juftlangan (PIN 0000 yoki 1234).
2. [ ] Sozlamalar → Chek printeri → **Bluetooth**: Android 12+ da "Yaqin qurilmalar" ruxsati so'raladi; "Ruxsat berish" → ro'yxat chiqadi.
3. [ ] Ruxsat rad etilsa — "Printerga ulanish uchun ruxsat bering" xabari; ilova yiqilmaydi. Telefon sozlamalarida ruxsat berib,
   "Ro'yxatni yangilash" — ro'yxat chiqadi.
4. [ ] Bluetooth o'chiq — "Bluetooth o'chiq — telefon sozlamalarida yoqing".
5. [ ] Printer tanlanadi → **Test chek**: sinov qismi va namuna chek to'liq chiqadi (oxirgi qatorlar va kesish ham), kirill harflari to'g'ri.
6. [ ] Kassada savdo → chek avtomatik chiqadi; 2 nusxa sozlanganda ikkala nusxa to'liq.
7. [ ] Uzun chek (30+ qator) va logotipli chek — kesilmasdan, oxirigacha chiqadi.
8. [ ] Printer o'chirilgan holda savdo → savdo saqlanadi, "Chek yopildi — chop etilmadi", "Qayta chop etish" printer yoqilgach ishlaydi.
   Ulanishni kutish fonda — kassa bu vaqtda ishlayveradi.
9. [ ] Holat qatori: printer juftlangan va Bluetooth yoqiq — "Printer ulangan"; Bluetooth o'chirilsa (ilova qayta ochilganda) — "ulanmagan".
10. [ ] Pul qutisi (printer orqali ulangan bo'lsa) naqd savdoda ochiladi.

## USB
1. [ ] Printer OTG orqali ulangan → Sozlamalar → **USB**: printer ro'yxatda (USB skaner ro'yxatda **yo'q**).
2. [ ] Tanlab "Test chek" → tizim ruxsat oynasi → "OK" → chek chiqadi. Keyingi cheklarda oyna chiqmaydi.
3. [ ] Ruxsat rad etilsa — "chop etilmadi", ilova yiqilmaydi.
4. [ ] Kabel uzilsa — sozlamada printer "Hozir topilmadi" bilan qoladi; savdo to'xtamaydi. Qayta ulanganda (ilova qayta ochilmasdan) chek chiqadi.
5. [ ] Bir vaqtda USB skaner va USB printer (OTG hub) — skaner savdo ekranida ishlayveradi.

## Natija
- Muammo bo'lsa: qurilma, Android versiyasi, printer modeli, aniq xabar → `docs/QUESTIONS.md` (Q-007) yoki yangi vazifa.
- Sunmi/iMin kabi ichki printerli qurilmalar SPP/USB orqali ishlamasligi mumkin — alohida transport kerak bo'ladi (Q-007).
