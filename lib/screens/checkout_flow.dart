import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../store_api.dart';
import '../payment_models.dart';
import '../widgets.dart';
import 'sign_in_screen.dart';
import 'order_confirmation_screen.dart';
import 'tracking_map_card.dart';

/// Native, authenticated COD and UPI checkout backed by the live order API.
/// Order confirmation and payment state always come from the server.
class InAppCheckoutScreen extends StatefulWidget {
  const InAppCheckoutScreen({super.key});

  @override
  State<InAppCheckoutScreen> createState() => _InAppCheckoutScreenState();
}

class _InAppCheckoutScreenState extends State<InAppCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _mobile = TextEditingController();
  final _pin = TextEditingController();
  final _city = TextEditingController();
  final _street = TextEditingController();
  String _addressType = 'Home';
  String _paymentMethod = 'cod';
  bool _addressSaved = false;
  String? _submitError;

  bool _didSetCustomerName = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final customerName = AppScope.of(context).customer?.name;
    if (!_didSetCustomerName && customerName != null) {
      _name.text = customerName;
      _didSetCustomerName = true;
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _mobile, _pin, _city, _street]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'This field is required.' : null;

  String? _validMobile(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^\d{10}$').hasMatch(digits)
        ? null : 'Enter a valid 10-digit mobile number.';
  }

  String? _validPin(String? value) => RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
      ? null : 'Enter a valid 6-digit PIN code.';

  String _availablePayment({required bool cod, required bool online}) {
    if (_paymentMethod == 'cod' && cod) return 'cod';
    if (_paymentMethod == 'online' && online) return 'online';
    if (cod) return 'cod';
    if (online) return 'online';
    return '';
  }

  void _saveAddress() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _addressSaved = true; _submitError = null; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Delivery details are ready to review.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _continueOrder(AppState state, {required bool cod, required bool online}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_addressSaved && !(_formKey.currentState?.validate() ?? false)) return;
    if (!_addressSaved) setState(() => _addressSaved = true);
    if (state.customer == null) {
      await pushScreen(context, const SignInScreen());
      if (!mounted || state.customer == null) return;
      return _continueOrder(state, cod: cod, online: online);
    }
    final payment = _availablePayment(cod: cod, online: online);
    if (payment.isEmpty) {
      setState(() => _submitError = 'The store has no available payment method right now.');
      return;
    }
    if (payment == 'online' && state.paymentGateway == null) {
      setState(() => _submitError = 'Secure online checkout is not available in this app build.');
      return;
    }
    setState(() { _submitError = null; });
    try {
      final order = await state.submitLiveOrder(
        paymentMethod: payment == 'cod' ? 'cod' : 'upi',
        shippingAddress: {
          'name': _name.text.trim(),
          'fullName': _name.text.trim(),
          'phone': _mobile.text.trim(),
          'mobile': _mobile.text.trim(),
          'address': _street.text.trim(),
          'addressLine1': _street.text.trim(),
          'street': _street.text.trim(),
          'city': _city.text.trim(),
          'state': 'Uttar Pradesh',
          'pincode': _pin.text.trim(),
          'postalCode': _pin.text.trim(),
          'country': 'India',
          'type': _addressType.toLowerCase(),
        },
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationScreen(order: order),
      ));
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _submitError = state.orderStatusCheckRequired
          ? 'The store response was unclear. Check order history before trying again.'
          : error.message);
    } on PaymentCancelledException {
      if (mounted) setState(() => _submitError = 'Payment was cancelled. No order was placed.');
    } on PaymentException catch (error) {
      if (mounted) setState(() => _submitError = error.message);
    } catch (_) {
      if (mounted) setState(() => _submitError = 'Order could not be placed. Please check your connection and try again.');
    }
  }

  void _checkOrderStatus(AppState state) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    state.goTab(2);
    state.refreshCustomerOrders();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final config = state.storeConfig;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final canUseCod = config?.codEnabled == true;
    final canUseOnline = config?.onlinePaymentsEnabled == true;
    final addressForm = _deliveryCard(state);
    final selectedPayment = _availablePayment(cod: canUseCod, online: canUseOnline);
    final orderReview = _orderCard(state, config: config, cod: canUseCod,
      online: canUseOnline, selectedPayment: selectedPayment);

    return AppPage(child: Column(children: [
      const AppTopBar(title: 'Checkout', subtitle: 'Delivery and payment', back: true),
      Expanded(child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 6, child: addressForm),
              const SizedBox(width: 14),
              Expanded(flex: 4, child: orderReview),
            ])
          else ...[
            addressForm,
            const SizedBox(height: 14),
            orderReview,
          ],
          const SizedBox(height: 12),
          _serviceStatus(state, canUseCod),
        ],
      )),
    ]));
  }

  Widget _deliveryCard(AppState state) {
    final scale = MediaQuery.textScalerOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: premiumCard(radius: 22),
      child: Form(key: _formKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CheckoutHeading(step: '1', title: 'Delivery address',
            subtitle: 'Where should we deliver your fresh flour?'),
          const Divider(height: 22),
          Row(children: [
            const Expanded(child: Eyebrow(text: 'ENTER DELIVERY DETAILS')),
            if (state.customer == null)
              TextButton.icon(
                onPressed: () => pushScreen(context, const SignInScreen()),
                icon: const Icon(Icons.person_outline_rounded, size: 16),
                label: const Text('Sign in'),
                style: TextButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
              ),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 460;
            final name = _input(_name, 'Full name', 'e.g. Prince Singh',
              validator: _required, autofill: AutofillHints.name,
              textCapitalization: TextCapitalization.words);
            final mobile = _input(_mobile, 'Mobile number', '10-digit mobile number',
              validator: _validMobile, type: TextInputType.phone,
              autofill: AutofillHints.telephoneNumber,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[+0-9\s-]'))]);
            final pin = _input(_pin, 'PIN code', '6-digit PIN code',
              validator: _validPin, type: TextInputType.number,
              autofill: AutofillHints.postalCode,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]);
            final city = _input(_city, 'City', 'e.g. Lucknow',
              validator: _required, autofill: AutofillHints.addressCity,
              textCapitalization: TextCapitalization.words);
            Widget pair(Widget first, Widget second) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: first), const SizedBox(width: 10), Expanded(child: second)],
            );
            if (!twoColumns) return Column(children: [name, mobile, pin, city,
              _streetField()]);
            return Column(children: [pair(name, mobile), pair(pin, city), _streetField()]);
          }),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8, runSpacing: 4, children: [
                const Text('Address type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                for (final type in ['Home', 'Work'])
                  ChoiceChip(
                    label: Text(type == 'Home' ? 'Home · all day' : 'Work · 9 AM–6 PM'),
                    selected: _addressType == type,
                    onSelected: (_) => setState(() { _addressType = type; _addressSaved = false; }),
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(fontSize: scale.scale(11),
                      color: _addressType == type ? AppColors.ink : AppColors.muted,
                      fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          SizedBox(height: 46, child: FilledButton(
            onPressed: _saveAddress,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navyDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            child: Text(_addressSaved ? 'DELIVERY DETAILS SAVED' : 'SAVE & DELIVER HERE'),
          )),
          if (_addressSaved) ...[
            const SizedBox(height: 10),
            Semantics(liveRegion: true, child: Text(
              '${_name.text} · ${_mobile.text} · ${_street.text}, ${_city.text} ${_pin.text}',
              style: const TextStyle(fontSize: 12, color: AppColors.green, height: 1.4),
            )),
          ],
        ],
      )),
    );
  }

  Widget _streetField() => _input(_street,
    'Street address / house no. / landmark',
    'Flat / house no., apartment, street, colony',
    validator: _required,
    autofill: AutofillHints.streetAddressLine1,
    textCapitalization: TextCapitalization.sentences,
  );

  Widget _input(TextEditingController controller, String label, String hint, {
    required String? Function(String?) validator,
    TextInputType? type,
    String? autofill,
    List<TextInputFormatter>? formatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: type,
      autofillHints: autofill == null ? null : [autofill],
      inputFormatters: formatters,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      validator: validator,
      onChanged: (_) { if (_addressSaved) setState(() => _addressSaved = false); },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
  );

  Widget _orderCard(AppState state, {required StoreConfig? config,
    required bool cod, required bool online, required String selectedPayment}) {
    final hasOilOrGhee = state.cart.any((line) =>
        line.product.groups.contains('Mustard Oil') || line.product.groups.contains('Desi Ghee'));
    final qualityBadge = hasOilOrGhee ? 'Fresh pantry essentials' : '100% cold milled';
    return Container(
    padding: const EdgeInsets.all(16),
    decoration: premiumCard(radius: 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Expanded(child: Text('ORDER ITEMS', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: .25))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFFEAF9F3), borderRadius: BorderRadius.circular(99)),
          child: Text(qualityBadge, style: const TextStyle(
            color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
      ]),
      const Divider(height: 20),
      if (state.cart.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Your basket is empty.', style: TextStyle(color: AppColors.muted)))
      else ...[
        for (final line in state.cart) _OrderItem(line: line),
        const Divider(height: 18),
        _AmountRow(label: 'Items subtotal', amount: money(state.cartSubtotal)),
        const SizedBox(height: 7),
        _AmountRow(label: 'Delivery', amount: config == null
          ? 'Confirming…'
          : state.cartSubtotal >= config.freeDeliveryThreshold ? 'FREE'
          : 'Confirmed at order submission', positive: state.cartSubtotal >= (config?.freeDeliveryThreshold ?? 1 << 30)),
        const Divider(height: 20),
        _AmountRow(label: 'Total before delivery confirmation',
          amount: money(state.cartSubtotal), prominent: true),
      ],
      const SizedBox(height: 14),
      const Text('PAYMENT METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      if (config == null)
        const Text('Store payment options are loading. Pull down to retry.',
          style: TextStyle(fontSize: 12, color: AppColors.muted))
      else ...[
        _PaymentOption(title: 'Cash on delivery', subtitle: cod
            ? 'Pay when your order arrives' : 'Not available from the store',
          selected: selectedPayment == 'cod', enabled: cod,
          onTap: cod ? () => setState(() => _paymentMethod = 'cod') : null),
        _PaymentOption(title: 'UPI · Razorpay', subtitle: online
            ? 'Pay securely in the app' : 'Currently unavailable',
          selected: selectedPayment == 'online', enabled: online,
          onTap: online ? () => setState(() => _paymentMethod = 'online') : null),
      ],
      const SizedBox(height: 12),
      if (_submitError != null) ...[
        const SizedBox(height: 8),
        StoreNotice(message: _submitError!),
      ],
      const SizedBox(height: 8),
      SizedBox(height: 48, child: FilledButton.icon(
        onPressed: state.isSubmittingOrder ? null
            : state.orderStatusCheckRequired ? () => _checkOrderStatus(state)
            : state.cart.isEmpty || config == null || selectedPayment.isEmpty
                ? null : () => _continueOrder(state, cod: cod, online: online),
        icon: state.isSubmittingOrder
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(state.orderStatusCheckRequired ? Icons.receipt_long_rounded
                : state.customer == null ? Icons.login_rounded : Icons.lock_open_rounded, size: 17),
        label: Text(state.isSubmittingOrder ? 'Placing your order…'
            : state.orderStatusCheckRequired ? 'Check order history before retrying'
            : state.customer == null ? 'Sign in to place order'
            : selectedPayment == 'online' ? 'Pay securely with UPI'
            : 'Place order with cash on delivery'),
      )),
    ]),
  );
  }

  Widget _serviceStatus(AppState state, bool cod) {
    final config = state.storeConfig;
    if (config == null) {
      return StoreNotice(message: 'Store settings are still loading.',
        onRetry: state.isLoadingCatalog ? null : state.refreshStore);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFFFAEF),
        border: Border.all(color: const Color(0x33C6922F)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.local_shipping_outlined, color: AppColors.gold, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Fresh chakki milling & delivery',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Free delivery on orders of ${money(config.freeDeliveryThreshold)} or more. '
            '${cod ? 'Cash on delivery is available.' : 'Cash on delivery is not available.'}',
            style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted)),
        ])),
      ]),
    );
  }
}

class _CheckoutHeading extends StatelessWidget {
  const _CheckoutHeading({required this.step, required this.title, required this.subtitle});
  final String step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(children: [
    CircleAvatar(radius: 18, backgroundColor: const Color(0xFFFFF1C7),
      child: Text(step, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900))),
    const SizedBox(width: 11),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    ])),
  ]);
}

class _OrderItem extends StatelessWidget {
  const _OrderItem({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      PackImage(asset: line.product.image, fallback: line.product.fallbackImage ?? AppImages.khapli,
        width: 48, height: 54, cacheWidth: 140),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(line.product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Wrap(spacing: 6, children: [
          _DetailPill(line.size.label),
          Text('Qty: ${line.qty}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      ])),
      const SizedBox(width: 6),
      Text(money(line.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
    ]),
  );
}

class _DetailPill extends StatelessWidget {
  const _DetailPill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(color: const Color(0xFFF4F5F7), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount,
    this.positive = false, this.prominent = false});
  final String label;
  final String amount;
  final bool positive;
  final bool prominent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(flex: 3, child: Text(label, style: TextStyle(fontSize: prominent ? 13 : 12,
        color: prominent ? AppColors.ink : AppColors.muted,
        fontWeight: prominent ? FontWeight.w900 : FontWeight.w500))),
      const SizedBox(width: 8),
      Expanded(flex: 2, child: Text(amount, textAlign: TextAlign.end,
        style: TextStyle(fontSize: prominent ? 15 : 12,
          color: positive ? AppColors.green : AppColors.ink,
          fontWeight: prominent ? FontWeight.w900 : FontWeight.w700))),
    ]),
  );
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({required this.title, required this.subtitle,
    required this.selected, required this.enabled, this.onTap});
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Material(
      color: enabled ? AppColors.paper : const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.ink : AppColors.line),
          ),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 19, color: enabled ? AppColors.orange : AppColors.muted),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: enabled ? AppColors.ink : AppColors.muted)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ])),
            if (selected) const Text('Available', style: TextStyle(fontSize: 10,
              color: AppColors.green, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    ),
  );
}

class InAppOrdersTab extends StatefulWidget {
  const InAppOrdersTab({super.key});

  @override
  State<InAppOrdersTab> createState() => _InAppOrdersTabState();
}

class _InAppOrdersTabState extends State<InAppOrdersTab> {
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    final customer = state.customer;
    if (customer == null) {
      _loadedFor = null;
    } else if (_loadedFor != customer.id) {
      _loadedFor = customer.id;
      Future<void>.microtask(state.refreshCustomerOrders);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final signedIn = state.customer != null;
    return RefreshIndicator(
      onRefresh: state.refreshCustomerOrders,
      child: ListView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SectionHeader(eyebrow: 'Purchases', title: 'Order history'),
          if (!signedIn && !state.restoringSession)
            SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.local_shipping_outlined, size: 34, color: AppColors.orange),
              const SizedBox(height: 10),
              Text('Your orders, all in one place', style: displayStyle(size: 20)),
              const SizedBox(height: 8),
              const Text('Sign in to see tracking updates, past orders and receipts.',
                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted)),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Sign in to your account', icon: Icons.login,
                onTap: () => pushScreen(context, const SignInScreen())),
            ]))
          else if (state.isLoadingCustomerOrders && state.customerOrders.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()))
          else if (state.customerOrdersError != null)
            StoreNotice(message: state.customerOrdersError!, onRetry: state.refreshCustomerOrders)
          else if (state.customerOrders.isEmpty)
            const StoreNotice(message: 'No orders yet. Your confirmed purchases will appear here.')
          else ...[
            for (final order in state.customerOrders)
              _OrderHistoryCard(order: order),
          ],
          const SectionHeader(eyebrow: 'Documents', title: 'Receipts'),
          StoreNotice(message: state.customerOrders.isEmpty
              ? 'Order receipts will appear here after the store confirms an order.'
              : 'Open an order to view its item, delivery and payment summary.'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PrimaryButton(label: 'Go to your basket', icon: Icons.shopping_bag_outlined,
              onTap: () => state.goTab(3)),
          ),
        ],
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final id = order['id'] is String ? order['id'] as String : '';
    final number = order['orderNumber'] is String ? order['orderNumber'] as String : id;
    final rawStatus = order['orderStatus'] is String ? order['orderStatus'] as String : 'confirmed';
    final status = rawStatus.replaceAll('_', ' ');
    final amount = order['total'];
    final total = amount is num ? money(amount.round()) : '—';
    final items = order['items'] is List ? (order['items'] as List).length : 0;
    final timestamp = order['createdAt'];
    final date = timestamp is String ? DateTime.tryParse(timestamp) : null;
    final dateLabel = date == null ? null : '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 9),
      child: Material(
        color: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: AppColors.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => pushScreen(context, OrderDetailsScreen(order: order)),
          child: Padding(padding: const EdgeInsets.all(14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(number.isEmpty ? 'Order' : number,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900))),
                _StatusPill(status: status),
              ]),
              const SizedBox(height: 7),
              Text('$items ${items == 1 ? 'item' : 'items'}${dateLabel == null ? '' : ' · $dateLabel'}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 9),
              Row(children: [
                Expanded(child: Text(total, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                const Text('Track order & receipt', style: TextStyle(fontSize: 11,
                  color: AppColors.navy2, fontWeight: FontWeight.w800)),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ]),
            ],
          )),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final delivered = status == 'delivered';
    final cancelled = status == 'cancelled' || status == 'returned';
    final tone = delivered ? AppColors.green : cancelled ? AppColors.muted : const Color(0xFF9A551C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: tone.withOpacity(.09), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: tone, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.order});
  final Map<String, dynamic> order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Map<String, dynamic> _order;
  bool _busy = false;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOrder());
  }

  Future<void> _refreshOrder() async {
    if (!mounted) return;
    final id = _order['id'] ?? _order['orderNumber'];
    if (id is! String || id.isEmpty || _refreshing) return;
    final state = AppScope.of(context);
    setState(() { _refreshing = true; _error = null; });
    try {
      final updated = await state.refreshCustomerOrder(id);
      if (mounted) setState(() => _order = updated);
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Tracking details could not be refreshed. Try again.');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _returnOrder() async {
    final orderId = widget.order['id'];
    if (orderId is! String || orderId.isEmpty || _busy) return;
    final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Request a return or replacement?'),
      content: const Text('The store will review this request for your delivered order.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send request')),
      ],
    ));
    if (approved != true || !mounted) return;
    final state = AppScope.of(context);
    setState(() { _busy = true; _error = null; });
    try {
      await state.requestCustomerOrderReturn(orderId, reason: 'Quality or packaging issue');
      if (mounted) Navigator.pop(context);
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Return request could not be sent. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelOrder() async {
    final orderId = widget.order['id'];
    if (orderId is! String || orderId.isEmpty || _busy) return;
    final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Cancel this order?'),
      content: const Text('The store will confirm whether this order is still eligible for cancellation.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep order')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Request cancellation')),
      ],
    ));
    if (approved != true || !mounted) return;
    final state = AppScope.of(context);
    setState(() { _busy = true; _error = null; });
    try {
      await state.cancelCustomerOrder(orderId);
      if (mounted) Navigator.pop(context);
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Cancellation could not be requested. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final number = order['orderNumber'] is String ? order['orderNumber'] as String
        : order['id'] as String? ?? 'Order details';
    final rawStatus = order['orderStatus'] is String ? order['orderStatus'] as String : 'confirmed';
    final status = rawStatus.replaceAll('_', ' ');
    final amount = order['total'];
    final total = amount is num ? money(amount.round()) : '—';
    final payment = order['paymentMethod'] is String ? order['paymentMethod'] as String : '—';
    final address = order['shippingAddress'];
    final addressText = address is Map ? [
      address['fullName'] ?? address['name'], address['addressLine1'] ?? address['address'],
      address['city'], address['pincode'] ?? address['postalCode'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ') : '';
    final items = order['items'] is List
        ? (order['items'] as List).whereType<Map>().toList() : const <Map>[];
    return AppPage(child: Column(children: [
      AppTopBar(title: 'Order details', subtitle: number, back: true),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 24), children: [
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_shipping_outlined, color: AppColors.orange),
            const SizedBox(width: 9),
            Expanded(child: Text(status, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
            _StatusPill(status: status),
          ]),
          const SizedBox(height: 8),
          if (order['estimatedDelivery'] is String)
            Text(order['estimatedDelivery'] as String, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          if ((order['driverName'] is String && (order['driverName'] as String).isNotEmpty) ||
              (order['vehicleNumber'] is String && (order['vehicleNumber'] as String).isNotEmpty)) ...[
            const Divider(height: 20),
            if (order['driverName'] is String && (order['driverName'] as String).isNotEmpty)
              InfoRow(icon: Icons.person_outline, title: 'Delivery partner', trailing: order['driverName'] as String),
            if (order['vehicleNumber'] is String && (order['vehicleNumber'] as String).isNotEmpty)
              InfoRow(icon: Icons.electric_rickshaw, title: 'Vehicle', trailing: order['vehicleNumber'] as String),
          ],
          const SizedBox(height: 8),
          _TrackingProgress(status: rawStatus, step: order['trackingStep']),
        ])),
        const SizedBox(height: 12),
        TrackingMapCard(order: order),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(
          onPressed: _refreshing ? null : _refreshOrder,
          icon: _refreshing
              ? const SizedBox.square(dimension: 15, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded, size: 17),
          label: Text(_refreshing ? 'Refreshing tracking…' : 'Refresh tracking'),
        )),
        const SectionHeader(eyebrow: 'Items', title: 'Order receipt'),
        SectionCard(child: Column(children: [
          for (final item in items) _ReceiptItem(item: item),
          const Divider(height: 20),
          _AmountRow(label: 'Subtotal', amount: _moneyValue(order['subtotal'])),
          if ((order['discount'] is num) && (order['discount'] as num) > 0)
            _AmountRow(label: 'Discount', amount: '-${_moneyValue(order['discount'])}', positive: true),
          _AmountRow(label: 'Delivery fee', amount: _moneyValue(order['deliveryFee'])),
          _AmountRow(label: 'Tax', amount: _moneyValue(order['tax'])),
          const Divider(height: 18),
          _AmountRow(label: 'Total', amount: total, prominent: true),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text('Payment: $payment · ${order['paymentStatus'] ?? 'pending'}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted))),
        ])),
        if (addressText.isNotEmpty) ...[
          const SectionHeader(eyebrow: 'Delivery', title: 'Shipping address'),
          SectionCard(child: Text(addressText, style: const TextStyle(fontSize: 13, height: 1.45))),
        ],
        if (_error != null) StoreNotice(message: _error!),
        if (['confirmed', 'milling', 'quality_check'].contains(rawStatus))
          Padding(padding: const EdgeInsets.only(top: 10), child: OutlinedButton.icon(
            onPressed: _busy ? null : _cancelOrder,
            icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cancel_outlined),
            label: Text(_busy ? 'Requesting…' : 'Request cancellation'),
          )),
        if (rawStatus == 'delivered')
          Padding(padding: const EdgeInsets.only(top: 10), child: OutlinedButton.icon(
            onPressed: _busy ? null : _returnOrder,
            icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.assignment_return_outlined),
            label: Text(_busy ? 'Requesting…' : 'Request return or replacement'),
          )),
      ])),
    ]));
  }
}

class _TrackingProgress extends StatelessWidget {
  const _TrackingProgress({required this.status, required this.step});
  final String status;
  final Object? step;
  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled' || status == 'returned' || status == 'return_requested') {
      return Text('Delivery status: ${status.replaceAll('_', ' ')}',
        style: const TextStyle(fontSize: 12, color: AppColors.muted));
    }
    final current = step is num ? (step as num).toInt().clamp(0, 5) : 1;
    const labels = ['Confirmed', 'Milling', 'Quality check', 'On the way', 'Delivered'];
    return Column(children: [
      for (var index = 0; index < labels.length; index++)
        Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          Icon(index + 1 <= current ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17, color: index + 1 <= current ? AppColors.green : AppColors.muted),
          const SizedBox(width: 8),
          Text(labels[index], style: TextStyle(fontSize: 12,
            fontWeight: index + 1 == current ? FontWeight.w900 : FontWeight.w500,
            color: index + 1 <= current ? AppColors.ink : AppColors.muted)),
        ])),
    ]);
  }
}

class _ReceiptItem extends StatelessWidget {
  const _ReceiptItem({required this.item});
  final Map item;
  @override
  Widget build(BuildContext context) {
    final product = item['product'];
    final variant = item['selectedVariant'];
    final name = product is Map ? product['name'] : item['productName'];
    final size = variant is Map ? variant['size'] : item['size'];
    final quantity = item['quantity'];
    final lineTotal = item['total'] ?? item['lineTotal'];
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
      const Icon(Icons.grain_rounded, color: AppColors.gold, size: 19),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name is String ? name : 'itsclear flour', maxLines: 2,
          overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        Text('${size is String ? size : ''}${quantity is num ? ' · Qty ${quantity.toInt()}' : ''}',
          style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ])),
      if (lineTotal is num) Text(money(lineTotal.round()),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
    ]));
  }
}

String _moneyValue(Object? value) => value is num ? money(value.round()) : '—';
