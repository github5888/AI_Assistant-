import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/app_state.dart';
import 'package:itsclear_app/auth_platform.dart';
import 'package:itsclear_app/main.dart';
import 'package:itsclear_app/store_api.dart';

class _SavedAdminVault implements SessionVault {
  String? token = 'saved-admin-token';

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async { token = value; }

  @override
  Future<void> clear() async { token = null; }
}

void main() {
  testWidgets('saved admin session reopens the console after the app process restarts', (tester) async {
    final vault = _SavedAdminVault();
    var newOrderArrived = false;
    final notices = <(String, String)>[];
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      final Object response = switch (request.url.path) {
        '/api/auth/me' => {
          'user': {'id': 'admin-1', 'name': 'Ops', 'email': 'ops@example.test', 'role': 'admin'},
        },
        '/api/orders' => newOrderArrived ? <Object>[
          {'id': 'order-new', 'orderNumber': 'CLR-2026-8881',
            'orderStatus': 'confirmed', 'total': 95, 'items': [],
            'shippingAddress': {'name': 'Buyer', 'addressLine1': 'Gomti Nagar'}},
        ] : <Object>[],
        '/api/products' => <Object>[],
        '/api/config' => {'codEnabled': true, 'onlinePaymentsEnabled': false,
          'currency': 'INR', 'freeDeliveryThreshold': 499},
        '/api/health' => {'status': 'online', 'dbStatus': 'connected'},
        '/api/coupons' => <Object>[],
        '/api/content/hero_banners' => {'data': <Object>[]},
        _ => throw StateError('Unexpected API request ${request.method} ${request.url.path}'),
      };
      return http.Response(jsonEncode(response), 200,
        headers: {'content-type': 'application/json'});
    }));
    addTearDown(api.close);

    await tester.pumpWidget(ItsClearApp(api: api, adminSessionVault: vault));
    await tester.pumpAndSettle();

    expect(find.text('Dispatch console'), findsOneWidget);
    expect(find.text('Manage homepage banners'), findsOneWidget);
    expect(find.text('Admin password'), findsNothing);
    expect(vault.token, 'saved-admin-token');
    final state = AppScope.of(tester.element(find.text('Dispatch console')));
    state.showTopNotice = (title, body) => notices.add((title, body));
    newOrderArrived = true;
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(find.text('CLR-2026-8881'), findsOneWidget);
    expect(notices, hasLength(1));
    expect(notices.single.$1, 'New order received');
    expect(notices.single.$2, '1 new order is ready in the dispatch console.');
    expect(tester.takeException(), isNull);
  });
}
