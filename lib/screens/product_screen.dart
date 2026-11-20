import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'viewer_screen.dart';

class ProductScreen extends StatefulWidget {
  final Product product;
  const ProductScreen({super.key, required this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _sizeIndex = 0;
  int _qty = 1;
  int _tabIndex = 0;
  int _galleryIndex = 0;

  List<String> get _gallery {
    final list = <String>[
      widget.product.image,
      AppImages.khapli,
      AppImages.protein,
      AppImages.lineup,
      AppImages.badges,
    ];
    return list.toSet().take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final product = widget.product;
    final size = product.sizes[_sizeIndex];
    final wished = state.wishlist.contains(product.id);
    final gallery = _gallery;

    return AppPage(
      child: Column(
        children: [
          AppTopBar(
            title: 'Product details',
            back: true,
            actions: [
              RoundIconButton(
                icon: wished ? Icons.favorite : Icons.favorite_border,
                color: wished ? AppColors.orange : null,
                onTap: () => state.toggleWish(product.id),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Gallery(
                    asset: gallery[_galleryIndex],
                    tag: product.tag,
                    index: _galleryIndex,
                    count: gallery.length,
                    onPrev: () => setState(() {
                      _galleryIndex = (_galleryIndex - 1 + gallery.length) % gallery.length;
                    }),
                    onNext: () => setState(() {
                      _galleryIndex = (_galleryIndex + 1) % gallery.length;
                    }),
                    onDot: (i) => setState(() => _galleryIndex = i),
                    onViewer: () => pushScreen(context, const ViewerScreen()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.orange),
                            const SizedBox(width: 4),
                            Text(
                              product.origin.toUpperCase(),
                              style: eyebrowStyle().copyWith(fontSize: 7.5, letterSpacing: 1.1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(product.name, style: displayStyle(size: 26)),
                        const SizedBox(height: 4),
                        Text(
                          product.subtitle,
                          style: const TextStyle(fontSize: 10, color: AppColors.muted),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Stars(value: product.rating, size: 11),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${product.rating.toStringAsFixed(1)} · ${product.reviews} verified reviews',
                                style: const TextStyle(fontSize: 9, color: AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              money(size.price),
                              style: displayStyle(size: 30),
                            ),
                            Text(
                              money(size.mrp),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Save ${money(size.mrp - size.price)}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Eyebrow(text: 'Choose pack size'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: List.generate(product.sizes.length, (i) {
                            return SizedBox(
                              width: 70,
                              child: PillButton(
                                label: product.sizes[i].label,
                                selected: i == _sizeIndex,
                                onTap: () => setState(() => _sizeIndex = i),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: const [
                            Expanded(child: SpecTile(value: '< 28°C', label: 'Cold milled')),
                            SizedBox(width: 7),
                            Expanded(child: SpecTile(value: '72%', label: 'Water absorption')),
                            SizedBox(width: 7),
                            Expanded(child: SpecTile(value: '100%', label: 'Bran retained')),
                            SizedBox(width: 7),
                            Expanded(child: SpecTile(value: '36', label: 'Rotis / kg')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _TabChip(
                              label: 'Overview',
                              selected: _tabIndex == 0,
                              onTap: () => setState(() => _tabIndex = 0),
                            ),
                            _TabChip(
                              label: 'Nutrition',
                              selected: _tabIndex == 1,
                              onTap: () => setState(() => _tabIndex = 1),
                            ),
                            _TabChip(
                              label: 'Lab report',
                              selected: _tabIndex == 2,
                              onTap: () => setState(() => _tabIndex = 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _DetailBody(index: _tabIndex, product: product),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BuyBar(
            qty: _qty,
            total: size.price * _qty,
            onMinus: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
            onPlus: () => setState(() => _qty += 1),
            onAdd: () {
              state.addToCart(product, size, _qty);
              state.goTab(3);
              popScreen(context);
            },
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  final String asset;
  final String tag;
  final int index;
  final int count;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onDot;
  final VoidCallback onViewer;

  const _Gallery({
    required this.asset,
    required this.tag,
    required this.index,
    required this.count,
    required this.onPrev,
    required this.onNext,
    required this.onDot,
    required this.onViewer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF6EC), Color(0xFFFFEFE1)],
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        children: [
          Center(
            child: PackImage(asset: asset, height: 244),
          ),
          Positioned(
            left: 10,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: AppGradients.navy,
              ),
              child: Text(
                tag.toUpperCase(),
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                  color: AppColors.goldLight,
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 130,
            child: RoundIconButton(icon: Icons.chevron_left, onTap: onPrev, size: 30),
          ),
          Positioned(
            right: 10,
            top: 130,
            child: RoundIconButton(icon: Icons.chevron_right, onTap: onNext, size: 30),
          ),
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(count, (i) {
                return InkWell(
                  onTap: () => onDot(i),
                  child: Container(
                    width: i == index ? 18 : 6,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == index ? AppColors.orange : const Color(0x33EF5B25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: InkWell(
              onTap: onViewer,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.refresh, size: 11, color: AppColors.ink),
                    SizedBox(width: 4),
                    Text(
                      '360°',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 46,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.line),
              ),
              child: const Row(
                children: [
                  Icon(Icons.thermostat, size: 11, color: AppColors.orange),
                  SizedBox(width: 4),
                  Text(
                    'Milled below 28°C',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.orange : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.orange : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final int index;
  final Product product;
  const _DetailBody({required this.index, required this.product});

  @override
  Widget build(BuildContext context) {
    if (index == 1) {
      return SectionCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: nutrition.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row['label']!,
                      style: const TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ),
                  Text(
                    row['value']!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }
    if (index == 2) {
      return SectionCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, size: 16, color: AppColors.green),
                SizedBox(width: 6),
                Text(
                  '6 of 6 parameters passed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...labTests.take(3).map((test) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          test.name,
                          style: const TextStyle(fontSize: 9.5, color: AppColors.ink),
                        ),
                      ),
                      Text(
                        test.result,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            const Text(
              'NABL report IC-0426/28 · certificate travels with every pack.',
              style: TextStyle(fontSize: 8.5, color: AppColors.muted),
            ),
          ],
        ),
      );
    }
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Text(
        'Triple-washed heritage grain from ${product.origin}, ground slowly on emery stone chakkis below 28°C. Full bran and natural germ oils stay intact — no maida, bleach or bleaching agents.',
        style: const TextStyle(fontSize: 10, height: 1.55, color: AppColors.muted),
      ),
    );
  }
}

class _BuyBar extends StatelessWidget {
  final int qty;
  final int total;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;

  const _BuyBar({
    required this.qty,
    required this.total,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xF8FFFDF8),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.line),
              color: AppColors.paper,
            ),
            child: Row(
              children: [
                IconButton(onPressed: onMinus, icon: const Icon(Icons.remove, size: 15)),
                Text(
                  '$qty',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                IconButton(onPressed: onPlus, icon: const Icon(Icons.add, size: 15)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryButton(
              label: 'Add · ${money(total)}',
              icon: Icons.arrow_forward,
              gradient: AppGradients.orange,
              height: 44,
              onTap: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}
