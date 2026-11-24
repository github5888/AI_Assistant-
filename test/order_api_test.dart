import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/store_api.dart';
import 'package:itsclear_app/payment_models.dart';

void main() {
  test('creates a customer COD order and loads/cancels only with bearer session', () async {
    final api = StoreApi('https://orders.example.test', client: MockClient((request) async {
      expect(request.followRedirects, isFalse);
      expect(request.headers['authorization'], 'Bearer signed-customer-session');
      if (request.method == 'POST' && request.url.path == '/api/payments/create-order') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['items'], [
          {'product': {'id': 'khapli-family'}, 'selectedVariant': {'id': 'kh-1kg'}, 'quantity': 2},
        ]);
        return http.Response(jsonEncode({
          'keyId': 'rzp_test_itsclear', 'providerOrderId': 'order_provider_1',
          'amount': 19000, 'currency': 'INR',
          'quote': {'subtotal': 190, 'discount': 0, 'deliveryFee': 0, 'tax': 0, 'total': 190},
        }), 201);
      }
      if (request.method == 'POST' && request.url.path == '/api/orders') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['paymentMethod'], anyOf('cod', 'upi'));
        if (body['paymentMethod'] == 'upi') {
          expect(body['paymentProof'], {
            'razorpayOrderId': 'order_provider_1',
            'razorpayPaymentId': 'pay_1',
            'razorpaySignature': 'signature_1',
          });
        }
        expect(body['deliverySlot'], '2-Hour Farm Express');
        expect(body['ecoPackaging'], isTrue);
        expect(body['items'], [
          {'product': {'id': 'khapli-family'}, 'selectedVariant': {'id': 'kh-1kg'}, 'quantity': 2},
        ]);
        expect((body['shippingAddress'] as Map)['pincode'], '226010');
        return http.Response(jsonEncode({
          'id': 'ord-test', 'orderNumber': 'CLR-2026-1234', 'orderStatus': 'confirmed',
          'paymentMethod': body['paymentMethod'], 'paymentStatus': body['paymentMethod'] == 'cod' ? 'pending' : 'paid', 'total': 190,
        }), 201);
      }
      if (request.method == 'GET' && request.url.path == '/api/orders') {
        return http.Response(jsonEncode([
          {'id': 'ord-test', 'orderNumber': 'CLR-2026-1234', 'orderStatus': 'confirmed', 'total': 190},
        ]), 200);
      }
      if (request.method == 'GET' && request.url.path == '/api/orders/ord-test') {
        return http.Response(jsonEncode({
          'id': 'ord-test', 'orderNumber': 'CLR-2026-1234',
          'orderStatus': 'on_the_way', 'trackingStep': 4, 'total': 190,
        }), 200);
      }
      if (request.method == 'POST' && request.url.path == '/api/orders/ord-test/cancel') {
        expect(jsonDecode(request.body), {'reason': 'Changed my mind'});
        return http.Response(jsonEncode({
          'id': 'ord-test', 'orderNumber': 'CLR-2026-1234', 'orderStatus': 'cancelled', 'total': 190,
        }), 200);
      }
      if (request.method == 'POST' && request.url.path == '/api/orders/ord-test/return') {
        expect(jsonDecode(request.body), {'reason': 'Pack issue'});
        return http.Response(jsonEncode({
          'id': 'ord-test', 'orderNumber': 'CLR-2026-1234', 'orderStatus': 'return_requested', 'total': 190,
        }), 200);
      }
      throw StateError('Unexpected request ${request.method} ${request.url}');
    }));
    addTearDown(api.close);

    final checkout = await api.createRazorpayOrder(
      token: 'signed-customer-session',
      items: const [{'product': {'id': 'khapli-family'}, 'selectedVariant': {'id': 'kh-1kg'}, 'quantity': 2}],
      shippingAddress: const {'name': 'Test Buyer', 'pincode': '226010'},
      paymentMethod: 'upi',
    );
    expect(checkout.keyId, 'rzp_test_itsclear');
    expect(checkout.providerOrderId, 'order_provider_1');
    expect(checkout.amountPaise, 19000);

    final created = await api.createOrder(
      token: 'signed-customer-session',
      items: const [{'product': {'id': 'khapli-family'}, 'selectedVariant': {'id': 'kh-1kg'}, 'quantity': 2}],
      shippingAddress: const {
        'name': 'Test Buyer', 'phone': '9876543210', 'address': '12 Gomti Nagar',
        'city': 'Lucknow', 'state': 'Uttar Pradesh', 'pincode': '226010', 'country': 'India',
      },
      paymentMethod: 'cod',
    );
    expect(created['orderNumber'], 'CLR-2026-1234');
    final paid = await api.createOrder(
      token: 'signed-customer-session',
      items: const [{'product': {'id': 'khapli-family'}, 'selectedVariant': {'id': 'kh-1kg'}, 'quantity': 2}],
      shippingAddress: const {'name': 'Test Buyer', 'pincode': '226010'},
      paymentMethod: 'upi',
      paymentProof: const RazorpayPaymentProof(
        razorpayOrderId: 'order_provider_1',
        razorpayPaymentId: 'pay_1',
        razorpaySignature: 'signature_1',
      ),
    );
    expect(paid['id'], 'ord-test');
    expect((await api.customerOrders('signed-customer-session')).single['id'], 'ord-test');
    expect((await api.customerOrder('ord-test', 'signed-customer-session'))['trackingStep'], 4);
    expect((await api.cancelOrder('ord-test', 'signed-customer-session', reason: 'Changed my mind'))['orderStatus'], 'cancelled');
    expect((await api.requestOrderReturn('ord-test', 'signed-customer-session', reason: 'Pack issue'))['orderStatus'], 'return_requested');
  });

  test('surfaces server price/stock conflicts without pretending an order succeeded', () async {
    final api = StoreApi('https://orders.example.test', client: MockClient((request) async =>
      http.Response(jsonEncode({'error': 'Stock changed during checkout. Please review your cart.'}), 409)));
    addTearDown(api.close);
    await expectLater(api.createOrder(
      token: 'signed-customer-session',
      items: const [{'product': {'id': 'khapli-family'}, 'selectedVariant': {'id': 'kh-1kg'}, 'quantity': 2}],
      shippingAddress: const {},
      paymentMethod: 'cod',
    ), throwsA(isA<StoreApiException>()
      .having((error) => error.status, 'status', 409)
      .having((error) => error.message, 'message', contains('Stock changed'))));
  });
}
