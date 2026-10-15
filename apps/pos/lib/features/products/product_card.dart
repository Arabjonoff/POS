import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/core/money/grouped_money_formatter.dart';
import 'package:pos_app/data/catalog/price_history.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/data/catalog/product_images.dart';
import 'package:pos_app/data/catalog/stock_history.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/features/products/product_list.dart';
import 'package:pos_app/features/products/product_thumbnail.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Tovar kartasi (`products.md`): yangi ([productId] `null`, [barcode] —
/// skanerdan) yoki mavjud. Natija — saqlangan tovar ID si.
Future<String?> showProductCard(
  BuildContext context, {
  String? productId,
  String? barcode,
}) => showPosDialog<String>(
  context: context,
  maxWidth: ProductCard.maxWidth,
  builder: (context) => ProductCard(productId: productId, barcode: barcode),
);

/// So'm matnidan tiyin: `12500`, `12 500`, `12500,50` (2 kasr xonagacha).
int? parseMoneyTiyin(String text) {
  final clean = text.replaceAll(RegExp(r'[\s  ]'), '');
  if (clean.isEmpty) return 0;
  final match = RegExp(r'^(\d{1,12})(?:[.,](\d{1,2}))?$').firstMatch(clean);
  if (match == null) return null;
  final som = int.parse(match.group(1)!);
  final frac = (match.group(2) ?? '').padRight(2, '0');
  return som * 100 + int.parse(frac);
}

/// Tiyin → maydon matni, mingliklar guruhlangan (`DecimalMoneyFormatter`).
String formatMoneyInput(int tiyin) {
  if (tiyin == 0) return '';
  final whole = GroupedMoneyFormatter.format('${tiyin ~/ 100}');
  final rest = tiyin % 100;
  return rest == 0 ? whole : '$whole,${rest.toString().padLeft(2, '0')}';
}

/// Miqdor matnidan `qty_milli`: dona — butun, kasrli birlik — 3 xonagacha.
int? parseQtyMilli(String text, {required bool fractional}) {
  final clean = text.replaceAll(RegExp(r'\s'), '');
  if (clean.isEmpty) return 0;
  final pattern = fractional
      ? RegExp(r'^(\d{1,9})(?:[.,](\d{1,3}))?$')
      : RegExp(r'^(\d{1,9})$');
  final match = pattern.firstMatch(clean);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final frac = ((match.groupCount >= 2 ? match.group(2) : null) ?? '').padRight(
    3,
    '0',
  );
  return whole * 1000 + (frac.isEmpty ? 0 : int.parse(frac));
}

String formatQtyInput(int milli, {required bool fractional}) {
  if (milli == 0) return '';
  if (!fractional || milli % 1000 == 0) return '${milli ~/ 1000}';
  final frac = (milli % 1000)
      .toString()
      .padLeft(3, '0')
      .replaceFirst(
        RegExp(r'0+$'),
        '',
      );
  return '${milli ~/ 1000},$frac';
}

class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({this.productId, this.barcode, super.key});

  static const double maxWidth = 640;

  final String? productId;
  final String? barcode;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  final _name = TextEditingController();
  final _sell = TextEditingController();
  final _cost = TextEditingController();
  final _plu = TextEditingController();
  final _minStock = TextEditingController();
  final _ikpu = TextEditingController();
  final _barcode = TextEditingController();

  ProductDraft? _draft;
  List<ProductProblem> _problems = const [];

  /// Kiritish xatolari (raqam emas): narx va minimal qoldiq.
  bool _badPrice = false;
  bool _badMinStock = false;

  /// Saqlash jarayoni (qayta bosishdan himoya — darhol yoqiladi).
  bool _busy = false;

  /// Haqiqiy yozish (tugmada spinner) — menejer PIN kutilayotganda emas.
  bool _saving = false;
  bool _subDialog = false;

  /// Rasm (T-105): joriy rasm id, yangi tanlangan (tayyorlangan JPEG) yoki
  /// olib tashlash — tovar saqlangandan keyin qo'llanadi.
  String? _imageId;
  Uint8List? _newImage;
  bool _removeImage = false;
  bool _imageBusy = false;
  bool _showHistory = false;
  bool _showMoves = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final c in [_name, _sell, _cost, _plu, _minStock, _ikpu, _barcode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.productId;
    final db = ref.read(appDatabaseProvider);
    ProductDraft draft;
    if (id != null) {
      draft =
          await ref.read(productEditorProvider).load(id) ??
          const ProductDraft();
    } else {
      final pcs =
          await (db.select(db.units)
                ..where((u) => u.code.equals(UnitCode.pcs.code))
                ..limit(1))
              .getSingleOrNull();
      draft = ProductDraft(
        unitId: pcs?.id,
        barcodes: [if (widget.barcode != null) widget.barcode!.trim()],
      );
    }
    final imageId = id == null
        ? null
        : (await (db.select(
            db.products,
          )..where((p) => p.id.equals(id))).getSingleOrNull())?.imageId;
    if (!mounted) return;
    final units = await db.select(db.units).get();
    final fractional =
        units.where((u) => u.id == draft.unitId).firstOrNull?.isFractional ??
        false;
    setState(() {
      _draft = draft;
      _imageId = imageId;
      _name.text = draft.name;
      _sell.text = formatMoneyInput(draft.sellPriceTiyin);
      _cost.text = formatMoneyInput(draft.costPriceTiyin);
      _plu.text = draft.pluCode;
      _minStock.text = formatQtyInput(
        draft.minStockMilli,
        fractional: fractional,
      );
      _ikpu.text = draft.ikpuCode;
    });
    // Skanerdan kelgan kod band bo'lsa — darhol ko'rsatiladi.
    if (draft.barcodes.isNotEmpty) await _check();
  }

  void _update(ProductDraft Function(ProductDraft) change) {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _draft = change(draft));
  }

  Future<void> _check() async {
    final draft = _draft;
    if (draft == null) return;
    final problems = await ref.read(productEditorProvider).validate(draft);
    if (!mounted) return;
    setState(
      () => _problems = [
        for (final p in problems)
          if (p.field == ProductField.barcodes) p,
      ],
    );
  }

  void _addBarcode(String raw) {
    final code = raw.trim();
    final draft = _draft;
    if (code.isEmpty || draft == null) return;
    _barcode.clear();
    if (!draft.barcodes.contains(code)) {
      _update((d) => d.copyWith(barcodes: [...d.barcodes, code]));
    }
    unawaited(_check());
  }

  void _removeBarcode(String code) {
    _update(
      (d) => d.copyWith(
        barcodes: [
          for (final b in d.barcodes)
            if (b != code) b,
        ],
      ),
    );
    unawaited(_check());
  }

  /// Matn maydonlaridan draft; noto'g'ri raqam — maydon ostida xato.
  ProductDraft? _collect(bool fractional) {
    final draft = _draft;
    if (draft == null) return null;
    final sell = parseMoneyTiyin(_sell.text);
    final cost = parseMoneyTiyin(_cost.text);
    final minStock = parseQtyMilli(_minStock.text, fractional: fractional);
    setState(() {
      _badPrice = sell == null || cost == null;
      _badMinStock = minStock == null;
    });
    if (sell == null || cost == null || minStock == null) return null;
    return draft.copyWith(
      name: _name.text,
      sellPriceTiyin: sell,
      costPriceTiyin: cost,
      pluCode: draft.isWeighted ? _plu.text : '',
      minStockMilli: minStock,
      ikpuCode: _ikpu.text,
    );
  }

  Future<void> _pickImage() async {
    if (_imageBusy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _imageBusy = true);
    try {
      final source = await ref.read(imageSourcePickerProvider)();
      if (source == null || !mounted) return;
      final jpeg = await ref.read(imagePreparerProvider)(source);
      if (!mounted) return;
      setState(() {
        _newImage = jpeg;
        _removeImage = false;
      });
    } on ProductImageException catch (e) {
      if (mounted) {
        showPosToast(
          context,
          message: e.reason == 'too_large'
              ? l10n.productImageTooLarge
              : l10n.productImageUnsupported,
          tone: PosTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _imageBusy = false);
    }
  }

  void _dropImage() => setState(() {
    _newImage = null;
    _removeImage = _imageId != null;
  });

  Future<void> _applyImage(String productId, {required String by}) async {
    final images = ref.read(productImageStoreProvider);
    final fresh = _newImage;
    if (fresh != null) {
      await images.setImage(productId, fresh, by: by);
    } else if (_removeImage) {
      await images.removeImage(productId, by: by);
    }
  }

  Future<void> _save({bool? active}) async {
    // Darhol band: tez ikki bosish yoki Enter ikki tovar yaratmasin
    // (audit UI-P1-2 — avval tekshiruv va ruxsatdan keyin band bo'lardi).
    if (_busy || _subDialog) return;
    setState(() => _busy = true);
    try {
      await _saveGuarded(active: active);
    } on Object catch (_) {
      // Kutilmagan xato (masalan, fon pull bilan to'qnashuv) — tugma
      // qotib qolmasin, foydalanuvchi bilsin (audit PR-P1-6).
      if (mounted) {
        showPosToast(
          context,
          message: AppLocalizations.of(context).productSaveFailed,
          tone: PosTone.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _saving = false;
        });
      }
    }
  }

  Future<void> _saveGuarded({bool? active}) async {
    final l10n = AppLocalizations.of(context);
    final units = ref.read(_unitsProvider).value ?? const <Unit>[];
    final fractional =
        units.where((u) => u.id == _draft?.unitId).firstOrNull?.isFractional ??
        false;
    var draft = _collect(fractional);
    if (draft == null) return;
    if (active != null) draft = draft.copyWith(isActive: active);
    final editor = ref.read(productEditorProvider);
    final problems = await editor.validate(draft);
    if (!mounted) return;
    if (problems.isNotEmpty) {
      setState(() => _problems = problems);
      return;
    }

    final user = ref.read(sessionProvider).user;
    if (user == null) return;
    var by = DiscountPolicy.canApprove(user.role) ? user.id : null;
    if (by == null) {
      setState(() => _subDialog = true);
      by = await requestManagerApproval(
        context,
        reason: l10n.productNeedsApproval,
      );
      if (!mounted) return;
      setState(() => _subDialog = false);
      if (by == null) return;
    }
    setState(() => _saving = true);
    try {
      final id = await editor.save(draft, by: by);
      await _applyImage(id, by: by);
      if (mounted) Navigator.of(context).pop(id);
    } on InvalidProductException catch (e) {
      if (mounted) setState(() => _problems = e.problems);
    }
  }

  String? _error(AppLocalizations l10n, ProductField field) {
    if (field == ProductField.price && _badPrice) return l10n.productErrPrice;
    for (final p in _problems) {
      if (p.field != field) continue;
      return _message(l10n, p);
    }
    return null;
  }

  String _message(AppLocalizations l10n, ProductProblem p) => switch (p.code) {
    ProductProblemCode.required => l10n.fieldRequired,
    ProductProblemCode.notPositive => l10n.productErrPrice,
    ProductProblemCode.tooLong => l10n.productErrNameTooLong(maxNameLength),
    ProductProblemCode.tooManyBarcodes => l10n.productErrTooManyBarcodes(
      maxBarcodes,
    ),
    ProductProblemCode.barcodeFormat => l10n.productErrBarcodeFormat(
      p.barcode ?? '',
    ),
    ProductProblemCode.barcodeCheckDigit => l10n.productErrBarcodeCheck(
      p.barcode ?? '',
    ),
    ProductProblemCode.barcodeRepeated => l10n.productErrBarcodeRepeated(
      p.barcode ?? '',
    ),
    ProductProblemCode.barcodeTaken => l10n.productErrBarcodeTaken(
      p.barcode ?? '',
      p.otherProduct ?? '',
    ),
    ProductProblemCode.pluFormat => l10n.productErrPluFormat,
    ProductProblemCode.pluTaken => l10n.productErrPluTaken(
      p.otherProduct ?? '',
    ),
    ProductProblemCode.weightedNeedsFractionalUnit =>
      l10n.productErrWeightedUnit,
    ProductProblemCode.ikpuFormat => l10n.productErrIkpu,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final draft = _draft;
    if (draft == null) {
      return const Padding(
        padding: EdgeInsets.all(PosSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final categories =
        ref.watch(productCategoriesProvider).value ?? const <ProductCategory>[];
    final units = ref.watch(_unitsProvider).value ?? const <Unit>[];
    final unit = units.where((u) => u.id == draft.unitId).firstOrNull;
    final unitCode = UnitCode.fromCode(unit?.code);
    final user = ref.watch(sessionProvider).user;
    final canSeeHistory =
        !draft.isNew && user != null && DiscountPolicy.canApprove(user.role);
    final stock = draft.isNew
        ? null
        : ref.watch(stockByProductProvider).value?[draft.id];
    final markup = (() {
      final sell = parseMoneyTiyin(_sell.text);
      final cost = parseMoneyTiyin(_cost.text);
      if (sell == null || cost == null) return null;
      return draft
          .copyWith(sellPriceTiyin: sell, costPriceTiyin: cost)
          .markupBp;
    })();
    final barcodeProblems = [
      for (final pr in _problems)
        if (pr.field == ProductField.barcodes) pr,
    ];

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: PosSpacing.m, bottom: PosSpacing.xs),
      child: Text(
        text,
        style: PosTypography.smallStrong.copyWith(color: p.textSecondary),
      ),
    );

    Widget chips<T>(
      List<(T, String)> options,
      T selected,
      ValueChanged<T> on,
    ) => Wrap(
      spacing: PosSpacing.s,
      runSpacing: PosSpacing.s,
      children: [
        for (final (value, text) in options)
          PosButton(
            key: ValueKey('product-chip-$value'),
            label: text,
            size: PosButtonSize.s,
            variant: value == selected
                ? PosButtonVariant.primary
                : PosButtonVariant.secondary,
            onPressed: () => on(value),
          ),
      ],
    );

    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[\d\s,.]'))];
    const money = [DecimalMoneyFormatter()];

    return ScanListener(
      enabled: !_subDialog,
      onScan: (e) => _addBarcode(e.code),
      child: PosDialog(
        icon: Icons.inventory_2_outlined,
        title: draft.isNew ? l10n.productNew : draft.name,
        message: stock == null
            ? null
            : l10n.productStockNow(fmt.qty(stock, unitCode)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImageSlot(
              imageId: _removeImage ? null : _imageId,
              fresh: _newImage,
              busy: _imageBusy,
              onPick: () => unawaited(_pickImage()),
              onRemove: _dropImage,
            ),
            const SizedBox(height: PosSpacing.m),
            PosTextField(
              key: const ValueKey('product-name'),
              controller: _name,
              label: l10n.productName,
              required: true,
              autofocus: draft.isNew,
              errorText: _error(l10n, ProductField.name),
              textInputAction: TextInputAction.next,
            ),
            label(l10n.productUnit),
            chips(
              [
                for (final u in units)
                  if (u.deletedAt == null)
                    (
                      u.id,
                      u.name.isNotEmpty
                          ? u.name
                          : UnitCode.fromCode(u.code).label(l10n),
                    ),
              ],
              draft.unitId,
              (id) => _update((d) => d.copyWith(unitId: id)),
            ),
            if (_error(l10n, ProductField.unit) case final error?)
              Padding(
                padding: const EdgeInsets.only(top: PosSpacing.xs),
                child: Text(
                  error,
                  style: PosTypography.small.copyWith(color: p.dangerText),
                ),
              ),
            label(l10n.productCategory),
            chips<String?>(
              [
                (null, l10n.productNoCategory),
                for (final c in categories) (c.id, c.name),
              ],
              draft.categoryId,
              (id) => _update(
                (d) => d.copyWith(categoryId: id, clearCategory: id == null),
              ),
            ),
            const SizedBox(height: PosSpacing.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PosTextField(
                    key: const ValueKey('product-sell'),
                    controller: _sell,
                    label: l10n.productSellPrice,
                    required: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: money,
                    errorText: _error(l10n, ProductField.price),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: PosSpacing.s),
                Expanded(
                  child: PosTextField(
                    key: const ValueKey('product-cost'),
                    controller: _cost,
                    label: l10n.productCostPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: money,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (markup != null)
              Padding(
                padding: const EdgeInsets.only(top: PosSpacing.xs),
                child: Text(
                  l10n.productMarkup(_percent(markup)),
                  style: PosTypography.small.copyWith(
                    color: markup < 0 ? p.dangerText : p.textSecondary,
                  ),
                ),
              ),
            label(l10n.productBarcodes),
            Wrap(
              spacing: PosSpacing.s,
              runSpacing: PosSpacing.s,
              children: [
                for (final (i, code) in draft.barcodes.indexed)
                  _BarcodeChip(
                    key: ValueKey('product-barcode-$code'),
                    code: code,
                    primary: i == 0,
                    onRemove: () => _removeBarcode(code),
                  ),
              ],
            ),
            const SizedBox(height: PosSpacing.s),
            PosTextField(
              key: const ValueKey('product-barcode-input'),
              controller: _barcode,
              hint: l10n.productBarcodeAdd,
              prefixIcon: Icons.qr_code_scanner,
              onSubmitted: _addBarcode,
            ),
            for (final pr in barcodeProblems)
              Padding(
                padding: const EdgeInsets.only(top: PosSpacing.xs),
                child: Text(
                  _message(l10n, pr),
                  style: PosTypography.small.copyWith(color: p.dangerText),
                ),
              ),
            const SizedBox(height: PosSpacing.s),
            PosListTile(
              leading: const Icon(Icons.scale_outlined),
              title: l10n.productWeighted,
              trailing: Switch(
                value: draft.isWeighted,
                onChanged: (v) => _update((d) => d.copyWith(isWeighted: v)),
              ),
              onTap: () =>
                  _update((d) => d.copyWith(isWeighted: !d.isWeighted)),
            ),
            if (draft.isWeighted)
              PosTextField(
                key: const ValueKey('product-plu'),
                controller: _plu,
                label: l10n.productPlu,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: _error(l10n, ProductField.plu),
              ),
            const SizedBox(height: PosSpacing.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PosTextField(
                    key: const ValueKey('product-min-stock'),
                    controller: _minStock,
                    label: l10n.productMinStock(unitCode.label(l10n)),
                    errorText: _badMinStock ? l10n.productErrQty : null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: digits,
                  ),
                ),
                const SizedBox(width: PosSpacing.s),
                Expanded(
                  child: PosTextField(
                    key: const ValueKey('product-ikpu'),
                    controller: _ikpu,
                    label: l10n.productIkpu,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: _error(l10n, ProductField.ikpu),
                  ),
                ),
              ],
            ),
            PosListTile(
              leading: const Icon(Icons.grid_view_outlined),
              title: l10n.productQuickButton,
              trailing: Switch(
                value: draft.quickButton,
                onChanged: (v) => _update((d) => d.copyWith(quickButton: v)),
              ),
              onTap: () =>
                  _update((d) => d.copyWith(quickButton: !d.quickButton)),
            ),
            if (canSeeHistory) ...[
              PosListTile(
                key: const ValueKey('product-history'),
                leading: const Icon(Icons.history),
                title: l10n.productPriceHistory,
                trailing: Icon(
                  _showHistory ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () => setState(() => _showHistory = !_showHistory),
              ),
              if (_showHistory) _PriceHistory(productId: draft.id!),
            ],
            if (!draft.isNew) ...[
              PosListTile(
                key: const ValueKey('product-stock-history'),
                leading: const Icon(Icons.swap_vert),
                title: l10n.productStockHistory,
                trailing: Icon(
                  _showMoves ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () => setState(() => _showMoves = !_showMoves),
              ),
              if (_showMoves)
                _StockHistoryList(productId: draft.id!, unit: unitCode),
            ],
            if (!draft.isActive)
              Padding(
                padding: const EdgeInsets.only(top: PosSpacing.s),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PosBadge(
                    label: l10n.productsBadgeInactive,
                    tone: PosTone.warning,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (!draft.isNew)
            PosButton(
              key: const ValueKey('product-toggle-active'),
              label: draft.isActive
                  ? l10n.productDeactivate
                  : l10n.productActivate,
              variant: draft.isActive
                  ? PosButtonVariant.ghost
                  : PosButtonVariant.secondary,
              onPressed: _busy
                  ? null
                  : () => unawaited(_save(active: !draft.isActive)),
            ),
          PosButton(
            label: l10n.actionCancel,
            variant: PosButtonVariant.secondary,
            shortcut: 'Esc',
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
          PosButton(
            key: const ValueKey('product-save'),
            label: l10n.actionSave,
            icon: Icons.check,
            loading: _saving,
            onPressed: _busy ? null : () => unawaited(_save()),
          ),
        ],
      ),
    );
  }

  /// Bazis punkt → `28,6%`.
  static String _percent(int bp) {
    final sign = bp < 0 ? '−' : '';
    final abs = bp.abs();
    final tenths = (abs + 5) ~/ 10;
    final whole = tenths ~/ 10;
    final rest = tenths % 10;
    return rest == 0 ? '$sign$whole%' : '$sign$whole,$rest%';
  }
}

/// Shtrix-kod: matn (asosiysi belgilangan) va olib tashlash tugmasi.
class _BarcodeChip extends StatelessWidget {
  const _BarcodeChip({
    required this.code,
    required this.primary,
    required this.onRemove,
    super.key,
  });

  final String code;
  final bool primary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: PosRadius.controlAll,
        border: Border.all(color: p.border),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: PosSpacing.m),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: PosTypography.bodyStrong.copyWith(
                color: p.text,
                fontFeatures: PosTypography.tabular,
              ),
            ),
            if (primary) ...[
              const SizedBox(width: PosSpacing.s),
              PosBadge(
                label: l10n.productBarcodePrimary,
                tone: PosTone.primary,
              ),
            ],
            PosIconButton(
              icon: Icons.close,
              tooltip: l10n.productBarcodeRemove,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

final _unitsProvider = StreamProvider<List<Unit>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.units)..where((u) => u.deletedAt.isNull())).watch();
});

/// Narx tarixi (onlayn): sana, narx, tannarx, kim.
class _PriceHistory extends ConsumerWidget {
  const _PriceHistory({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final history = ref.watch(priceHistoryProvider(productId));
    final style = PosTypography.small.copyWith(color: p.textSecondary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PosSpacing.l,
        0,
        PosSpacing.l,
        PosSpacing.s,
      ),
      child: history.when(
        loading: () => const LinearProgressIndicator(),
        // Tarix faqat serverda: har qanday xato — internet/server yo'q.
        error: (_, _) => Text(l10n.productPriceHistoryOffline, style: style),
        data: (rows) => rows.isEmpty
            ? Text(l10n.productPriceHistoryEmpty, style: style)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: PosSpacing.xs,
                      ),
                      child: Text(
                        [
                          fmt.dateTime(r.at),
                          l10n.productPriceHistoryRow(
                            fmt.money(r.sellPriceTiyin),
                            fmt.money(r.costPriceTiyin),
                          ),
                          if (r.byName != null) r.byName!,
                        ].join(' · '),
                        style: PosTypography.small.copyWith(color: p.text),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Qoldiq harakatlari: yuborilmaganlar (belgi bilan) va server tarixi.
class _StockHistoryList extends ConsumerWidget {
  const _StockHistoryList({required this.productId, required this.unit});

  final String productId;
  final UnitCode unit;

  static String _type(AppLocalizations l10n, String type) => switch (type) {
    'receipt' => l10n.moveReceipt,
    'sale' => l10n.moveSale,
    'refund' => l10n.moveRefund,
    'inventory' => l10n.moveInventory,
    _ => l10n.moveAdjustment,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final history = ref.watch(stockHistoryProvider(productId)).value;
    final style = PosTypography.small.copyWith(color: p.textSecondary);
    if (history == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: PosSpacing.l),
        child: LinearProgressIndicator(),
      );
    }
    final moves = history.all;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PosSpacing.l,
        0,
        PosSpacing.l,
        PosSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (moves.isEmpty && !history.offline)
            Text(l10n.stockHistoryEmpty, style: style),
          for (final m in moves)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        fmt.dateTime(m.at),
                        _type(l10n, m.type),
                        ?m.byName,
                      ].join(' · '),
                      style: PosTypography.small.copyWith(color: p.text),
                    ),
                  ),
                  if (m.pending) ...[
                    PosBadge(
                      label: l10n.stockHistoryPending,
                      tone: PosTone.warning,
                    ),
                    const SizedBox(width: PosSpacing.s),
                  ],
                  Text(
                    m.qtyMilli > 0
                        ? '+${fmt.qty(m.qtyMilli, unit)}'
                        : fmt.qty(m.qtyMilli, unit),
                    style: PosTypography.bodyStrong.copyWith(
                      color: m.qtyMilli < 0 ? p.dangerText : p.successText,
                      fontFeatures: PosTypography.tabular,
                    ),
                  ),
                ],
              ),
            ),
          if (history.offline) Text(l10n.stockHistoryOffline, style: style),
        ],
      ),
    );
  }
}

/// Tovar rasmi: katta ko'rinish, qo'shish/almashtirish/olib tashlash va
/// serverga hali yuklanmagan bo'lsa — belgi.
class _ImageSlot extends ConsumerWidget {
  const _ImageSlot({
    required this.imageId,
    required this.fresh,
    required this.busy,
    required this.onPick,
    required this.onRemove,
  });

  final String? imageId;
  final Uint8List? fresh;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final id = imageId;
    final hasImage = fresh != null || id != null;
    final state = id == null
        ? null
        : ref.watch(productImageStateProvider(id)).value;
    final pending =
        fresh != null ||
        state == ImageState.local ||
        state == ImageState.failed;
    final freshBytes = fresh;
    return Row(
      key: const ValueKey('product-image'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (freshBytes != null)
          PosThumbnail(image: MemoryImage(freshBytes), size: PosSizes.thumbL)
        else
          ProductThumbnail(imageId: id, size: PosSizes.thumbL),
        const SizedBox(width: PosSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.fieldOptional(l10n.productImage),
                style: PosTypography.smallStrong.copyWith(color: p.text),
              ),
              const SizedBox(height: PosSpacing.xs),
              Text(
                l10n.productImageHint,
                style: PosTypography.small.copyWith(color: p.textSecondary),
              ),
              if (hasImage && pending) ...[
                const SizedBox(height: PosSpacing.xs),
                PosBadge(
                  label: l10n.productImageNotUploaded,
                  tone: PosTone.warning,
                ),
              ],
              const SizedBox(height: PosSpacing.s),
              Wrap(
                spacing: PosSpacing.s,
                runSpacing: PosSpacing.s,
                children: [
                  PosButton(
                    key: const ValueKey('product-image-pick'),
                    label: hasImage
                        ? l10n.productImageReplace
                        : l10n.productImageAdd,
                    icon: Icons.image_outlined,
                    size: PosButtonSize.s,
                    variant: PosButtonVariant.secondary,
                    loading: busy,
                    onPressed: busy ? null : onPick,
                  ),
                  if (hasImage)
                    PosButton(
                      key: const ValueKey('product-image-remove'),
                      label: l10n.productImageRemove,
                      icon: Icons.delete_outline,
                      size: PosButtonSize.s,
                      variant: PosButtonVariant.ghost,
                      onPressed: busy ? null : onRemove,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
