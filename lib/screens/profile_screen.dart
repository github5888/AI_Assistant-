import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calculator_screen.dart';
import 'checkout_flow.dart';
import 'commerce_screens.dart';
import 'list_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (state.isLive) {
      return ListView(
        primary: false,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SectionHeader(eyebrow: 'Your account', title: 'Guest profile'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PrimaryButton(
              label: 'Sign in',
              icon: Icons.login,
              onTap: () => pushScreen(context, const SignInScreen()),
            ),
          ),
          SectionCard(child: InfoRow(
            icon: Icons.receipt_long,
            title: 'My orders & receipts',
            onTap: () => state.goTab(2),
          )),
          StoreNotice(
            message: switch (state.storeOnline) {
              true => 'Live store is connected.',
              false => 'The store is temporarily unavailable.',
              null => 'Store status has not been confirmed.',
            },
            onRetry: state.isLoadingCatalog ? null : state.refreshStore,
          ),
          SectionCard(child: InfoRow(
            icon: Icons.favorite_border,
            title: 'Saved items',
            subtitle: '${state.wishlist.length} flours',
            onTap: () => pushScreen(context, const WishlistScreen()),
          )),
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
                subtitle: 'Harvest & delivery updates',
                onTap: () => pushScreen(context, const NotificationsScreen()),
              ),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(
                icon: Icons.confirmation_number,
                title: 'Offers & coupons',
                subtitle: 'CLEAR50 · up to 25% off',
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
