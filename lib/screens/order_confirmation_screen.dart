import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tracking_map_card.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final number = order['orderNumber'] is String ? order['orderNumber'] as String
        : order['id'] as String? ?? 'Order confirmed';
    final rawTotal = order['total'];
    final total = rawTotal is num ? money(rawTotal.round()) : null;
    final status = order['orderStatus'] is String ? (order['orderStatus'] as String).replaceAll('_', ' ')
        : 'confirmed';
    final rawPayment = order['paymentMethod'] is String ? order['paymentMethod'] as String : 'cod';
    final paymentLabel = rawPayment == 'cod' ? 'Cash on delivery' : 'UPI via Razorpay';
    return AppPage(child: Column(children: [
      const AppTopBar(title: 'Order confirmed', back: true),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(18, 26, 18, 26), children: [
        Center(child: Container(
          width: 76, height: 76,
          decoration: const BoxDecoration(color: Color(0xFFEAF6EE), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: AppColors.green, size: 44),
        )),
        const SizedBox(height: 18),
        Text('Thank you for your order', textAlign: TextAlign.center,
          style: displayStyle(size: 24)),
        const SizedBox(height: 7),
        const Text('The store has confirmed your order.', textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 22),
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Eyebrow(text: 'ORDER REFERENCE'),
          const SizedBox(height: 6),
          SelectableText(number, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const Divider(height: 22),
          InfoRow(icon: Icons.payments_outlined, title: 'Payment',
            subtitle: paymentLabel, trailing: total ?? 'Confirmed'),
          InfoRow(icon: Icons.local_shipping_outlined, title: 'Order status',
            subtitle: status, trailing: order['estimatedDelivery'] is String
                ? order['estimatedDelivery'] as String : null),
        ])),
        const SizedBox(height: 14),
        TrackingMapCard(order: order),
        const SizedBox(height: 4),
        PrimaryButton(
          label: 'View my orders',
          icon: Icons.receipt_long_outlined,
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            state.goTab(2);
            state.refreshCustomerOrders();
          },
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Continue shopping')),
      ])),
    ]));
  }
}
