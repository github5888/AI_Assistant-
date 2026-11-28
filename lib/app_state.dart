import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'auth_models.dart';
import 'auth_platform.dart';
import 'data.dart';
import 'payment_models.dart';
import 'payment_platform.dart';
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
  AppState({this.api, this.sessionVault, this.addressVault, this.googleIdentity, this.paymentGateway})
    : wishlist = api == null ? <String>{'khapli', 'protein'} : <String>{},
      orderIds = api == null ? <String>['IC40821', 'IC39744', 'IC38109'] : <String>[];

  final StoreApi? api;
  final SessionVault? sessionVault;
  final AddressVault? addressVault;
  final GoogleIdentity? googleIdentity;
  final PaymentGateway? paymentGateway;
  CustomerSession? _session;
  CustomerAccount? get customer => _session?.account;
  String? get customerToken => _session?.token;
  Future<void> Function(Map<String, dynamic>)? notificationOpener;
  Future<void> Function()? refreshPushRegistration;
  void Function(String title, String body)? showTopNotice;
  int notificationUnreadCount = 0;

  void updateNotificationUnreadCount(int count) {
    final next = count < 0 ? 0 : count;
    if (notificationUnreadCount == next || _disposed) return;
    notificationUnreadCount = next;
    notifyListeners();
  }

  Future<void> openNotification(Map<String, dynamic> data) async {
    await notificationOpener?.call(data);
  }
  bool restoringSession = false;
  Map<String, Object?>? savedShippingAddress;
  bool restoringAddress = false;

  Future<void> restoreSavedAddress() async {
    final vault = addressVault;
    if (vault == null || restoringAddress || savedShippingAddress != null || _disposed) return;
    restoringAddress = true;
    try {
      savedShippingAddress = await vault.read();
    } catch (_) {
      savedShippingAddress = null;
    } finally {
      restoringAddress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> saveShippingAddress(Map<String, Object?> address) async {
    final vault = addressVault;
    if (vault != null) await vault.write(address);
    savedShippingAddress = Map<String, Object?>.unmodifiable(address);
    if (!_disposed) notifyListeners();
  }

  Future<void> clearSavedShippingAddress() async {
    await addressVault?.clear();
    savedShippingAddress = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> restoreSession() async {
    final service = api;
    final vault = sessionVault;
    if (service == null || vault == null || restoringSession || _session != null) return;
    restoringSession = true;
    notifyListeners();
    try {
      final token = await vault.read();
      if (token == null || token.isEmpty || _disposed) return;
      final account = await service.currentCustomer(token);
      if (!_disposed) _session = CustomerSession(account, token);
    } catch (error) {
      // Keep the stored session on transient network errors. Never show it as
      // authenticated before /me has confirmed it.
      if (error is AuthException && (error.status == 401 || error.status == 404)) {
        try { await vault.clear(); } catch (_) { /* Retry on next launch. */ }
      }
    } finally {
      restoringSession = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> acceptSession(CustomerSession session) async {
    if (_disposed || restoringSession) return;
    try {
      await sessionVault?.write(session.token);
    } catch (_) {
      throw const AuthException('Could not save your secure session. Please try again.');
    }
    if (_disposed) return;
    if (_session?.account.id != session.account.id) {
      _customerOrders = const [];
      customerOrdersError = null;
      notificationUnreadCount = 0;
    }
    _session = session;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await sessionVault?.clear();
    } catch (_) {
      throw const AuthException('Could not clear your saved session. Please try again.');
    }
    if (_disposed) return;
    _session = null;
    notificationUnreadCount = 0;
    _customerOrders = const [];
    useGrainCoins = false;
    _clearLiveCoupon();
    orderStatusCheckRequired = false;
    customerOrdersError = null;
    notifyListeners();
    try { await googleIdentity?.signOut(); } catch (_) { /* Store sign-out is complete. */ }
  }

  bool get isLive => api != null;
  bool _disposed = false;
  bool isLoadingCatalog = false;
  bool catalogError = false;
  bool? storeOnline;
  StoreConfig? storeConfig;
  List<Map<String, dynamic>>? _liveHeroBanners;
  List<Map<String, dynamic>>? get liveHeroBanners => _liveHeroBanners;
  List<StoreCoupon> liveCoupons = const [];
  bool isLoadingCoupons = false;
  bool couponListError = false;
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
    await Future.wait([_loadCatalog(api!), _loadConfig(api!), _loadHealth(api!), _loadCoupons(api!),
      _loadHeroBanners(api!)]);
    if (_disposed) return;
    isLoadingCatalog = false;
    notifyListeners();
  }

  Future<void> refreshHomeHeroBanners() async {
    final service = api;
    if (service == null || _disposed) return;
    await _loadHeroBanners(service);
  }

  Future<void> _loadHeroBanners(StoreApi service) async {
    try {
      _liveHeroBanners = await service.homeHeroBanners();
    } catch (_) {
      _liveHeroBanners = null;
    }
    if (!_disposed) notifyListeners();
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

  Future<void> _loadCoupons(StoreApi service) async {
    isLoadingCoupons = true;
    try {
      liveCoupons = await service.coupons();
      couponListError = false;
    } catch (_) {
      liveCoupons = const [];
      couponListError = true;
    } finally {
      isLoadingCoupons = false;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    paymentGateway?.dispose();
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
  String? appliedCouponCode;
  bool appliedCouponFreeShipping = false;
  int _liveCouponDiscount = 0;
  bool useGrainCoins = false;
  bool isApplyingCoupon = false;
  String? couponError;
  bool orderPlaced = false;
  String orderId = 'IC91032';
  bool isSubmittingOrder = false;
  bool orderStatusCheckRequired = false;
  bool isLoadingCustomerOrders = false;
  String? customerOrdersError;
  List<Map<String, dynamic>> _customerOrders = const [];
  List<Map<String, dynamic>> get customerOrders => _customerOrders;

  final Address address = Address();
  final List<CartLine> cart = <CartLine>[];
  final Set<String> wishlist;
  final List<String> orderIds;

  int get cartCount => cart.fold(0, (sum, line) => sum + line.qty);
  int get cartSubtotal => cart.fold(0, (sum, line) => sum + line.total);
  int get cartMrp => cart.fold(0, (sum, line) => sum + line.mrpTotal);
  int get cartSavings => cartMrp - cartSubtotal;
  int get couponDiscount => isLive
      ? (couponApplied ? _liveCouponDiscount : 0)
      : couponApplied ? 50 : 0;
  int get coinsAvailable => isLive ? (customer?.clearCoins ?? 0) : 0;
  int get maxCoinsRedeemable {
    if (!isLive || coinsAvailable <= 0) return 0;
    final afterCoupon = (cartSubtotal - couponDiscount).clamp(0, cartSubtotal);
    return coinsAvailable < afterCoupon ~/ 2 ? coinsAvailable : afterCoupon ~/ 2;
  }
  int get coinsToRedeem => useGrainCoins ? maxCoinsRedeemable : 0;
  int get delivery {
    if (cart.isEmpty) return 0;
    if (isLive && appliedCouponFreeShipping && couponApplied) return 0;
    final afterDiscounts = cartSubtotal - couponDiscount - coinsToRedeem;
    final threshold = isLive ? (storeConfig?.freeDeliveryThreshold ?? 499) : 499;
    return afterDiscounts >= threshold ? 0 : 49;
  }
  int get cartTotal {
    final value = cartSubtotal + delivery - couponDiscount - coinsToRedeem;
    return value < 0 ? 0 : value;
  }

  void setUseGrainCoins(bool enabled) {
    useGrainCoins = enabled && isLive && coinsAvailable > 0;
    notifyListeners();
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

  void _clearLiveCoupon() {
    couponApplied = false;
    appliedCouponCode = null;
    appliedCouponFreeShipping = false;
    _liveCouponDiscount = 0;
    couponError = null;
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
    if (isLive) _clearLiveCoupon();
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
      if (cart[index].qty == qty) return;
      cart[index].qty = qty;
    }
    if (isLive) _clearLiveCoupon();
    notifyListeners();
  }

  void removeFromCart(String key) {
    final previousLength = cart.length;
    cart.removeWhere((line) => line.key == key);
    if (cart.length != previousLength && isLive) _clearLiveCoupon();
    notifyListeners();
  }

  bool applyCoupon(String code) {
    if (isLive) return false;
    final ok = code.trim().toUpperCase() == 'CLEAR50';
    couponApplied = ok;
    appliedCouponCode = ok ? 'CLEAR50' : null;
    appliedCouponFreeShipping = false;
    notifyListeners();
    return ok;
  }

  void clearAppliedCoupon() {
    _clearLiveCoupon();
    notifyListeners();
  }

  Future<bool> applyLiveCoupon(String code) async {
    final service = api;
    final normalized = code.trim().toUpperCase();
    if (service == null || !isLive) return false;
    if (normalized.isEmpty) {
      couponError = 'Enter a coupon code.';
      notifyListeners();
      return false;
    }
    if (isApplyingCoupon) return false;
    isApplyingCoupon = true;
    couponError = null;
    final validatedSubtotal = cartSubtotal;
    notifyListeners();
    try {
      final result = await service.validateCoupon(
        code: normalized,
        subtotal: validatedSubtotal,
      );
      if (_disposed) return false;
      if (validatedSubtotal != cartSubtotal) {
        couponError = 'Basket changed. Apply the coupon again.';
        return false;
      }
      appliedCouponCode = result.code;
      appliedCouponFreeShipping = result.freeShipping;
      _liveCouponDiscount = result.discount.clamp(0, cartSubtotal).toInt();
      couponApplied = result.freeShipping || _liveCouponDiscount > 0;
      if (!couponApplied) couponError = 'This coupon does not apply to the current basket.';
      return couponApplied;
    } on StoreApiException catch (error) {
      if (!_disposed) {
        _clearLiveCoupon();
        couponError = error.message;
      }
      return false;
    } finally {
      isApplyingCoupon = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitLiveOrder({
    required Map<String, Object?> shippingAddress,
    required String paymentMethod,
  }) async {
    final service = api;
    final session = _session;
    if (service == null) throw const StoreApiException('Live checkout is unavailable.');
    if (session == null) throw const StoreApiException('Sign in to place your order.', status: 401);
    if (isSubmittingOrder) throw const StoreApiException('Your order is already being submitted.');
    if (cart.isEmpty) throw const StoreApiException('Your basket is empty.');
    if (!const {'cod', 'upi', 'card', 'netbanking'}.contains(paymentMethod)) {
      throw const StoreApiException('Choose a supported payment method.');
    }
    if (paymentMethod != 'cod' && paymentGateway == null) {
      throw const StoreApiException('Online payment is not available in this app build.');
    }
    final items = <Map<String, Object?>>[];
    for (final line in List<CartLine>.of(cart)) {
      final variantId = line.size.id;
      if (variantId == null || variantId.isEmpty) {
        throw const StoreApiException('A selected pack is missing its store variant. Please refresh the catalog.');
      }
      // orderPricing.js resolves the public Product.id and variant.id from
      // nested `product` and `selectedVariant` references (not Mongo _id).
      items.add({
        'product': {'id': line.product.id},
        'selectedVariant': {'id': variantId},
        'quantity': line.qty,
      });
    }
    final couponCode = couponApplied ? appliedCouponCode : null;
    final requestedCoins = coinsToRedeem;
    isSubmittingOrder = true;
    customerOrdersError = null;
    var finalOrderRequestStarted = false;
    notifyListeners();
    try {
      RazorpayPaymentProof? proof;
      if (paymentMethod != 'cod') {
        final gateway = paymentGateway!;
        final paymentOrder = await service.createRazorpayOrder(
          token: session.token,
          items: items,
          shippingAddress: shippingAddress,
          paymentMethod: paymentMethod,
          couponCode: couponCode,
          coinsUsed: requestedCoins,
        );
        proof = await gateway.pay(
          order: paymentOrder,
          email: session.account.email,
          phone: shippingAddress['phone'] is String ? shippingAddress['phone'] as String : '',
          paymentMethod: paymentMethod,
        );
      }
      finalOrderRequestStarted = true;
      final order = await service.createOrder(
        token: session.token,
        items: items,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        paymentProof: proof,
        couponCode: couponCode,
        coinsUsed: requestedCoins,
      );
      if (!_disposed && identical(_session, session)) {
        _customerOrders = List.unmodifiable([order, ..._customerOrders
            .where((existing) => existing['id'] != order['id'])]);
        cart.clear();
        _clearLiveCoupon();
        useGrainCoins = false;
        final used = order['coinsUsed'];
        final earned = order['coinsEarned'];
        if (used is num && earned is num && used.isFinite && earned.isFinite) {
          final balance = (session.account.clearCoins - used.floor() + earned.floor())
              .clamp(0, 1 << 31).toInt();
          final account = session.account;
          _session = CustomerSession(CustomerAccount(
            id: account.id, email: account.email, name: account.name, clearCoins: balance,
          ), session.token);
        }
        orderStatusCheckRequired = false;
        notifyListeners();
      }
      return order;
    } on StoreApiException catch (error) {
      if (finalOrderRequestStarted && !_disposed && identical(_session, session) &&
          (error.status == null || error.status! >= 500)) {
        orderStatusCheckRequired = true;
        notifyListeners();
      }
      rethrow;
    } catch (_) {
      if (finalOrderRequestStarted && !_disposed && identical(_session, session)) {
        orderStatusCheckRequired = true;
        notifyListeners();
      }
      rethrow;
    } finally {
      isSubmittingOrder = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<Map<String, dynamic>> refreshCustomerOrder(String idOrNumber) async {
    final service = api;
    final session = _session;
    if (service == null || session == null) {
      throw const StoreApiException('Sign in to view your orders.', status: 401);
    }
    final order = await service.customerOrder(idOrNumber, session.token);
    if (!_disposed && identical(_session, session)) {
      final index = _customerOrders.indexWhere((item) =>
        item['id'] == order['id'] || item['orderNumber'] == order['orderNumber']);
      if (index < 0) {
        _customerOrders = List.unmodifiable([order, ..._customerOrders]);
      } else {
        final updated = List<Map<String, dynamic>>.of(_customerOrders);
        updated[index] = order;
        _customerOrders = List.unmodifiable(updated);
      }
      notifyListeners();
    }
    return order;
  }

  Future<Map<String, dynamic>> cancelCustomerOrder(String orderId, {String? reason}) async {
    final service = api;
    final session = _session;
    if (service == null || session == null) {
      throw const StoreApiException('Sign in to manage your orders.', status: 401);
    }
    final updated = await service.cancelOrder(orderId, session.token, reason: reason);
    if (!_disposed && identical(_session, session)) {
      _customerOrders = List.unmodifiable(_customerOrders.map((order) =>
        order['id'] == updated['id'] ? updated : order));
      notifyListeners();
    }
    return updated;
  }

  Future<Map<String, dynamic>> requestCustomerOrderReturn(String orderId, {String? reason}) async {
    final service = api;
    final session = _session;
    if (service == null || session == null) {
      throw const StoreApiException('Sign in to manage your orders.', status: 401);
    }
    final updated = await service.requestOrderReturn(orderId, session.token, reason: reason);
    if (!_disposed && identical(_session, session)) {
      _customerOrders = List.unmodifiable(_customerOrders.map((order) =>
        order['id'] == updated['id'] ? updated : order));
      notifyListeners();
    }
    return updated;
  }

  Future<void> refreshCustomerOrders() async {
    final service = api;
    final session = _session;
    if (service == null || session == null || isLoadingCustomerOrders) return;
    isLoadingCustomerOrders = true;
    customerOrdersError = null;
    notifyListeners();
    try {
      final orders = await service.customerOrders(session.token);
      if (!_disposed && identical(_session, session)) {
        _customerOrders = orders;
        customerOrdersError = null;
        orderStatusCheckRequired = false;
      }
    } on StoreApiException catch (error) {
      if (identical(_session, session)) customerOrdersError = error.message;
    } catch (_) {
      if (identical(_session, session)) {
        customerOrdersError = 'Could not load your orders. Pull down to try again.';
      }
    } finally {
      isLoadingCustomerOrders = false;
      if (!_disposed) {
        notifyListeners();
        if (_session != null && !identical(_session, session)) {
          Future<void>.microtask(refreshCustomerOrders);
        }
      }
    }
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
