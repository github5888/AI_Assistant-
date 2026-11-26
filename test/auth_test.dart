import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/app_state.dart';
import 'package:itsclear_app/auth_models.dart';
import 'package:itsclear_app/auth_platform.dart';
import 'package:itsclear_app/main.dart';
import 'package:itsclear_app/store_api.dart';
import 'package:itsclear_app/screens/sign_in_screen.dart';

const fixtureUser = {'id': 'customer-1', 'email': 'buyer@example.test', 'name': 'Demo Buyer', 'role': 'customer'};
const fixtureAdmin = {'id': 'admin-1', 'email': 'admin@example.test', 'name': 'Store Admin', 'role': 'admin'};
const responseSession = {'success': true, 'user': fixtureUser, 'token': 'fixture-store-session'};
http.Response respond(Object value, [int status = 200]) => http.Response(jsonEncode(value), status);

class _MemoryVault implements SessionVault {
  String? value;
  @override
  Future<void> clear() async { value = null; }
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async { value = token; }
}

class _Google implements GoogleIdentity {
  @override
  Future<String?> idToken() async => 'fixture-provider-token';
  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('sign-in offers a visible admin route without using the customer password form', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(tester.view.reset);
    final api = StoreApi('https://example.test', client: MockClient((_) async => respond({})));
    final state = AppState(api: api);
    addTearDown(api.close);
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      home: AppScope(notifier: state, child: const SignInScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Admin / staff sign-in'), findsOneWidget);
    expect(find.text('Dispatch console'), findsNothing);
    expect(find.text('Sign in with password instead'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin email and password entered in customer sign-in open the dispatch console', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final adminVault = _MemoryVault();
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      if (request.url.path == '/api/auth/login') {
        expect(jsonDecode(request.body), {
          'emailOrPhone': 'admin@example.test', 'password': 'admin-pass',
        });
        return respond({'user': fixtureAdmin, 'token': 'fixture-admin-session'});
      }
      if (request.url.path == '/api/auth/admin-login') {
        expect(jsonDecode(request.body), {
          'email': 'admin@example.test', 'password': 'admin-pass',
        });
        return respond({'user': fixtureAdmin, 'token': 'fixture-admin-session'});
      }
      if (request.url.path == '/api/auth/me') {
        expect(request.headers['authorization'], 'Bearer fixture-admin-session');
        return respond({'user': fixtureAdmin});
      }
      if (request.url.path == '/api/orders') {
        expect(request.headers['authorization'], 'Bearer fixture-admin-session');
        return respond([]);
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    }));
    final state = AppState(api: api);
    addTearDown(api.close);
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(home: AppScope(notifier: state,
      child: SignInScreen(adminSessionVault: adminVault))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in with password instead'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@example.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin-pass');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(adminVault.value, 'fixture-admin-session');
    expect(find.text('Dispatch console'), findsOneWidget);
    expect(find.text('Admin-only order operations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('customer auth uses documented JSON payloads and never follows redirects', () async {
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      expect(request.followRedirects, isFalse);
      final body = request.body.isEmpty ? null : jsonDecode(request.body);
      switch (request.url.path) {
        case '/api/auth/login/send-otp':
          expect(body, {'email': 'buyer@example.test'});
          return respond({'success': true, 'resendAfter': 30});
        case '/api/auth/login/verify-otp':
          expect(body, {'email': 'buyer@example.test', 'otp': '123456', 'portal': 'customer'});
          return respond(responseSession);
        case '/api/auth/login':
          if (body['emailOrPhone'] == 'admin@example.test') {
            expect(body, {'emailOrPhone': 'admin@example.test', 'password': 'admin-pass'});
            return respond({'user': fixtureAdmin, 'token': 'fixture-admin-session'});
          }
          expect(body, {'emailOrPhone': 'buyer@example.test', 'password': 'fixture-pass'});
          return respond({'user': fixtureUser, 'token': 'fixture-store-session'});
        case '/api/auth/google':
          expect(body, {'credential': 'fixture-provider-token', 'portal': 'customer'});
          return respond({'requiresLinking': true, 'email': 'buyer@example.test'});
        case '/api/auth/google/link':
          expect(body, {'credential': 'fixture-provider-token', 'otp': '123456'});
          return respond(responseSession);
        case '/api/auth/register/send-otp':
          expect(body, {'fullName': 'Demo Buyer', 'mobile': '9999999999', 'email': 'buyer@example.test',
            'password': 'fixture-pass', 'confirmPassword': 'fixture-pass'});
          return respond({'success': true});
        case '/api/auth/register/resend-otp':
          expect(body, {'email': 'buyer@example.test'});
          return respond({'success': true});
        case '/api/auth/register/verify-and-create':
          expect(body, {'email': 'buyer@example.test', 'otp': '123456'});
          return respond(responseSession, 201);
        case '/api/auth/me':
          expect(request.method, 'GET');
          expect(request.headers['authorization'], 'Bearer fixture-store-session');
          return respond({'user': fixtureUser});
        default:
          throw StateError('Unexpected route');
      }
    }));
    addTearDown(api.close);
    expect((await api.requestLoginOtp('  BUYER@example.test ')).resendAfter, 30);
    expect((await api.verifyLoginOtp('buyer@example.test', '123456')).account.name, 'Demo Buyer');
    final customerLogin = await api.passwordLogin('buyer@example.test', 'fixture-pass');
    expect(customerLogin.customerSession?.account.id, 'customer-1');
    expect(customerLogin.adminSession, isNull);
    final adminLogin = await api.passwordLogin('admin@example.test', 'admin-pass');
    expect(adminLogin.adminSession?.email, 'admin@example.test');
    expect(adminLogin.customerSession, isNull);
    final google = await api.googleLogin('fixture-provider-token');
    expect(google.linkEmail, 'buyer@example.test');
    expect(google.session, isNull);
    expect((await api.linkGoogleOtp('fixture-provider-token', '123456')).account.email, 'buyer@example.test');
    await api.startRegistration(name: 'Demo Buyer', mobile: '9999999999', email: 'buyer@example.test',
      password: 'fixture-pass', confirmPassword: 'fixture-pass');
    await api.resendRegistrationOtp('buyer@example.test');
    expect((await api.verifyRegistrationOtp('buyer@example.test', '123456')).account.email, 'buyer@example.test');
    expect((await api.currentCustomer('fixture-store-session')).id, 'customer-1');
  });

  test('OTP errors handle rate limiting and do not expose local test codes', () async {
    var rateLimited = true;
    final api = StoreApi('https://example.test', client: MockClient((request) async => rateLimited
        ? respond({'error': 'Please wait', 'retryAfter': 22}, 429)
        : respond({'success': true, 'mode': 'local', 'devOtp': '654321'})));
    addTearDown(api.close);
    await expectLater(api.requestLoginOtp('buyer@example.test'), throwsA(isA<AuthException>()
      .having((error) => error.retryAfter, 'retry', 22)));
    rateLimited = false;
    await expectLater(api.requestLoginOtp('buyer@example.test'), throwsA(isA<AuthException>()
      .having((error) => error.message, 'message', isNot(contains('654321')))));
  });

  test('expired sessions are cleared without setting a customer', () async {
    final api = StoreApi('https://example.test', client: MockClient((request) async => respond({'error': 'Expired'}, 401)));
    final vault = _MemoryVault()..value = 'expired-fixture';
    final state = AppState(api: api, sessionVault: vault);
    addTearDown(api.close);
    addTearDown(state.dispose);
    await state.restoreSession();
    expect(state.customer, isNull);
    expect(vault.value, isNull);
  });

  for (final linking in [false, true]) {
    testWidgets(linking ? 'Google identity requires ownership code before linking' : 'email OTP signs the customer into the app', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 720);
      addTearDown(tester.view.reset);
      final vault = _MemoryVault();
      final api = StoreApi('https://example.test', client: MockClient((request) async {
        return switch (request.url.path) {
          '/api/products' => respond([]),
          '/api/config' => respond({'onlinePaymentsEnabled': false, 'codEnabled': true, 'currency': 'INR', 'freeDeliveryThreshold': 499}),
          '/api/health' => respond({'status': 'online', 'dbStatus': 'connected'}),
          '/api/auth/google' => respond({'requiresLinking': true, 'email': 'buyer@example.test'}),
          '/api/auth/login/send-otp' => respond({'success': true, 'resendAfter': 0}),
          '/api/auth/login/verify-otp' || '/api/auth/google/link' => respond(responseSession),
          _ => respond({}, 404),
        };
      }));
      await tester.pumpWidget(ItsClearApp(api: api, sessionVault: vault, googleIdentity: _Google()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      if (linking) {
        await tester.tap(find.text('Sign in with Google'));
        await tester.pumpAndSettle();
        expect(find.text('Link your Google account'), findsOneWidget);
      } else {
        await tester.enterText(find.byType(TextFormField).first, 'buyer@example.test');
      }
      expect(vault.value, isNull);
      await tester.ensureVisible(find.text('Send email OTP'));
      await tester.tap(find.text('Send email OTP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '123456');
      final verify = find.text(linking ? 'Verify & link Google' : 'Verify email code');
      await tester.ensureVisible(verify);
      await tester.tap(verify);
      await tester.pumpAndSettle();
      expect(vault.value, 'fixture-store-session');
      expect(find.text('buyer@example.test'), findsOneWidget);
      await tester.tap(find.byTooltip('Sign out'));
      await tester.pumpAndSettle();
      expect(vault.value, isNull);
      expect(find.text('Your itsclear account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
