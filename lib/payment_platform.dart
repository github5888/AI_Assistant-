import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'payment_models.dart';

abstract interface class PaymentGateway {
  Future<RazorpayPaymentProof> pay({
    required RazorpayOrder order,
    required String email,
    required String phone,
    required String paymentMethod,
  });
  void dispose();
}

/// Native Razorpay Checkout wrapper. The app opens a server-created order,
/// receives the provider signature, then submits that proof to itsclear.
class NativeRazorpayGateway implements PaymentGateway {
  NativeRazorpayGateway() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  final Razorpay _razorpay = Razorpay();
  Completer<RazorpayPaymentProof>? _pending;

  @override
  Future<RazorpayPaymentProof> pay({required RazorpayOrder order,
    required String email, required String phone, required String paymentMethod}) {
    if (_pending != null) throw const PaymentException('A payment is already open.');
    final methodOption = switch (paymentMethod) {
      'upi' => const {'upi': true},
      'card' => const {'card': true},
      'netbanking' => const {'netbanking': true},
      _ => null,
    };
    if (methodOption == null) throw const PaymentException('Choose a supported online payment method.');
    final pending = Completer<RazorpayPaymentProof>();
    _pending = pending;
    try {
      _razorpay.open({
        'key': order.keyId,
        'order_id': order.providerOrderId,
        'amount': order.amountPaise,
        'currency': order.currency,
        'name': 'itsclear',
        'description': 'Fresh stoneground flour order',
        'method': methodOption,
        'prefill': {
          if (phone.trim().isNotEmpty) 'contact': phone.trim(),
          if (email.trim().isNotEmpty) 'email': email.trim(),
        },
        'theme': {'color': '#101A3A'},
        'retry': {'enabled': true, 'max_count': 2},
      });
    } catch (_) {
      _pending = null;
      throw const PaymentException('Razorpay Checkout could not be opened. Please try again.');
    }
    return pending.future.whenComplete(() { _pending = null; });
  }

  void _onSuccess(PaymentSuccessResponse response) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    final orderId = response.orderId;
    final paymentId = response.paymentId;
    final signature = response.signature;
    if (orderId == null || orderId.isEmpty || paymentId == null || paymentId.isEmpty ||
        signature == null || signature.isEmpty) {
      pending.completeError(const PaymentException('Razorpay did not return a complete payment signature.'));
      return;
    }
    pending.complete(RazorpayPaymentProof(razorpayOrderId: orderId,
      razorpayPaymentId: paymentId, razorpaySignature: signature));
  }

  void _onFailure(PaymentFailureResponse response) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      pending.completeError(const PaymentCancelledException());
    } else {
      pending.completeError(PaymentException(response.message?.trim().isNotEmpty == true
          ? response.message!.trim() : 'Razorpay could not complete the payment. Please try again.'));
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // A wallet selection is not a captured-payment confirmation. Continue to
    // wait for the signed payment-success callback from the provider.
  }

  @override
  void dispose() {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const PaymentCancelledException());
    }
    _pending = null;
    _razorpay.clear();
  }
}
