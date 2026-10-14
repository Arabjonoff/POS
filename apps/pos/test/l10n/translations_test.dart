import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tarjima fayllari va "kodda qattiq yozilgan matn yo'q" qoidasi
/// (CLAUDE.md, 6-qoida).
void main() {
  Map<String, dynamic> readArb(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, dynamic>;

  final template = readArb('app_uz.arb');
  final messageKeys = template.keys.where((k) => !k.startsWith('@')).toSet();

  /// Shablondagi `placeholders` nomlari (masalan, `count`).
  Set<String> placeholdersOf(String key) {
    final meta = template['@$key'] as Map<String, dynamic>?;
    final defs = meta?['placeholders'] as Map<String, dynamic>?;
    return defs?.keys.toSet() ?? const {};
  }

  group('ARB files', () {
    for (final file in ['app_uz_Cyrl.arb', 'app_ru.arb']) {
      test('$file has exactly the same keys as app_uz.arb', () {
        final arb = readArb(file);
        final keys = arb.keys.where((k) => !k.startsWith('@')).toSet();
        expect(keys.difference(messageKeys), isEmpty, reason: 'ortiqcha');
        expect(messageKeys.difference(keys), isEmpty, reason: 'tarjima yo‘q');
      });

      test('$file messages are not empty and keep placeholders', () {
        final arb = readArb(file);
        for (final key in messageKeys) {
          final value = arb[key] as String;
          expect(value.trim(), isNotEmpty, reason: key);
          for (final name in placeholdersOf(key)) {
            expect(value, contains('{$name'), reason: '$key: {$name}');
          }
        }
      });
    }

    test('every template message has a description', () {
      for (final key in messageKeys) {
        if (key.startsWith('@@')) continue;
        final meta = template['@$key'] as Map<String, dynamic>?;
        expect(meta?['description'], isA<String>(), reason: key);
      }
    });
  });

  group('no hard-coded user-facing text in lib/', () {
    // Foydalanuvchiga ko'rinadigan matn qabul qiladigan parametrlar.
    const params =
        'label|title|subtitle|message|hint|hintText|labelText|helperText|'
        'errorText|tooltip|semanticLabel|semanticsLabel|actionLabel|'
        'backspaceTooltip|clearTooltip|decrementTooltip|incrementTooltip|'
        'currency|unit|text';
    final textCall = RegExp(r'''\bText\(\s*['"]([^'"]*)['"]''');
    final namedParam = RegExp('\\b(?:$params)\\s*:\\s*[\'"]([^\'"]*)[\'"]');
    final hasLetter = RegExp(r'\p{L}', unicode: true);

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.replaceAll(r'\', '/').contains('/l10n/gen/'),
        )
        .toList();

    test('scans source files', () => expect(files, isNotEmpty));

    test('Text(...) and label/title/... params use l10n', () {
      final offenders = <String>[];
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (final (i, line) in lines.indexed) {
          if (line.contains('i18n-ignore')) continue;
          for (final re in [textCall, namedParam]) {
            for (final m in re.allMatches(line)) {
              if (hasLetter.hasMatch(m.group(1)!)) {
                offenders.add('${file.path}:${i + 1}: ${line.trim()}');
              }
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the check itself catches a hard-coded string', () {
      expect(textCall.hasMatch("Text('Salom')"), isTrue);
      expect(namedParam.hasMatch("label: 'Saqlash'"), isTrue);
      expect(namedParam.hasMatch('label: l10n.actionSave'), isFalse);
      expect(
        hasLetter.hasMatch(textCall.firstMatch("Text('12:00')")!.group(1)!),
        isFalse,
      );
    });
  });
}
