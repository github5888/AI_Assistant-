import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calculator_screen.dart';
import 'product_screen.dart';

class HomeHarvestCarousel extends StatefulWidget {
  const HomeHarvestCarousel({super.key});

  @override
  State<HomeHarvestCarousel> createState() => _HomeHarvestCarouselState();
}

class _HomeHeroSlide {
  const _HomeHeroSlide({required this.tag, required this.title,
    required this.description, required this.image, required this.light,
    required this.shade, required this.accent, this.cta = 'Shop the harvest',
    this.ctaLink = '/shop', this.networkImage = false, this.productIndex});

  final String tag;
  final String title;
  final String description;
  final String image;
  final Color light;
  final Color shade;
  final Color accent;
  final String cta;
  final String ctaLink;
  final bool networkImage;
  final int? productIndex;
}

class _HomeHarvestCarouselState extends State<HomeHarvestCarousel> {
  final _controller = PageController();
  int _active = 0;

  static const _fallbackSlides = <_HomeHeroSlide>[
    _HomeHeroSlide(tag: 'THE HARVEST', title: 'Khapli\nChakki Atta',
      description: 'Stoneground whole wheat for everyday rotis.', image: AppImages.khapli,
      light: Color(0xFFFFF5E5), shade: Color(0xFFF3D39E), accent: Color(0xFF81431D), productIndex: 0),
    _HomeHeroSlide(tag: 'THE PROTEIN BLEND', title: 'High Protein\nAtta',
      description: 'A blend of wheat, soya and peanut.', image: AppImages.protein,
      light: Color(0xFFF0F5E8), shade: Color(0xFFC6D8AE), accent: Color(0xFF3C592B), productIndex: 1),
    _HomeHeroSlide(tag: 'THE FAMILY PACK', title: 'Khapli\nFamily Packs',
      description: 'Larger bags for the whole household.', image: AppImages.handle,
      light: Color(0xFFFFF1EA), shade: Color(0xFFF0C6AF), accent: Color(0xFF843D2E), productIndex: 2),
  ];

  List<_HomeHeroSlide> _slidesFor(AppState state) {
    final banners = state.liveHeroBanners;
    if (banners == null) return _fallbackSlides;
    const colors = [
      (Color(0xFFFFF5E5), Color(0xFFF3D39E), Color(0xFF81431D)),
      (Color(0xFFF0F5E8), Color(0xFFC6D8AE), Color(0xFF3C592B)),
      (Color(0xFFFFF1EA), Color(0xFFF0C6AF), Color(0xFF843D2E)),
    ];
    final activeBanners = banners.where((banner) => banner['isActive'] != false).toList();
    return List.generate(activeBanners.length, (index) {
      final banner = activeBanners[index];
      final palette = colors[index % colors.length];
      final rawImage = banner['imageUrl'] is String ? (banner['imageUrl'] as String).trim() : '';
      final parsedImage = Uri.tryParse(rawImage);
      final image = rawImage.isEmpty ? '' : parsedImage?.hasScheme == true
          ? rawImage : state.api?.base.resolve(rawImage).toString() ?? rawImage;
      return _HomeHeroSlide(
        tag: banner['badge'] is String ? banner['badge'] as String : '',
        title: banner['headline'] is String ? banner['headline'] as String : 'ItsClear essentials',
        description: banner['subtitle'] is String ? banner['subtitle'] as String : '',
        image: image,
        light: palette.$1,
        shade: palette.$2,
        accent: palette.$3,
        cta: banner['primaryCtaText'] is String && (banner['primaryCtaText'] as String).trim().isNotEmpty
            ? (banner['primaryCtaText'] as String).trim() : 'Shop now',
        ctaLink: banner['primaryCtaLink'] is String ? banner['primaryCtaLink'] as String : '/shop',
        networkImage: rawImage.isNotEmpty,
      );
    }).where((slide) => slide.image.isNotEmpty).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final slides = _slidesFor(state);
    if (slides.isEmpty) return const SizedBox.shrink();
    final activeIndex = _active.clamp(0, slides.length - 1).toInt();
    final scaledTitle = MediaQuery.textScalerOf(context).scale(25);
    final extra = (scaledTitle - 25).clamp(0, 35).toDouble();
    return Column(children: [
      SizedBox(
        height: 226 + extra * 7,
        child: PageView.builder(
          key: const ValueKey('home-hero-carousel'),
          controller: _controller,
          itemCount: slides.length,
          onPageChanged: (index) => setState(() => _active = index),
          itemBuilder: (context, index) {
            final slide = slides[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: slide.shade),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [slide.light, Color.lerp(slide.light, slide.shade, .57)!],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Row(children: [
                  Expanded(flex: 6, child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slide.tag, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: slide.accent, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.05)),
                      const SizedBox(height: 5),
                      Flexible(child: Text(slide.title, maxLines: 4, overflow: TextOverflow.ellipsis,
                        style: displayStyle(size: 25))),
                      const SizedBox(height: 7),
                      Flexible(child: Text(slide.description, maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.ink, fontSize: 12, height: 1.25))),
                    ],
                  )),
                  const SizedBox(width: 5),
                  Expanded(flex: extra > 7 ? 3 : 5, child: _HarvestPack(
                    image: slide.image, shade: slide.shade,
                    networkImage: slide.networkImage,
                  )),
                ])),
                const SizedBox(height: 4),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    minimumSize: const Size(44, 44),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    Product? target;
                    if (slide.productIndex != null) {
                      target = state.featuredPack(slide.productIndex!);
                    } else {
                      for (final product in state.catalog) {
                        if (slide.ctaLink.contains(product.id)) target = product;
                      }
                    }
                    final selectedProduct = target;
                    if (selectedProduct != null) {
                      pushScreen(context, ProductScreen(product: selectedProduct));
                    } else {
                      state.setCategory(0);
                      state.goTab(1);
                    }
                  },
                  label: Text(slide.cta),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  iconAlignment: IconAlignment.end,
                ),
              ]),
            );
          },
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < slides.length; i++)
          Semantics(
            selected: i == activeIndex,
            button: true,
            label: 'Harvest slide ${i + 1} of ${slides.length}',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _controller.animateToPage(i,
                duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic),
              child: SizedBox(width: 44, height: 32, child: Center(child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: i == activeIndex ? 22 : 6, height: 5,
                decoration: BoxDecoration(
                  color: i == activeIndex ? AppColors.ink : const Color(0xFFD7B99E),
                  borderRadius: BorderRadius.circular(8),
                ),
              ))),
            ),
          ),
      ]),
    ]);
  }
}

class _HarvestPack extends StatelessWidget {
  const _HarvestPack({required this.image, required this.shade, this.networkImage = false});
  final String image;
  final Color shade;
  final bool networkImage;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Center(child: AspectRatio(aspectRatio: 1, child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: shade,
          border: Border.all(color: Colors.white54, width: 2)),
      ))),
      Align(alignment: const Alignment(0, .85), child: FractionallySizedBox(
        widthFactor: .80,
        child: Container(height: 11, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [BoxShadow(color: Color(0x52101A3A), blurRadius: 12, spreadRadius: 1)],
        )),
      )),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: networkImage
            ? Image.network(image, fit: BoxFit.contain, filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => PackImage(asset: AppImages.khapli, cacheWidth: 440))
            : PackImage(asset: image, cacheWidth: 440),
      ),
    ]);
  }
}

class HomeQuickLinks extends StatelessWidget {
  const HomeQuickLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final config = state.storeConfig;
    final scale = MediaQuery.textScalerOf(context);
    return Column(children: [
      SizedBox(height: 23 + scale.scale(10) * 1.4, child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        children: [
          const TrustChip(icon: Icons.grass_rounded, label: 'Cold milled'),
          const TrustChip(icon: Icons.verified_outlined, label: 'Zero maida'),
          if (config != null)
            TrustChip(icon: Icons.local_shipping_outlined,
              label: 'Free delivery from ${money(config.freeDeliveryThreshold)}'),
        ],
      )),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _HomeShortcut(icon: Icons.receipt_long_outlined,
            title: 'Your orders', onTap: () => state.goTab(2))),
          const SizedBox(width: 8),
          Expanded(child: _HomeShortcut(icon: Icons.calculate_outlined,
            title: 'Calculator', onTap: () => pushScreen(context, const CalculatorScreen()))),
        ]),
      ),
    ]);
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line)),
      child: InkWell(onTap: onTap, child: Container(
        constraints: BoxConstraints(minHeight: 36 + MediaQuery.textScalerOf(context).scale(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(
            color: AppColors.sand, borderRadius: BorderRadius.circular(9),
          ), child: Icon(icon, color: const Color(0xFF8E421E), size: 17)),
          const SizedBox(width: 7),
          Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.1, fontWeight: FontWeight.w800))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 14),
        ]),
      )),
    );
  }
}

class HomePhotoCategories extends StatelessWidget {
  const HomePhotoCategories({super.key});

  static const _categories = [
    (filter: 'Khapli', label: 'Khapli', image: AppImages.khapli, tone: Color(0xFFF8EBD7)),
    (filter: 'Protein', label: 'Protein', image: AppImages.protein, tone: Color(0xFFEAF1E2)),
    (filter: 'Family', label: 'Family', image: AppImages.handle, tone: Color(0xFFF9E7DE)),
    (filter: 'Bundle', label: 'Bundles', image: AppImages.duo, tone: Color(0xFFF0ECF5)),
    (filter: 'Mustard Oil', label: 'Mustard oil', image: AppImages.mustardOil, tone: Color(0xFFFFF3DC)),
    (filter: 'Desi Ghee', label: 'Desi ghee', image: AppImages.desiGhee, tone: Color(0xFFFFEFC5)),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scaledText = MediaQuery.textScalerOf(context).scale(11);
    return LayoutBuilder(builder: (context, constraints) {
      final width = ((constraints.maxWidth - 28 - 24) / 4).clamp(62.0, scaledText > 14 ? 128.0 : 142.0).toDouble();
      final tileWidth = scaledText > 14 ? width.clamp(100.0, 128.0).toDouble() : width;
      return SizedBox(height: 76 + scaledText * 2.35, child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return SizedBox(width: tileWidth, child: Material(
            color: category.tone,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: AppColors.line)),
            child: InkWell(
              key: ValueKey('home-category-${category.filter}'),
              onTap: () {
                state.setCategory(categoryFilters.indexOf(category.filter));
                state.goTab(1);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 7, 4, 6),
                child: Column(children: [
                  Expanded(child: PackImage(asset: category.image, cacheWidth: 220)),
                  const SizedBox(height: 5),
                  Text(category.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, height: 1.13, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ));
        },
      ));
    });
  }
}
