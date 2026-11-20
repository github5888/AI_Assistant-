import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itsclear_app/main.dart';
import 'package:itsclear_app/widgets.dart';

void configurePhone(WidgetTester tester, Size size, {double textScale = 1}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewPadding = const FakeViewPadding(top: 30, bottom: 24);
  tester.view.padding = tester.view.viewPadding;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Finder tab(String name) => find.descendant(
  of: find.byType(BottomDock),
  matching: find.text(name),
);

void main() {
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(360, 640), 1.3),
    (const Size(412, 915), 1.0),
    (const Size(720, 360), 1.0),
  ]) {
    testWidgets('tabs fit ${size.width} × ${size.height} at $scale text scale', (
      tester,
    ) async {
      configurePhone(tester, size, textScale: scale);
      await tester.pumpWidget(const ItsClearApp());
      await tester.pumpAndSettle();

      for (final (label, header) in [
        ('Home', 'Delivering to'),
        ('Shop', 'Shop the harvest'),
        ('Lab', 'Zero-Maida Lab'),
        ('Basket', 'Your basket'),
        ('Profile', 'My account'),
      ]) {
        await tester.tap(tab(label));
        await tester.pumpAndSettle();
        final topBar = find.byType(AppTopBar);
        expect(topBar, findsOneWidget);
        expect(find.descendant(of: topBar, matching: find.text(header)), findsOneWidget);
        final dock = tester.getRect(find.byType(BottomDock));
        expect(tester.getTopLeft(topBar).dy, greaterThanOrEqualTo(30));
        expect(tester.getBottomLeft(topBar).dy, lessThan(dock.top));
        expect(dock.bottom, lessThanOrEqualTo(size.height - 24));
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('product actions stay above system navigation on a small phone', (tester) async {
    configurePhone(tester, const Size(320, 568));
    await tester.pumpWidget(const ItsClearApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shop the harvest'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'product layout');
    expect(find.text('Product details'), findsOneWidget);
    expect(tester.getTopLeft(find.byType(AppTopBar)).dy, 30);
    final add = find.textContaining('Add ·');
    expect(tester.getBottomLeft(add).dy, lessThan(568 - 24));
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Your basket'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'populated basket layout');
  });

  testWidgets('basket dock yields space to the Android keyboard', (tester) async {
    configurePhone(tester, const Size(320, 568));
    await tester.pumpWidget(const ItsClearApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shop the harvest'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Add ·'));
    await tester.pumpAndSettle();

    final coupon = find.byType(TextField);
    await tester.ensureVisible(coupon);
    await tester.showKeyboard(coupon);
    tester.view.padding = const FakeViewPadding(top: 30);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(find.byType(BottomDock), findsNothing);
    await tester.enterText(coupon, 'CLEAR50');
    await tester.pump();
    expect(find.text('CLEAR50'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.resetViewInsets();
    tester.view.padding = tester.view.viewPadding;
    await tester.pumpAndSettle();
    expect(find.byType(BottomDock), findsOneWidget);
  });
}
