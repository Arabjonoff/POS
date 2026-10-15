/// O'zbekiston telefon raqami — server bilan bir xil qoida
/// (`backend/apps/core/phone.py`): `90 123 45 67`, `+998 (90) 123-45-67`,
/// `998901234567` → `+998901234567`.
///
/// Bo'sh matn → `''` (telefon ixtiyoriy). Noto'g'ri raqam → `null`.
String? normalizePhone(String raw) {
  var value = raw.replaceAll(RegExp(r'[\s\-()]'), '');
  if (value.isEmpty) return '';
  if (value.startsWith('+')) value = value.substring(1);
  if (!RegExp(r'^\d+$').hasMatch(value)) return null;
  if (value.length == 9) value = '998$value';
  if (!RegExp(r'^998\d{9}$').hasMatch(value)) return null;
  return '+$value';
}
