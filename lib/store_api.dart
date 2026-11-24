import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_models.dart';
import 'data.dart';
import 'payment_models.dart';

/// The storefront catalog and customer authentication API.
class StoreApi {
  StoreApi(String baseUrl, {http.Client? client})
      : base = Uri.parse(baseUrl),
        _client = client ?? http.Client() {
    if (base.scheme != 'https' || base.host.isEmpty ||
        base.userInfo.isNotEmpty || base.hasQuery || base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw ArgumentError('Set ITSCLEAR_API_BASE_URL to an HTTPS origin');
    }
  }

  final Uri base;
  final http.Client _client;
  static const productionUrl = 'https://itsclear.in';

  void close() => _client.close();

  Future<Object?> _get(List<String> segments, {Map<String, String>? query}) async {
    final uri = base.replace(pathSegments: ['api', ...segments], queryParameters: query);
    final response = await _client.get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const StoreApiException('The store service is unavailable. Try again.');
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const StoreApiException('The store returned an invalid response.');
    }
  }

  Future<Map<String, dynamic>> _auth(List<String> route, {
    Map<String, String>? payload, String? token,
  }) async {
    final request = http.Request(
      payload == null ? 'GET' : 'POST',
      base.replace(pathSegments: ['api', 'auth', ...route]),
    )..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (payload != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(payload);
    }
    final http.Response response;
    try {
      response = await (() async => http.Response.fromStream(await _client.send(request)))()
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const AuthException('Could not reach the store. Check your connection and try again.');
    }
    final status = response.statusCode;
    Map<String, dynamic> result = const {};
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) result = data;
    } on FormatException {
      // HTTP errors are still handled when a proxy returns a non-JSON response.
    }
    if (status < 200 || status >= 300 || result['success'] == false || result.isEmpty) {
      final hint = result['error'];
      final message = status >= 400 && status < 500 && hint is String && hint.isNotEmpty
          ? hint
          : 'The store could not complete this request. Please try again.';
      throw AuthException(message, status: status,
          retryAfter: _wholeNumber(result['retryAfter'] ?? result['resendAfter']));
    }
    return result;
  }

  OtpChallenge _challenge(Map<String, dynamic> result) {
    if (result['mode'] == 'local') {
      throw const AuthException('The store’s email delivery is not available. Try another sign-in method.');
    }
    if (result['success'] != true) {
      throw const AuthException('The store did not confirm the code request.');
    }
    return OtpChallenge(_wholeNumber(result['resendAfter']) ?? 30,
        _wholeNumber(result['expiresIn']) ?? 300);
  }

  Future<OtpChallenge> requestLoginOtp(String email) async => _challenge(await _auth(
    ['login', 'send-otp'], payload: {'email': email.trim().toLowerCase()},
  ));

  Future<CustomerSession> verifyLoginOtp(String email, String otp) async => CustomerSession.fromJson(await _auth(
    ['login', 'verify-otp'], payload: {'email': email.trim().toLowerCase(), 'otp': otp.trim(), 'portal': 'customer'},
  ));

  Future<CustomerSession> passwordLogin(String emailOrPhone, String password) async => CustomerSession.fromJson(await _auth(
    ['login'], payload: {'emailOrPhone': emailOrPhone.trim(), 'password': password},
  ));

  Future<OtpChallenge> startRegistration({required String name, required String mobile,
    required String email, required String password, required String confirmPassword}) async => _challenge(await _auth(
      ['register', 'send-otp'], payload: {'fullName': name.trim(), 'mobile': mobile.trim(),
        'email': email.trim().toLowerCase(), 'password': password, 'confirmPassword': confirmPassword},
  ));

  Future<OtpChallenge> resendRegistrationOtp(String email) async => _challenge(await _auth(
    ['register', 'resend-otp'], payload: {'email': email.trim().toLowerCase()},
  ));

  Future<CustomerSession> verifyRegistrationOtp(String email, String otp) async => CustomerSession.fromJson(await _auth(
    ['register', 'verify-and-create'], payload: {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
  ));

  Future<GoogleExchange> googleLogin(String credential) async {
    final result = await _auth(['google'], payload: {'credential': credential, 'portal': 'customer'});
    if (result['requiresLinking'] == true) {
      final email = result['email'];
      if (email is! String || email.isEmpty) throw const AuthException('The store did not identify the account to link.');
      return GoogleExchange.needsLink(email);
    }
    return GoogleExchange.signedIn(CustomerSession.fromJson(result));
  }

  Future<CustomerSession> linkGoogleOtp(String credential, String otp) async => CustomerSession.fromJson(await _auth(
    ['google', 'link'], payload: {'credential': credential, 'otp': otp.trim()},
  ));

  Future<CustomerAccount> currentCustomer(String token) async => CustomerAccount.fromJson(
    (await _auth(['me'], token: token))['user'],
  );

  Future<List<Product>> products() async {
    final rows = await _get(['products']);
    if (rows is! List) throw const StoreApiException('Invalid product catalog.');
    final catalog = rows.whereType<Map<String, dynamic>>()
        .map((row) => _product(row)).whereType<Product>().toList();
    if (rows.isNotEmpty && catalog.isEmpty) {
      throw const StoreApiException('The product catalog could not be read.');
    }
    return List.unmodifiable(catalog);
  }

  Future<Product> product(String id) async {
    final payload = await _get(['products', id]);
    final result = payload is Map<String, dynamic> ? _product(payload) : null;
    if (result == null || result.id != id) {
      throw const StoreApiException('This product could not be refreshed.');
    }
    return result;
  }

  Future<StoreConfig> config() async {
    final row = await _get(['config']);
    if (row is! Map<String, dynamic> ||
        row['onlinePaymentsEnabled'] is! bool || row['codEnabled'] is! bool ||
        row['currency'] != 'INR' || _wholeNumber(row['freeDeliveryThreshold']) == null) {
      throw const StoreApiException('Store configuration could not be read.');
    }
    return StoreConfig(
      onlinePaymentsEnabled: row['onlinePaymentsEnabled'] as bool,
      codEnabled: row['codEnabled'] as bool,
      freeDeliveryThreshold: _wholeNumber(row['freeDeliveryThreshold'])!,
    );
  }

  Future<bool> healthy() async {
    final row = await _get(['health']);
    return row is Map && row['status'] == 'online' && row['dbStatus'] == 'connected';
  }

  Future<Object?> _orderRequest(List<String> route, String method, String token, {
    Map<String, Object?>? payload,
    String resource = 'orders',
  }) async {
    final request = http.Request(method, base.replace(pathSegments: ['api', resource, ...route]))
      ..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    if (payload != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(payload);
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const StoreApiException('Could not reach the store. Check your connection and try again.');
    }
    Object? result;
    try {
      result = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const StoreApiException('The store returned an invalid order response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final row = result is Map<String, dynamic> ? result : const <String, dynamic>{};
      final message = response.statusCode < 500 && row['error'] is String
          ? row['error'] as String
          : 'The store could not complete this order. Please try again.';
      throw StoreApiException(message, status: response.statusCode);
    }
    return result;
  }

  /// Public active coupon list; the backend has no /coupons/validate route.
  Future<List<StoreCoupon>> coupons() async {
    final rows = await _get(['coupons']);
    if (rows is! List) throw const StoreApiException('The store returned an invalid coupon list.');
    final now = DateTime.now().toUtc();
    final result = <StoreCoupon>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final code = _text(row['code']).toUpperCase();
      final type = _text(row['discountType']);
      final value = row['discountValue'];
      if (code.isEmpty || row['active'] != true || !{'percentage', 'flat'}.contains(type) ||
          value is! num || !value.isFinite || value < 0) continue;
      final validFrom = DateTime.tryParse(_text(row['validFrom']));
      final validUntil = DateTime.tryParse(_text(row['validUntil']));
      final usageLimit = _wholeNumber(row['usageLimit']) ?? 0;
      final usedCount = _wholeNumber(row['usedCount']) ?? 0;
      if ((validFrom != null && now.isBefore(validFrom.toUtc())) ||
          (validUntil != null && now.isAfter(validUntil.toUtc())) ||
          (usageLimit > 0 && usedCount >= usageLimit)) continue;
      result.add(StoreCoupon(
        code: code,
        description: _text(row['description']),
        discountType: type,
        discountValue: value.toDouble(),
        minOrderValue: _wholeNumber(row['minOrderValue']) ?? 0,
      ));
    }
    return List.unmodifiable(result);
  }

  /// Previews the public coupon data. The authenticated order endpoint
  /// independently rechecks coupon existence, active status and minimum value.
  Future<CouponValidation> validateCoupon({
    required String code,
    required int subtotal,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) throw const StoreApiException('Enter a coupon code.');
    final active = await coupons();
    StoreCoupon? coupon;
    for (final candidate in active) {
      if (candidate.code == normalized) {
        coupon = candidate;
        break;
      }
    }
    if (coupon == null) throw const StoreApiException('This coupon is not active.');
    if (subtotal < coupon.minOrderValue) {
      throw StoreApiException('Add items worth ₹${coupon.minOrderValue} to use this coupon.');
    }

    final freeShipping = normalized == 'FREESHIP';
    final discount = freeShipping ? 0 : coupon.discountType == 'percentage'
        ? (subtotal * coupon.discountValue / 100).round()
        : coupon.discountValue.round().clamp(0, subtotal).toInt();
    if (!freeShipping && discount == 0) {
      throw const StoreApiException('This coupon does not discount the current basket.');
    }
    return CouponValidation(code: normalized, discount: discount, freeShipping: freeShipping);
  }

  Map<String, Object?> _orderQuotePayload({
    required List<Map<String, Object?>> items,
    required Map<String, Object?> shippingAddress,
    required String paymentMethod,
    String? couponCode,
    int coinsUsed = 0,
  }) => {
    'items': items,
    'shippingAddress': shippingAddress,
    'paymentMethod': paymentMethod,
    'deliverySlot': '2-Hour Farm Express',
    'ecoPackaging': true,
    'coinsUsed': coinsUsed,
    if (couponCode != null && couponCode.trim().isNotEmpty)
      'couponCode': couponCode.trim().toUpperCase(),
  };

  Future<RazorpayOrder> createRazorpayOrder({
    required String token,
    required List<Map<String, Object?>> items,
    required Map<String, Object?> shippingAddress,
    required String paymentMethod,
    String? couponCode,
    int coinsUsed = 0,
  }) async {
    final payload = await _orderRequest(['create-order'], 'POST', token,
      payload: _orderQuotePayload(items: items, shippingAddress: shippingAddress,
        paymentMethod: paymentMethod, couponCode: couponCode, coinsUsed: coinsUsed),
      resource: 'payments');
    return RazorpayOrder.fromJson(payload);
  }

  Future<Map<String, dynamic>> createOrder({
    required String token,
    required List<Map<String, Object?>> items,
    required Map<String, Object?> shippingAddress,
    required String paymentMethod,
    RazorpayPaymentProof? paymentProof,
    String? couponCode,
    int coinsUsed = 0,
  }) async {
    final result = await _orderRequest([], 'POST', token, payload: {
      ..._orderQuotePayload(items: items, shippingAddress: shippingAddress,
        paymentMethod: paymentMethod, couponCode: couponCode, coinsUsed: coinsUsed),
      if (paymentProof != null) 'paymentProof': paymentProof.toJson(),
    });
    if (result is! Map<String, dynamic> || result['id'] is! String ||
        (result['orderNumber'] is! String && result['id'] is! String)) {
      throw const StoreApiException('The store did not return a valid order confirmation.');
    }
    return Map<String, dynamic>.unmodifiable(result);
  }

  Future<List<Map<String, dynamic>>> customerOrders(String token) async {
    final result = await _orderRequest([], 'GET', token);
    if (result is! List) throw const StoreApiException('The store returned an invalid order list.');
    return List.unmodifiable(result.whereType<Map<String, dynamic>>()
        .map((row) => Map<String, dynamic>.unmodifiable(row)));
  }

  Future<Map<String, dynamic>> customerOrder(String idOrNumber, String token) async {
    final result = await _orderRequest([idOrNumber], 'GET', token);
    if (result is! Map<String, dynamic>) throw const StoreApiException('The store returned an invalid order.');
    return Map<String, dynamic>.unmodifiable(result);
  }

  Future<Map<String, dynamic>> cancelOrder(String id, String token, {String? reason}) async {
    final result = await _orderRequest([id, 'cancel'], 'POST', token, payload: {
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    if (result is! Map<String, dynamic>) throw const StoreApiException('The store returned an invalid order update.');
    return Map<String, dynamic>.unmodifiable(result);
  }

  Future<Map<String, dynamic>> requestOrderReturn(String id, String token, {String? reason}) async {
    final result = await _orderRequest([id, 'return'], 'POST', token, payload: {
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    if (result is! Map<String, dynamic>) throw const StoreApiException('The store returned an invalid return request.');
    return Map<String, dynamic>.unmodifiable(result);
  }

  Future<List<StoreReview>> reviews(Product product) async {
    final rows = await _get(['reviews'], query: {'productId': product.id});
    if (rows is! List) throw const StoreApiException('Reviews could not be read.');
    final reviews = <StoreReview>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final productId = row['productId'];
      // Never show reviews for a different item if the endpoint ignores the filter.
      if (productId is! String || (productId != product.id && productId != product.databaseId)) continue;
      final body = _text(row['comment']);
      final rawRating = row['rating'];
      if (body.isEmpty || rawRating is! num || !rawRating.isFinite ||
          rawRating < 1 || rawRating > 5) continue;
      reviews.add(StoreReview(body, rawRating.toDouble()));
    }
    return List.unmodifiable(reviews);
  }

  Product? _product(Map<String, dynamic> row) {
    final id = _text(row['id']);
    final name = _text(row['name']);
    final variants = row['variants'];
    if (id.isEmpty || name.isEmpty || variants is! List) return null;
    final sizes = <ProductSize>[];
    for (final variant in variants.whereType<Map<String, dynamic>>()) {
      final variantId = _text(variant['id']);
      final label = _text(variant['size']);
      final price = _wholeNumber(variant['price']);
      if (variantId.isEmpty || label.isEmpty || price == null) continue;
      final weight = variant['weightInKg'];
      final compactLabel = weight is num && weight.isFinite && weight > 0
          ? '${weight == weight.round() ? weight.round() : weight} kg' : label;
      final stock = _wholeNumber(variant['stockCount']);
      sizes.add(ProductSize(compactLabel, price,
        _wholeNumber(variant['originalPrice']) ?? price,
        id: variantId,
        description: label,
        inStock: variant['inStock'] == true && (stock == null || stock > 0),
        stockCount: stock,
      ));
    }
    if (sizes.isEmpty) return null;

    final category = _text(row['category'] ?? row['categoryName'] ?? row['type']).toLowerCase();
    final searchable = '$category ${id.toLowerCase()} ${name.toLowerCase()}';
    final isProtein = searchable.contains('multigrain') || searchable.contains('protein');
    final isMustardOil = searchable.contains('mustard') || category == 'oil' || category.contains('oil_');
    final isDesiGhee = searchable.contains('ghee');
    final isKhapli = category.contains('khapli');
    final featured = row['featured'] == true;
    final images = row['images'];
    final gallery = <String>[];
    if (images is List) {
      for (final image in images.whereType<String>()) {
        final candidate = Uri.tryParse(image);
        if (candidate == null || image.trim().isEmpty) continue;
        final url = base.resolveUri(candidate);
        if (url.scheme == 'https' && url.host.isNotEmpty &&
            url.origin == base.origin && url.userInfo.isEmpty) gallery.add(url.toString());
      }
    }
    final fallback = isProtein ? AppImages.protein
        : isMustardOil ? AppImages.mustardOil
        : isDesiGhee ? AppImages.desiGhee
        : AppImages.khapli;
    final nutrition = row['nutrition'];
    final rating = row['rating'];
    return Product(
      id: id,
      databaseId: _text(row['_id']),
      name: name,
      subtitle: _text(row['subTitle'] ?? row['subtitle']),
      origin: _text(row['origin']),
      rating: rating is num && rating.isFinite ? rating.clamp(0, 5).toDouble() : 0,
      reviews: _wholeNumber(row['reviewCount']) ?? 0,
      image: gallery.isEmpty ? fallback : gallery.first,
      gallery: List.unmodifiable(gallery),
      fallbackImage: fallback,
      tag: featured ? 'Featured' : isMustardOil ? 'Cold Pressed'
          : isDesiGhee ? 'Bilona Ghee'
          : isProtein ? 'Protein' : 'Stoneground',
      featured: featured,
      groups: [
        if (isProtein) 'Protein',
        if (isKhapli || searchable.contains('khapli')) 'Khapli',
        if (isMustardOil) 'Mustard Oil',
        if (isDesiGhee) 'Desi Ghee',
        if (searchable.contains('family') || searchable.contains('handle')) 'Family',
        if (searchable.contains('duo') || category.contains('combo') || category.contains('bundle')) 'Bundle',
      ],
      sizes: List.unmodifiable(sizes),
      description: _text(row['description']),
      batch: _text(row['labTestBatch']),
      nutritionFacts: nutrition is Map<String, dynamic> ? {
        for (final entry in nutrition.entries)
          if (entry.value is String) entry.key: entry.value as String,
      } : const {},
    );
  }

  static String _text(Object? value) => value is String ? value.trim() : '';
  static int? _wholeNumber(Object? value) => value is num && value.isFinite &&
      value >= 0 && value == value.roundToDouble() ? value.toInt() : null;
}

class StoreCoupon {
  const StoreCoupon({required this.code, required this.description,
    required this.discountType, required this.discountValue, required this.minOrderValue});
  final String code;
  final String description;
  final String discountType;
  final double discountValue;
  final int minOrderValue;
}

class CouponValidation {
  const CouponValidation({required this.code, required this.discount,
    this.message = '', this.freeShipping = false});
  final String code;
  final int discount;
  final String message;
  final bool freeShipping;
}

class StoreConfig {
  const StoreConfig({required this.onlinePaymentsEnabled, required this.codEnabled,
    required this.freeDeliveryThreshold});
  final bool onlinePaymentsEnabled;
  final bool codEnabled;
  final int freeDeliveryThreshold;
}

class StoreReview {
  const StoreReview(this.body, this.rating);
  final String body;
  final double rating;
}

class StoreApiException implements Exception {
  const StoreApiException(this.message, {this.status});
  final String message;
  final int? status;
}
