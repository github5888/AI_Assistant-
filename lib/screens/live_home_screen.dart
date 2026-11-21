import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets.dart';
import 'live_home_sections.dart';
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
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.only(top: 10), child: HomeHarvestCarousel(),
          )),
          const SliverToBoxAdapter(child: HomeQuickLinks()),
          SliverToBoxAdapter(child: SectionHeader(
            eyebrow: 'Find your flour', title: 'Shop by category',
            action: 'See all', onAction: browse,
          )),
          const SliverToBoxAdapter(child: HomePhotoCategories()),
          SliverToBoxAdapter(child: SectionHeader(
            eyebrow: 'The favourites', title: 'Featured flours',
            action: 'View all', onAction: browse,
          )),
          if (state.catalogError || featured.isEmpty)
            const SliverToBoxAdapter(child: CatalogStatus(emptyMessage: 'No products are listed right now.')),
          CatalogSliverGrid(products: featured),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
        ],
      ),
    );
  }
}
