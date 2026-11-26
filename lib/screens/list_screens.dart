import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data.dart';
import '../notification_models.dart';
import '../store_api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'commerce_screens.dart';
import 'product_screen.dart';
import 'sign_in_screen.dart';

class ListScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  const ListScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        children: [
          AppTopBar(
            title: title,
            subtitle: subtitle,
            back: true,
            actions: actions,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = state.catalog.where((p) => state.wishlist.contains(p.id)).toList();

    return ListScaffold(
      title: 'Saved items',
      subtitle: '${items.length} flours',
      actions: [
        RoundIconButton(
          icon: Icons.search,
          onTap: () => state.goTab(1),
        ),
      ],
      children: items.isEmpty
          ? [
              const SizedBox(height: 80),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.favorite_border, size: 40, color: AppColors.muted),
                    const SizedBox(height: 12),
                    Text('Nothing saved yet', style: displayStyle(size: 20)),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap the heart on any pack to keep it here.',
                      style: TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ]
          : items.map((product) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: InkWell(
                  onTap: () => pushScreen(context, ProductScreen(product: product)),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: premiumCard(radius: 16),
                    child: Row(
                      children: [
                        PackImage(asset: product.image, fallback: product.fallbackImage ?? AppImages.khapli, width: 56, height: 66),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                product.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                money(product.sizes.first.price),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => state.addToCart(product, product.sizes.first, 1),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.orange,
                            ),
                            child: const Icon(Icons.add, size: 15, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => state.toggleWish(product.id),
                          child: const Icon(Icons.close, size: 16, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
    );
  }
}

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListScaffold(
      title: 'Offers & coupons',
      subtitle: 'Harvest savings',
      children: state.isLive
          ? [
              if (state.isLoadingCoupons)
                const Padding(padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()))
              else if (state.couponListError)
                StoreNotice(message: 'Store offers could not be loaded.',
                  onRetry: state.isLoadingCatalog ? null : state.refreshStore)
              else if (state.liveCoupons.isEmpty)
                const Padding(padding: EdgeInsets.all(22),
                  child: Center(child: Text('There are no active coupons from the store right now.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted))))
              else
                for (final coupon in state.liveCoupons)
                  _OfferCard(
                    code: coupon.code,
                    title: coupon.description.isNotEmpty ? coupon.description
                        : coupon.code == 'FREESHIP' ? 'Free delivery'
                        : coupon.discountType == 'percentage'
                            ? '${coupon.discountValue.toStringAsFixed(0)}% off'
                            : '${money(coupon.discountValue.round())} off',
                    body: coupon.minOrderValue > 0
                        ? 'Minimum basket value ${money(coupon.minOrderValue)}. Final eligibility is checked when the order is placed.'
                        : 'Enter this code in your basket. Final eligibility is checked when the order is placed.',
                    onApply: () async {
                      await Clipboard.setData(ClipboardData(text: coupon.code));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${coupon.code} copied · apply it in your basket.'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                  ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PrimaryButton(
                  label: 'Browse products',
                  icon: Icons.arrow_forward,
                  onTap: () => state.goTab(1),
                ),
              ),
            ]
          : [
              _OfferCard(
                code: 'CLEAR50',
                title: '₹50 off your next order',
                body: 'Sample offer for the offline preview only.',
                onApply: () {
                  state.applyCoupon('CLEAR50');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CLEAR50 sample coupon applied.')),
                  );
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PrimaryButton(
                  label: 'Browse products',
                  icon: Icons.arrow_forward,
                  onTap: () => state.goTab(1),
                ),
              ),
            ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String code;
  final String title;
  final String body;
  final VoidCallback onApply;
  const _OfferCard({
    required this.code,
    required this.title,
    required this.body,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppGradients.navy,
        border: Border.all(color: AppColors.glassLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number, size: 16, color: AppColors.amber),
              const SizedBox(width: 7),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.goldLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: const TextStyle(fontSize: 9, height: 1.5, color: Color(0xA6FFFFFF)),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onApply,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: AppGradients.orange,
              ),
              child: const Text(
                'Use offer',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<PushNotificationItem> _items = const [];
  int _page = 1;
  int _totalPages = 1;
  int _unreadCount = 0;
  String _status = 'all';
  String? _category;
  String? _error;
  bool _loading = true;
  bool _working = false;
  bool _requested = false;
  String? _requestedToken;
  String? _loadedToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = AppScope.of(context).customerToken;
    if (!_requested || token != _requestedToken) {
      _requested = true;
      _requestedToken = token;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load({bool append = false}) async {
    final state = AppScope.of(context);
    final api = state.api;
    final token = state.customerToken;
    if (!state.isLive || api == null || token == null) {
      if (mounted) setState(() {
        _loading = false; _error = null; _items = const []; _unreadCount = 0;
      });
      return;
    }
    if (_loadedToken != token) {
      _loadedToken = token;
      _items = const [];
      _unreadCount = 0;
      _page = 1;
      _totalPages = 1;
    }
    final page = append ? _page + 1 : 1;
    setState(() { _loading = !append; _working = append; _error = null; });
    try {
      final result = await api.notificationHistory(token, page: page,
        status: _status, category: _category);
      if (!mounted || AppScope.of(context).customerToken != token) return;
      setState(() {
        _items = append ? [..._items, ...result.items] : result.items;
        _page = result.page;
        _totalPages = result.totalPages;
        _unreadCount = result.unreadCount;
      });
      state.updateNotificationUnreadCount(result.unreadCount);
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Notifications could not be loaded.');
    } finally {
      if (mounted) setState(() { _loading = false; _working = false; });
    }
  }

  Future<void> _markAllRead() async {
    final state = AppScope.of(context);
    final token = state.customerToken;
    final api = state.api;
    if (token == null || api == null || _working) return;
    setState(() => _working = true);
    try {
      _unreadCount = await api.markAllNotificationsRead(token);
      state.updateNotificationUnreadCount(_unreadCount);
      await _load();
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openItem(PushNotificationItem item) async {
    final state = AppScope.of(context);
    final api = state.api;
    final token = state.customerToken;
    if (!item.read && api != null && token != null) {
      try {
        _unreadCount = await api.markNotificationRead(token, item.id);
        state.updateNotificationUnreadCount(_unreadCount);
        if (mounted) setState(() => _items = [
          for (final existing in _items)
            if (existing.id == item.id)
              PushNotificationItem(
                id: existing.id, title: existing.title, message: existing.message,
                imageUrl: existing.imageUrl, type: existing.type, category: existing.category,
                priority: existing.priority, referenceId: existing.referenceId,
                deepLinkDestination: existing.deepLinkDestination, read: true,
                createdAt: existing.createdAt,
              )
            else existing,
        ]);
      } catch (_) {
        // The destination may still be opened if read-state sync is unavailable.
      }
    }
    if (item.deepLinkDestination.isNotEmpty) {
      await state.openNotification(item.toTapData());
    }
  }

  Future<void> _delete(PushNotificationItem item) async {
    final state = AppScope.of(context);
    final api = state.api;
    final token = state.customerToken;
    if (api == null || token == null || _working) return;
    setState(() => _working = true);
    try {
      _unreadCount = await api.deleteNotification(token, item.id);
      state.updateNotificationUnreadCount(_unreadCount);
      if (mounted) setState(() => _items = _items.where((row) => row.id != item.id).toList());
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final actions = <Widget>[
      if (state.customerToken != null)
        IconButton(tooltip: 'Notification preferences',
          onPressed: () => pushScreen(context, const NotificationPreferencesScreen()),
          icon: const Icon(Icons.tune_rounded)),
      if (state.customerToken != null && _unreadCount > 0)
        IconButton(tooltip: 'Mark all as read', onPressed: _working ? null : _markAllRead,
          icon: const Icon(Icons.done_all_rounded)),
      IconButton(tooltip: 'Refresh notifications', onPressed: _loading ? null : () => _load(),
        icon: const Icon(Icons.refresh_rounded)),
    ];
    if (!state.isLive) {
      return ListScaffold(title: 'Notifications', subtitle: 'Harvest & delivery updates',
        actions: actions, children: notifications.map((item) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 9),
          decoration: premiumCard(radius: 14),
          child: ListTile(
            leading: const Icon(Icons.notifications_none, color: AppColors.orange),
            title: Text(item.title), subtitle: Text('${item.body} · ${item.time}'),
          ),
        )).toList());
    }
    if (state.customerToken == null) {
      return ListScaffold(title: 'Notifications', subtitle: 'Your order & delivery updates',
        actions: actions, children: [
          const SizedBox(height: 32),
          const Center(child: Text('Sign in to view your notification inbox.')),
          Center(child: TextButton(onPressed: () => pushScreen(context, const SignInScreen()),
            child: const Text('Sign in'))),
        ]);
    }
    return ListScaffold(title: 'Notifications',
      subtitle: '$_unreadCount unread · your ItsClear updates', actions: actions,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 2, 16, 8), child: Wrap(spacing: 6, children: [
          for (final option in const [('all', 'All'), ('unread', 'Unread'), ('read', 'Read')])
            ChoiceChip(label: Text(option.$2), selected: _status == option.$1,
              onSelected: (_) { setState(() => _status = option.$1); _load(); }),
          DropdownButton<String?>(value: _category, hint: const Text('Category'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any category')),
              DropdownMenuItem(value: 'order', child: Text('Orders')),
              DropdownMenuItem(value: 'payment', child: Text('Payments')),
              DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
              DropdownMenuItem(value: 'promotion', child: Text('Promotions')),
            ], onChanged: (value) { setState(() => _category = value); _load(); }),
        ])),
        if (_error != null) Padding(padding: const EdgeInsets.all(14),
          child: Text(_error!, style: const TextStyle(color: Colors.red))),
        if (_loading && _items.isEmpty)
          const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())),
        if (!_loading && _items.isEmpty && _error == null)
          const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No notifications yet.'))),
        for (final item in _items) Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 9),
          decoration: premiumCard(radius: 14),
          child: ListTile(
            onTap: _working ? null : () => _openItem(item),
            leading: CircleAvatar(backgroundColor: item.read ? AppColors.sand : const Color(0xFFEAF6EE),
              child: Icon(item.read ? Icons.notifications_none : Icons.notifications_active_outlined,
                size: 18, color: item.read ? AppColors.muted : AppColors.green)),
            title: Text(item.title, style: TextStyle(fontSize: 12, fontWeight:
              item.read ? FontWeight.w600 : FontWeight.w900, color: AppColors.ink)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (item.message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(item.message, style: const TextStyle(fontSize: 11, color: AppColors.muted))),
              if (item.createdAt != null) Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(_timeLabel(item.createdAt!), style: const TextStyle(fontSize: 10, color: AppColors.orange))),
            ]),
            trailing: IconButton(tooltip: 'Delete notification', onPressed: _working ? null : () => _delete(item),
              icon: const Icon(Icons.delete_outline, size: 18)),
          ),
        ),
        if (_loading && _items.isNotEmpty)
          const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
        if (!_loading && _page < _totalPages)
          Center(child: TextButton(onPressed: _working ? null : () => _load(append: true),
            child: const Text('Load more'))),
      ]);
  }

  String _timeLabel(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _loading = true;
  bool _saving = false;
  bool _requested = false;
  String? _requestedToken;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = AppScope.of(context).customerToken;
    if (!_requested || token != _requestedToken) {
      _requested = true;
      _requestedToken = token;
      _preferences = const NotificationPreferences();
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    final state = AppScope.of(context);
    final api = state.api;
    final token = state.customerToken;
    if (api == null || token == null) {
      if (mounted) setState(() { _loading = false; _error = 'Sign in to manage notification preferences.'; });
      return;
    }
    try {
      final result = await api.notificationPreferences(token);
      if (mounted && AppScope.of(context).customerToken == token) {
        setState(() { _preferences = result; _error = null; _loading = false; });
      }
    } on StoreApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Notification preferences could not be loaded.'; _loading = false; });
    }
  }

  Future<void> _save() async {
    final state = AppScope.of(context);
    final api = state.api;
    final token = state.customerToken;
    if (api == null || token == null || _saving) return;
    setState(() { _saving = true; _error = null; });
    try {
      _preferences = await api.updateNotificationPreferences(token, _preferences);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification preferences saved.')));
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Notification preferences could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomer = AppScope.of(context).customerToken != null;
    return ListScaffold(
    title: 'Notification preferences',
    subtitle: 'Choose the updates you want to receive',
    actions: [IconButton(tooltip: 'Save preferences', onPressed: !hasCustomer || _saving || _loading ? null : _save,
      icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.save_outlined))],
    children: [
      if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      if (_error != null) Padding(padding: const EdgeInsets.all(14),
        child: Text(_error!, style: const TextStyle(color: Colors.red))),
      _preferenceSwitch('Order updates', 'Order confirmation and status changes', _preferences.orderUpdates,
        (value) => _preferences = _preferences.copyWith(orderUpdates: value)),
      _preferenceSwitch('Payment updates', 'Payment and refund status', _preferences.paymentUpdates,
        (value) => _preferences = _preferences.copyWith(paymentUpdates: value)),
      _preferenceSwitch('Delivery updates', 'Dispatch and delivery progress', _preferences.deliveryUpdates,
        (value) => _preferences = _preferences.copyWith(deliveryUpdates: value)),
      _preferenceSwitch('Promotional offers', 'Coupons and store promotions', _preferences.promotionalOffers,
        (value) => _preferences = _preferences.copyWith(promotionalOffers: value)),
      _preferenceSwitch('Product availability', 'Back-in-stock alerts', _preferences.productAvailabilityAlerts,
        (value) => _preferences = _preferences.copyWith(productAvailabilityAlerts: value)),
      _preferenceSwitch('Cart reminders', 'Reminders about items in your cart', _preferences.cartReminders,
        (value) => _preferences = _preferences.copyWith(cartReminders: value)),
      _preferenceSwitch('Announcements', 'Important ItsClear notices', _preferences.generalAnnouncements,
        (value) => _preferences = _preferences.copyWith(generalAnnouncements: value)),
    ],
  );
  }

  Widget _preferenceSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(title: Text(title), subtitle: Text(subtitle), value: value,
        onChanged: _loading || _saving || AppScope.of(context).customerToken == null
            ? null : (next) => setState(() => onChanged(next)));
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListScaffold(
      title: 'My orders',
      subtitle: '${state.orderIds.length} recent deliveries',
      children: state.orderIds.map((id) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 9),
          decoration: premiumCard(radius: 14),
          child: InfoRow(
            icon: Icons.local_shipping,
            title: 'Order #$id',
            subtitle: 'Khapli 10kg sack · delivered in 94 mins',
            trailing: 'Delivered',
            onTap: () => pushScreen(context, const TrackingScreen()),
          ),
        );
      }).toList(),
    );
  }
}
