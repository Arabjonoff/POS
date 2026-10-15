import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/scanner/scanner_settings.dart';
import 'package:pos_app/app/shell/app_status_bar.dart';
import 'package:pos_app/app/shell/subscription_banner.dart';
import 'package:pos_app/app/sync/sales_gate.dart';
import 'package:pos_app/app/sync/subscription_notice.dart';
import 'package:pos_app/core/barcode/barcode.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/data/catalog/product_editor.dart'
    show stockByProductProvider;
import 'package:pos_app/data/catalog/top_sellers.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/refunds/refund_writer.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/cart/cart_controller.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/features/pos/payment/customer_picker.dart';
import 'package:pos_app/features/pos/payment/payment_dialog.dart';
import 'package:pos_app/features/pos/widgets/cart_panel.dart';
import 'package:pos_app/features/pos/widgets/discount_dialog.dart';
import 'package:pos_app/features/pos/widgets/product_panel.dart';
import 'package:pos_app/features/pos/widgets/qty_dialog.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/products/product_card.dart';
import 'package:pos_app/features/refunds/refund_dialog.dart';
import 'package:pos_app/features/scanner/camera_scan_page.dart';
import 'package:pos_app/features/shift/cash_movement_dialog.dart';
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

  /// `null` — standart: "Sevimlilar" (bo'lsa), aks holda "Hammasi".
  ProductTab? _tab;

  /// Oxirgi skanerlangan, bazada yo'q kod (qizil xabar).
  String? _notFound;

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

  bool _wasActive = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Boshqa bo'limdan qaytildi (Ctrl+1 yoki menyu): bo'lim almashganda fokus
    // yo'qoladi — tezkor tugmalar (F12 …) yana ishlashi uchun qaytarib olamiz.
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_wasActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusScreen());
    }
    _wasActive = active;
  }

  /// Fokus kassa ekraniga (tezkor tugmalar va "fokus yana skanerga").
  /// Boshqa sahifa yoki oynadagi aniq maydon fokusini tortib olmaymiz.
  void _focusScreen() {
    if (!mounted || _dialogOpen || !TickerMode.valuesOf(context).enabled) {
      return;
    }
    final focus = FocusManager.instance.primaryFocus;
    final other = focus?.context;
    if (focus != null &&
        focus is! FocusScopeNode &&
        other != null &&
        !_screenFocus.hasFocus) {
      final route = ModalRoute.of(other);
      if (route != null && route != ModalRoute.of(context) && route.isCurrent) {
        return;
      }
    }
    _screenFocus.requestFocus();
  }

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

  /// Tab bosildi: qidiruv tozalanadi (natija hamma tovardan edi).
  void _selectTab(ProductTab tab) {
    _search.clear();
    setState(() {
      _results = const [];
      _tab = tab;
    });
    _focusScreen();
  }

  /// "Sevimlilar": tez tugmalar, keyin so'nggi 30 kunda ko'p sotilganlar.
  List<CatalogProduct> _favorites(ProductCatalog catalog) {
    final seen = <String>{};
    final top = ref.watch(topSellersProvider).value ?? const <String>[];
    return [
      for (final p in catalog.quick())
        if (seen.add(p.id)) p,
      ...top
          .map(catalog.byId)
          .nonNulls
          .where((p) => p.isActive && seen.add(p.id)),
    ];
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
    // Qoldiq yo'q — savdo to'xtamaydi (qoldiq eskirgan bo'lishi mumkin),
    // lekin kassir bilsin.
    final stock = StockView.of(ref.read(stockByProductProvider).value);
    final out = stock.isOut(product);
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
    _added(scanned: barcode != null);
    if (out && mounted) {
      showPosToast(
        context,
        message: l10n.posOutOfStockAdded(product.name),
        tone: PosTone.warning,
      );
    }
  }

  /// Tovar savatga tushdi. Chaqnash va signal — faqat skaner uchun: oddiy
  /// bosishda savatdagi yangi qator belgilanadi, ekran chaqnamaydi.
  void _added({required bool scanned}) {
    if (scanned) {
      _feedback.flash(PosScanResult.success);
      unawaited(ref.read(scanSignalProvider).success());
    }
    if (_notFound != null) setState(() => _notFound = null);
    if (_hasQuery) _clearSearch();
    _focusScreen();
  }

  /// Kod bazada yo'q: qizil xabar kod bilan (keyingi skangacha yoki
  /// yopilguncha) + xato ovozi; "Yangi tovar qo'shish" shu kod bilan.
  void _showNotFound(String code) {
    _feedback.flash(PosScanResult.error);
    unawaited(ref.read(scanSignalProvider).notFound());
    setState(() => _notFound = code);
  }

  /// Topilmagan kod bilan tovar kartasi; saqlansa — darhol chekka.
  Future<void> _addNewProduct(String code) async {
    final id = await _dialog(() => showProductCard(context, barcode: code));
    if (!mounted) return;
    setState(() => _notFound = null);
    if (id == null) return _focusScreen();
    // Katalog bazadan qayta quriladi — yangi tovar paydo bo'lishini kutamiz.
    var product = _catalog.byId(id);
    for (var i = 0; product == null && i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      product = _catalog.byId(id);
    }
    if (product != null) {
      await _pick(product, barcode: code);
    } else {
      _focusScreen();
    }
  }

  void _warn(String message, {PosScanResult result = PosScanResult.warning}) {
    _feedback.flash(result);
    unawaited(ref.read(scanSignalProvider).notFound());
    showPosToast(context, message: message, tone: PosTone.warning);
  }

  void _onScan(ScanEvent event) {
    if (_dialogOpen) return;
    // Yangi skan — eski "topilmadi" xabari endi tegishli emas.
    if (_notFound != null) setState(() => _notFound = null);
    final l10n = AppLocalizations.of(context);
    if (Barcodes.check(event.code) == BarcodeCheck.invalidCheckDigit) {
      _warn(l10n.scanInvalidCode, result: PosScanResult.error);
      return;
    }
    final match = _catalog.byCode(event.code);
    if (match == null) {
      _showNotFound(event.code);
      return;
    }
    if (!match.product.sellable) {
      _warn(l10n.posNotSellable);
      return;
    }
    if (match.weighted) {
      _cart.addMatch(match);
      _added(scanned: true);
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

  /// F12: to'lov oynasi. Yakunlansa — savat bo'shaydi, 3 s xabar (qaytim
  /// bilan), fokus yana skanerga.
  Future<void> _pay() async {
    final cart = _state.cart;
    if (!ref.read(salesAllowedProvider) || cart.isEmpty || _dialogOpen) return;
    final result = await _dialog(() => showPaymentDialog(context, cart: cart));
    if (result == null || !mounted) return _focusScreen();
    _cart.clearActive();
    final l10n = AppLocalizations.of(context);
    final change = result.changeTiyin;
    final done = change > 0
        ? l10n.paySaleDoneChange(context.fmt.money(change))
        : l10n.paySaleDone;
    showPosToast(
      context,
      message: done,
      tone: PosTone.success,
      duration: const Duration(seconds: 3),
    );
    _focusScreen();
    final printer = ref.read(printerSettingsProvider).value;
    if (printer != null && printer.configured && printer.autoPrint) {
      // Chek fonda: savdo uni kutmaydi, xato savdoni to'xtatmaydi.
      unawaited(_printReceipt(result.sale.id, done: done));
    } else if (printer != null && printer.configured && printer.openDrawer) {
      // Chek chiqmasa ham naqd savdoda pul qutisi ochiladi (audit PRN-B14).
      unawaited(
        ref.read(printerServiceProvider).openDrawerForSale(result.sale.id),
      );
    }
  }

  /// [done] — savdo xabari: chek xatosi uni yopsa ham qaytim ko'rinib tursin.
  Future<void> _printReceipt(
    String saleId, {
    bool copy = false,
    String? done,
  }) async {
    final outcome = await ref
        .read(printerServiceProvider)
        .printSale(saleId, copy: copy);
    if (!mounted || outcome == PrintOutcome.printed) return;
    // Qayta urinish — o'sha chek (birinchi chop etish xato bo'lsa, mijozga
    // "NUSXA" belgili chek chiqmasin; audit PRN-B13).
    _receiptFailed(
      () => unawaited(_printReceipt(saleId, copy: copy)),
      done: done,
    );
  }

  /// "Oxirgi chek": oxirgi savdo nusxasi.
  Future<void> _reprintLast() async {
    final outcome = await ref.read(printerServiceProvider).reprintLast();
    if (!mounted || outcome == PrintOutcome.printed) return;
    _receiptFailed(() => unawaited(_reprintLast()));
  }

  void _receiptFailed(VoidCallback retry, {String? done}) {
    final l10n = AppLocalizations.of(context);
    showPosToast(
      context,
      message: done == null
          ? l10n.posReceiptFailed
          : l10n.posSaleDoneReceiptFailed(done),
      tone: PosTone.warning,
      actionLabel: l10n.posReprint,
      onAction: retry,
      duration: const Duration(seconds: 8),
    );
  }

  /// F8: qaytarish (menejer/ega tasdig'i bilan).
  Future<void> _openRefund() async {
    final result = await _dialog(() => showRefundDialog(context));
    if (result != null && mounted) {
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
    _focusScreen();
  }

  /// F9: kassaga pul kiritish/chiqarish.
  Future<void> _openCash() async {
    final result = await _dialog(() => showCashMovementDialog(context));
    if (result != null && mounted) showCashMovementDone(context, result);
    _focusScreen();
  }

  /// F4: chek mijozi.
  Future<void> _chooseCustomer() async {
    final choice = await _dialog(
      () => showCustomerDialog(context, selectedId: _state.cart.customerId),
    );
    if (choice != null) _cart.setCustomer(choice.customer?.id);
    _focusScreen();
  }

  /// Oyna ochiq paytda skaner ro'yxati o'chadi — raqamlar oynaga tushadi.
  Future<T?> _dialog<T>(Future<T?> Function() open) async {
    setState(() => _dialogOpen = true);
    try {
      return await open();
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _openQuickSheet() async {
    final catalog = _catalog;
    final favorites = _favorites(catalog);
    final stock = StockView.of(ref.read(stockByProductProvider).value);
    final picked = await _dialog(
      () => showModalBottomSheet<CatalogProduct>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => _QuickSheet(
          catalog: catalog,
          favorites: favorites,
          stock: stock,
        ),
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
    if (key == LogicalKeyboardKey.f4) {
      unawaited(_chooseCustomer());
      return true;
    }
    if (key == LogicalKeyboardKey.f8) {
      unawaited(_openRefund());
      return true;
    }
    if (key == LogicalKeyboardKey.f9) {
      unawaited(_openCash());
      return true;
    }
    if (key == LogicalKeyboardKey.f6) {
      _newCart();
      return true;
    }
    if (key == LogicalKeyboardKey.f12) {
      unawaited(_pay());
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_notFound != null) {
        setState(() => _notFound = null);
      } else if (_hasQuery) {
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
    // Qidiruvda Enter — tanlangan natija savatga (telefon klaviaturasi —
    // `onSubmitted`).
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        searching &&
        _hasQuery) {
      _pickHighlighted();
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

  String? _customerName(Cart cart) {
    final id = cart.customerId;
    if (id == null) return null;
    for (final c
        in ref.watch(customersProvider).value ?? const <CustomerEntry>[]) {
      if (c.id == id) return c.name;
    }
    return null;
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
      enabled: !_dialogOpen,
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
    final printer = ref.watch(printerSettingsProvider).value;
    final canPrint = printer != null && printer.configured;
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
            onChanged: (q) {
              if (_notFound != null) setState(() => _notFound = null);
              _onQuery(q);
            },
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
        if (canPrint) ...[
          const SizedBox(width: PosSpacing.s),
          PosIconButton(
            key: const ValueKey('pos-last-receipt'),
            icon: Icons.print_outlined,
            tooltip: l10n.posLastReceipt,
            variant: PosIconButtonVariant.outlined,
            onPressed: () => unawaited(_reprintLast()),
          ),
        ],
        if (!compact) ...[
          const SizedBox(width: PosSpacing.s),
          PosButton(
            key: const ValueKey('pos-refund'),
            label: l10n.refundTitle,
            icon: Icons.assignment_return_outlined,
            variant: PosButtonVariant.secondary,
            shortcut: 'F8',
            onPressed: () => unawaited(_openRefund()),
          ),
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

  /// Skanerlangan kod bazada yo'q: kod, "Yangi tovar qo'shish", yopish.
  Widget? _notFoundBar() {
    final code = _notFound;
    if (code == null) return null;
    final l10n = AppLocalizations.of(context);
    final c = PosPalette.of(context).tone(PosTone.danger);
    return Semantics(
      key: const ValueKey('pos-not-found'),
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          PosSpacing.l,
          PosSpacing.s,
          PosSpacing.s,
          PosSpacing.s,
        ),
        decoration: BoxDecoration(
          color: c.soft,
          borderRadius: PosRadius.controlAll,
          border: Border.all(color: c.text.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: c.onSoft),
            const SizedBox(width: PosSpacing.m),
            Expanded(
              child: Text(
                l10n.posCodeNotFoundCode(code),
                style: PosTypography.bodyStrong.copyWith(
                  color: c.onSoft,
                  fontFeatures: PosTypography.tabular,
                ),
              ),
            ),
            const SizedBox(width: PosSpacing.s),
            PosButton(
              key: const ValueKey('pos-add-product'),
              label: l10n.posAddNewProduct,
              icon: Icons.add,
              size: PosButtonSize.s,
              onPressed: () => unawaited(_addNewProduct(code)),
            ),
            PosIconButton(
              icon: Icons.close,
              tooltip: l10n.actionClose,
              onPressed: () {
                setState(() => _notFound = null);
                _focusScreen();
              },
            ),
          ],
        ),
      ),
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
    final l10n = AppLocalizations.of(context);
    final help = salesBlockHelp(l10n, block);
    // Oflaynda — internetga ulanish kifoya; boshqalarida — kim bilan bog'lanish.
    final contact = block == SalesBlock.offlineTooLong
        ? null
        : contactLine(l10n, ref.watch(supportPhoneProvider));
    return NoticeBar(
      key: const ValueKey('sales-block-banner'),
      tone: PosTone.danger,
      icon: Icons.block,
      rounded: true,
      text: salesBlockLabel(l10n, block),
      detail: help,
      extra: contact,
    );
  }

  Widget _twoPane(CartState state, ProductCatalog catalog, SalesBlock block) {
    final p = PosPalette.of(context);
    final banner = _banner(block);
    final notFound = _notFoundBar();
    final favorites = _favorites(catalog);
    final tab =
        _tab ?? (favorites.isEmpty ? const AllTab() : const FavoritesTab());
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
                if (notFound != null) ...[
                  const SizedBox(height: PosSpacing.m),
                  notFound,
                ],
                const SizedBox(height: PosSpacing.m),
                Expanded(
                  child: ProductGrid(
                    catalog: catalog,
                    // "Sevimlilar" bo'shab qolsa — "Hammasi".
                    tab: tab is FavoritesTab && favorites.isEmpty
                        ? const AllTab()
                        : tab,
                    onTab: _selectTab,
                    onPick: (p) => unawaited(_pick(p)),
                    favorites: favorites,
                    stock: StockView.of(
                      ref.watch(stockByProductProvider).value,
                    ),
                    results: _hasQuery ? _results : null,
                    highlighted: _highlighted,
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
                      customerName: _customerName(state.cart),
                      payEnabled: block == SalesBlock.none,
                      onDiscount: () => unawaited(_discount()),
                      onCustomer: () => unawaited(_chooseCustomer()),
                      onRemoveCustomer: () => _cart.setCustomer(null),
                      onPay: () => unawaited(_pay()),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PosIconButton(
                  key: const ValueKey('pos-refund'),
                  icon: Icons.assignment_return_outlined,
                  tooltip: AppLocalizations.of(context).refundTitle,
                  variant: PosIconButtonVariant.outlined,
                  onPressed: () => unawaited(_openRefund()),
                ),
                const SizedBox(width: PosSpacing.s),
                PosIconButton(
                  icon: Icons.receipt_long_outlined,
                  tooltip: AppLocalizations.of(context).shiftTitle,
                  variant: PosIconButtonVariant.outlined,
                  onPressed: () => context.go('/pos/shift'),
                ),
              ],
            ),
          ),
        ),
        for (final bar in [banner, _notFoundBar()])
          if (bar != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PosSpacing.l,
                PosSpacing.s,
                PosSpacing.l,
                0,
              ),
              child: bar,
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
              onPay: () => unawaited(_pay()),
            ),
          ),
        ),
      ],
    );
  }
}

/// Telefon: tovar kartalari alohida varaqda.
class _QuickSheet extends StatefulWidget {
  const _QuickSheet({
    required this.catalog,
    required this.favorites,
    required this.stock,
  });

  final ProductCatalog catalog;
  final List<CatalogProduct> favorites;
  final StockView stock;

  @override
  State<_QuickSheet> createState() => _QuickSheetState();
}

class _QuickSheetState extends State<_QuickSheet> {
  late ProductTab _tab = widget.favorites.isEmpty
      ? const AllTab()
      : const FavoritesTab();

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
              child: ProductGrid(
                catalog: widget.catalog,
                tab: _tab,
                onTab: (t) => setState(() => _tab = t),
                onPick: (product) => Navigator.of(context).pop(product),
                favorites: widget.favorites,
                stock: widget.stock,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
