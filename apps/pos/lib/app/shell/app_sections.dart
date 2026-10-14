import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Ilova bo'limlari — navigatsiya tartibi shu ro'yxat tartibi.
enum AppSection {
  pos('/pos', Icons.point_of_sale_outlined, Icons.point_of_sale),
  products('/products', Icons.inventory_2_outlined, Icons.inventory_2),
  receiving('/receiving', Icons.move_to_inbox_outlined, Icons.move_to_inbox),
  customers('/customers', Icons.people_outline, Icons.people),
  reports('/reports', Icons.bar_chart_outlined, Icons.bar_chart),
  settings('/settings', Icons.settings_outlined, Icons.settings)
  ;

  const AppSection(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    pos => l10n.navPos,
    products => l10n.navProducts,
    receiving => l10n.navReceiving,
    customers => l10n.navCustomers,
    reports => l10n.navReports,
    settings => l10n.navSettings,
  };

  /// Desktop tezkor tugmasi: Ctrl+1 … Ctrl+6 (F-tugmalar kassa ekraniga
  /// band: F1 qidiruv, F2 miqdor, … F12 to'lash).
  SingleActivator get shortcut =>
      SingleActivator(_digitKeys[index], control: true);

  String get shortcutLabel => 'Ctrl+${index + 1}';

  PosDestination destination(AppLocalizations l10n) => PosDestination(
    icon: icon,
    selectedIcon: selectedIcon,
    label: label(l10n),
    shortcut: shortcutLabel,
  );

  static const List<LogicalKeyboardKey> _digitKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
  ];
}
