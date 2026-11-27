import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/app_state.dart';
import 'package:itsclear_app/auth_platform.dart';
import 'package:itsclear_app/screens/admin_dispatch_screen.dart';
import 'package:itsclear_app/store_api.dart';

class _AdminVault implements SessionVault {
  String? token = 'admin-test-token';
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async { token = value; }
  @override
  Future<void> clear() async { token = null; }
}

void main() {
  testWidgets('admin map cards remain readable with larger system text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer admin-test-token');
      if (request.url.path == '/api/auth/me') {
        return http.Response(jsonEncode({'user': {
          'id': 'admin-1', 'name': 'Admin', 'email': 'admin@example.test', 'role': 'admin',
        }}), 200);
      }
      if (request.url.path == '/api/orders') {
        return http.Response(jsonEncode([
          {
            'id': 'order-address-only', 'orderNumber': 'CLR-2026-4214',
            'orderStatus': 'confirmed', 'total': 544, 'items': [],
            'shippingAddress': {
              'name': 'Unnati', 'addressLine1': 'Gomti Nagar', 'city': 'Lucknow',
              'state': 'Uttar Pradesh', 'pincode': '226010',
            },
          },
          {
            'id': 'order-with-pin', 'orderNumber': 'CLR-2026-6610',
            'orderStatus': 'out_for_delivery', 'total': 944, 'items': [],
            'shippingAddress': {
              'name': 'Customer', 'addressLine1': 'Chinhat', 'city': 'Lucknow',
              'state': 'Uttar Pradesh', 'pincode': '226028',
              'location': {'latitude': 26.862609, 'longitude': 81.048675},
            },
          },
        ]), 200);
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    }));
    final state = AppState(api: api);
    final vault = _AdminVault();
    addTearDown(api.close);
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AppScope(notifier: state,
      child: AdminDispatchScreen(vault: vault))));
    await tester.pumpAndSettle();

    expect(find.text('CLR-2026-4214'), findsOneWidget);
    expect(find.text('Manage homepage banners'), findsOneWidget);
    expect(find.text('No saved pin · address search'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Saved pin · 26.862609, 81.048675'), 220,
      scrollable: find.byType(Scrollable).first);
    expect(find.text('Saved pin · 26.862609, 81.048675'), findsOneWidget);
    expect(find.text('Open map'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
