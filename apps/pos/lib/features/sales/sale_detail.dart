import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/shell/app_sections.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/refunds/refund_writer.dart';
import 'package:pos_app/data/sales/remote_sale.dart';
import 'package:pos_app/features/common/load_state.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/receipt_loader.dart';
import 'package:pos_app/features/printing/receipt_preview.dart';
import 'package:pos_app/features/refunds/refund_dialog.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Chek tafsiloti uchun ma'lumot: chek (printerdagidek), holat, qaytarishlar.
class SaleDetailData {
  const SaleDetailData({
    required this.receipt,
    required this.status,
    required this.refunds,
    this.otherKassa,
  });

  /// Boshqa kassa cheki (serverdan, T-110).
  factory SaleDetailData.remote(RemoteSale sale, ReceiptData receipt) =>
      SaleDetailData(
        receipt: receipt,
        status: sale.status,
        otherKassa: sale.sale.deviceNumber,
        refunds: [
          for (final r in sale.refunds)
            SaleRefundInfo(
              at: r.at,
              method: r.method,
              totalTiyin: r.totalTiyin,
              reason: r.reason,
            ),
        ],
      );

  final ReceiptData receipt;

  /// `completed` / `partially_refunded` / `refunded`.
  final String status;
  final List<SaleRefundInfo> refunds;

  /// Boshqa kassa raqami (serverdan olingan chek); shu kassaniki — `null`.
  final int? otherKassa;
}

/// Chekdagi qaytarish (ro'yxat uchun).
class SaleRefundInfo {
  const SaleRefundInfo({
    required this.at,
    required this.method,
    required this.totalTiyin,
    required this.reason,
  });

  final DateTime at;

  /// `cash` / `debt`.
  final String method;
  final int totalTiyin;
  final String reason;
}

/// Server chekini chek ko'rinishiga (do'kon, birliklar, qarz — lokal baza).
ReceiptSource remoteReceiptSource(RemoteSale remote) {
  final sale = remote.sale;
  return ReceiptSource(
    storeId: sale.store,
    number: sale.number,
    soldAt: sale.soldAt,
    cashierName: sale.cashierName,
    customerId: sale.customer,
    discountTiyin: sale.discountTiyin,
    totalTiyin: sale.totalTiyin,
    items: [
      for (final i in sale.items)
        ReceiptSourceItem(
          productId: i.product,
          name: i.nameSnapshot,
          qtyMilli: i.qtyMilli,
          priceTiyin: i.priceTiyin,
          discountTiyin: i.discountTiyin,
          totalTiyin: i.totalTiyin,
        ),
    ],
    payments: [
      for (final p in sale.payments)
        ReceiptPayment(
          method: p.method.json ?? 'cash',
          amountTiyin: p.amountTiyin,
          receivedTiyin: p.receivedTiyin,
          changeTiyin: p.changeTiyin,
        ),
    ],
  );
}

/// Savdo yoki qaytarish o'zgarsa qayta o'qiladi; chek yo'q — `null`.
final StreamProviderFamily<SaleDetailData?, String> saleDetailProvider =
    StreamProvider.autoDispose.family<SaleDetailData?, String>((ref, saleId) {
      final db = ref.watch(appDatabaseProvider);
      final loader = ref.watch(receiptLoaderProvider);
      return db
          .customSelect('SELECT 1', readsFrom: {db.sales, db.refunds})
          .watch()
          .asyncMap((_) async {
            final sale = await (db.select(
              db.sales,
            )..where((s) => s.id.equals(saleId))).getSingleOrNull();
            final receipt = await loader.load(saleId);
            if (sale == null || receipt == null) return null;
            final refunds =
                await (db.select(db.refunds)
                      ..where((r) => r.saleId.equals(saleId))
                      ..orderBy([(r) => OrderingTerm.asc(r.at)]))
                    .get();
            return SaleDetailData(
              receipt: receipt,
              status: sale.status,
              refunds: [
                for (final r in refunds)
                  SaleRefundInfo(
                    at: r.at,
                    method: r.method,
                    totalTiyin: r.totalTiyin,
                    reason: r.reason,
                  ),
              ],
            );
          });
    });

/// Cheklar tarixida tanlangan chek: ko'rinish, qayta chop etish (NUSXA),
/// qaytarish (`receipt-history.md`). [onClose] — tor ekranda orqaga.
/// [saleId] — shu kassa cheki; [remote] — boshqa kassa cheki (T-110).
class SaleDetail extends ConsumerStatefulWidget {
  const SaleDetail({
    required this.onDialog,
    this.saleId,
    this.remote,
    this.onClose,
    super.key,
  }) : assert((saleId == null) != (remote == null), 'saleId yoki remote');

  final String? saleId;
  final RemoteSale? remote;
  final VoidCallback? onClose;

  /// Qaytarish oynasi ochildi/yopildi (ekran skanerini o'chirish uchun).
  final ValueChanged<bool> onDialog;

  @override
  ConsumerState<SaleDetail> createState() => _SaleDetailState();
}

class _SaleDetailState extends ConsumerState<SaleDetail> {
  /// Chek ochilganda fokus panelga: Ctrl+P va Esc darhol ishlaydi.
  final _focus = FocusNode(debugLabel: 'sale-detail');
  bool _printing = false;

  /// Boshqa kassa cheki: qaytarishdan keyin serverdan yangilanadi.
  late RemoteSale? _remote = widget.remote;
  SaleDetailData? _remoteData;

  Future<void> _buildRemote() async {
    final remote = _remote;
    if (remote == null) return;
    final receipt = await ref
        .read(receiptLoaderProvider)
        .fromSource(remoteReceiptSource(remote));
    if (mounted) {
      setState(() => _remoteData = SaleDetailData.remote(remote, receipt));
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_buildRemote());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && TickerMode.valuesOf(context).enabled) {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _reprint() async {
    if (_printing) return;
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(printerSettingsProvider).value;
    if (settings == null || !settings.configured) {
      showPosToast(
        context,
        message: l10n.printerNotConfigured,
        tone: PosTone.warning,
        actionLabel: l10n.salesSetUpPrinter,
        onAction: () => context.go(AppSection.settings.path),
      );
      return;
    }
    setState(() => _printing = true);
    final printer = ref.read(printerServiceProvider);
    final remote = _remoteData;
    final outcome = remote != null
        ? await printer.printReceipt(remote.receipt, copy: true)
        : await printer.printSale(widget.saleId!, copy: true);
    if (!mounted) return;
    setState(() => _printing = false);
    if (outcome == PrintOutcome.printed) {
      showPosToast(context, message: l10n.printerSent, tone: PosTone.success);
    } else {
      showPosToast(
        context,
        message: l10n.posReceiptFailed,
        tone: PosTone.warning,
        actionLabel: l10n.posReprint,
        onAction: () => unawaited(_reprint()),
        duration: const Duration(seconds: 8),
      );
    }
  }

  Future<void> _refund() async {
    widget.onDialog(true);
    final remote = _remote;
    final result = await showRefundDialog(
      context,
      saleId: widget.saleId,
      sale: remote?.refundable,
    );
    widget.onDialog(false);
    if (result == null || !mounted) return;
    if (remote != null) {
      // Qaytarish lokal yozildi (outbox) — serverdagi holat + lokal qaytarish.
      final fresh = await ref
          .read(remoteSalesProvider)
          .find(remote.sale.number);
      if (fresh is RemoteSaleFound && mounted) {
        _remote = fresh.sale;
        await _buildRemote();
      }
      if (!mounted) return;
    }
    final l10n = AppLocalizations.of(context);
    final amount = context.fmt.money(result.totalTiyin);
    showPosToast(
      context,
      message: result.method == RefundMethod.cash
          ? l10n.refundDoneCash(amount)
          : l10n.refundDoneDebt(amount),
      tone: PosTone.success,
      duration: const Duration(seconds: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final saleId = widget.saleId;
    final detail = saleId == null
        ? null
        : ref.watch(saleDetailProvider(saleId));
    final data = saleId == null ? _remoteData : detail?.value;
    if (data == null) {
      return LoadState(
        failed: detail?.hasError ?? false,
        onRetry: () {
          if (saleId != null) ref.invalidate(saleDetailProvider(saleId));
        },
      );
    }
    final p = PosPalette.of(context);
    final fmt = context.fmt;
    final settings =
        ref.watch(printerSettingsProvider).value ?? const PrinterSettings();
    final rows = ref.watch(printerServiceProvider).previewRows(data.receipt);
    final receipt = data.receipt;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () =>
            unawaited(_reprint()),
      },
      child: Focus(
        focusNode: _focus,
        child: ListView(
          key: const ValueKey('sale-detail'),
          padding: const EdgeInsets.only(bottom: PosSpacing.l),
          children: [
            Row(
              children: [
                if (widget.onClose != null) ...[
                  PosIconButton(
                    key: const ValueKey('sale-detail-back'),
                    icon: Icons.arrow_back,
                    tooltip: l10n.labelWithShortcut(l10n.salesBack, 'Esc'),
                    onPressed: widget.onClose,
                  ),
                  const SizedBox(width: PosSpacing.s),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.number,
                        style: PosTypography.h3.copyWith(color: p.text),
                      ),
                      Text(
                        fmt.dateTime(receipt.soldAt),
                        style: PosTypography.small.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                      if (data.otherKassa case final kassa?) ...[
                        const SizedBox(height: PosSpacing.xs),
                        PosBadge(
                          key: const ValueKey('sale-other-kassa'),
                          label: l10n.salesOtherKassa(kassa),
                          tone: PosTone.primary,
                          icon: Icons.cloud_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
                if (data.status == 'refunded')
                  PosBadge(
                    label: l10n.salesStatusRefunded,
                    tone: PosTone.danger,
                  )
                else if (data.status == 'partially_refunded')
                  PosBadge(
                    label: l10n.salesStatusPartial,
                    tone: PosTone.warning,
                  ),
              ],
            ),
            const SizedBox(height: PosSpacing.m),
            Wrap(
              spacing: PosSpacing.s,
              runSpacing: PosSpacing.s,
              children: [
                PosButton(
                  key: const ValueKey('sale-reprint'),
                  label: l10n.posReprint,
                  icon: Icons.print_outlined,
                  shortcut: 'Ctrl+P',
                  loading: _printing,
                  onPressed: () => unawaited(_reprint()),
                ),
                PosButton(
                  key: const ValueKey('sale-refund'),
                  label: l10n.refundTitle,
                  icon: Icons.assignment_return_outlined,
                  variant: PosButtonVariant.secondary,
                  onPressed: data.status == 'refunded'
                      ? null
                      : () => unawaited(_refund()),
                ),
              ],
            ),
            if (data.refunds.isNotEmpty) ...[
              const SizedBox(height: PosSpacing.l),
              Text(
                l10n.salesRefunds,
                style: PosTypography.smallStrong.copyWith(
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(height: PosSpacing.xs),
              for (final r in data.refunds)
                PosListTile(
                  leading: const Icon(Icons.assignment_return_outlined),
                  title: fmt.money(r.totalTiyin),
                  subtitle: [
                    fmt.dateTime(r.at),
                    if (r.method == 'debt')
                      l10n.refundMethodDebt
                    else
                      l10n.refundMethodCash,
                    if (r.reason.isNotEmpty) r.reason,
                  ].join(' · '),
                ),
            ],
            const SizedBox(height: PosSpacing.l),
            ReceiptPreview(
              key: const ValueKey('sale-receipt-preview'),
              rows: rows,
              width: settings.width,
              encoding: settings.encoding,
            ),
          ],
        ),
      ),
    );
  }
}
