import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data.dart';
import 'store_api.dart';

class CartLine {
  final String key;
  final Product product;
  final ProductSize size;
  int qty;

  CartLine({
    required this.key,
    required this.product,
    required this.size,
    required this.qty,
  });

  int get total => size.price * qty;
  int get mrpTotal => size.mrp * qty;
}

class Address {
  String name = 'Aarav Sharma';
  String phone = '+91 98765 43210';
  String line = '12, Green Park';
  String city = 'Lucknow, Uttar Pradesh';
  String pin = '226001';
}

class AppState extends ChangeNotifier {
  AppState({this.api})
    : wishlist = api == null ? <String>{'khapli', 'protein'} : <String>{},
      orderIds = api == null ? <String>['IC40821', 'IC39744', 'IC38109'] : <String>[];

  final StoreApi? api;
  bool get isLive => api != null;
  bool _disposed = false;
  bool isLoadingCatalog = false;
  bool catalogError = false;
  bool? storeOnline;
  StoreConfig? storeConfig;
  List<Product> _liveCatalog = const [];
  List<Product> get catalog => isLive ? _liveCatalog : products;
  List<Product> get featuredProducts {
    if (!isLive) return catalog.take(4).toList();
    final featured = catalog.where((product) => product.featured).toList();
    return (featured.isEmpty ? catalog : featured).take(4).toList();
  }

  Future<void> refreshStore() async {
    if (api == null || _disposed || isLoadingCatalog) return;
    isLoadingCatalog = true;
    catalogError = false;
    notifyListeners();
    await Future.wait([_loadCatalog(api!), _loadConfig(api!), _loadHealth(api!)]);
    if (_disposed) return;
    isLoadingCatalog = false;
    notifyListeners();
  }

  Future<void> _loadCatalog(StoreApi service) async {
    try {
      final result = await service.products();
      if (_disposed) return;
      _liveCatalog = result;
    } catch (_) {
      if (_disposed) return;
      catalogError = true;
    }
    notifyListeners();
  }

  Future<void> _loadConfig(StoreApi service) async {
    try {
      storeConfig = await service.config();
    } catch (_) {
      storeConfig = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadHealth(StoreApi service) async {
    try {
      storeOnline = await service.healthy();
    } catch (_) {
      storeOnline = null;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Product? featuredPack(int slide) {
    if (!isLive) return products[slide];
    const ids = [
      'itsclear-khapli-ancient', 'itsclear-high-protein', 'itsclear-khapli-10k-handle',
    ];
    for (final product in catalog) {
      if (product.id == ids[slide]) return product;
    }
    return null;
  }

  int tab = 0;
  int heroIndex = 0;
  int viewerIndex = 0;
  double viewerAngle = 0;
  int categoryIndex = 0;
  int sortIndex = 0;
  String searchQuery = '';
  int members = 4;
  int rotis = 16;
  int slotIndex = 0;
  int paymentIndex = 0;
  bool couponApplied = false;
  bool orderPlaced = false;
  String orderId = 'IC91032';

  final Address address = Address();
  final List<CartLine> cart = <CartLine>[];
  final Set<String> wishlist;
  final List<String> orderIds;

  int get cartCount => cart.fold(0, (sum, line) => sum + line.qty);
  int get cartSubtotal => cart.fold(0, (sum, line) => sum + line.total);
  int get cartMrp => cart.fold(0, (sum, line) => sum + line.mrpTotal);
  int get cartSavings => cartMrp - cartSubtotal;
  int get delivery => cartSubtotal >= 499 || cart.isEmpty ? 0 : 49;
  int get couponDiscount => couponApplied ? 50 : 0;
  int get cartTotal {
    final value = cartSubtotal + delivery - couponDiscount;
    return value < 0 ? 0 : value;
  }

  int get calcMonthly => rotis * 30;
  double get calcClearKg => calcMonthly / 36;
  double get calcFactoryKg => calcMonthly / 28;
  double get calcSavedKg => calcFactoryKg - calcClearKg;

  List<Product> get filteredProducts {
    final filter = categoryFilters[categoryIndex];
    final list = catalog.where((p) => filter == 'All' || p.groups.contains(filter)).toList();
    if (sortIndex == 1) {
      list.sort((a, b) => a.sizes.first.price.compareTo(b.sizes.first.price));
    } else if (sortIndex == 2) {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  List<Product> get searchResults {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return catalog.take(4).toList();
    return catalog.where((p) => '${p.name} ${p.subtitle}'.toLowerCase().contains(q)).toList();
  }

  void goTab(int index) {
    tab = index;
    notifyListeners();
  }

  void setHeroIndex(int index) {
    heroIndex = index;
    notifyListeners();
  }

  void setViewerIndex(int index) {
    viewerIndex = index;
    viewerAngle = 0;
    notifyListeners();
  }

  void setViewerAngle(double angle) {
    viewerAngle = angle;
    notifyListeners();
  }

  void resetViewer() {
    viewerIndex = 0;
    viewerAngle = 0;
    notifyListeners();
  }

  void setCategory(int index) {
    categoryIndex = index;
    notifyListeners();
  }

  void setSort(int index) {
    sortIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setMembers(int value) {
    members = value;
    rotis = value * 4 < 4 ? 4 : value * 4;
    notifyListeners();
  }

  void setRotis(int value) {
    rotis = value;
    notifyListeners();
  }

  void setSlot(int index) {
    slotIndex = index;
    notifyListeners();
  }

  void setPayment(int index) {
    paymentIndex = index;
    notifyListeners();
  }

  void toggleWish(String id) {
    if (wishlist.contains(id)) {
      wishlist.remove(id);
    } else {
      wishlist.add(id);
    }
    notifyListeners();
  }

  bool addToCart(Product product, ProductSize size, int qty) {
    if (qty <= 0 || !size.inStock) return false;
    final key = '${product.id}_${size.id ?? size.label}';
    final index = cart.indexWhere((line) => line.key == key);
    final nextQty = qty + (index < 0 ? 0 : cart[index].qty);
    final stock = size.stockCount;
    if (stock != null && nextQty > stock) return false;
    if (index >= 0) {
      cart[index].qty = nextQty;
    } else {
      cart.add(CartLine(key: key, product: product, size: size, qty: qty));
    }
    notifyListeners();
    return true;
  }

  void setQty(String key, int qty) {
    final index = cart.indexWhere((line) => line.key == key);
    if (index < 0) return;
    if (qty <= 0) {
      cart.removeAt(index);
    } else {
      final stock = cart[index].size.stockCount;
      if (stock != null && qty > stock) return;
      cart[index].qty = qty;
    }
    notifyListeners();
  }

  void removeFromCart(String key) {
    cart.removeWhere((line) => line.key == key);
    notifyListeners();
  }

  bool applyCoupon(String code) {
    if (isLive) return false;
    final ok = code.trim().toUpperCase() == 'CLEAR50';
    couponApplied = ok;
    notifyListeners();
    return ok;
  }

  void placeOrder() {
    if (isLive) return;
    orderId = 'IC${91032 + orderIds.length}';
    orderIds.insert(0, orderId);
    cart.clear();
    couponApplied = false;
    orderPlaced = true;
    notifyListeners();
  }

  void backToHome() {
    tab = 0;
    orderPlaced = false;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    Key? key,
    required AppState notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.notifier!;
  }
}
