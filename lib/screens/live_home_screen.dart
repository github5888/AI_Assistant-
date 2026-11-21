import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets.dart';
import 'home_screen.dart';
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
          const SliverToBoxAdapter(child: HomeIntro()),
          SliverToBoxAdapter(child: CatalogHeading(
            title: 'Featured flours',
            trailing: TextButton(onPressed: browse, child: const Text('View all')),
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
