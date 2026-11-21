import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'sign_in_screen.dart';

/// Native checkout surface. It intentionally does not submit until the backend
/// order and payment contracts are available. The basket remains untouched.
class InAppCheckoutScreen extends StatelessWidget {
  const InAppCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final config = state.storeConfig;
    return AppPage(child: Column(children: [
      const AppTopBar(title: 'Checkout', subtitle: 'Delivery and payment', back: true),
      Expanded(child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const StoreNotice(message: 'Checkout setup is in progress. You can review your basket here, but no personal details are saved or sent.'),
          const SectionHeader(eyebrow: '01 · Delivery', title: 'Contact & address'),
          const SectionCard(child: Column(children: [
            _DeliveryField(label: 'Full name', hint: AutofillHints.name),
            _DeliveryField(label: 'Mobile number', hint: AutofillHints.telephoneNumber, type: TextInputType.phone),
            _DeliveryField(label: 'House, street or locality', hint: AutofillHints.streetAddressLine1),
            _DeliveryField(label: 'City', hint: AutofillHints.addressCity),
            _DeliveryField(label: 'PIN code', hint: AutofillHints.postalCode, type: TextInputType.number),
          ])),
          const SectionHeader(eyebrow: '02 · Payment', title: 'Payment methods'),
          if (config == null)
            StoreNotice(message: 'Store payment settings are unavailable.',
              onRetry: state.isLoadingCatalog ? null : state.refreshStore)
          else
            SectionCard(padding: EdgeInsets.zero, child: Column(children: [
              InfoRow(icon: Icons.payments_outlined, title: 'Cash on delivery',
                subtitle: config.codEnabled
                  ? 'Enabled by the store · in-app order submission pending'
                  : 'Disabled by the store'),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(icon: Icons.credit_card, title: 'Online payment',
                subtitle: config.onlinePaymentsEnabled
                  ? 'Enabled by the store · in-app payment verification pending'
                  : 'Currently disabled by the store'),
            ])),
          const SectionHeader(eyebrow: '03 · Review', title: 'Order summary'),
          if (state.cart.isEmpty)
            const StoreNotice(message: 'Your basket is empty.')
          else
            SectionCard(padding: EdgeInsets.zero, child: Column(children: [
              for (final line in state.cart)
                InfoRow(icon: Icons.shopping_bag_outlined, title: line.product.name,
                  subtitle: '${line.size.label} × ${line.qty}', trailing: money(line.total)),
              const Divider(height: 1, color: AppColors.line),
              InfoRow(icon: Icons.receipt_long, title: 'Item subtotal', trailing: money(state.cartSubtotal)),
            ])),
          const StoreNotice(message: 'Order submission is not connected yet. No order will be placed and you will not be charged. Final delivery charges and discounts must be confirmed by the store.'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FilledButton(onPressed: null, child: Text('Place order')),
          ),
        ],
      )),
    ]));
  }
}

class _DeliveryField extends StatelessWidget {
  const _DeliveryField({required this.label, required this.hint, this.type});
  final String label;
  final String hint;
  final TextInputType? type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(labelText: label),
        autofillHints: [hint],
        keyboardType: type,
        textInputAction: TextInputAction.next,
      ),
    );
  }
}

class InAppOrdersTab extends StatelessWidget {
  const InAppOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final signedIn = state.customer != null;
    return ListView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SectionHeader(eyebrow: 'Purchases', title: 'Order history'),
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.local_shipping_outlined, size: 34, color: AppColors.orange),
          const SizedBox(height: 10),
          Text('Track your delivery', style: displayStyle(size: 21)),
          const SizedBox(height: 8),
          Text(signedIn ? 'Live order tracking is not available in the app yet.'
              : 'Sign in to your itsclear account. Live order tracking is not available in the app yet.',
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted)),
          if (!signedIn && !state.restoringSession) ...[
            const SizedBox(height: 12),
            PrimaryButton(label: 'Sign in to your account', icon: Icons.login,
              onTap: () => pushScreen(context, const SignInScreen())),
          ],
        ])),
        const SectionHeader(eyebrow: 'Documents', title: 'Receipts'),
        const StoreNotice(message: 'Receipts will appear here after the store confirms an order or payment.'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: PrimaryButton(
            label: 'Go to your basket',
            icon: Icons.shopping_bag_outlined,
            onTap: () => AppScope.of(context).goTab(3),
          ),
        ),
      ],
    );
  }
}
