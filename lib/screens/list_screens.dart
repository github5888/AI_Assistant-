import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'commerce_screens.dart';
import 'product_screen.dart';

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

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListScaffold(
      title: 'Notifications',
      subtitle: 'Harvest & delivery updates',
      children: notifications.map((item) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 9),
          decoration: premiumCard(radius: 14),
          child: ListTile(
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: AppColors.sand,
              ),
              child: const Icon(Icons.notifications_none, size: 17, color: AppColors.orange),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  item.time,
                  style: const TextStyle(fontSize: 7.5, color: AppColors.orange),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
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
