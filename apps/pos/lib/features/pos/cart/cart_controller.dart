import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/money/money.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/features/pos/cart/cart.dart';

/// Ochiq cheklar va tanlangan qator.
class CartState {
  const CartState({
    required this.carts,
    this.active = 0,
    this.selectedLineId,
    this.lastAdded,
  });

  /// Slot tartibida, kamida bittasi bor.
  final List<Cart> carts;

  /// [carts] dagi joriy chek indeksi.
  final int active;

  /// Klaviatura (F2, Delete, ↑/↓) ishlaydigan qator.
  final String? selectedLineId;

  /// Oxirgi qo'shilgan/oshirilgan qator: ekran unga aylanadi va yondiradi.
  final LineAdded? lastAdded;

  Cart get cart => carts[active];

  CartLine? get selectedLine {
    for (final line in cart.lines) {
      if (line.id == selectedLineId) return line;
    }
    return null;
  }

  bool get canAddCart => carts.length < CartController.maxCarts;

  CartState copyWith({
    List<Cart>? carts,
    int? active,
    String? selectedLineId,
    bool clearSelection = false,
    LineAdded? lastAdded,
  }) => CartState(
    carts: carts ?? this.carts,
    active: active ?? this.active,
    selectedLineId: clearSelection
        ? null
        : (selectedLineId ?? this.selectedLineId),
    lastAdded: lastAdded ?? this.lastAdded,
  );
}

/// Har qo'shish alohida hodisa (bir qator ketma-ket ikki marta ham).
class LineAdded {
  const LineAdded(this.lineId, this.seq);

  final String lineId;
  final int seq;
}

/// O'chirilgan qator — "Bekor qilish" uchun.
class RemovedLine {
  const RemovedLine(this.cartId, this.line, this.index);

  final String cartId;
  final CartLine line;
  final int index;
}

/// Savat: har o'zgarish darhol `cart_drafts` ga yoziladi (ilova o'ldirilsa
/// ham tiklanadi, `pos-screen.md`). Yozuvlar navbat bilan, tartib saqlanadi.
class CartController extends AsyncNotifier<CartState> {
  static const int maxCarts = 5;

  late AppDatabase _db;
  Future<void> _writes = Future.value();
  int _seq = 0;

  @override
  Future<CartState> build() async {
    _db = ref.watch(appDatabaseProvider);
    final rows = await (_db.select(
      _db.cartDrafts,
    )..orderBy([(c) => OrderingTerm.asc(c.slot)])).get();
    final carts = [for (final r in rows) _fromRow(r)];
    if (carts.isEmpty) {
      final cart = Cart(id: newId(), slot: 0);
      carts.add(cart);
      _save(cart);
    }
    return CartState(carts: carts);
  }

  /// Saqlash navbati tugashini kutish (testlar, ilovadan chiqish).
  Future<void> flush() => _writes;

  CartState get _s => state.requireValue;

  // ---- Qatorlar ---------------------------------------------------------

  /// Tovar qo'shish. Dona tovar savatda bo'lsa — miqdor +1 (chegirmasiz
  /// qatorga); vaznli yoki tarozi kodi — har doim yangi qator (`barcode.md`).
  void add(CatalogProduct product, {int? qtyMilli, String? barcode}) {
    final cart = _s.cart;
    final separate = product.isWeighted || qtyMilli != null;
    if (!separate) {
      final index = cart.lines.indexWhere(
        (l) => l.productId == product.id && !l.weighted,
      );
      if (index >= 0) {
        final line = cart.lines[index];
        _updateLine(line.copyWith(qtyMilli: line.qtyMilli + Money.qtyScale));
        _markAdded(line.id);
        return;
      }
    }
    final line = CartLine(
      id: newId(),
      productId: product.id,
      name: product.name,
      unit: product.unit,
      weighted: product.isWeighted,
      barcode: barcode ?? product.primaryBarcode,
      qtyMilli: qtyMilli ?? Money.qtyScale,
      priceTiyin: product.priceTiyin,
      costTiyin: product.costTiyin,
    );
    _replaceCart(cart.copyWith(lines: [...cart.lines, line]));
    _markAdded(line.id);
  }

  /// Tarozi kodi: vazn yoki (narx turidagi formatda) narxdan miqdor.
  void addMatch(CodeMatch match) {
    final product = match.product;
    final qty =
        match.qtyMilli ??
        (match.priceTiyin != null && product.priceTiyin > 0
            ? Money.mulDivHalfUp(
                match.priceTiyin!,
                Money.qtyScale,
                product.priceTiyin,
              )
            : null);
    add(product, qtyMilli: qty, barcode: match.code);
  }

  void setQty(String lineId, int qtyMilli) {
    if (qtyMilli <= 0) return;
    final line = _line(lineId);
    if (line == null || line.qtyMilli == qtyMilli) return;
    _updateLine(line.copyWith(qtyMilli: qtyMilli));
  }

  RemovedLine? remove(String lineId) {
    final cart = _s.cart;
    final index = cart.lines.indexWhere((l) => l.id == lineId);
    if (index < 0) return null;
    final line = cart.lines[index];
    final lines = [...cart.lines]..removeAt(index);
    // Tanlov qo'shni qatorga o'tadi (Delete ketma-ket bosilsa).
    final next = lines.isEmpty
        ? null
        : lines[index < lines.length ? index : lines.length - 1].id;
    _replaceCart(cart.copyWith(lines: lines), selectedLineId: next);
    return RemovedLine(cart.id, line, index);
  }

  void undoRemove(RemovedLine removed) {
    final i = _s.carts.indexWhere((c) => c.id == removed.cartId);
    if (i < 0) return;
    final cart = _s.carts[i];
    if (cart.lines.any((l) => l.id == removed.line.id)) return;
    final lines = [...cart.lines]
      ..insert(removed.index.clamp(0, cart.lines.length), removed.line);
    _replaceCartAt(
      i,
      cart.copyWith(lines: lines),
      selectedLineId: removed.line.id,
    );
  }

  void setLineDiscount(String lineId, Discount? discount) {
    final line = _line(lineId);
    if (line == null) return;
    _updateLine(
      line.copyWith(discount: discount, clearDiscount: discount == null),
    );
  }

  void setCartDiscount(Discount? discount) {
    _replaceCart(
      _s.cart.copyWith(discount: discount, clearDiscount: discount == null),
    );
  }

  // ---- Tanlov -----------------------------------------------------------

  void select(String? lineId) {
    state = AsyncData(
      _s.copyWith(selectedLineId: lineId, clearSelection: lineId == null),
    );
  }

  /// ↑/↓: tanlovni siljitish (tanlov yo'q bo'lsa — oxirgi qator).
  void moveSelection(int delta) {
    final lines = _s.cart.lines;
    if (lines.isEmpty) return;
    final current = lines.indexWhere((l) => l.id == _s.selectedLineId);
    final next = current < 0
        ? lines.length - 1
        : (current + delta).clamp(0, lines.length - 1);
    select(lines[next].id);
  }

  // ---- Cheklar (tablar) -------------------------------------------------

  /// F6: yangi chek (eng ko'pi [maxCarts]). Joriy chek bo'sh bo'lsa — yangisi
  /// ochilmaydi.
  bool newCart() {
    if (!_s.canAddCart) return false;
    if (_s.cart.isEmpty) return true;
    final used = {for (final c in _s.carts) c.slot};
    var slot = 0;
    while (used.contains(slot)) {
      slot++;
    }
    final cart = Cart(id: newId(), slot: slot);
    final carts = [..._s.carts, cart]..sort((a, b) => a.slot.compareTo(b.slot));
    state = AsyncData(
      _s.copyWith(
        carts: carts,
        active: carts.indexOf(cart),
        clearSelection: true,
      ),
    );
    _save(cart);
    return true;
  }

  void switchTo(int index) {
    if (index < 0 || index >= _s.carts.length || index == _s.active) return;
    // Bo'sh kechiktirilgan chek tashlab ketilsa — yopiladi.
    final leaving = _s.cart;
    if (leaving.isEmpty && _s.carts.length > 1) {
      final carts = [..._s.carts]..removeAt(_s.active);
      final target = index > _s.active ? index - 1 : index;
      state = AsyncData(
        _s.copyWith(carts: carts, active: target, clearSelection: true),
      );
      _delete(leaving.id);
      return;
    }
    state = AsyncData(_s.copyWith(active: index, clearSelection: true));
  }

  /// Joriy chekni bo'shatish (savdo yakunlanganda — T-043). Boshqa ochiq
  /// cheklar bo'lsa, bo'sh chek yopiladi.
  void clearActive() {
    final cart = _s.cart;
    if (_s.carts.length > 1) {
      final carts = [..._s.carts]..removeAt(_s.active);
      state = AsyncData(
        _s.copyWith(
          carts: carts,
          active: _s.active.clamp(0, carts.length - 1),
          clearSelection: true,
        ),
      );
      _delete(cart.id);
      return;
    }
    final empty = Cart(id: newId(), slot: cart.slot);
    state = AsyncData(_s.copyWith(carts: [empty], clearSelection: true));
    _delete(cart.id);
    _save(empty);
  }

  // ---- Ichki ------------------------------------------------------------

  CartLine? _line(String id) {
    for (final l in _s.cart.lines) {
      if (l.id == id) return l;
    }
    return null;
  }

  void _updateLine(CartLine line) {
    final cart = _s.cart;
    _replaceCart(
      cart.copyWith(
        lines: [for (final l in cart.lines) l.id == line.id ? line : l],
      ),
    );
  }

  void _replaceCart(Cart cart, {String? selectedLineId}) =>
      _replaceCartAt(_s.active, cart, selectedLineId: selectedLineId);

  void _replaceCartAt(int index, Cart cart, {String? selectedLineId}) {
    final carts = [..._s.carts]..[index] = cart;
    final keep =
        selectedLineId ??
        (cart.lines.any((l) => l.id == _s.selectedLineId)
            ? _s.selectedLineId
            : null);
    state = AsyncData(
      _s.copyWith(
        carts: carts,
        selectedLineId: keep,
        clearSelection: keep == null,
      ),
    );
    _save(cart);
  }

  void _markAdded(String lineId) {
    state = AsyncData(
      _s.copyWith(selectedLineId: lineId, lastAdded: LineAdded(lineId, ++_seq)),
    );
  }

  void _save(Cart cart) {
    final now = clock.now();
    final row = CartDraftsCompanion.insert(
      id: cart.id,
      slot: cart.slot,
      customerId: Value(cart.customerId),
      linesJson: Value(jsonEncode([for (final l in cart.lines) l.toJson()])),
      discountJson: Value(
        cart.discount == null ? null : jsonEncode(cart.discount!.toJson()),
      ),
      createdAt: now,
      updatedAt: now,
    );
    _enqueue(
      () => _db
          .into(_db.cartDrafts)
          .insert(
            row,
            onConflict: DoUpdate(
              (_) => CartDraftsCompanion(
                slot: row.slot,
                customerId: row.customerId,
                linesJson: row.linesJson,
                discountJson: row.discountJson,
                updatedAt: Value(now),
              ),
            ),
          ),
    );
  }

  void _delete(String cartId) => _enqueue(
    () => (_db.delete(_db.cartDrafts)..where((c) => c.id.equals(cartId))).go(),
  );

  void _enqueue(Future<Object?> Function() write) {
    _writes = _writes.then((_) => write()).then<void>((_) {});
  }

  static Cart _fromRow(CartDraft row) {
    List<Object?> lines;
    try {
      lines = jsonDecode(row.linesJson) as List<Object?>;
    } on Object {
      lines = const [];
    }
    Object? discount;
    try {
      discount = row.discountJson == null
          ? null
          : jsonDecode(row.discountJson!);
    } on Object {
      discount = null;
    }
    return Cart(
      id: row.id,
      slot: row.slot,
      customerId: row.customerId,
      lines: [...lines.map(CartLine.fromJson).nonNulls],
      discount: Discount.fromJson(discount),
    );
  }
}

final cartControllerProvider = AsyncNotifierProvider<CartController, CartState>(
  CartController.new,
);
