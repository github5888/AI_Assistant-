import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itsclear_app/widgets.dart';

void main() {
  testWidgets('long order status details wrap below the title on a narrow phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: Center(child: SizedBox(width: 330, child: Card(child: InfoRow(
        icon: Icons.local_shipping_outlined,
        title: 'Order status',
        subtitle: 'confirmed',
        trailing: 'Within 2 Hours (Express Fresh Chakki Delivery)',
      )))),
    )));

    expect(find.text('Order status'), findsOneWidget);
    expect(find.text('Within 2 Hours (Express Fresh Chakki Delivery)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
