import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calculator_screen.dart';
import 'product_screen.dart';
import 'storefront_layout.dart';

class LiveHomeScreen extends StatelessWidget {
  const LiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final featured = state.featuredProducts;
    void browse() {
      state.setCategory(0);
      state.goTab(1);
    }

    return RefreshIndicator(
      onRefresh: state.refreshStore,
      child: CustomScrollView(
        key: const PageStorageKey('live-home'),
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: CatalogSearchBar()),
          SliverToBoxAdapter(child: _HarvestBanner(onBrowse: () {
            final product = state.featuredPack(0);
            if (product == null) {
              browse();
            } else {
              pushScreen(context, ProductScreen(product: product));
            }
          })),
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.only(top: 8), child: CatalogCategoryStrip(browseFromHome: true),
          )),
          SliverToBoxAdapter(child: CatalogHeading(
            title: 'Featured flours',
            trailing: TextButton(onPressed: browse, child: const Text('View all')),
          )),
          if (state.catalogError || featured.isEmpty)
            const SliverToBoxAdapter(child: CatalogStatus(emptyMessage: 'No products are listed right now.')),
          CatalogSliverGrid(products: featured),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
            child: Material(
              color: AppColors.paper,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.line)),
              child: Column(children: [
                InfoRow(icon: Icons.receipt_long_outlined, title: 'Your orders',
                  subtitle: 'History and receipts', onTap: () => state.goTab(2)),
                const Divider(height: 1, color: AppColors.line),
                InfoRow(icon: Icons.calculate_outlined, title: 'Grain calculator',
                  subtitle: 'Find your monthly pack', onTap: () => pushScreen(context, const CalculatorScreen())),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}

class _HarvestBanner extends StatelessWidget {
  const _HarvestBanner({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEEE2),
        border: Border.all(color: const Color(0xFFEED9C6)),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Row(children: [
        Expanded(flex: 5, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STONEGROUND ATTA', style: TextStyle(color: Color(0xFF8E421E),
              fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .9)),
            const SizedBox(height: 5),
            Text('Fresh flour.\nMilled slow.', style: displayStyle(size: 23)),
            const SizedBox(height: 5),
            const Text('Khapli & high-protein atta', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 7),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                minimumSize: const Size(0, 42),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              onPressed: onBrowse, child: const Text('Shop the harvest'),
            ),
          ],
        )),
        const SizedBox(width: 7),
        const Expanded(flex: 3, child: PackImage(asset: AppImages.khapli, height: 126)),
      ]),
    );
  }
}
