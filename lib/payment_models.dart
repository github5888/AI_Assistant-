class RazorpayOrder {
  const RazorpayOrder({required this.keyId, required this.providerOrderId,
    required this.amountPaise, required this.currency});

  final String keyId;
  final String providerOrderId;
  final int amountPaise;
  final String currency;

  factory RazorpayOrder.fromJson(Object? value) {
    if (value is! Map || value['keyId'] is! String || value['providerOrderId'] is! String ||
        value['amount'] is! num || value['currency'] is! String) {
      throw const PaymentException('The store returned an invalid online payment order.');
    }
    final rawAmount = value['amount'] as num;
    if (!rawAmount.isFinite || rawAmount != rawAmount.roundToDouble()) {
      throw const PaymentException('The store returned an invalid Razorpay amount.');
    }
    final amount = rawAmount.toInt();
    final key = (value['keyId'] as String).trim();
    final providerId = (value['providerOrderId'] as String).trim();
    final currency = (value['currency'] as String).trim();
    if (amount <= 0 || key.isEmpty || providerId.isEmpty || currency != 'INR') {
      throw const PaymentException('The store returned invalid Razorpay checkout details.');
    }
    return RazorpayOrder(keyId: key, providerOrderId: providerId,
      amountPaise: amount, currency: currency);
  }
}

class RazorpayPaymentProof {
  const RazorpayPaymentProof({required this.razorpayOrderId,
    required this.razorpayPaymentId, required this.razorpaySignature});

  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, Object?> toJson() => {
    'razorpayOrderId': razorpayOrderId,
    'razorpayPaymentId': razorpayPaymentId,
    'razorpaySignature': razorpaySignature,
  };
}

class PaymentException implements Exception {
  const PaymentException(this.message);
  final String message;
}

class PaymentCancelledException implements Exception {
  const PaymentCancelledException();
}
