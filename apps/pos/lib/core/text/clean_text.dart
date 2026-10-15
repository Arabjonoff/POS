/// Foydalanuvchi kiritgan bir qatorli matn (tovar, mijoz nomi): boshqaruv
/// belgilari (NUL, ESC, tab, yangi qator...) olib tashlanadi, ketma-ket
/// bo'shliqlar bittaga qisqaradi. Boshqaruv belgilari printerga buyruq bo'lib
/// ketadi, NUL esa serverda saqlanmaydi (audit PR-P0-2).
String cleanLine(String text) => text
    .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Belgilar soni (Unicode kod nuqtalari) — server `max_length` bilan bir xil.
int codePointLength(String text) => text.runes.length;
