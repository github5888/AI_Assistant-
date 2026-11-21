import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calculator_screen.dart';
import 'commerce_screens.dart';
import 'list_screens.dart';
import 'product_screen.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final textExtra = (MediaQuery.textScalerOf(context).scale(20) - 20)
        .clamp(0, 40).toDouble();

    return ListView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 22),
      children: [
        const _HomeIntro(),
        SectionHeader(
          eyebrow: 'The favourites',
          title: 'Best sellers',
          action: 'See all',
          onAction: () => state.goTab(1),
        ),
        if (state.featuredProducts.isNotEmpty) SizedBox(
          height: 258 + textExtra * 6,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: state.featuredProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final product = state.featuredProducts[index];
              return ProductCard(
                product: product,
                width: 166,
                onTap: () => pushScreen(context, ProductScreen(product: product)),
              );
            },
          ),
        ),
        SectionHeader(
          eyebrow: 'Slow milled, honestly',
          title: 'Made the clear way',
          action: state.isLive ? 'Browse flours' : 'Our standard',
          onAction: () => state.goTab(state.isLive ? 1 : 2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StoryCard(
                  image: AppImages.chakki,
                  eyebrow: '01 · Cold milled',
                  title: 'Below 28°C',
                  subtitle: 'Live enzymes intact',
                  onTap: () => state.goTab(state.isLive ? 1 : 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StoryCard(
                  image: AppImages.roti,
                  eyebrow: '02 · Better yield',
                  title: '36 rotis / kg',
                  subtitle: 'Soft for 14 hours',
                  onTap: () => pushScreen(context, const CalculatorScreen()),
                ),
              ),
            ],
          ),
        ),
        _CalcPromo(onTap: () => pushScreen(context, const CalculatorScreen())),
        if (!state.isLive) ...[
          PromiseCard(onTap: () => state.goTab(2)),
          _SaleCard(onTap: () => pushScreen(context, const OffersScreen())),
          _PromoCard(
            icon: Icons.science,
            eyebrow: 'Zero-maida lab',
            title: 'Proof, not promises.',
            subtitle: 'NABL batch certificate · 6/6 tests passed',
            onTap: () => state.goTab(2),
          ),
          SectionHeader(
            eyebrow: 'Popular this month',
            title: 'Top ranked',
            action: 'Shop',
            onAction: () => state.goTab(1),
          ),
          ...ranked.take(4).map((item) => _RankHomeRow(item: item)),
        ],
        const SizedBox(height: 8),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, size: 12, color: AppColors.gold),
              SizedBox(width: 5),
              Text(
                '100% whole grain · nothing else',
                style: TextStyle(fontSize: 8.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeIntro extends StatefulWidget {
  const _HomeIntro();

  @override
  State<_HomeIntro> createState() => _HomeIntroState();
}

class _HomeIntroState extends State<_HomeIntro> {
  final PageController _heroController = PageController(initialPage: 0);

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final compact = MediaQuery.sizeOf(context).width < 360;
    final textExtra = (MediaQuery.textScalerOf(context).scale(20) - 20)
        .clamp(0, 40).toDouble();

    return Column(
      children: [
        const SizedBox(height: 10),
        if (!state.isLive) _LocationChip(pin: state.address.pin),
        SizedBox(
          height: (compact ? 304 : 286) + textExtra * 14,
          child: PageView.builder(
            key: const ValueKey('home-hero-carousel'),
            controller: _heroController,
            itemCount: heroSlides.length,
            onPageChanged: state.setHeroIndex,
            itemBuilder: (context, index) {
              final slide = heroSlides[index];
              return _HeroCard(
                slide: slide,
                onShop: () {
                  final product = state.featuredPack(slide.productIndex);
                  if (product == null) {
                    state.setCategory(0);
                    state.goTab(1);
                  } else {
                    pushScreen(context, ProductScreen(product: product));
                  }
                },
                onLab: state.isLive ? null : () => state.goTab(2),
                onViewer: state.isLive ? null : () => pushScreen(context, const ViewerScreen()),
                onReset: () {
                  _heroController.jumpToPage(0);
                  state.setHeroIndex(0);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(heroSlides.length, (index) {
            final active = state.heroIndex == index;
            return InkWell(
              onTap: () {
                _heroController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                );
                state.setHeroIndex(index);
              },
              child: Container(
                width: active ? 18 : 6,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active ? AppColors.orange : const Color(0x33EF5B25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36 + textExtra,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              if (!state.isLive)
                const TrustChip(icon: Icons.local_shipping, label: 'Free shipping')
              else if (state.storeConfig case final config?)
                TrustChip(icon: Icons.local_shipping,
                  label: 'Free delivery from ${money(config.freeDeliveryThreshold)}'),
              const TrustChip(icon: Icons.thermostat, label: 'Cold milled'),
              const TrustChip(icon: Icons.verified, label: 'Zero maida'),
              if (!state.isLive) const TrustChip(icon: Icons.flash_on, label: '2-hour EV'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          crossAxisCount: compact || state.isLive ? 2 : 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          mainAxisExtent: 108 + textExtra * 4,
          children: [
            if (!state.isLive) QuickAction(
              icon: Icons.near_me,
              title: 'Track order',
              subtitle: 'Live EV status',
              onTap: () => pushScreen(context, const TrackingScreen()),
            ),
            if (state.isLive)
              QuickAction(
                icon: Icons.receipt_long,
                title: 'Your orders',
                subtitle: 'History & receipts',
                onTap: () => state.goTab(2),
              )
            else
            QuickAction(
              icon: Icons.verified,
              title: 'Verify pack',
              subtitle: 'Batch #IC-0426',
              onTap: () => state.goTab(2),
            ),
            if (!state.isLive) QuickAction(
              icon: Icons.confirmation_number,
              title: 'Offers',
              subtitle: 'CLEAR50 is live',
              onTap: () => pushScreen(context, const OffersScreen()),
            ),
            QuickAction(
              icon: Icons.opacity,
              title: 'Calculator',
              subtitle: 'Rotis per kg',
              onTap: () => pushScreen(context, const CalculatorScreen()),
            ),
          ],
        ),
        SectionHeader(
          eyebrow: 'Find your flour',
          title: 'Shop by category',
          action: 'See all',
          onAction: () {
            state.setCategory(0);
            state.goTab(1);
          },
        ),
        SizedBox(
          height: 148 + textExtra * 2,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                onTap: () {
                  final filterIndex = categoryFilters.indexOf(category.filter);
                  state.setCategory(filterIndex < 0 ? 0 : filterIndex);
                  state.goTab(1);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LocationChip extends StatelessWidget {
  final String pin;
  const _LocationChip({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x0D101A3A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 12, color: AppColors.orange),
          const SizedBox(width: 5),
          Text(
            pin,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.expand_more, size: 13, color: AppColors.orange),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final HeroSlide slide;
  final VoidCallback onShop;
  final VoidCallback? onLab;
  final VoidCallback? onViewer;
  final VoidCallback onReset;

  const _HeroCard({
    required this.slide,
    required this.onShop,
    required this.onLab,
    required this.onViewer,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF8), Color(0xFFFFF0E4)],
        ),
        border: Border.all(color: const Color(0x38EF5B25)),
        boxShadow: const [
          BoxShadow(color: Color(0x21101A3A), blurRadius: 34, offset: Offset(0, 16)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x26EF5B25), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFF6EC), Color(0xFFFFF0DF)],
                                ),
                                border: Border.all(color: const Color(0x47C6922F)),
                              ),
                              child: Text(
                                slide.pill,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  height: 1.3,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text.rich(
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              TextSpan(
                                style: displayStyle(size: 22),
                                children: [
                                  TextSpan(text: '${slide.title} '),
                                  TextSpan(
                                    text: slide.accent,
                                    style: displayStyle(size: 22, color: AppColors.orange),
                                  ),
                                  TextSpan(text: '\n${slide.tail}'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                            Flexible(
                              child: Text(
                                slide.description,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: PackImage(asset: slide.image, height: 200),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: _SmallAction(
                        label: 'Shop the harvest',
                        icon: Icons.arrow_forward,
                        primary: true,
                        onTap: onShop,
                      ),
                    ),
                    if (onLab != null) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: _SmallAction(
                          label: 'Zero-maida lab',
                          primary: false,
                          onTap: onLab!,
                        ),
                      ),
                    ],
                  ],
                ),
                if (onViewer != null) ...[
                  const SizedBox(height: 9),
                  InkWell(
                    onTap: onViewer,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xF2FFFFFF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.line),
                        boxShadow: const [
                          BoxShadow(color: Color(0x14101A3A), blurRadius: 14, offset: Offset(0, 5)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.refresh, size: 12, color: AppColors.ink),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Drag 360° to inspect authentic packaging',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onReset,
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool primary;
  final VoidCallback onTap;
  const _SmallAction({
    required this.label,
    required this.primary,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: primary ? AppGradients.orange : null,
          color: primary ? null : const Color(0xF2FFFFFF),
          border: Border.all(color: primary ? AppColors.orange : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: primary ? Colors.white : AppColors.ink,
                ),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 3),
              Icon(icon, size: 11, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 94,
        decoration: premiumCard(radius: 16),
        padding: const EdgeInsets.all(7),
        child: Column(
          children: [
            Container(
              height: 82,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF6EC), Color(0xFFFFEFE1)],
                ),
              ),
              child: PackImage(asset: category.image),
            ),
            const SizedBox(height: 7),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              category.note,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 7.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SaleCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppGradients.navy,
          border: Border.all(color: AppColors.glassLine),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.star, size: 11, color: AppColors.goldLight),
                      SizedBox(width: 5),
                      Text(
                        'LIMITED TIME',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Super Sale · up to 25% off',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Use code CLEAR50 on selected attas',
                    style: TextStyle(fontSize: 8.5, color: Color(0xA6FFFFFF)),
                  ),
                ],
              ),
            ),
            const _Clock(),
          ],
        ),
      ),
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: const [
        Text('02', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.goldLight)),
        Text(' : ', style: TextStyle(fontSize: 8, color: Color(0x80FFFFFF))),
        Text('14', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.goldLight)),
        Text(' : ', style: TextStyle(fontSize: 8, color: Color(0x80FFFFFF))),
        Text('37', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.goldLight)),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PromoCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF142247),
          border: Border.all(color: AppColors.glassLine),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x33C6922F),
              ),
              child: Icon(icon, size: 20, color: AppColors.goldLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 8, color: Color(0x99FFFFFF)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_upward, size: 16, color: AppColors.goldLight),
          ],
        ),
      ),
    );
  }
}

class _CalcPromo extends StatelessWidget {
  final VoidCallback onTap;
  const _CalcPromo({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(13),
        decoration: premiumCard(radius: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sand,
              ),
              child: const Icon(Icons.opacity, size: 18, color: AppColors.orange),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How much atta does your family need?',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '36 rotis per kg · find your perfect pack',
                    style: TextStyle(fontSize: 8.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 17, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _RankHomeRow extends StatelessWidget {
  final RankedItem item;
  const _RankHomeRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: premiumCard(radius: 14),
      child: Row(
        children: [
          Text(
            '#0${ranked.indexOf(item) + 1}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 10),
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
