import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/main.dart';
import 'package:itsclear_app/store_api.dart';

void main() {
  testWidgets('live checkout validates and saves delivery details locally', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 760);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 18);
    addTearDown(tester.view.reset);

    final api = StoreApi('https://checkout.example.test', client: MockClient((request) async {
      final Object value = switch (request.url.path) {
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
        _ => {'status': 'online', 'dbStatus': 'connected'},
      };
      return http.Response(jsonEncode(value), 200);
    }));

    await tester.pumpWidget(ItsClearApp(api: api));
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

    expect(find.text('Delivery address'), findsOneWidget);
    expect(find.text('ORDER ITEMS'), findsOneWidget);
    expect(find.text('Cash on delivery'), findsOneWidget);
    expect(tester.widget<TextFormField>(find.byType(TextFormField).at(0)).enabled, isTrue);

    await tester.tap(find.text('SAVE & DELIVER HERE'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required.'), findsNWidgets(3));
    expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);
    expect(find.text('Enter a valid 6-digit PIN code.'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Saloni Gupta');
    await tester.enterText(fields.at(1), '9876543210');
    await tester.enterText(fields.at(2), '226010');
    await tester.enterText(fields.at(3), 'Lucknow');
    await tester.enterText(fields.at(4), '12, Gomti Nagar');
    await tester.ensureVisible(find.text('SAVE & DELIVER HERE'));
    await tester.tap(find.text('SAVE & DELIVER HERE'));
    await tester.pumpAndSettle();
    expect(find.text('DELIVERY DETAILS SAVED'), findsOneWidget);
    expect(find.textContaining('Saloni Gupta · 9876543210'), findsOneWidget);
    // Order creation is server-authenticated; guests are prompted to sign in.
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton,
      'Sign in to place order')).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
