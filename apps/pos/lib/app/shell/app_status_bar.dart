import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/app/sync/sales_gate.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Holat qatori: internet, navbatdagi yozuvlar, printer, smena (+ soat
/// desktopda). Doim ko'rinadi (CLAUDE.md, UI/UX qoidalari).
class AppStatusBar extends ConsumerWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final connection = ref.watch(connectionStatusProvider);
    final printer = ref.watch(printerStatusProvider);
    final queued = ref.watch(pendingEventsProvider).value ?? 0;
    final shiftOpen = ref.watch(shiftOpenProvider).value ?? false;

    final connectionItem = switch (connection) {
      ConnectionStatus.unknown => PosStatusItem(
        icon: Icons.wifi_find,
        label: l10n.statusConnectionUnknown,
      ),
      ConnectionStatus.online => PosStatusItem(
        icon: Icons.wifi,
        label: l10n.statusOnline,
        tone: PosTone.success,
      ),
      ConnectionStatus.offline => PosStatusItem(
        icon: Icons.wifi_off,
        // Telefonda qisqa: joy tor, navbat soni alohida yozuvda.
        label: queued > 0 && !compact
            ? l10n.statusOfflineSaving(queued)
            : l10n.statusOffline,
        tone: PosTone.warning,
      ),
    };

    final block = ref.watch(salesBlockProvider);
    final rejected = ref.watch(rejectedEventsProvider).value ?? 0;
    final skew = ref.watch(clockSkewProvider);

    final items = [
      // Eng muhimi — birinchi: savdo to'xtagan bo'lsa, sababi.
      if (block != SalesBlock.none)
        PosStatusItem(
          icon: Icons.block,
          label: switch (block) {
            SalesBlock.readonly => l10n.statusSalesReadonly,
            SalesBlock.blocked => l10n.statusSalesBlocked,
            SalesBlock.offlineTooLong => l10n.statusSalesOffline,
            SalesBlock.deviceBlocked => l10n.statusDeviceBlocked,
            SalesBlock.none => '',
          },
          tone: PosTone.danger,
        ),
      connectionItem,
      PosStatusItem(
        icon: queued > 0 ? Icons.sync : Icons.cloud_done_outlined,
        label: l10n.statusQueued(queued),
      ),
      switch (printer) {
        PrinterStatus.unknown => PosStatusItem(
          icon: Icons.print_outlined,
          label: l10n.statusPrinterUnknown,
        ),
        PrinterStatus.ready => PosStatusItem(
          icon: Icons.print_outlined,
          label: l10n.statusPrinterReady,
          tone: PosTone.success,
        ),
        PrinterStatus.missing => PosStatusItem(
          icon: Icons.print_disabled_outlined,
          label: l10n.statusPrinterMissing,
          tone: PosTone.danger,
        ),
      },
      if (rejected > 0)
        PosStatusItem(
          icon: Icons.error_outline,
          label: l10n.statusRejected(rejected),
          tone: PosTone.danger,
        ),
      if (skew)
        PosStatusItem(
          icon: Icons.schedule,
          label: l10n.statusClockSkew,
          tone: PosTone.warning,
        ),
      if (shiftOpen)
        PosStatusItem(
          icon: Icons.schedule,
          label: l10n.statusShiftOpen,
          tone: PosTone.success,
        )
      else
        PosStatusItem(
          icon: Icons.schedule,
          label: l10n.statusShiftClosed,
          tone: PosTone.warning,
        ),
    ];

    return PosStatusBar(
      atTop: compact,
      items: items,
      trailing: compact ? null : const _Clock(),
    );
  }
}

/// Soat (daqiqa aniqligida, do'kon vaqt zonasida).
class _Clock extends ConsumerStatefulWidget {
  const _Clock();

  @override
  ConsumerState<_Clock> createState() => _ClockState();
}

class _ClockState extends ConsumerState<_Clock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    return Text(
      context.fmt.time(now),
      style: PosTypography.small.copyWith(fontFeatures: PosTypography.tabular),
    );
  }
}
