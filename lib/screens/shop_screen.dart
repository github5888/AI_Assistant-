import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'product_screen.dart';
import 'search_screen.dart';
import 'storefront_layout.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.isLive) return const _LiveShop();
    final visible = state.filteredProducts;
    final textExtra = MediaQuery.textScalerOf(context).scale(12) - 12;

    return ListView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader(
          eyebrow: 'Find your flour',
          title: 'All products',
          action: 'Search',
          onAction: () => pushScreen(context, const SearchScreen()),
        ),
        SizedBox(
          height: 40 + textExtra.clamp(0, 24).toDouble() * 2,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categoryFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              return PillButton(
                label: categoryFilters[index],
                selected: state.categoryIndex == index,
                onTap: () => state.setCategory(index),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Sort',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
              ),
              for (var index = 0; index < sortLabels.length; index++)
                PillButton(
                  label: sortLabels[index],
                  selected: state.sortIndex == index,
                  onTap: () => state.setSort(index),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 258 + textExtra.clamp(0, 24).toDouble() * 9,
            ),
            itemBuilder: (context, index) {
              final product = visible[index];
              return ProductCard(
                product: product,
                onTap: () => pushScreen(
                  context,
                  ProductScreen(product: product),
                ),
              );
            },
          ),
        ),
        if (!state.isLive) ...[
        SectionHeader(
          eyebrow: 'Better together',
          title: 'Monthly bundles',
          action: 'See all',
          onAction: () => state.setCategory(4),
        ),
        ...bundles.map((bundle) => _BundleCard(bundle: bundle)),
        SectionHeader(
          eyebrow: 'Popular this month',
          title: 'Top ranked',
          action: 'Shop',
          onAction: () => state.setCategory(0),
        ),
        ...ranked.map((item) => _RankedRow(item: item)),
        ],
      ],
    );
  }
}

class _LiveShop extends StatelessWidget {
  const _LiveShop();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final visible = state.filteredProducts;
    return RefreshIndicator(
      onRefresh: state.refreshStore,
      child: CustomScrollView(
        key: const PageStorageKey('live-shop'),
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: CatalogSearchBar()),
          const SliverToBoxAdapter(child: CatalogCategoryStrip()),
          SliverToBoxAdapter(child: CatalogHeading(
            title: state.categoryIndex == 0 ? 'All products' : categoryFilters[state.categoryIndex],
            trailing: PopupMenuButton<int>(
              tooltip: 'Sort products',
              initialValue: state.sortIndex,
              onSelected: state.setSort,
              icon: const Icon(Icons.sort_rounded, size: 22, color: AppColors.ink),
              itemBuilder: (context) => [
                for (var i = 0; i < sortLabels.length; i++)
                  PopupMenuItem(value: i, child: Text(sortLabels[i])),
              ],
            ),
          )),
          if (state.catalogError || visible.isEmpty)
            const SliverToBoxAdapter(child: CatalogStatus(emptyMessage: 'No products in this category.')),
          CatalogSliverGrid(products: visible),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
        ],
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  final Bundle bundle;
  const _BundleCard({required this.bundle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: premiumCard(radius: 18),
      child: Row(
        children: [
          PackImage(asset: bundle.image, width: 70, height: 84),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bundle.tag.toUpperCase(),
                  style: eyebrowStyle().copyWith(fontSize: 7.5),
                ),
                const SizedBox(height: 4),
                Text(
                  bundle.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bundle.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      money(bundle.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      money(bundle.mrp),
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: AppColors.muted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  final RankedItem item;
  const _RankedRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: premiumCard(radius: 14),
      child: Row(
        children: [
          PackImage(asset: item.image, width: 42, height: 50),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Stars(value: item.rating, size: 8),
                    const SizedBox(width: 5),
                    Text(
                      '${item.rating.toStringAsFixed(1)} · ${item.size}',
                      style: const TextStyle(fontSize: 8, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            money(item.price),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
