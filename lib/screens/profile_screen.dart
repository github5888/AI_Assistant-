import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../auth_models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calculator_screen.dart';
import 'sign_in_screen.dart';
import 'commerce_screens.dart';
import 'list_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (state.isLive) {
      final customer = state.customer;
      final storeMessage = switch (state.storeOnline) {
        true => 'Store is connected',
        false => 'Store is temporarily unavailable',
        null => 'Store status is not confirmed',
      };
      return ListView(
        primary: false,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          if (state.restoringSession)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: StoreNotice(message: 'Checking your saved session…'))
          else if (customer == null)
            SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your itsclear account', style: displayStyle(size: 21)),
              const SizedBox(height: 6),
              const Text('Sign in to see orders, saved addresses and Grain Coins.',
                style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted)),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Sign in', icon: Icons.login,
                onTap: () => pushScreen(context, const SignInScreen())),
            ]))
          else
            SectionCard(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(children: [
                CircleAvatar(radius: 25, backgroundColor: AppColors.navyDeep,
                  child: Text(customer.name.trim().isEmpty ? '?' : customer.name.trim()[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(customer.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(customer.email, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ])),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () async {
                    try {
                      await state.signOut();
                    } on AuthException catch (error) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message)));
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                ),
              ])),
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 6), child: Row(children: [
            Icon(state.storeOnline == true ? Icons.cloud_done_outlined : Icons.cloud_outlined,
              size: 16, color: state.storeOnline == true ? AppColors.green : AppColors.muted),
            const SizedBox(width: 7),
            Expanded(child: Text(storeMessage,
              style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600))),
            if (state.storeOnline != true)
              TextButton(onPressed: state.isLoadingCatalog ? null : state.refreshStore,
                child: Text(state.isLoadingCatalog ? 'Checking…' : 'Retry')),
          ])),
          if (state.savedShippingAddress != null)
            _SavedDeliveryAddress(address: state.savedShippingAddress!, onRemove: state.clearSavedShippingAddress),
          SectionCard(padding: const EdgeInsets.symmetric(vertical: 3), child: Column(children: [
            InfoRow(icon: Icons.receipt_long, title: 'My orders & receipts',
              subtitle: 'Track deliveries and view receipts', onTap: () => state.goTab(2)),
            const Divider(height: 1, indent: 58, color: AppColors.line),
            InfoRow(icon: Icons.favorite_border, title: 'Saved items',
              subtitle: '${state.wishlist.length} products',
              onTap: () => pushScreen(context, const WishlistScreen())),
            const Divider(height: 1, indent: 58, color: AppColors.line),
            InfoRow(icon: Icons.confirmation_number_outlined, title: 'Offers & coupons',
              subtitle: state.isLoadingCoupons ? 'Loading store offers…'
                  : state.couponListError ? 'Store offers unavailable'
                  : '${state.liveCoupons.length} active store offers',
              onTap: () => pushScreen(context, const OffersScreen())),
            if (customer != null) ...[
              const Divider(height: 1, indent: 58, color: AppColors.line),
              InfoRow(icon: Icons.savings_outlined, title: 'Grain Coins',
                subtitle: '${customer.clearCoins} available'),
            ],
          ])),
        ],
      );
    }

    return ListView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _ProfileCard(state: state),
        _StatsRow(state: state),
        SectionCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              InfoRow(
                icon: Icons.shopping_bag,
                title: 'My orders',
                subtitle: '${state.orderIds.length} recent deliveries',
                onTap: () => pushScreen(context, const OrdersScreen()),
              ),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(
                icon: Icons.favorite_border,
                title: 'Saved items',
                subtitle: '${state.wishlist.length} flours',
                onTap: () => pushScreen(context, const WishlistScreen()),
              ),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle: state.notificationUnreadCount > 0
                    ? '${state.notificationUnreadCount} unread · Harvest & delivery updates'
                    : 'Harvest & delivery updates',
                onTap: () => pushScreen(context, const NotificationsScreen()),
              ),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(
                icon: Icons.confirmation_number,
                title: 'Offers & coupons',
                subtitle: state.isLive
                    ? state.isLoadingCoupons ? 'Loading store offers…'
                        : state.couponListError ? 'Store offers unavailable'
                        : state.liveCoupons.isEmpty ? 'No active offers right now'
                        : '${state.liveCoupons.length} active store offers'
                    : 'CLEAR50 · up to 25% off',
                onTap: () => pushScreen(context, const OffersScreen()),
              ),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(
                icon: Icons.location_on,
                title: 'Delivery addresses',
                subtitle: 'Home · ${state.address.pin}',
                onTap: () => pushScreen(context, const CheckoutScreen()),
              ),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(
                icon: Icons.description,
                title: 'Lab certificates',
                subtitle: 'Batch #IC-0426',
                onTap: () => state.goTab(2),
              ),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(
                icon: Icons.help_outline,
                title: 'Help & FAQ',
                subtitle: 'Cold milling · delivery',
                onTap: () => _showInfo(context, 'Help & FAQ', 'This is a UI-only demo. All answers are illustrative and no network request is made.'),
              ),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(
                icon: Icons.info_outline,
                title: 'About this app',
                subtitle: 'Flutter UI · exact packaging',
                onTap: () => _showInfo(context, 'About this app', 'A Flutter ecommerce app UI built around the exact itsclear™ pouch. No backend, payments, chat or AI assistant.'),
              ),
            ],
          ),
        ),
        const SectionHeader(
          eyebrow: 'From our kitchens',
          title: 'Loved by homes',
        ),
        _ReviewCard(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryButton(
            label: 'Open grain calculator',
            icon: Icons.arrow_forward,
            onTap: () => pushScreen(context, const CalculatorScreen()),
          ),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _SavedDeliveryAddress extends StatelessWidget {
  const _SavedDeliveryAddress({required this.address, required this.onRemove});
  final Map<String, Object?> address;
  final Future<void> Function() onRemove;

  String _text(String key, [String? fallback]) {
    final value = address[key] ?? (fallback == null ? null : address[fallback]);
    return value is String ? value.trim() : '';
  }

  double? _coordinate(Object? value) => value is num && value.isFinite ? value.toDouble() : null;

  @override
  Widget build(BuildContext context) {
    final location = address['location'];
    final coords = location is Map ? location : const <Object?, Object?>{};
    final latitude = _coordinate(coords['latitude']);
    final longitude = _coordinate(coords['longitude']);
    final lines = <String>[
      _text('addressLine1', 'address'),
      [_text('city'), _text('state'), _text('pincode', 'postalCode')]
          .where((part) => part.isNotEmpty).join(', '),
    ].where((part) => part.isNotEmpty).toList();
    return SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Saved delivery address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text(lines.isEmpty ? 'Address saved on this device' : lines.join('\n'),
        style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted)),
      if (latitude != null && longitude != null) ...[
        const SizedBox(height: 5),
        Text('Exact pin · ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w700)),
      ],
      const SizedBox(height: 6),
      Wrap(spacing: 8, children: [
        TextButton.icon(
          onPressed: () => pushScreen(context, const CheckoutScreen()),
          icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
          label: const Text('Edit address or pin'),
        ),
        if (latitude != null && longitude != null)
          TextButton.icon(
            onPressed: () async {
              final uri = Uri.https('www.google.com', '/maps/search/', {
                'api': '1', 'query': '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
              });
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open Maps on this device.')),
                );
              }
            },
            icon: const Icon(Icons.map_outlined, size: 16),
            label: const Text('Open pin in Maps'),
          ),
        TextButton.icon(
          onPressed: () async {
            try {
              await onRemove();
            } catch (_) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not remove the saved address.')),
              );
            }
          },
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Remove'),
        ),
      ]),
    ]));
  }
}

class _ProfileCard extends StatelessWidget {
  final AppState state;
  const _ProfileCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppGradients.navy,
        border: Border.all(color: AppColors.glassLine),
        boxShadow: const [
          BoxShadow(color: Color(0x33101A3A), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x55EF5B25), Colors.transparent],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.orange,
                ),
                child: const Center(
                  child: Text(
                    'AS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Aarav Sharma',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'aarav.sharma@email.com',
                      style: TextStyle(fontSize: 9, color: Color(0x99FFFFFF)),
                    ),
                    SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(Icons.verified, size: 11, color: AppColors.goldLight),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Verified buyer since 2024',
                            style: TextStyle(fontSize: 8, color: AppColors.goldLight),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0x33C6922F),
                  border: Border.all(color: const Color(0x66FFD493)),
                ),
                child: const Text(
                  'GOLD MEMBER',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Color(0xFFFFD493),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: premiumCard(),
      child: Row(
        children: [
          _Stat(value: '${state.orderIds.length + 10}', label: 'Orders'),
          Container(width: 1, height: 30, color: AppColors.line),
          _Stat(value: '${state.wishlist.length}', label: 'Saved'),
          Container(width: 1, height: 30, color: AppColors.line),
          _Stat(value: '84 kg', label: 'Flour'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 8.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stars(value: 5, size: 10),
              const SizedBox(width: 6),
              const Text(
                '“The rotis stay soft all day.”',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Meera Iyer · Bengaluru, Indiranagar',
            style: TextStyle(fontSize: 8.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
