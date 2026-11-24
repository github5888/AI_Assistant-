import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'data.dart';
import 'theme.dart';

Future<T?> pushScreen<T>(BuildContext context, Widget screen) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(builder: (_) => screen),
  );
}

void popScreen(BuildContext context) => Navigator.of(context).pop();

const appSystemBars = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  systemNavigationBarColor: AppColors.cream,
  systemNavigationBarIconBrightness: Brightness.dark,
);

/// System-safe frame shared by routes outside the main tab shell.
class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: appSystemBars,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showLogo;
  final bool back;
  final List<Widget> actions;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = false,
    this.back = false,
    this.actions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: const BoxDecoration(
            color: Color(0xF8FFFDF8),
            border: Border(
              bottom: BorderSide(color: AppColors.line, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              if (back)
                RoundIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => popScreen(context),
                )
              else if (showLogo)
                const _BrandMark()
              else
                const SizedBox(width: 2),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.ink,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.navy,
            boxShadow: [
              BoxShadow(color: Color(0x33101A3A), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.eco, size: 16, color: AppColors.goldLight),
        ),
        const SizedBox(width: 6),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: AppColors.ink,
            ),
            children: [
              TextSpan(text: 'itsclear'),
              TextSpan(
                text: '™',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final bool filled;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.orange : AppColors.paper,
          border: Border.all(color: filled ? AppColors.orange : AppColors.line),
          boxShadow: const [
            BoxShadow(color: Color(0x0F101A3A), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.44,
          color: color ?? (filled ? Colors.white : AppColors.ink),
        ),
      ),
    );
  }
}

class BottomDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int cartCount;
  final bool showOrders;

  const BottomDock({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.cartCount,
    this.showOrders = false,
  });

  static const _items = <_DockSpec>[
    _DockSpec(Icons.home, 'Home'),
    _DockSpec(Icons.search, 'Shop'),
    _DockSpec(Icons.science, 'Lab'),
    _DockSpec(Icons.shopping_bag, 'Basket'),
    _DockSpec(Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppGradients.dock),
            child: Row(
              children: List.generate(_items.length, (index) {
                final spec = showOrders && index == 2
                    ? const _DockSpec(Icons.receipt_long, 'Orders')
                    : _items[index];
                final selected = index == selectedIndex;
                final badge = index == 3 && cartCount > 0 ? cartCount : null;
                return Expanded(
                  child: _DockItem(
                    spec: spec,
                    selected: selected,
                    badge: badge,
                    onTap: () => onTap(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockSpec {
  final IconData icon;
  final String label;
  const _DockSpec(this.icon, this.label);
}

class _DockItem extends StatelessWidget {
  final _DockSpec spec;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _DockItem({
    required this.spec,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: selected ? AppGradients.orange : null,
                    color: selected ? null : Colors.transparent,
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x55EF5B25),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    spec.icon,
                    size: 19,
                    color: selected ? Colors.white : const Color(0x9AFFFFFF),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: -2,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.navy, width: 1.5),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? AppColors.amber : const Color(0xCFFFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Stars extends StatelessWidget {
  final double value;
  final double size;
  const Stars({super.key, required this.value, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i + 1 <= value.round();
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: size,
          color: AppColors.gold,
        );
      }),
    );
  }
}

class PackImage extends StatelessWidget {
  final String asset;
  final String fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;
  const PackImage({
    super.key,
    required this.asset,
    this.fallback = AppImages.khapli,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (asset.startsWith('https://')) {
      return Image.network(asset,
        width: width, height: height, fit: fit, cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => Image.asset(fallback, width: width, height: height, fit: fit),
      );
    }
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      cacheWidth: cacheWidth,
    );
  }
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  final bool rule;
  const Eyebrow({
    super.key,
    required this.text,
    this.color = AppColors.orange,
    this.rule = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rule)
          Container(
            width: 16,
            height: 2,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              gradient: LinearGradient(colors: [AppColors.orange, AppColors.gold]),
            ),
          ),
        Flexible(
          child: Text(
            text.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: eyebrowStyle(color: color),
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(text: eyebrow, rule: true),
                const SizedBox(height: 5),
                Text(title, style: sectionStyle()),
              ],
            ),
          ),
          if (action != null)
            InkWell(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    action!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 14, color: AppColors.orange),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Gradient? gradient;
  final Color textColor;
  final double height;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient,
    this.textColor = Colors.white,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: gradient ?? AppGradients.navy,
          boxShadow: const [
            BoxShadow(color: Color(0x33101A3A), blurRadius: 20, offset: Offset(0, 9)),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 7),
                Icon(icon, size: 15, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final String? subtitle;
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected ? AppGradients.orange : null,
          color: selected ? null : AppColors.paper,
          border: Border.all(
            color: selected ? AppColors.orange : AppColors.line,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 7.5,
                    color: selected ? Colors.white70 : AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final double? width;
  final VoidCallback onTap;
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.isLive) {
      return _LiveProductCard(product: product, width: width, openDetails: onTap);
    }
    final wished = state.wishlist.contains(product.id);
    return Container(
      width: width,
      decoration: premiumCard(radius: 18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Container(
                  height: 138,
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFAF3), Color(0xFFFFF1E5)],
                    ),
                  ),
                  child: PackImage(asset: product.image, fallback: product.fallbackImage ?? AppImages.khapli),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: AppGradients.navy,
                      border: Border.all(color: const Color(0x55C6922F)),
                    ),
                    child: Text(
                      product.tag.toUpperCase(),
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
                  right: 7,
                  top: 7,
                  child: InkWell(
                    onTap: () => state.toggleWish(product.id),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xE6FFFFFF),
                      ),
                      child: Icon(
                        wished ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: wished ? AppColors.orange : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onTap,
                  child: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Stars(value: product.rating, size: 9),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${product.rating.toStringAsFixed(1)} · ${product.reviews} reviews',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 8, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            money(product.sizes.first.price),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            money(product.sizes.first.mrp),
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppColors.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final size = product.sizes.first;
                        if (!size.inStock) {
                          onTap();
                          return;
                        }
                        final added = state.addToCart(product, size, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(added ? '${product.name} added to basket' : 'This quantity is not available.'),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      },
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

class _LiveProductCard extends StatelessWidget {
  const _LiveProductCard({required this.product, required this.width, required this.openDetails});
  final Product product;
  final double? width;
  final VoidCallback openDetails;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final size = product.sizes.first;
    final wished = state.wishlist.contains(product.id);
    final scaler = MediaQuery.textScalerOf(context);

    void add() {
      if (!size.inStock) { openDetails(); return; }
      final added = state.addToCart(product, size, 1);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(added ? 'Added to your basket' : 'This quantity is not available.'),
          duration: const Duration(milliseconds: 1100),
        ));
    }

    return SizedBox(width: width, child: LayoutBuilder(builder: (context, bounds) {
      final rowLayout = bounds.maxWidth >= 274;
      final imageWidth = rowLayout ? (bounds.maxWidth * .34).clamp(88, 144).toDouble() : bounds.maxWidth;
      final cacheWidth = (imageWidth * MediaQuery.devicePixelRatioOf(context)).clamp(150, 480).round();
      final image = Stack(fit: StackFit.expand, children: [
        Material(
          color: const Color(0xFFFAF0E5),
          child: InkWell(
            onTap: openDetails,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
              child: PackImage(asset: product.image,
                fallback: product.fallbackImage ?? AppImages.khapli, cacheWidth: cacheWidth),
            ),
          ),
        ),
        Positioned(top: 2, right: 2, child: IconButton(
          tooltip: wished ? 'Remove from saved items' : 'Save item',
          style: IconButton.styleFrom(backgroundColor: AppColors.paper, foregroundColor: AppColors.ink),
          icon: Icon(wished ? Icons.favorite : Icons.favorite_border, size: 16),
          onPressed: () => state.toggleWish(product.id),
        )),
      ]);

      final details = Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          InkWell(onTap: openDetails, child: SizedBox(
            width: double.infinity,
            height: scaler.scale(13) * 2.38,
            child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          )),
          const SizedBox(height: 3),
          Row(children: [
            Expanded(child: Text(size.label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted))),
            if (product.rating > 0) ...[
              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFA56722)),
              const SizedBox(width: 2),
              Text(product.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.w700, color: AppColors.ink)),
            ],
          ]),
          const SizedBox(height: 3),
          Row(children: [
            Expanded(child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(money(size.price), style: const TextStyle(fontSize: 17, height: 1.05,
                  fontWeight: FontWeight.w900, color: AppColors.ink)),
                if (size.mrp > size.price) Text(money(size.mrp), style: const TextStyle(fontSize: 10,
                  color: AppColors.muted, decoration: TextDecoration.lineThrough)),
              ]),
            )),
            const SizedBox(width: 5),
            Tooltip(
              message: size.inStock ? 'Add ${product.name}, ${size.label}' : 'View available pack sizes',
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEBDE),
                  foregroundColor: const Color(0xFF923B18),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  minimumSize: const Size(44, 40),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                onPressed: add,
                child: Text(size.inStock ? 'Add' : 'Sizes'),
              ),
            ),
          ]),
        ]),
      );

      return Card(
        margin: EdgeInsets.zero,
        color: AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line)),
        clipBehavior: Clip.antiAlias,
        child: rowLayout
            ? Row(children: [SizedBox(width: imageWidth, height: double.infinity, child: image),
                Expanded(child: details)])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: image), details]),
      );
    }));
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
        decoration: premiumCard(radius: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1E7), Color(0xFFFFE1C9)],
                ),
              ),
              child: Icon(icon, size: 18, color: AppColors.orange),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 7, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  final String image;
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const StoryCard({
    super.key,
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 150,
          decoration: premiumCard(radius: 20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(image, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6070C20)],
                    stops: [0.25, 1],
                  ),
                ),
              ),
              Positioned(
                left: 11,
                right: 11,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
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
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 8, color: Color(0xBFFFFFFF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromiseCard extends StatelessWidget {
  final VoidCallback onTap;
  const PromiseCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navy2],
        ),
        border: Border.all(color: AppColors.glassLine),
        boxShadow: const [
          BoxShadow(color: Color(0x3D101A3A), blurRadius: 34, offset: Offset(0, 16)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -60,
            child: Container(
              width: 170,
              height: 170,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow(
                      text: 'The clear standard',
                      color: AppColors.amber,
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Nothing added.\nNothing removed.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        letterSpacing: -0.7,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      '6 lab tests · 0 maida · 0 bleach · 100% bran retained',
                      style: TextStyle(fontSize: 8.5, color: Color(0x9FFFFFFF)),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: AppGradients.orange,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See lab report',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PackImage(asset: AppImages.badges, width: 88, height: 116),
            ],
          ),
        ],
      ),
    );
  }
}

class TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const TrustChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
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
          Icon(icon, size: 14, color: AppColors.orange),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class SpecTile extends StatelessWidget {
  final String value;
  final String label;
  const SpecTile({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
      decoration: premiumCard(radius: 14),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 7.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: padding,
      decoration: premiumCard(),
      child: child,
    );
  }
}

class AppField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  const AppField({
    super.key,
    required this.label,
    required this.initialValue,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: eyebrowStyle(color: AppColors.muted).copyWith(fontSize: 7.5, letterSpacing: 1.1),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(isDense: true),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trailingBelow = (trailing?.length ?? 0) > 20;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1E7), Color(0xFFFFE1C9)],
                ),
              ),
              child: Icon(icon, size: 16, color: AppColors.orange),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
                      ),
                    ),
                  if (trailingBelow)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(trailing!, maxLines: 3, softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, height: 1.3,
                          fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ),
                ],
              ),
            ),
            if (trailing != null && !trailingBelow)
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              )
            else if (trailing == null)
              const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class StoreNotice extends StatelessWidget {
  const StoreNotice({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class CatalogStatus extends StatelessWidget {
  const CatalogStatus({super.key, this.emptyMessage = 'No products found.'});

  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.isLoadingCatalog && state.catalog.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.catalogError) {
      return StoreNotice(
        message: state.catalog.isEmpty
            ? 'Could not load the live catalog.'
            : 'Could not refresh. Showing the last loaded catalog.',
        onRetry: state.refreshStore,
      );
    }
    return StoreNotice(message: emptyMessage);
  }
}
