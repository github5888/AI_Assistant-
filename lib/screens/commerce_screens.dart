import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _coupon = TextEditingController();

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (state.isLive && state.cart.isNotEmpty) {
      final threshold = state.storeConfig?.freeDeliveryThreshold;
      return ListView(
        primary: false,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ...state.cart.map((line) => _CartLineCard(line: line)),
          StoreNotice(message: 'Item subtotal: ${money(state.cartSubtotal)}'
            '${threshold != null && threshold > 0 ? '\nWebsite free-delivery threshold: ${money(threshold)}' : ''}'),
          const _WebsiteCheckoutNotice(),
        ],
      );
    }

    return state.cart.isEmpty
        ? _EmptyCart(onShop: () => state.goTab(1))
        : ListView(
            primary: false,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _FreeShipping(subtotal: state.cartSubtotal),
              ...state.cart.map((line) => _CartLineCard(line: line)),
              _CouponCard(
                controller: _coupon,
                applied: state.couponApplied,
                onApply: () {
                  final ok = state.applyCoupon(_coupon.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'CLEAR50 applied · ₹50 off' : 'Use code CLEAR50'),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                },
              ),
              _BillCard(state: state),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: PrimaryButton(
                  label: 'Proceed to checkout · ${money(state.cartTotal)}',
                  icon: Icons.arrow_forward,
                  onTap: () => pushScreen(context, const CheckoutScreen()),
                ),
              ),
              const SizedBox(height: 10),
              const Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 5,
                children: [
                  Icon(Icons.lock, size: 11, color: AppColors.muted),
                  Text(
                    'Secure checkout · 100% purity guaranteed',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 8.5, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          );
  }
}

class _WebsiteCheckoutNotice extends StatelessWidget {
  const _WebsiteCheckoutNotice();

  @override
  Widget build(BuildContext context) {
    final site = AppScope.of(context).api!.base;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'In-app checkout and promo codes are not connected yet. To order, use the store website. You’ll need to add your items again there.',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Open store website',
            icon: Icons.open_in_new,
            onTap: () async {
              try {
                if (await launchUrl(site, mode: LaunchMode.externalApplication)) return;
              } catch (_) {
                // Fall back to a human-readable address if no browser opens.
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Open ${site.origin} in your browser.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyCart({required this.onShop});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: AppColors.sand,
                    ),
                    child: const Icon(Icons.shopping_bag, size: 32, color: AppColors.orange),
                  ),
                  const SizedBox(height: 16),
                  Text('Your basket is empty', style: displayStyle(size: 20)),
                  const SizedBox(height: 7),
                  const Text(
                    'Good flour makes better rotis. Start with our bestsellers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Explore attas',
                    icon: Icons.arrow_forward,
                    onTap: onShop,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeShipping extends StatelessWidget {
  final int subtotal;
  const _FreeShipping({required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final double pct = (subtotal / 499).clamp(0.0, 1.0).toDouble();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: premiumCard(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtotal >= 499
                ? 'Free shipping unlocked!'
                : 'Add ${money(499 - subtotal)} for free shipping',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: const Color(0x1AEF5B25),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  final CartLine line;
  const _CartLineCard({required this.line});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(11),
      decoration: premiumCard(radius: 16),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 68,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFFF6EC),
            ),
            child: PackImage(asset: line.product.image, fallback: line.product.fallbackImage ?? AppImages.khapli),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line.size.label,
                  style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyStepper(
                      qty: line.qty,
                      onMinus: () => state.setQty(line.key, line.qty - 1),
                      onPlus: () => state.setQty(line.key, line.qty + 1),
                    ),
                    const Spacer(),
                    Text(
                      money(line.total),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => state.removeFromCart(line.key),
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.delete_outline, size: 16, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
        color: AppColors.paper,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(onTap: onMinus, child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.remove, size: 12),
          )),
          Text('$qty', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
          InkWell(onTap: onPlus, child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.add, size: 12),
          )),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final TextEditingController controller;
  final bool applied;
  final VoidCallback onApply;
  const _CouponCard({
    required this.controller,
    required this.applied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55EF5B25), style: BorderStyle.solid),
        color: AppColors.paper,
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number, size: 16, color: AppColors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'COUPON CODE',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          InkWell(
            onTap: onApply,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: AppGradients.orange,
              ),
              child: Text(
                applied ? 'Applied' : 'Apply',
                style: const TextStyle(
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

class _BillCard extends StatelessWidget {
  final AppState state;
  const _BillCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: premiumCard(),
      child: Column(
        children: [
          _BillRow(label: 'Subtotal', value: money(state.cartSubtotal)),
          _BillRow(label: 'You save', value: '- ${money(state.cartSavings)}', green: true),
          _BillRow(label: 'Delivery', value: state.delivery == 0 ? 'FREE' : money(state.delivery), green: state.delivery == 0),
          if (state.couponApplied)
            _BillRow(label: 'CLEAR50', value: '- ${money(state.couponDiscount)}', green: true),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                money(state.cartTotal),
                style: displayStyle(size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool green;
  const _BillRow({required this.label, required this.value, this.green = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: green ? AppColors.green : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (state.isLive) {
      return const AppPage(child: Column(children: [
        AppTopBar(title: 'Checkout', back: true),
        Expanded(child: SingleChildScrollView(child: _WebsiteCheckoutNotice())),
      ]));
    }

    return AppPage(
      child: Column(
        children: [
          AppTopBar(
            title: 'Checkout',
            subtitle: 'Step 1 of 1 · UI demo',
            back: true,
            actions: [
              RoundIconButton(
                icon: Icons.help_outline,
                onTap: () => _showInfo(context),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                const _Stepper(),
                _AddressCard(state: state),
                _SlotCard(state: state),
                _PaymentCard(state: state),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user, size: 15, color: AppColors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your details stay on this device · UI demo only',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _CheckoutSummary(state: state),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: PrimaryButton(
                    label: 'Place order · ${money(state.cartTotal)}',
                    icon: Icons.arrow_forward,
                    onTap: () {
                      if (state.cart.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add a pack to your basket first'),
                            duration: Duration(milliseconds: 900),
                          ),
                        );
                        return;
                      }
                      state.placeOrder();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('UI demo only'),
        content: const Text(
          'This checkout is a front-end interaction demo. No payment, API call or backend is involved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: const [
          _Step(label: 'Basket', done: true),
          Expanded(child: _Line(done: true)),
          _Step(label: 'Checkout', active: true),
          Expanded(child: _Line(done: false)),
          _Step(label: 'Confirm', done: false),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final bool active;
  final bool done;
  const _Step({required this.label, this.active = false, this.done = false});

  @override
  Widget build(BuildContext context) {
    final color = active || done ? AppColors.orange : AppColors.muted;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 7.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        color: color,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final bool done;
  const _Line({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: done ? AppColors.orange : AppColors.line,
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AppState state;
  const _AddressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHead(icon: Icons.location_on, title: 'Delivery address'),
          const SizedBox(height: 12),
          AppField(
            label: 'Full name',
            initialValue: state.address.name,
            onChanged: (v) => state.address.name = v,
          ),
          Row(
            children: [
              Expanded(
                child: AppField(
                  label: 'Phone',
                  initialValue: state.address.phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => state.address.phone = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppField(
                  label: 'Pincode',
                  initialValue: state.address.pin,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => state.address.pin = v,
                ),
              ),
            ],
          ),
          AppField(
            label: 'Flat / house no.',
            initialValue: state.address.line,
            onChanged: (v) => state.address.line = v,
          ),
          AppField(
            label: 'City & state',
            initialValue: state.address.city,
            onChanged: (v) => state.address.city = v,
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final AppState state;
  const _SlotCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHead(icon: Icons.local_shipping, title: 'Delivery slot'),
          const SizedBox(height: 12),
          Row(
            children: [
              _SlotPill(
                title: '2-hour EV',
                subtitle: '~94 mins',
                selected: state.slotIndex == 0,
                onTap: () => state.setSlot(0),
              ),
              _SlotPill(
                title: 'Tomorrow',
                subtitle: '9 AM – 1 PM',
                selected: state.slotIndex == 1,
                onTap: () => state.setSlot(1),
              ),
              _SlotPill(
                title: 'Scheduled',
                subtitle: 'Pick a day',
                selected: state.slotIndex == 2,
                onTap: () => state.setSlot(2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotPill extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _SlotPill({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: PillButton(
          label: title,
          subtitle: subtitle,
          selected: selected,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final AppState state;
  const _PaymentCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final methods = <Map<String, dynamic>>[
      {'icon': Icons.account_balance_wallet, 'title': 'UPI', 'sub': 'GPay · PhonePe · Paytm'},
      {'icon': Icons.credit_card, 'title': 'Card', 'sub': 'Credit / debit card'},
      {'icon': Icons.money, 'title': 'Cash', 'sub': 'Pay on delivery'},
    ];
    return SectionCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: _CardHead(icon: Icons.credit_card, title: 'Payment method'),
          ),
          ...List.generate(methods.length, (index) {
            final method = methods[index];
            final selected = state.paymentIndex == index;
            return InkWell(
              onTap: () => state.setPayment(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.sand,
                      ),
                      child: Icon(method['icon'] as IconData, size: 16, color: AppColors.orange),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['title'] as String,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            method['sub'] as String,
                            style: const TextStyle(fontSize: 8, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? AppColors.orange : AppColors.line),
                        gradient: selected ? AppGradients.orange : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, size: 11, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CardHead extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardHead({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.orange),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  final AppState state;
  const _CheckoutSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: premiumCard(),
      child: Column(
        children: [
          _BillRow(label: 'Subtotal', value: money(state.cartSubtotal)),
          _BillRow(label: 'Delivery', value: state.delivery == 0 ? 'FREE' : money(state.delivery)),
          if (state.couponApplied)
            _BillRow(label: 'CLEAR50', value: '- ${money(state.couponDiscount)}', green: true),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Total payable',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(money(state.cartTotal), style: displayStyle(size: 20)),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return AppPage(
      child: Column(
        children: [
          AppTopBar(title: 'Order confirmed', subtitle: 'Fresh flour is on its way'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              children: [
                Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFEAD9),
                    ),
                    child: const Icon(Icons.check_circle, size: 38, color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(child: _ProgressPill()),
                const SizedBox(height: 14),
                const Center(
                  child: Eyebrow(text: 'Order confirmed'),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text.rich(
                    TextSpan(
                      style: displayStyle(size: 28),
                      children: [
                        const TextSpan(text: 'Fresh flour is '),
                        TextSpan(
                          text: 'on its way.',
                          style: displayStyle(size: 28, color: AppColors.orange),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Order #${state.orderId} is being packed. Stone-milled within 24h and heading to you in a climate-controlled EV van.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, height: 1.6, color: AppColors.muted),
                ),
                const SizedBox(height: 22),
                SectionCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: const [
                      InfoRow(icon: Icons.local_shipping, title: 'Express EV delivery', trailing: '~94 mins'),
                      Divider(height: 1, color: AppColors.line),
                      InfoRow(icon: Icons.location_on, title: 'Delivering to', trailing: '226001'),
                      Divider(height: 1, color: AppColors.line),
                      InfoRow(icon: Icons.verified, title: 'Batch certificate', trailing: '#IC-0426'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Back to home',
                  icon: Icons.arrow_forward,
                  onTap: () {
                    state.backToHome();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                const SizedBox(height: 10),
                Center(
                  child: InkWell(
                    onTap: () => pushScreen(context, const TrackingScreen()),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Track my order',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_upward, size: 12, color: AppColors.orange),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text('Confirmed', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.orange)),
        SizedBox(width: 5),
        _DotLine(),
        Text('Packed', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.orange)),
        SizedBox(width: 5),
        _DotLine(),
        Text('On the way', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.muted)),
      ],
    );
  }
}

class _DotLine extends StatelessWidget {
  const _DotLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 2,
      color: AppColors.line,
    );
  }
}

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return AppPage(
      child: Column(
        children: [
          AppTopBar(
            title: 'Track order',
            subtitle: '#${state.orderId} · EV delivery',
            back: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDCE8FF), Color(0xFFFFF1E5)],
                    ),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _RoutePainter()),
                      ),
                      const Center(
                        child: Icon(Icons.local_shipping, size: 38, color: AppColors.orange),
                      ),
                      const Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            '~94 mins · climate-controlled EV van',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: List.generate(timeline.length, (index) {
                      final step = timeline[index];
                      final done = index < 3;
                      return _TimelineRow(
                        title: step.title,
                        detail: step.detail,
                        done: done,
                        last: index == timeline.length - 1,
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Back to home',
                  icon: Icons.arrow_forward,
                  onTap: () {
                    state.backToHome();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String title;
  final String detail;
  final bool done;
  final bool last;
  const _TimelineRow({
    required this.title,
    required this.detail,
    required this.done,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.green : AppColors.paper,
                border: Border.all(color: done ? AppColors.green : AppColors.line),
              ),
              child: done
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!last)
              Container(
                width: 2,
                height: 42,
                color: AppColors.line,
              ),
          ],
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x55EF5B25)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(20, size.height - 34)
      ..quadraticBezierTo(size.width * 0.45, 20, size.width - 24, 44);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
