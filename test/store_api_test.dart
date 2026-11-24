import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/app_state.dart';
import 'package:itsclear_app/main.dart';
import 'package:itsclear_app/data.dart';
import 'package:itsclear_app/widgets.dart';
import 'package:itsclear_app/store_api.dart';

Map<String, Object?> productFixture({List<String> images = const []}) => {
  'id': 'itsclear-khapli-ancient', '_id': 'db-1', 'name': 'Live Khapli Flour',
  'subTitle': 'Live subtitle', 'category': 'khapli', 'featured': true, 'images': images,
  'rating': 4.8, 'reviewCount': 12, 'labTestBatch': 'TEST-0001',
  'nutrition': {'protein': '14.5 g'}, 'description': 'Live product description',
  'variants': [
    {'id': 'small', 'size': '1 kg Net Weight', 'weightInKg': 1, 'price': 95,
      'originalPrice': 115, 'inStock': true, 'stockCount': 1},
    {'id': 'large', 'size': '5 kg Net Weight', 'weightInKg': 5, 'price': 440,
      'originalPrice': 520, 'inStock': false, 'stockCount': 0},
  ],
};

http.Response jsonAnswer(Object value) => http.Response.bytes(
  utf8.encode(jsonEncode(value)), 200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object> get configFixture => {
  'onlinePaymentsEnabled': false,
  'codEnabled': true,
  'currency': 'INR',
  'freeDeliveryThreshold': 399,
};

void main() {
  test('validates coupons from the public active-coupon list contract', () async {
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/coupons');
      expect(request.headers['authorization'], isNull);
      return jsonAnswer([
        {'code': 'WELCOME20', 'active': true, 'discountType': 'percentage',
          'discountValue': 20, 'minOrderValue': 500, 'usageLimit': 0, 'usedCount': 0},
        {'code': 'OFF', 'active': false, 'discountType': 'flat', 'discountValue': 50},
      ]);
    }));
    addTearDown(api.close);
    final result = await api.validateCoupon(code: ' welcome20 ', subtotal: 800);
    expect(result.code, 'WELCOME20');
    expect(result.discount, 160);
    expect(result.freeShipping, isFalse);
    await expectLater(api.validateCoupon(code: 'OFF', subtotal: 800),
        throwsA(isA<StoreApiException>()));
    await expectLater(api.validateCoupon(code: 'WELCOME20', subtotal: 400),
        throwsA(isA<StoreApiException>().having((e) => e.message, 'message', contains('₹500'))));
  });

  test('supports free-shipping coupons from the active coupon list', () async {
    final api = StoreApi('https://example.test', client: MockClient((request) async => jsonAnswer([
      {'code': 'FREESHIP', 'active': true, 'discountType': 'flat', 'discountValue': 0},
    ])));
    addTearDown(api.close);
    final result = await api.validateCoupon(code: 'FREESHIP', subtotal: 250);
    expect(result.discount, 0);
    expect(result.freeShipping, isTrue);
  });

  test('loads observed catalog, detail, config, health and scopes reviews', () async {
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.origin, 'https://example.test');
      final product = productFixture(images: ['/images/pack.png', 'https://other.test/img.png']);
      return switch (request.url.path) {
        '/api/products' => jsonAnswer([product]),
        '/api/products/itsclear-khapli-ancient' => jsonAnswer(product),
        '/api/config' => jsonAnswer(configFixture),
        '/api/health' => jsonAnswer({'status': 'online', 'dbStatus': 'connected'}),
        '/api/reviews' => () {
          expect(request.url.queryParameters['productId'], 'itsclear-khapli-ancient');
          return jsonAnswer([
            {'productId': 'another', 'comment': 'Not for this product', 'rating': 5},
            {'productId': 'db-1', 'comment': 'Fresh pack', 'rating': 5},
          ]);
        }(),
        _ => http.Response('Not found', 404),
      };
    }));
    addTearDown(api.close);
    final products = await api.products();
    final item = products.single;
    expect(item.name, 'Live Khapli Flour');
    expect(item.gallery, ['https://example.test/images/pack.png']);
    expect(item.batch, 'TEST-0001');
    expect(item.sizes.first.id, 'small');
    expect(item.sizes.first.price, 95);
    expect(item.sizes.last.inStock, isFalse);
    expect((await api.product(item.id)).nutritionFacts['protein'], '14.5 g');
    expect((await api.reviews(item)).single.body, 'Fresh pack');
    final config = await api.config();
    expect(config.codEnabled, isTrue);
    expect(config.onlinePaymentsEnabled, isFalse);
    expect(config.freeDeliveryThreshold, 399);
    expect(await api.healthy(), isTrue);
  });

  test('maps mustard oil and desi ghee catalog categories to their packaging assets', () async {
    final api = StoreApi('https://example.test', client: MockClient((request) async =>
      jsonAnswer([
        {'id': 'wooden-kohlu-mustard-oil', 'name': 'Cold Pressed Mustard Oil',
          'category': 'mustard_oil', 'subTitle': 'Wooden Kohlu Pressed',
          'variants': [{'id': 'oil-500ml', 'size': '500 ml Glass Bottle',
            'price': 145, 'originalPrice': 175, 'inStock': true, 'stockCount': 80}]},
        {'id': 'traditional-desi-ghee', 'name': 'Traditional Desi Ghee',
          'category': 'desi-ghee', 'subtitle': 'Bilona churned',
          'variants': [{'id': 'ghee-500ml', 'size': '500 ml Glass Jar',
            'price': 549, 'originalPrice': 649, 'inStock': true, 'stockCount': 75}]},
      ])));
    addTearDown(api.close);
    final products = await api.products();
    final oil = products.firstWhere((product) => product.id == 'wooden-kohlu-mustard-oil');
    final ghee = products.firstWhere((product) => product.id == 'traditional-desi-ghee');
    expect(oil.groups, contains('Mustard Oil'));
    expect(oil.tag, 'Cold Pressed');
    expect(oil.image, AppImages.mustardOil);
    expect(oil.sizes.single.id, 'oil-500ml');
    expect(ghee.groups, contains('Desi Ghee'));
    expect(ghee.tag, 'Bilona Ghee');
    expect(ghee.image, AppImages.desiGhee);
    expect(ghee.sizes.single.id, 'ghee-500ml');
  });

  test('rejects insecure API origins and handles bad catalog responses', () async {
    expect(() => StoreApi('http://example.test'), throwsArgumentError);
    final api = StoreApi('https://example.test', client: MockClient((request) async => http.Response('<html/>', 200)));
    addTearDown(api.close);
    await expectLater(api.products(), throwsA(isA<StoreApiException>()));
  });

  test('live state reports catalog failure without demo data, retries and blocks mock checkout', () async {
    var fail = true;
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      if (request.url.path == '/api/products') {
        return fail ? http.Response('', 503) : jsonAnswer([productFixture()]);
      }
      if (request.url.path == '/api/config') return jsonAnswer(configFixture);
      return jsonAnswer({'status': 'online', 'dbStatus': 'connected'});
    }));
    final state = AppState(api: api);
    addTearDown(api.close);
    addTearDown(state.dispose);
    await state.refreshStore();
    expect(state.catalogError, isTrue);
    expect(state.catalog, isEmpty);
    fail = false;
    await state.refreshStore();
    expect(state.catalogError, isFalse);
    expect(state.searchResults.single.name, 'Live Khapli Flour');
    final item = state.catalog.single;
    expect(state.addToCart(item, item.sizes.last, 1), isFalse);
    expect(state.addToCart(item, item.sizes.first, 1), isTrue);
    expect(state.addToCart(item, item.sizes.first, 1), isFalse);
    expect(state.applyCoupon('CLEAR50'), isFalse);
    state.placeOrder();
    expect(state.orderIds, isEmpty);
    expect(state.cartCount, 1);
  });

  testWidgets('live Shop shows backend items on a phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 700);
    addTearDown(tester.view.reset);
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      return switch (request.url.path) {
        '/api/products' => jsonAnswer([productFixture()]),
        '/api/config' => jsonAnswer(configFixture),
        _ => jsonAnswer({'status': 'online', 'dbStatus': 'connected'}),
      };
    }));
    await tester.pumpWidget(ItsClearApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    expect(find.text('Live Khapli Flour'), findsOneWidget);
    expect(find.text('Khapli Ancient Atta'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live Basket opens native checkout and never places a local order', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 760);
    addTearDown(tester.view.reset);
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      expect(request.method, 'GET');
      return switch (request.url.path) {
        '/api/products' => jsonAnswer([productFixture()]),
        '/api/products/itsclear-khapli-ancient' => jsonAnswer(productFixture()),
        '/api/config' => jsonAnswer(configFixture),
        _ => jsonAnswer({'status': 'online', 'dbStatus': 'connected'}),
      };
    }));
    await tester.pumpWidget(ItsClearApp(api: api));
    await tester.pumpAndSettle();

    expect(find.text('Online store'), findsOneWidget);
    expect(find.text('Shop itsclear™'), findsNothing);
    expect(find.text('Zero-maida lab'), findsNothing);
    expect(find.text('Lab'), findsNothing);
    await tester.tap(find.text('Shop the harvest'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Add ·'));
    await tester.pumpAndSettle();
    expect(find.text('Your basket'), findsOneWidget);
    expect(find.text('Fresh Chakki Basket'), findsOneWidget);
    expect(find.textContaining('Add ₹304 for free delivery'), findsOneWidget);
    expect(find.text('Items subtotal'), findsOneWidget);
    expect(find.text('Open store website'), findsNothing);
    await tester.tap(find.text('Continue to checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Delivery address'), findsOneWidget);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Sign in to place order'), 300, scrollable: scrollable);
    expect(find.text('Currently unavailable'), findsNWidgets(3));
    final submit = find.widgetWithText(FilledButton, 'Sign in to place order');
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live Orders and Profile expose receipt and sign-in screens', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      return switch (request.url.path) {
        '/api/products' => jsonAnswer([productFixture()]),
        '/api/config' => jsonAnswer(configFixture),
        _ => jsonAnswer({'status': 'online', 'dbStatus': 'connected'}),
      };
    }));
    await tester.pumpWidget(ItsClearApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomDock), matching: find.text('Orders')));
    await tester.pumpAndSettle();
    expect(find.text('Order history'), findsOneWidget);
    expect(find.text('Receipts'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Send email OTP'), findsOneWidget);
    final google = find.widgetWithText(OutlinedButton, 'Sign in with Google');
    await tester.scrollUntilVisible(google, 150, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<OutlinedButton>(google).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

}
