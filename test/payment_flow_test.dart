import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/app_state.dart';
import 'package:itsclear_app/auth_models.dart';
import 'package:itsclear_app/auth_platform.dart';
import 'package:itsclear_app/data.dart';
import 'package:itsclear_app/payment_models.dart';
import 'package:itsclear_app/payment_platform.dart';
import 'package:itsclear_app/store_api.dart';

class _Vault implements SessionVault {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

class _Gateway implements PaymentGateway {
  RazorpayOrder? openedOrder;
  @override
  Future<RazorpayPaymentProof> pay({required RazorpayOrder order,
    required String email, required String phone}) async {
    openedOrder = order;
    expect(email, 'buyer@example.test');
    expect(phone, '9876543210');
    return const RazorpayPaymentProof(razorpayOrderId: 'order_gateway_1',
      razorpayPaymentId: 'pay_gateway_1', razorpaySignature: 'valid-signature');
  }
  @override
  void dispose() {}
}

void main() {
  test('live coupon validation follows basket changes and sends code to order API', () async {
    Map<String, dynamic>? submittedOrder;
    final api = StoreApi('https://coupons.example.test', client: MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer customer-session');
      if (request.method == 'POST' && request.url.path == '/api/coupons/validate') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['code'], 'WELCOME20');
        expect(body['subtotal'], anyOf(123, 246));
        return http.Response(jsonEncode({
          'success': true,
          'coupon': {'code': 'WELCOME20', 'discountAmount': 40},
        }), 200);
      }
      if (request.method == 'POST' && request.url.path == '/api/orders') {
        submittedOrder = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({
          'id': 'order-coupon-1', 'orderNumber': 'CLR-COUPON-1',
          'orderStatus': 'confirmed', 'paymentMethod': 'cod',
        }), 201);
      }
      throw StateError('Unexpected request ${request.method} ${request.url}');
    }));
    final state = AppState(api: api, sessionVault: _Vault());
    addTearDown(state.dispose);
    addTearDown(api.close);
    await state.acceptSession(const CustomerSession(
      CustomerAccount(id: 'customer-1', email: 'buyer@example.test', name: 'Buyer'),
      'customer-session',
    ));
    const product = Product(id: 'khapli', databaseId: 'db-khapli',
      name: 'Khapli Atta', subtitle: '', origin: '', rating: 0, reviews: 0,
      image: AppImages.khapli, tag: '', groups: [],
      sizes: [ProductSize('1 kg', 123, 123, id: 'variant-1')]);
    state.addToCart(product, product.sizes.single, 1);
    expect(await state.applyLiveCoupon(' welcome20 '), isTrue);
    expect(state.couponDiscount, 40);
    state.setQty(state.cart.single.key, 2);
    expect(state.couponApplied, isFalse);
    expect(state.couponDiscount, 0);
    expect(await state.applyLiveCoupon('WELCOME20'), isTrue);
    await state.submitLiveOrder(
      paymentMethod: 'cod',
      shippingAddress: const {'name': 'Buyer', 'phone': '9876543210', 'pincode': '226010'},
    );
    expect(submittedOrder?['couponCode'], 'WELCOME20');
    expect((submittedOrder?['items'] as List).single['productId'], 'db-khapli');
    expect(state.cart, isEmpty);
    expect(state.couponApplied, isFalse);
  });

  test('ambiguous server failure blocks another submit until order history is checked', () async {
    final api = StoreApi('https://payments.example.test', client: MockClient((request) async {
      if (request.url.path == '/api/orders' && request.method == 'POST') {
        return http.Response(jsonEncode({'error': 'Internal Server Error'}), 500);
      }
      if (request.url.path == '/api/orders' && request.method == 'GET') {
        return http.Response('[]', 200);
      }
      throw StateError('Unexpected request ${request.method} ${request.url}');
    }));
    final state = AppState(api: api, sessionVault: _Vault());
    addTearDown(state.dispose);
    addTearDown(api.close);
    await state.acceptSession(const CustomerSession(
      CustomerAccount(id: 'customer-1', email: 'buyer@example.test', name: 'Buyer'),
      'customer-session',
    ));
    const product = Product(id: 'khapli', name: 'Khapli Atta', subtitle: '', origin: '',
      rating: 0, reviews: 0, image: AppImages.khapli, tag: '', groups: [],
      sizes: [ProductSize('1 kg', 123, 123, id: '1kg')]);
    state.addToCart(product, product.sizes.single, 1);
    await expectLater(state.submitLiveOrder(paymentMethod: 'cod',
      shippingAddress: const {'name': 'Buyer', 'phone': '9876543210', 'pincode': '226010'}),
      throwsA(isA<StoreApiException>()));
    expect(state.orderStatusCheckRequired, isTrue);
    expect(state.cart, hasLength(1));
    await state.refreshCustomerOrders();
    expect(state.orderStatusCheckRequired, isFalse);
    expect(state.customerOrders, isEmpty);
  });

  test('online order waits for Razorpay signature and server order confirmation', () async {
    final gateway = _Gateway();
    var finalOrderCreated = false;
    final api = StoreApi('https://payments.example.test', client: MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer customer-session');
      if (request.url.path == '/api/payments/create-order') {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['paymentMethod'], 'upi');
        expect(body['items'], [{'productId': 'db-khapli', 'variantId': '1kg', 'quantity': 1}]);
        return http.Response(jsonEncode({
          'keyId': 'rzp_test_key', 'providerOrderId': 'order_gateway_1',
          'amount': 12300, 'currency': 'INR',
          'quote': {'subtotal': 123, 'discount': 0, 'deliveryFee': 0, 'tax': 0, 'total': 123},
        }), 201);
      }
      if (request.url.path == '/api/orders') {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['paymentMethod'], 'upi');
        expect(body['items'], [{'productId': 'db-khapli', 'variantId': '1kg', 'quantity': 1}]);
        expect(body['paymentProof'], {
          'razorpayOrderId': 'order_gateway_1',
          'razorpayPaymentId': 'pay_gateway_1',
          'razorpaySignature': 'valid-signature',
        });
        final address = body['shippingAddress'] as Map<String, dynamic>;
        expect(address['pincode'], '226010');
        final order = {
          'id': 'order-confirmed-1', 'orderNumber': 'CLR-2026-2021',
          'orderStatus': 'confirmed', 'paymentMethod': 'upi', 'paymentStatus': 'paid',
          'subtotal': 123, 'deliveryFee': 0, 'discount': 0, 'tax': 0, 'total': 123,
          'items': [], 'shippingAddress': address,
        };
        finalOrderCreated = true;
        return http.Response(jsonEncode(order), 201);
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    }));
    final state = AppState(api: api, sessionVault: _Vault(), paymentGateway: gateway);
    addTearDown(state.dispose);
    addTearDown(api.close);
    await state.acceptSession(const CustomerSession(
      CustomerAccount(id: 'customer-1', email: 'buyer@example.test', name: 'Buyer'),
      'customer-session',
    ));
    const product = Product(id: 'khapli', databaseId: 'db-khapli',
      name: 'Khapli Atta', subtitle: '', origin: '',
      rating: 0, reviews: 0, image: AppImages.khapli, tag: '', groups: [],
      sizes: [ProductSize('1 kg', 123, 123, id: '1kg')]);
    expect(state.addToCart(product, product.sizes.single, 1), isTrue);

    final order = await state.submitLiveOrder(
      paymentMethod: 'upi',
      shippingAddress: const {'name': 'Buyer', 'phone': '9876543210', 'pincode': '226010'},
    );
    expect(gateway.openedOrder?.providerOrderId, 'order_gateway_1');
    expect(finalOrderCreated, isTrue);
    expect(order['orderNumber'], 'CLR-2026-2021');
    expect(state.cart, isEmpty);
    expect(state.customerOrders.single['paymentStatus'], 'paid');
  });
}
