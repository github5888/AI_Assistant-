import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_state.dart';
import 'store_api.dart';
import 'screens/checkout_flow.dart';
import 'screens/list_screens.dart';
import 'screens/product_screen.dart';

@pragma('vm:entry-point')
Future<void> itsClearFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Customer-device FCM registration and notification tap routing.
/// The server remains the only authority for sending messages and reading orders.
class PushNotificationService {
  PushNotificationService({required this.api, required this.navigatorKey});

  final StoreApi api;
  final GlobalKey<NavigatorState> navigatorKey;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _deviceIdKey = 'itsclear.push-device-id.v1';

  AppState? _state;
  String? _boundCustomerToken;
  String? _pendingToken;
  Map<String, dynamic>? _pendingTap;
  String? _deviceId;
  Future<void> _syncQueue = Future<void>.value();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  OverlayEntry? _foregroundNotice;
  Timer? _foregroundNoticeTimer;

  Future<void> initialize(AppState state) async {
    _state = state;
    state.notificationOpener = (data) async => _handleMessageData(data);
    state.refreshPushRegistration = () async {
      final token = state.customerToken;
      if (token != null) await _register(token);
    };
    state.addListener(_onStateChanged);
    FirebaseMessaging.onBackgroundMessage(itsClearFirebaseBackgroundHandler);
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    _tokenSubscription = _messaging.onTokenRefresh.listen((_) => _queueRegistration(force: true));
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _pendingTap = Map<String, dynamic>.from(initial.data);
    } catch (_) {
      // Firebase may be temporarily unavailable; normal app use can continue.
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingTap());
    _onStateChanged();
  }

  void _onStateChanged() {
    final token = _state?.customerToken;
    if (token == _boundCustomerToken) {
      if (token != null && _pendingTap != null) _openPendingTap();
      return;
    }
    final previous = _boundCustomerToken;
    _boundCustomerToken = token;
    _syncQueue = _syncQueue.then((_) async {
      if (token == null) {
        if (previous != null) await _unregister(previous);
      } else {
        await _register(token);
      }
    }).catchError((Object _) {});
    if (token != null && _pendingTap != null) _openPendingTap();
  }

  void _queueRegistration({bool force = false}) {
    final token = _state?.customerToken;
    if (token == null || (!force && token == _pendingToken)) return;
    _pendingToken = token;
    _syncQueue = _syncQueue.then((_) => _register(token)).catchError((Object _) {});
  }

  Future<void> _register(String customerToken) async {
    final permissionBefore = await _messaging.getNotificationSettings();
    var permission = permissionBefore.authorizationStatus;
    if (permission == AuthorizationStatus.notDetermined) {
      final requested = await _messaging.requestPermission(
        alert: true, badge: true, sound: true, provisional: false,
      );
      permission = requested.authorizationStatus;
    }
    final fcmToken = await _messaging.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;
    final deviceId = await _stableDeviceId();
    final package = await PackageInfo.fromPlatform();
    final metadata = await _deviceMetadata();
    final permissionStatus = switch (permission) {
      AuthorizationStatus.authorized => 'granted',
      AuthorizationStatus.provisional => 'provisional',
      _ => 'denied',
    };
    await api.registerDevice(customerToken, {
      'fcmToken': fcmToken,
      'deviceId': deviceId,
      'deviceName': metadata.$1,
      'platform': Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web',
      'appVersion': package.version,
      'osVersion': metadata.$2,
      'notificationPermissionStatus': permissionStatus,
    });
    _pendingToken = null;
    await _refreshUnreadCount(customerToken);
  }

  Future<void> _unregister(String customerToken) async {
    final deviceId = _deviceId ?? await _stableDeviceId();
    try {
      await api.unregisterDevice(customerToken, deviceId);
    } catch (_) {
      // Don't block customer sign-out on a transient push-service outage.
    }
  }

  Future<String> _stableDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      _deviceId = existing;
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final value = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await _storage.write(key: _deviceIdKey, value: value);
    _deviceId = value;
    return value;
  }

  Future<(String, String)> _deviceMetadata() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      final model = android.model.trim().isEmpty ? 'Android device' : android.model.trim();
      return ('${android.brand} $model'.trim(), 'Android ${android.version.release} (API ${android.version.sdkInt})');
    }
    if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return (ios.name, 'iOS ${ios.systemVersion}');
    }
    return ('itsclear device', Platform.operatingSystemVersion);
  }

  Future<void> _refreshUnreadCount(String token) async {
    try {
      final count = await api.notificationUnreadCount(token);
      if (_state?.customerToken == token) _state?.updateNotificationUnreadCount(count);
    } catch (_) {
      // Inbox polling is best-effort and never blocks order or sign-in flows.
    }
  }

  void _showForegroundMessage(RemoteMessage message) {
    final token = _state?.customerToken;
    if (token != null) unawaited(_refreshUnreadCount(token));
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'itsclear update';
    final body = message.notification?.body ?? message.data['message']?.toString() ?? '';
    _dismissForegroundNotice();
    final canOpen = message.data.isNotEmpty;
    _foregroundNotice = OverlayEntry(builder: (_) => Positioned(
      top: 0,
      left: 12,
      right: 12,
      child: SafeArea(bottom: false, child: _ForegroundNotificationCard(
        title: title,
        body: body,
        canOpen: canOpen,
        onOpen: canOpen ? () {
          _dismissForegroundNotice();
          _handleMessageTap(message);
        } : null,
        onDismiss: _dismissForegroundNotice,
      )),
    ));
    overlay.insert(_foregroundNotice!);
    _foregroundNoticeTimer = Timer(const Duration(seconds: 5), _dismissForegroundNotice);
  }

  void _dismissForegroundNotice() {
    _foregroundNoticeTimer?.cancel();
    _foregroundNoticeTimer = null;
    _foregroundNotice?.remove();
    _foregroundNotice = null;
  }

  void _handleMessageTap(RemoteMessage message) =>
      _handleMessageData(Map<String, dynamic>.from(message.data));

  void _handleMessageData(Map<String, dynamic> data) {
    final customerToken = _state?.customerToken;
    if (customerToken != null) unawaited(_refreshUnreadCount(customerToken));
    if (customerToken == null || navigatorKey.currentState == null) {
      _pendingTap = data;
      return;
    }
    _pendingTap = null;
    unawaited(_openDestination(data));
  }

  void _openPendingTap() {
    final pending = _pendingTap;
    if (pending != null && _state?.customerToken != null && navigatorKey.currentState != null) {
      _handleMessageData(pending);
    }
  }

  Future<void> _openDestination(Map<String, dynamic> data) async {
    final state = _state;
    final navigator = navigatorKey.currentState;
    if (state == null || navigator == null || state.customerToken == null) return;
    final screen = (data['screen'] ?? data['deepLinkDestination'] ?? '').toString().toUpperCase();
    final referenceId = (data['referenceId'] ?? '').toString();
    switch (screen) {
      case 'HOME':
        navigator.popUntil((route) => route.isFirst);
        state.goTab(0);
        return;
      case 'CART':
        navigator.popUntil((route) => route.isFirst);
        state.goTab(3);
        return;
      case 'WISHLIST':
        navigator.popUntil((route) => route.isFirst);
        state.goTab(4);
        await navigator.push(MaterialPageRoute<void>(builder: (_) => const WishlistScreen()));
        return;
      case 'OFFERS':
        await navigator.push(MaterialPageRoute<void>(builder: (_) => const OffersScreen()));
        return;
      case 'NOTIFICATIONS':
        await navigator.push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()));
        return;
      case 'PRODUCT_DETAILS':
        if (referenceId.isEmpty || state.api == null) return;
        try {
          final product = await state.api!.product(referenceId);
          if (navigatorKey.currentState == null) return;
          await navigatorKey.currentState!.push(MaterialPageRoute<void>(
            builder: (_) => ProductScreen(product: product)));
        } catch (_) {
          _showRouteError('This product could not be opened.');
        }
        return;
      case 'ORDER_DETAILS':
      case 'ORDER_TRACKING':
      case 'REFUND_DETAILS':
        if (referenceId.isEmpty || state.api == null) return;
        try {
          final order = await state.api!.customerOrder(referenceId, state.customerToken!);
          if (navigatorKey.currentState == null) return;
          await navigatorKey.currentState!.push(MaterialPageRoute<void>(
            builder: (_) => OrderDetailsScreen(order: order)));
        } catch (_) {
          _showRouteError('These order details are unavailable for this account.');
        }
        return;
      default:
        _showRouteError('This notification destination is not supported yet.');
    }
  }

  void _showRouteError(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> dispose() async {
    _dismissForegroundNotice();
    if (_state != null) {
      _state!.removeListener(_onStateChanged);
      _state!.notificationOpener = null;
      _state!.refreshPushRegistration = null;
    }
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}

class _ForegroundNotificationCard extends StatelessWidget {
  const _ForegroundNotificationCard({required this.title, required this.body,
    required this.canOpen, required this.onOpen, required this.onDismiss});

  final String title;
  final String body;
  final bool canOpen;
  final VoidCallback? onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 12,
    shadowColor: const Color(0x33101A3A),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFFFF1DF),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_active_rounded,
              color: Color(0xFFB97712), size: 20)),
          const SizedBox(width: 11),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 1),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: Color(0xFF101A3A))),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(body, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.25,
                    color: Color(0xFF596274))),
              ],
              if (canOpen) ...[
                const SizedBox(height: 5),
                const Text('TAP TO OPEN', style: TextStyle(fontSize: 10,
                  letterSpacing: .6, fontWeight: FontWeight.w900,
                  color: Color(0xFFB97712))),
              ],
            ]))),
          IconButton(onPressed: onDismiss, tooltip: 'Dismiss notification',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF596274))),
        ]),
      ),
    ),
  );
}
