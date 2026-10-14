import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/scanner/scanner_settings.dart';
import 'package:pos_app/app/shell/app_status_bar.dart';
import 'package:pos_app/app/sync/sales_gate.dart';
import 'package:pos_app/core/barcode/barcode.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/cart/cart_controller.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/features/pos/widgets/cart_panel.dart';
import 'package:pos_app/features/pos/widgets/discount_dialog.dart';
import 'package:pos_app/features/pos/widgets/product_panel.dart';
import 'package:pos_app/features/pos/widgets/qty_dialog.dart';
import 'package:pos_app/features/scanner/camera_scan_page.dart';
import 'package:pos_app/features/shift/open_shift_card.dart';
import 'package:pos_app/features/shift/shift_providers.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Kassa ekrani (`docs/specs/pos-screen.md`). Smena ochilmaguncha savat
/// o'rnida "Smenani oching" kartasi.
class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(currentShiftProvider);
    final cart = ref.watch(cartControllerProvider);
    if (!shift.hasValue || !cart.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (shift.value == null) return const OpenShiftCard();
    return const CashierView();
  }
}

/// Smena ochiq: qidiruv/tez tugmalar + savat. Tezkor tugmalar (F1…F12,
/// Delete, ↑/↓, Esc) fokus shu ekranda bo'lganda ishlaydi (oyna ochiq
/// bo'lsa — yo'q); skaner — har doim (`barcode.md`).
class CashierView extends ConsumerStatefulWidget {
  const CashierView({super.key});

  /// Kontent shu kenglikdan katta bo'lsa — ikki panel (chap 60%, o'ng 40%).
  static const double twoPaneMinWidth = 720;

  @override
  ConsumerState<CashierView> createState() => _CashierViewState();
}

class _CashierViewState extends ConsumerState<CashierView> {
  final _screenFocus = FocusNode(debugLabel: 'cashier');
  final _searchFocus = FocusNode(debugLabel: 'search');
  final _search = TextEditingController();
  final _feedback = PosScanFeedbackController();

  List<CatalogProduct> _results = const [];
  int _highlighted = 0;
  String? _category;

  /// Oyna ochiq — tezkor tugmalar va ikkinchi oyna kutadi.
  bool _dialogOpen = false;

  CartController get _cart => ref.read(cartControllerProvider.notifier);

  CartState get _state => ref.read(cartControllerProvider).requireValue;

  ProductCatalog get _catalog =>
      ref.read(productCatalogProvider).value ?? ProductCatalog(const []);

  bool get _hasQuery => _search.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusScreen());
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _screenFocus.dispose();
    _searchFocus.dispose();
    _search.dispose();
    _feedback.dispose();
    super.dispose();
  }

  void _focusScreen() {
    if (!mounted) return;
    final focus = FocusManager.instance.primaryFocus;
    final inside =
        _screenFocus.hasFocus || focus == null || focus.context == null;
    // Boshqa ekran/oyna fokusini tortib olmaymiz.
    if (inside || !_isTopmost(focus.context!)) _screenFocus.requestFocus();
  }

  bool _isTopmost(BuildContext other) =>
      ModalRoute.of(other)?.isCurrent ?? true;

  // ---- Qidiruv ----------------------------------------------------------

  void _onQuery(String query) {
    setState(() {
      _results = _catalog.search(query);
      _highlighted = 0;
    });
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _results = const []);
  }

  /// Matn maydoni fokusda bo'lmaganda yozilgan matn (skaner xizmati orqali).
  void _onTyping(String text) {
    if (_dialogOpen) return;
    final value = _search.text + text;
    final end = TextSelection.collapsed(offset: value.length);
    _search.value = TextEditingValue(text: value, selection: end);
    _searchFocus.requestFocus();
    // Desktopda fokus olgan maydon butun matnni belgilaydi — keyingi harf
    // uni almashtirmasin: kursor oxirga.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _search.text == value) _search.selection = end;
    });
    _onQuery(value);
  }

  void _pickHighlighted() {
    if (_results.isEmpty) return;
    unawaited(_pick(_results[_highlighted.clamp(0, _results.length - 1)]));
  }

  // ---- Savatga qo'shish -------------------------------------------------

  Future<void> _pick(CatalogProduct product, {String? barcode}) async {
    final l10n = AppLocalizations.of(context);
    if (!product.sellable) {
      _warn(l10n.posNotSellable);
      return;
    }
    if (product.isWeighted) {
      final qty = await _dialog(
        () => showQtyDialog(
          context,
          productName: product.name,
          weighted: true,
          unit: UnitCode.fromCode(product.unit).label(l10n),
        ),
      );
      if (qty == null || !mounted) return;
      _cart.add(product, qtyMilli: qty, barcode: barcode);
    } else {
      _cart.add(product, barcode: barcode);
    }
    _added();
  }

  void _added() {
    _feedback.flash(PosScanResult.success);
    unawaited(ref.read(scanSignalProvider).success());
    if (_hasQuery) _clearSearch();
    _focusScreen();
  }

  void _warn(String message, {PosScanResult result = PosScanResult.warning}) {
    _feedback.flash(result);
    unawaited(ref.read(scanSignalProvider).notFound());
    showPosToast(context, message: message, tone: PosTone.warning);
  }

  void _onScan(ScanEvent event) {
    if (_dialogOpen) return;
    final l10n = AppLocalizations.of(context);
    if (Barcodes.check(event.code) == BarcodeCheck.invalidCheckDigit) {
      _warn(l10n.scanInvalidCode, result: PosScanResult.error);
      return;
    }
    final match = _catalog.byCode(event.code);
    if (match == null) {
      _warn(l10n.posCodeNotFound);
      return;
    }
    if (!match.product.sellable) {
      _warn(l10n.posNotSellable);
      return;
    }
    if (match.weighted) {
      _cart.addMatch(match);
      _added();
      return;
    }
    unawaited(_pick(match.product, barcode: match.code));
  }

  // ---- Qator amallari ---------------------------------------------------

  Future<void> _editQty(CartLine line) async {
    final l10n = AppLocalizations.of(context);
    final unit = UnitCode.fromCode(line.unit);
    final qty = await _dialog(
      () => showQtyDialog(
        context,
        productName: line.name,
        weighted: line.weighted || unit.fractional,
        unit: unit.label(l10n),
        initialMilli: line.qtyMilli,
      ),
    );
    if (qty != null) _cart.setQty(line.id, qty);
    _focusScreen();
  }

  void _remove(CartLine line) {
    final removed = _cart.remove(line.id);
    if (removed == null) return;
    final l10n = AppLocalizations.of(context);
    showPosToast(
      context,
      message: l10n.posLineRemoved(line.name),
      actionLabel: l10n.actionUndo,
      onAction: () => _cart.undoRemove(removed),
    );
  }

  Future<void> _discount() async {
    final state = _state;
    final cart = state.cart;
    if (cart.isEmpty) return;
    final line = state.selectedLine;
    final choice = await _dialog(
      () => showDiscountDialog(
        context,
        hasLine: line != null,
        lineBase: line?.grossTiyin ?? 0,
        checkBase: cart.subtotalTiyin,
        lineDiscount: line?.discount,
        checkDiscount: cart.discount,
      ),
    );
    if (choice == null || !mounted) return _focusScreen();
    var discount = choice.discount;
    if (discount != null) {
      final policy = await ref.read(discountPolicyProvider.future);
      final base = choice.target == DiscountTarget.line
          ? line!.grossTiyin
          : cart.subtotalTiyin;
      if (policy.needsApproval(discount, base)) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        final approver = await _dialog(
          () => requestManagerApproval(
            context,
            reason: l10n.posDiscountNeedsApproval(
              '${policy.cashierMaxBp ~/ 100}',
            ),
          ),
        );
        if (approver == null) return _focusScreen();
        discount = discount.approved(approver);
      }
    }
    if (choice.target == DiscountTarget.line) {
      _cart.setLineDiscount(line!.id, discount);
    } else {
      _cart.setCartDiscount(discount);
    }
    _focusScreen();
  }

  void _newCart() {
    if (!_cart.newCart()) {
      showPosToast(
        context,
        message: AppLocalizations.of(context).posCartLimit,
        tone: PosTone.warning,
      );
    }
    _focusScreen();
  }

  void _pay() {
    final allowed = ref.read(salesAllowedProvider);
    if (!allowed || _state.cart.isEmpty) return;
    // To'lov oynasi — T-043.
    showPosToast(
      context,
      message: AppLocalizations.of(context).posPayComingSoon,
    );
  }

  Future<T?> _dialog<T>(Future<T?> Function() open) async {
    _dialogOpen = true;
    try {
      return await open();
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _openQuickSheet() async {
    final picked = await _dialog(
      () => showModalBottomSheet<CatalogProduct>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => _QuickSheet(catalog: _catalog),
      ),
    );
    if (picked != null && mounted) await _pick(picked);
  }

  // ---- Klaviatura -------------------------------------------------------

  bool _onKey(KeyEvent event) {
    if (event is KeyUpEvent || _dialogOpen || !mounted) return false;
    if (!TickerMode.valuesOf(context).enabled) return false;
    // Fokus boshqa sahifa/oynada (masalan, smena sahifasi) — tegmaymiz.
    if (!_screenFocus.hasFocus) return false;
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed || keyboard.isAltPressed) return false;
    final searching = _searchFocus.hasFocus;

    if (key == LogicalKeyboardKey.f1) {
      _searchFocus.requestFocus();
      _search.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _search.text.length,
      );
      return true;
    }
    if (key == LogicalKeyboardKey.f2) {
      final line = _state.selectedLine ?? _lastLine;
      if (line != null) unawaited(_editQty(line));
      return true;
    }
    if (key == LogicalKeyboardKey.f3) {
      unawaited(_discount());
      return true;
    }
    if (key == LogicalKeyboardKey.f6) {
      _newCart();
      return true;
    }
    if (key == LogicalKeyboardKey.f12) {
      _pay();
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_hasQuery) {
        _clearSearch();
      } else if (searching) {
        _focusScreen();
      } else {
        _cart.select(null);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final delta = key == LogicalKeyboardKey.arrowUp ? -1 : 1;
      if (_hasQuery) {
        if (_results.isEmpty) return true;
        setState(() {
          _highlighted = (_highlighted + delta).clamp(0, _results.length - 1);
        });
      } else {
        _cart.moveSelection(delta);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.delete) {
      // Qidiruvda matn bor — Delete matnni o'chiradi.
      if (searching && _hasQuery) return false;
      final line = _state.selectedLine;
      if (line != null) _remove(line);
      return true;
    }
    return false;
  }

  CartLine? get _lastLine {
    final lines = _state.cart.lines;
    return lines.isEmpty ? null : lines.last;
  }

  // ---- Maket ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartControllerProvider).requireValue;
    final catalog =
        ref.watch(productCatalogProvider).value ?? ProductCatalog(const []);
    final block = ref.watch(salesBlockProvider);

    return ScanListener(
      onScan: _onScan,
      onTyping: _onTyping,
      child: Focus(
        focusNode: _screenFocus,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= CashierView.twoPaneMinWidth
              ? _twoPane(state, catalog, block)
              : _onePane(state, block),
        ),
      ),
    );
  }

  Widget _searchRow({required bool compact}) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: PosSearchField(
            controller: _search,
            focusNode: _searchFocus,
            hint: l10n.posSearchHint,
            clearTooltip: l10n.actionClear,
            shortcut: compact ? null : 'F1',
            large: !compact,
            onChanged: _onQuery,
            onSubmitted: (_) => _pickHighlighted(),
          ),
        ),
        if (cameraScanAvailable) ...[
          const SizedBox(width: PosSpacing.s),
          PosIconButton(
            icon: Icons.qr_code_scanner,
            tooltip: l10n.scanCamera,
            variant: PosIconButtonVariant.outlined,
            onPressed: () => unawaited(openCameraScanner(context)),
          ),
        ],
        if (compact) ...[
          const SizedBox(width: PosSpacing.s),
          PosIconButton(
            icon: Icons.grid_view_outlined,
            tooltip: l10n.posQuickButtons,
            variant: PosIconButtonVariant.outlined,
            onPressed: () => unawaited(_openQuickSheet()),
          ),
        ],
        if (!compact) ...[
          const SizedBox(width: PosSpacing.s),
          PosButton(
            label: l10n.shiftTitle,
            icon: Icons.receipt_long_outlined,
            variant: PosButtonVariant.secondary,
            onPressed: () => context.go('/pos/shift'),
          ),
        ],
      ],
    );
  }

  Widget _lines(CartState state, {required bool swipe}) {
    final l10n = AppLocalizations.of(context);
    if (state.cart.isEmpty) {
      return PosEmptyState(
        icon: Icons.qr_code_scanner,
        title: l10n.posEmptyCart,
      );
    }
    return CartLines(
      state: state,
      swipeToRemove: swipe,
      onSelect: (id) {
        _cart.select(id);
        _focusScreen();
      },
      onQtyChanged: (line, qty) => _cart.setQty(line.id, qty),
      onQtyTap: (line) => unawaited(_editQty(line)),
      onRemove: _remove,
    );
  }

  Widget? _banner(SalesBlock block) {
    if (block == SalesBlock.none) return null;
    final p = PosPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(PosSpacing.m),
      decoration: BoxDecoration(
        color: p.dangerSoft,
        borderRadius: PosRadius.controlAll,
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: p.onDangerSoft),
          const SizedBox(width: PosSpacing.s),
          Expanded(
            child: Text(
              salesBlockLabel(AppLocalizations.of(context), block),
              style: PosTypography.bodyStrong.copyWith(color: p.onDangerSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoPane(CartState state, ProductCatalog catalog, SalesBlock block) {
    final p = PosPalette.of(context);
    final banner = _banner(block);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(PosSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _searchRow(compact: false),
                const SizedBox(height: PosSpacing.m),
                Expanded(
                  child: _hasQuery
                      ? SearchResults(
                          results: _results,
                          highlighted: _highlighted,
                          onPick: (p) => unawaited(_pick(p)),
                        )
                      : QuickPanel(
                          catalog: catalog,
                          category: _category,
                          onCategory: (c) => setState(() => _category = c),
                          onPick: (p) => unawaited(_pick(p)),
                        ),
                ),
              ],
            ),
          ),
        ),
        Container(width: 1, color: p.border),
        Expanded(
          flex: 2,
          child: ColoredBox(
            color: p.surface,
            child: PosScanFeedback(
              controller: _feedback,
              child: Padding(
                padding: const EdgeInsets.all(PosSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CartTabs(
                      state: state,
                      onSelect: _cart.switchTo,
                      onNew: _newCart,
                    ),
                    if (banner != null) ...[
                      const SizedBox(height: PosSpacing.s),
                      banner,
                    ],
                    const SizedBox(height: PosSpacing.s),
                    Expanded(child: _lines(state, swipe: false)),
                    const SizedBox(height: PosSpacing.m),
                    CartSummary(
                      cart: state.cart,
                      payEnabled: block == SalesBlock.none,
                      onDiscount: () => unawaited(_discount()),
                      onPay: _pay,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _onePane(CartState state, SalesBlock block) {
    final p = PosPalette.of(context);
    final banner = _banner(block);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PosSpacing.l,
            PosSpacing.m,
            PosSpacing.l,
            0,
          ),
          child: _searchRow(compact: true),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PosSpacing.l,
            PosSpacing.s,
            PosSpacing.l,
            0,
          ),
          child: CartTabs(
            state: state,
            compact: true,
            onSelect: _cart.switchTo,
            onNew: _newCart,
            trailing: PosIconButton(
              icon: Icons.receipt_long_outlined,
              tooltip: AppLocalizations.of(context).shiftTitle,
              variant: PosIconButtonVariant.outlined,
              onPressed: () => context.go('/pos/shift'),
            ),
          ),
        ),
        if (banner != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PosSpacing.l,
              PosSpacing.s,
              PosSpacing.l,
              0,
            ),
            child: banner,
          ),
        Expanded(
          child: PosScanFeedback(
            controller: _feedback,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PosSpacing.l),
              child: _hasQuery
                  ? SearchResults(
                      results: _results,
                      highlighted: _highlighted,
                      onPick: (p) => unawaited(_pick(p)),
                    )
                  : _lines(state, swipe: true),
            ),
          ),
        ),
        // Yopishqoq panel: JAMI + To'lash.
        DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PosSpacing.m),
            child: CartSummary(
              cart: state.cart,
              compact: true,
              payEnabled: block == SalesBlock.none,
              onDiscount: () => unawaited(_discount()),
              onPay: _pay,
            ),
          ),
        ),
      ],
    );
  }
}

/// Telefon: tez tugmalar alohida varaqda.
class _QuickSheet extends StatefulWidget {
  const _QuickSheet({required this.catalog});

  final ProductCatalog catalog;

  @override
  State<_QuickSheet> createState() => _QuickSheetState();
}

class _QuickSheetState extends State<_QuickSheet> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Padding(
        padding: const EdgeInsets.all(PosSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.posQuickButtons,
              style: PosTypography.h3.copyWith(color: p.text),
            ),
            const SizedBox(height: PosSpacing.m),
            Expanded(
              child: QuickPanel(
                catalog: widget.catalog,
                category: _category,
                onCategory: (c) => setState(() => _category = c),
                onPick: (product) => Navigator.of(context).pop(product),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
