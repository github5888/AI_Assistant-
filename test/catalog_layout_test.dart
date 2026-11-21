import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/main.dart';
import 'package:itsclear_app/store_api.dart';
import 'package:itsclear_app/widgets.dart';

Map<String, Object?> _pack(String id, String name, String category) => {
  'id': id,
  'name': name,
  'category': category,
  'featured': true,
  'rating': 4.8,
  'variants': [
    {'id': '$id-large', 'size': '10 kg carry pack', 'weightInKg': 10, 'price': 1650,
      'originalPrice': 1900, 'inStock': true, 'stockCount': 12},
  ],
};

StoreApi _api() => StoreApi('https://catalog.example.test', client: MockClient((request) async {
  final data = switch (request.url.path) {
    '/api/products' => [
      _pack('a', 'Khapli Stoneground Atta Family Pack', 'khapli'),
      _pack('b', 'High Protein Whole Wheat Flour', 'multigrain'),
    ],
    '/api/config' => {'codEnabled': true, 'onlinePaymentsEnabled': false, 'currency': 'INR', 'freeDeliveryThreshold': 499},
    _ => {'status': 'online', 'dbStatus': 'connected'},
  };
  return http.Response(jsonEncode(data), 200);
}));

Finder _dock(String label) => find.descendant(of: find.byType(BottomDock), matching: find.text(label));

void _phone(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewPadding = const FakeViewPadding(top: 25, bottom: 20);
  tester.view.padding = tester.view.viewPadding;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  for (final size in [const Size(320, 640), const Size(360, 720), const Size(412, 840)]) {
    testWidgets('illustrated home intro precedes a compact two-column grid at $size', (tester) async {
      _phone(tester, size);
      await tester.pumpWidget(ItsClearApp(api: _api()));
      await tester.pumpAndSettle();

      final hero = find.byKey(const ValueKey('home-hero-carousel'));
      expect(hero.hitTestable(), findsOneWidget);
      expect(find.text('Shop the harvest').hitTestable(), findsOneWidget);
      expect(find.text('2-hour EV'), findsNothing);
      final homeScroll = find.descendant(
        of: find.byKey(const PageStorageKey('live-home')),
        matching: find.byType(Scrollable),
      ).first;
      await tester.scrollUntilVisible(find.text('Shop by category'), 120, scrollable: homeScroll);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('a')), 120, scrollable: homeScroll);
      final first = tester.getRect(find.byKey(const ValueKey('a')));
      final second = tester.getRect(find.byKey(const ValueKey('b')));
      expect(tester.getTopLeft(find.text('Shop by category')).dy, lessThan(first.top));
      expect(first.top, second.top);
      expect(first.height, lessThanOrEqualTo(240));
      expect(first.right, lessThan(second.left));
      expect(second.right, lessThan(size.width));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the illustrated hero swipes to the next product story', (tester) async {
    _phone(tester, const Size(360, 720));
    await tester.pumpWidget(ItsClearApp(api: _api()));
    await tester.pumpAndSettle();
    final hero = find.byKey(const ValueKey('home-hero-carousel'));
    final controller = tester.widget<PageView>(hero).controller!;
    expect(controller.page, closeTo(0, 0.01));
    expect(find.text('Khapli\nChakki Atta'), findsOneWidget);
    await tester.drag(hero, const Offset(-290, 0));
    await tester.pumpAndSettle();
    expect(controller.page, closeTo(1, 0.01));
    expect(find.text('High Protein\nAtta').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home photo tile opens the matching Shop filter', (tester) async {
    _phone(tester, const Size(320, 640));
    await tester.pumpWidget(ItsClearApp(api: _api()));
    await tester.pumpAndSettle();
    final category = find.byKey(const ValueKey('home-category-Khapli'));
    final scroll = find.descendant(
      of: find.byKey(const PageStorageKey('live-home')),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(category, 100, scrollable: scroll);
    await tester.pumpAndSettle();
    await tester.tap(category.hitTestable());
    await tester.pumpAndSettle();
    final shop = find.byKey(const PageStorageKey('live-shop'));
    expect(shop.hitTestable(), findsOneWidget);
    expect(find.descendant(of: shop, matching: find.byKey(const ValueKey('a'))), findsOneWidget);
    expect(find.descendant(of: shop, matching: find.byKey(const ValueKey('b'))), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top bar search opens the native product search', (tester) async {
    _phone(tester, const Size(320, 640));
    await tester.pumpWidget(ItsClearApp(api: _api()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search products'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Protein');
    await tester.pumpAndSettle();
    expect(find.text('High Protein Whole Wheat Flour'), findsOneWidget);
    expect(find.text('Khapli Stoneground Atta Family Pack'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('larger system text gets wider cards without overflowing', (tester) async {
    _phone(tester, const Size(320, 640), scale: 1.6);
    await tester.pumpWidget(ItsClearApp(api: _api()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'increased text on Home');
    await tester.tap(_dock('Shop'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'increased text on live shop');
    final first = tester.getRect(find.byKey(const ValueKey('a')));
    await tester.scrollUntilVisible(find.byKey(const ValueKey('b')), 50,
      scrollable: find.descendant(of: find.byKey(const PageStorageKey('live-shop')), matching: find.byType(Scrollable)).first);
    final second = tester.getRect(find.byKey(const ValueKey('b')));
    final currentFirst = tester.getRect(find.byKey(const ValueKey('a')));
    expect(first.width, greaterThan(first.height));
    expect(second.top, greaterThan(currentFirst.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact product Add still updates the real in-app basket', (tester) async {
    _phone(tester, const Size(360, 720));
    await tester.pumpWidget(ItsClearApp(api: _api()));
    await tester.pumpAndSettle();
    await tester.tap(_dock('Shop'));
    await tester.pumpAndSettle();
    final add = find.descendant(of: find.byKey(const ValueKey('a')), matching: find.text('Add'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(_dock('Basket'));
    await tester.pumpAndSettle();
    expect(find.text('Khapli Stoneground Atta Family Pack'), findsOneWidget);
    expect(find.textContaining('Item subtotal: ₹1,650'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
