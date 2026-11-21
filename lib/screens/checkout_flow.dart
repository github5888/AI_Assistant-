import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

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
    return ListView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SectionHeader(eyebrow: 'Purchases', title: 'Order history'),
        const StoreNotice(message: 'Order history and tracking are not connected yet.'),
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

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(child: Column(children: [
      AppTopBar(title: 'Sign in', subtitle: 'Your itsclear account', back: true),
      Expanded(child: _SignInOptions()),
    ]));
  }
}

class _SignInOptions extends StatelessWidget {
  const _SignInOptions();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        SectionHeader(eyebrow: 'Mobile number', title: 'Sign in with OTP'),
        SectionCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              enabled: false,
              decoration: InputDecoration(prefixText: '+91 ', labelText: 'Mobile number'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            FilledButton(onPressed: null, child: Text('Send OTP')),
            SizedBox(height: 8),
            Text('OTP sign-in is not connected yet.'),
          ],
        )),
        SectionHeader(eyebrow: 'Or use your account', title: 'Google sign-in'),
        SectionCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(onPressed: null, child: Text('Sign in with Google')),
            SizedBox(height: 8),
            Text('Google sign-in needs app registration and server verification before it can be used.'),
          ],
        )),
      ],
    );
  }
}
