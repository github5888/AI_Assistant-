import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itsclear_app/screens/tracking_map_card.dart';

void main() {
  testWidgets('shows route preview without pretending GPS is live when no location is sent', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: TrackingMapCard(order: {
        'id': 'order-preview',
        'orderStatus': 'confirmed',
        'estimatedDelivery': 'Within 2 Hours',
        'shippingAddress': {
          'addressLine1': '12 Gomti Nagar', 'city': 'Lucknow', 'pincode': '226010',
        },
      })),
    )));
    expect(find.text('Dispatch queued'), findsOneWidget);
    expect(find.text('Within 2 Hours'), findsOneWidget);
    expect(find.text('Schematic preview · waiting for a GPS update'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Open Maps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows partner GPS only for a valid server location payload', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: TrackingMapCard(order: {
        'orderStatus': 'out_for_delivery',
        'tracking': {
          'currentLocation': {'latitude': 26.8467, 'longitude': 80.9462},
          'progress': .55,
          'distanceKm': 6.8,
        },
        'shippingAddress': {'city': 'Lucknow', 'pincode': '226010',
          'location': {'latitude': 26.8467, 'longitude': 80.9462}},
      })),
    )));
    expect(find.text('GPS update received'), findsOneWidget);
    expect(find.text('Exact drop pin'), findsOneWidget);
    expect(find.text('Partner GPS · 26.846700, 80.946200'), findsOneWidget);
    expect(find.text('Open partner pin in Maps'), findsOneWidget);
    expect(find.text('6.8 km'), findsOneWidget);
    expect(find.text('Schematic route · GPS coordinates supplied by store'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
