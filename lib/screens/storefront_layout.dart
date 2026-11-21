import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'product_screen.dart';
import 'search_screen.dart';

/// The same pack-card grid on Home and Shop. Use a horizontal card at large
/// text sizes rather than stretching a narrow two-column grid vertically.
class CatalogSliverGrid extends StatelessWidget {
  const CatalogSliverGrid({super.key, required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final textExtra = (scaler.scale(13) - 13).clamp(0, 26).toDouble();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      sliver: SliverLayoutBuilder(builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final singleColumn = width < 274 || scaler.scale(13) > 17.6;
        final columns = singleColumn ? 1 : (width >= 518 ? 3 : 2);
        final rowLayout = singleColumn && width >= 274;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: rowLayout ? 140 + textExtra * 11 : 230 + textExtra * 7,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final product = products[index];
            return ProductCard(key: ValueKey(product.id), product: product,
              onTap: () => pushScreen(context, ProductScreen(product: product)));
          }, childCount: products.length),
        );
      }),
    );
  }
}

class CatalogSearchBar extends StatelessWidget {
  const CatalogSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Material(
        color: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => pushScreen(context, const SearchScreen()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: AppColors.ink, size: 20),
              const SizedBox(width: 9),
              const Expanded(child: Text('Search atta, flour or pack size', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600))),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.muted),
            ]),
          ),
        ),
      ),
    );
  }
}

class CatalogCategoryStrip extends StatelessWidget {
  const CatalogCategoryStrip({super.key, this.browseFromHome = false});
  final bool browseFromHome;
  static const _icons = [Icons.grid_view_rounded, Icons.grass_rounded,
    Icons.bolt_rounded, Icons.shopping_bag_outlined, Icons.inventory_2_outlined];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final height = 31 + MediaQuery.textScalerOf(context).scale(13) * 1.25;
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: categoryFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final selected = !browseFromHome && state.categoryIndex == index;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Material(
            color: selected ? AppColors.ink : AppColors.paper,
            shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.ink : AppColors.line)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                state.setCategory(index);
                if (browseFromHome) state.goTab(1);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(children: [
                  Icon(_icons[index], size: 16, color: selected ? AppColors.amber : const Color(0xFF9A431E)),
                  const SizedBox(width: 5),
                  Text(categoryFilters[index], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.ink)),
                ]),
              ),
            ),
          ));
        },
      ),
    );
  }
}

class CatalogHeading extends StatelessWidget {
  const CatalogHeading({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 21, height: 1.12,
          fontWeight: FontWeight.w800, letterSpacing: -.45, color: AppColors.ink))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}
