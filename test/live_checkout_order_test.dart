import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/app_state.dart';
import 'package:itsclear_app/auth_platform.dart';
import 'package:itsclear_app/main.dart';
import 'package:itsclear_app/store_api.dart';

class _Vault implements SessionVault {
  @override
  Future<String?> read() async => 'valid-customer-token';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('signed-in COD checkout posts to the store and shows its confirmed order', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 18);
    addTearDown(tester.view.reset);

    var submitted = false;
    Map<String, dynamic>? submittedBody;
    String? submittedAuthorization;
    final requests = <String>[];
    final api = StoreApi('https://checkout.example.test', client: MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      final response = switch (request.url.path) {
        '/api/products' => [
          {
            'id': 'khapli-family', 'name': 'Khapli Atta', 'category': 'khapli', 'featured': true,
            'variants': [
              {'id': 'kh-1kg', 'size': '1 kg', 'weightInKg': 1, 'price': 95,
                'originalPrice': 115, 'inStock': true, 'stockCount': 8},
            ],
          },
        ],
        '/api/config' => {'codEnabled': true, 'onlinePaymentsEnabled': false,
          'currency': 'INR', 'freeDeliveryThreshold': 499},
        '/api/health' => {'status': 'online', 'dbStatus': 'connected'},
        '/api/auth/me' => () {
          expect(request.headers['authorization'], 'Bearer valid-customer-token');
          return {'user': {'id': 'customer-1', 'email': 'buyer@example.test',
            'name': 'Demo Buyer', 'role': 'customer'}};
        }(),
        '/api/orders' when request.method == 'POST' => () {
          submittedAuthorization = request.headers['authorization'];
          submittedBody = jsonDecode(request.body) as Map<String, dynamic>;
          final address = submittedBody!['shippingAddress'] as Map<String, dynamic>;
          submitted = true;
          return {
            'id': 'ord-live-test', 'orderNumber': 'CLR-2026-1234',
            'orderStatus': 'confirmed', 'paymentMethod': 'cod', 'paymentStatus': 'pending',
            'total': 95, 'subtotal': 95, 'discount': 0, 'tax': 0, 'deliveryFee': 0,
            'trackingStep': 1, 'estimatedDelivery': 'Within 2 Hours',
            'items': [{'product': {'name': 'Khapli Atta'},
              'selectedVariant': {'size': '1 kg'}, 'quantity': 1, 'total': 95}],
            'shippingAddress': address,
          };
        }(),
        '/api/orders' when request.method == 'GET' => [
          {
            'id': 'ord-live-test', 'orderNumber': 'CLR-2026-1234',
            'orderStatus': 'confirmed', 'paymentMethod': 'cod', 'paymentStatus': 'pending',
            'total': 95, 'subtotal': 95, 'discount': 0, 'tax': 0, 'deliveryFee': 0,
            'trackingStep': 1, 'estimatedDelivery': 'Within 2 Hours',
            'items': [{'product': {'name': 'Khapli Atta'}, 'selectedVariant': {'size': '1 kg'}, 'quantity': 1}],
            'shippingAddress': {'name': 'Demo Buyer', 'address': '12 Gomti Nagar',
              'city': 'Lucknow', 'pincode': '226010'},
          },
        ],
        _ => {'status': 'online', 'dbStatus': 'connected'},
      };
      final status = request.url.path == '/api/orders' && request.method == 'POST' ? 201 : 200;
      return http.Response(jsonEncode(response), status);
    }));

    await tester.pumpWidget(ItsClearApp(api: api, sessionVault: _Vault()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    final add = find.descendant(of: find.byKey(const ValueKey('khapli-family')),
      matching: find.text('Add'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basket'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to checkout'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    const values = ['Demo Buyer', '9876543210', '226010', 'Lucknow', '12, Gomti Nagar'];
    for (var index = 0; index < values.length; index++) {
      final field = fields.at(index);
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.enterText(field, values[index]);
      await tester.pump();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('SAVE & DELIVER HERE'));
    await tester.tap(find.text('SAVE & DELIVER HERE'));
    await tester.pumpAndSettle();
    expect(find.text('DELIVERY DETAILS SAVED'), findsOneWidget);
    final submit = find.text('Place order with cash on delivery');
    final appState = AppScope.of(tester.element(submit));
    expect(appState.customer?.id, 'customer-1');
    expect(appState.cartCount, 1);
    expect(appState.cart.single.size.id, 'kh-1kg');
    expect(appState.isSubmittingOrder, isFalse);
    expect(appState.storeConfig?.codEnabled, isTrue);
    final submitButton = find.ancestor(of: submit, matching: find.byType(FilledButton)).first;
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
    await tester.ensureVisible(submitButton);
    tester.widget<FilledButton>(submitButton).onPressed!();
    await tester.pumpAndSettle();

    final visibleText = tester.widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '').where((text) => text.isNotEmpty).join(' | ');
    expect(submitted, isTrue,
      reason: 'Checkout did not POST the order. Cart=${appState.cartCount}; '
        'busy=${appState.isSubmittingOrder}; requests=$requests; screen text=$visibleText');
    expect(submittedAuthorization, 'Bearer valid-customer-token');
    expect(submittedBody?['paymentMethod'], 'cod');
    expect(submittedBody?['items'], [
      {'productId': 'khapli-family', 'variantId': 'kh-1kg', 'quantity': 1},
    ]);
    final submittedAddress = submittedBody?['shippingAddress'] as Map<String, dynamic>;
    expect(submittedAddress['name'], 'Demo Buyer');
    expect(submittedAddress['phone'], '9876543210');
    expect(submittedAddress['pincode'], '226010');
    expect(find.text('CLR-2026-1234'), findsOneWidget);
    expect(find.text('The store has confirmed your order.'), findsOneWidget);
    await tester.tap(find.text('View my orders'));
    await tester.pumpAndSettle();
    expect(find.text('CLR-2026-1234'), findsOneWidget);
    expect(find.text('Track order & receipt'), findsOneWidget);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
