import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Ilova bo'limlari — navigatsiya tartibi shu ro'yxat tartibi.
enum AppSection {
  pos('/pos', Icons.point_of_sale_outlined, Icons.point_of_sale, 1),
  sales('/sales', Icons.receipt_outlined, Icons.receipt, 7),
  products('/products', Icons.inventory_2_outlined, Icons.inventory_2, 2),
  receiving(
    '/receiving',
    Icons.move_to_inbox_outlined,
    Icons.move_to_inbox,
    3,
  ),
  customers('/customers', Icons.people_outline, Icons.people, 4),
  reports('/reports', Icons.bar_chart_outlined, Icons.bar_chart, 5),
  settings('/settings', Icons.settings_outlined, Icons.settings, 6)
  ;

  const AppSection(this.path, this.icon, this.selectedIcon, this.digit);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  /// Ctrl+raqam. "Cheklar" (T-109) keyin qo'shildi — Ctrl+7, qolganlari
  /// kassirlar odatiga ko'ra o'zgarmaydi.
  final int digit;

  String label(AppLocalizations l10n) => switch (this) {
    pos => l10n.navPos,
    sales => l10n.navSales,
    products => l10n.navProducts,
    receiving => l10n.navReceiving,
    customers => l10n.navCustomers,
    reports => l10n.navReports,
    settings => l10n.navSettings,
  };

  /// Desktop tezkor tugmasi: Ctrl+1 … Ctrl+7 (F-tugmalar kassa ekraniga
  /// band: F1 qidiruv, F2 miqdor, … F12 to'lash).
  SingleActivator get shortcut =>
      SingleActivator(_digitKeys[digit - 1], control: true);

  String get shortcutLabel => 'Ctrl+$digit';

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
    LogicalKeyboardKey.digit7,
  ];
}
