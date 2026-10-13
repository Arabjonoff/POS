import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

void main() {
  test('light theme uses design tokens', () {
    final theme = PosTheme.light();
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, PosColors.lightPrimary);
    expect(theme.scaffoldBackgroundColor, PosColors.lightBackground);
  });

  test('dark theme uses design tokens', () {
    final theme = PosTheme.dark();
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, PosColors.darkPrimary);
    expect(theme.scaffoldBackgroundColor, PosColors.darkBackground);
  });
}
