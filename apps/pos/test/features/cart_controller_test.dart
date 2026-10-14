import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/cart/cart_controller.dart';

import '../helpers/sqlite.dart';

const CatalogProduct non = CatalogProduct(
  id: 'non',
  name: 'Non',
  priceTiyin: 400000,
  costTiyin: 300000,
  unit: 'dona',
  barcodes: ['4780000000017'],
);

const CatalogProduct olma = CatalogProduct(
  id: 'olma',
  name: 'Olma',
  priceTiyin: 1500000,
  costTiyin: 1000000,
  unit: 'kg',
  isWeighted: true,
  pluCode: '12345',
);

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  ProviderContainer open() {
    final c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<CartController> controller([ProviderContainer? c]) async {
    final target = c ?? container;
    await target.read(cartControllerProvider.future);
    final notifier = target.read(cartControllerProvider.notifier);
    // Baza yopilishidan oldin saqlash navbati tugasin.
    addTearDown(notifier.flush);
    return notifier;
  }

  CartState state([ProviderContainer? c]) =>
      (c ?? container).read(cartControllerProvider).requireValue;

  setUp(() {
    db = openTestDatabase();
    addTearDown(db.close);
    container = open();
  });

  group('cart math', () {
    test('line and check discounts, totals in tiyin', () {
      const line = CartLine(
        id: 'l',
        productId: 'p',
        name: 'Olma',
        unit: 'kg',
        qtyMilli: 1250,
        priceTiyin: 1500000,
        costTiyin: 0,
        discount: Discount.percent(1000),
      );
      // 15 000 × 1,250 = 18 750; −10% = 1 875.
      expect(line.grossTiyin, 1875000);
      expect(line.discountTiyin, 187500);
      expect(line.totalTiyin, 1687500);

      const cart = Cart(
        id: 'c',
        slot: 0,
        lines: [line],
        discount: Discount.amount(87500),
      );
      expect(cart.subtotalTiyin, 1687500);
      expect(cart.totalTiyin, 1600000);
      expect(cart.allDiscountsTiyin, 275000);
    });

    test('discount never exceeds the base', () {
      expect(const Discount.amount(500).of(300), 300);
      expect(const Discount.percent(15000).of(300), 300);
    });
  });

  test('same piece product → qty +1; weighted → new line', () async {
    final cart = await controller();
    cart
      ..add(non)
      ..add(non)
      ..add(olma, qtyMilli: 500)
      ..add(olma, qtyMilli: 250);
    final lines = state().cart.lines;
    expect(lines, hasLength(3));
    expect(lines[0].qtyMilli, 2000);
    expect(lines[0].barcode, '4780000000017');
    expect([lines[1].qtyMilli, lines[2].qtyMilli], [500, 250]);
    expect(state().cart.totalTiyin, 800000 + 750000 + 375000);
    expect(state().cart.itemCount, 4);
    // Oxirgi qo'shilgan qator tanlanadi va yondiriladi.
    expect(state().lastAdded!.lineId, lines[2].id);
    expect(state().selectedLineId, lines[2].id);
  });

  test('scale barcode by price derives the weight', () async {
    final cart = await controller();
    cart.addMatch(
      const CodeMatch(product: olma, code: '2112345007503', priceTiyin: 750000),
    );
    final line = state().cart.lines.single;
    expect(line.qtyMilli, 500);
    expect(line.barcode, '2112345007503');
    expect(line.totalTiyin, 750000);
  });

  test('remove selects the neighbour; undo restores the position', () async {
    final cart = await controller();
    cart
      ..add(non)
      ..add(olma, qtyMilli: 1000)
      ..add(
        const CatalogProduct(
          id: 'sut',
          name: 'Sut',
          priceTiyin: 1,
          costTiyin: 0,
          unit: 'dona',
        ),
      );
    final middle = state().cart.lines[1].id;
    final removed = cart.remove(middle)!;
    expect(state().cart.lines.map((l) => l.productId), ['non', 'sut']);
    expect(state().selectedLine!.productId, 'sut');

    cart.undoRemove(removed);
    expect(state().cart.lines.map((l) => l.productId), ['non', 'olma', 'sut']);
    expect(state().selectedLineId, middle);
    // Ikki marta undo — dublikat yo'q.
    cart.undoRemove(removed);
    expect(state().cart.lines, hasLength(3));
  });

  test('arrow keys move the selection inside the cart', () async {
    final cart = await controller();
    cart
      ..add(non)
      ..add(olma, qtyMilli: 1000)
      ..select(null)
      ..moveSelection(-1);
    expect(state().selectedLine!.productId, 'olma');
    cart.moveSelection(-1);
    expect(state().selectedLine!.productId, 'non');
    cart.moveSelection(-1);
    expect(state().selectedLine!.productId, 'non');
  });

  test('qty must stay positive', () async {
    final cart = await controller()
      ..add(non);
    final id = state().cart.lines.single.id;
    cart
      ..setQty(id, 0)
      ..setQty(id, -1000);
    expect(state().cart.lines.single.qtyMilli, 1000);
    cart.setQty(id, 3000);
    expect(state().cart.lines.single.qtyMilli, 3000);
  });

  group('deferred checks', () {
    test('up to 5 carts; an empty current cart is reused', () async {
      final cart = await controller();
      expect(cart.newCart(), isTrue);
      expect(state().carts, hasLength(1));
      for (var i = 0; i < 4; i++) {
        cart
          ..add(non)
          ..newCart();
      }
      expect(state().carts, hasLength(5));
      cart.add(non);
      expect(cart.newCart(), isFalse);
      expect(state().carts.map((c) => c.slot), [0, 1, 2, 3, 4]);
      expect(state().active, 4);
    });

    test('switching away from an empty cart closes it', () async {
      final cart = await controller()
        ..add(non)
        ..newCart();
      expect(state().carts, hasLength(2));
      cart.switchTo(0);
      expect(state().carts, hasLength(1));
      expect(state().active, 0);
    });

    test('clearActive empties the last cart, closes a deferred one', () async {
      final cart = await controller()
        ..add(non)
        ..newCart()
        ..add(olma, qtyMilli: 300)
        ..clearActive();
      expect(state().carts, hasLength(1));
      expect(state().cart.lines.single.productId, 'non');
      cart.clearActive();
      expect(state().carts.single.isEmpty, isTrue);
    });
  });

  test('carts survive an app restart (autosave to cart_drafts)', () async {
    final cart = await controller()
      ..add(non)
      ..add(non)
      ..add(olma, qtyMilli: 1250);
    final olmaLine = state().cart.lines[1].id;
    cart
      ..setLineDiscount(olmaLine, const Discount.percent(500))
      ..setCartDiscount(const Discount.amount(10000))
      ..newCart()
      ..add(olma, qtyMilli: 400);
    await cart.flush();
    container.dispose();

    // Ilova o'ldirildi va qayta ochildi.
    final reopened = open();
    await controller(reopened);
    final s = state(reopened);
    expect(s.carts, hasLength(2));
    final first = s.carts[0];
    expect(first.lines.map((l) => l.qtyMilli), [2000, 1250]);
    expect(first.lines[1].discount, const Discount.percent(500));
    expect(first.discount, const Discount.amount(10000));
    expect(first.totalTiyin, 800000 + 1781250 - 10000);
    expect(s.carts[1].lines.single.qtyMilli, 400);
  });

  test('a broken draft row does not break the cashier screen', () async {
    await db
        .into(db.cartDrafts)
        .insert(
          CartDraftsCompanion.insert(
            id: 'broken',
            slot: 0,
            linesJson: const Value('{not json'),
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
    await controller();
    expect(state().cart.id, 'broken');
    expect(state().cart.isEmpty, isTrue);
  });
}
