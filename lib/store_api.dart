import 'dart:convert';

import 'package:http/http.dart' as http;

import 'data.dart';

/// The public, read-only portion of the itsclear storefront API.
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

  Future<List<StoreReview>> reviews(Product product) async {
    final rows = await _get(['reviews'], query: {'productId': product.id});
    if (rows is! List) throw const StoreApiException('Reviews could not be read.');
    final reviews = <StoreReview>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final productId = row['productId'];
      // Never show reviews for a different item if the endpoint ignores the filter.
      if (productId is! String || (productId != product.id && productId != product.databaseId)) continue;
      final body = _text(row['comment']);
      final rating = _wholeNumber(row['rating']);
      if (body.isEmpty || rating == null || rating < 1 || rating > 5) continue;
      reviews.add(StoreReview(body, rating));
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

    final isProtein = row['category'] == 'multigrain';
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
    final fallback = isProtein ? AppImages.protein : AppImages.khapli;
    final nutrition = row['nutrition'];
    final rating = row['rating'];
    return Product(
      id: id,
      databaseId: _text(row['_id']),
      name: name,
      subtitle: _text(row['subTitle']),
      origin: _text(row['origin']),
      rating: rating is num && rating.isFinite ? rating.clamp(0, 5).toDouble() : 0,
      reviews: _wholeNumber(row['reviewCount']) ?? 0,
      image: gallery.isEmpty ? fallback : gallery.first,
      gallery: List.unmodifiable(gallery),
      fallbackImage: fallback,
      tag: featured ? 'Featured' : (isProtein ? 'Protein' : 'Stoneground'),
      featured: featured,
      groups: [
        if (isProtein) 'Protein',
        if (row['category'] == 'khapli') 'Khapli',
        if (id.contains('family') || id.contains('handle')) 'Family',
        if (id.contains('duo')) 'Bundle',
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
  final int rating;
}

class StoreApiException implements Exception {
  const StoreApiException(this.message);
  final String message;
}
